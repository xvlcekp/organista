import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show PlatformException;
import 'package:organista/config/app_constants.dart';
import 'package:organista/extensions/string_extensions.dart';
import 'package:organista/features/show_playlist/error/playlist_error.dart';
import 'package:organista/features/show_repositories/models/repository_error.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/firebase_collection_name.dart';
import 'package:organista/models/music_sheets/music_sheet_list_extension.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/music_sheets/music_sheet_payload.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/models/playlists/playlist_key.dart';
import 'package:organista/models/playlists/playlist_payload.dart';
import 'package:organista/models/repositories/repository_payload.dart';
import 'package:organista/models/users/user_info_payload.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/models/repositories/repository_key.dart';
import 'package:organista/services/auth/auth_user.dart';

class FirebaseFirestoreRepository {
  final FirebaseFirestore _instance;

  /// Whether a Firebase user is currently signed in. Injectable so tests can exercise
  /// the permission-denied handling without a Firebase app.
  final bool Function() _isUserSignedIn;

  static bool _defaultIsUserSignedIn() => FirebaseAuth.instance.currentUser != null;

  FirebaseFirestoreRepository({
    required FirebaseFirestore instance,
    bool skipSettingsConfiguration = false,
    bool Function() isUserSignedIn = _defaultIsUserSignedIn,
  }) : _instance = instance,
       _isUserSignedIn = isUserSignedIn {
    if (!skipSettingsConfiguration) {
      _instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  }

  /// Extracts the Firestore error code (e.g. `permission-denied`) from an error, or null if it has none.
  ///
  /// cloud_firestore throws either a [FirebaseException] or a [PlatformException], and the
  /// PlatformException shape differs per platform: Android uses the generic code `firebase_firestore`
  /// with the Firestore code in `details['code']`, while iOS puts the Firestore code at the top level.
  String? _firestoreErrorCode(Object error) {
    if (error is FirebaseException) return error.code;
    if (error is! PlatformException) return null;
    final details = error.details;
    if (details is Map && details['code'] is String) return details['code'] as String;
    return error.code;
  }

  /// Checks if an error is a permission-denied error.
  bool _isPermissionDeniedError(Object error) => _firestoreErrorCode(error) == 'permission-denied';

  /// Handles permission-denied errors by checking auth state to distinguish
  /// between transient auth issues (during app resume) and real permission violations.
  void _handlePermissionDenied(String context, Object error, StackTrace stackTrace) {
    if (_isUserSignedIn()) {
      // User is authenticated but access denied - this is a real permission error
      logger.e(
        'Permission denied $context for authenticated user - possible security rules violation',
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      // User not authenticated - likely transient auth state during app resume
      logger.d('Permission denied $context - auth may be transitioning, Firestore will retry automatically');
    }
  }

  /// Logs a failed playlist write. The rules allow owner writes, so `permission-denied` normally means the session
  /// ended (which `AuthBloc` handles) and goes through [_handlePermissionDenied]; anything else is a real error.
  void _logPlaylistWriteFailure(Object e, StackTrace stackTrace, String context) {
    if (_isPermissionDeniedError(e)) {
      _handlePermissionDenied('when $context', e, stackTrace);
      return;
    }
    logger.e('Error $context', error: e, stackTrace: stackTrace);
  }

  /// Executes a Firestore operation with unified error handling for permission-denied errors.
  /// Returns the default value if permission-denied occurs, otherwise rethrows for other error handlers.
  Future<T> _executeWithPermissionHandling<T>({
    required Future<T> Function() operation,
    required T defaultValue,
    required String context,
  }) async {
    try {
      return await operation();
    } on Exception catch (e, stackTrace) {
      if (_isPermissionDeniedError(e)) {
        _handlePermissionDenied(context, e, stackTrace);
        return defaultValue;
      }
      rethrow;
    }
  }

  /// Creates a unified error handler for streams that handles permission-denied errors.
  /// Returns the empty value and logs appropriately based on auth state.
  T Function(Object, StackTrace) _createStreamErrorHandler<T>({
    required T emptyValue,
    required String context,
    required String errorMessage,
  }) {
    return (error, stackTrace) {
      if (_isPermissionDeniedError(error)) {
        _handlePermissionDenied(context, error, stackTrace);
      } else {
        logger.e(errorMessage, error: error, stackTrace: stackTrace);
      }
      return emptyValue;
    };
  }

  // USER OPERATIONS

  /// Creates a new user document in Firestore.
  /// Uses Firebase Auth user ID as document ID to ensure uniqueness.
  /// If user already exists, this will fail silently (Firestore handles duplicates).
  Future<void> createUserDocument({
    required AuthUser user,
  }) async {
    try {
      final userPayload = UserInfoPayload(
        userId: user.id,
        displayName: '',
        email: user.email,
      );

      final userDoc = _instance.collection(FirebaseCollectionName.users).doc(user.id);
      final snapshot = await userDoc.get();

      if (snapshot.exists) {
        logger.i('User document ${user.id} already exists, skipping creation');
        return;
      }

      await userDoc.set(userPayload);

      logger.i('Successfully created user document for ${user.id}');
    } on FirebaseException catch (e) {
      // Re-throw Firebase exceptions
      logger.e('Firebase error creating user document: $e', error: e, stackTrace: StackTrace.current);
      rethrow;
    } catch (e, stackTrace) {
      logger.e('Error creating user document', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> deleteUser({required String userId}) async {
    try {
      await _deleteUserData(userId);
      return true;
    } catch (e, stackTrace) {
      logger.e('Error deleting user', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _deleteUserData(String userId) async {
    try {
      await Future.wait([
        // The users rule is keyed on the document id (`request.auth.uid == userId`), which a field query cannot
        // prove to the rules engine, so the document has to be addressed by id.
        _instance.collection(FirebaseCollectionName.users).doc(userId).delete(),
        _deleteDocuments(FirebaseCollectionName.playlists, PlaylistKey.userId, userId),
        _deleteDocuments(FirebaseCollectionName.repositories, RepositoryKey.userId, userId),
      ]);
      logger.i('${FirebaseCollectionName.users} document $userId was deleted.');
    } catch (e, stackTrace) {
      logger.e('Error in _deleteUserData', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _deleteDocuments(String collectionName, String userKey, String userId) async {
    try {
      final snapshot = await _instance.collection(collectionName).where(userKey, isEqualTo: userId).get();
      await Future.wait(
        snapshot.docs.map((doc) async {
          await doc.reference.delete();
          logger.i('$collectionName document ${doc.id} with user id $userId was deleted.');
        }),
      );
    } catch (e, stackTrace) {
      logger.e('Error deleting documents from $collectionName', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // PLAYLIST OPERATIONS

  Stream<Playlist> getPlaylistStream(String playlistId) {
    return _instance
        .collection(FirebaseCollectionName.playlists)
        .doc(playlistId)
        .snapshots(includeMetadataChanges: true)
        .where((event) => !event.metadata.hasPendingWrites)
        .map((snapshot) {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) {
            logger.w("Playlist document does not exist: $playlistId");
            return Playlist.empty();
          }
          logger.d("Got new update for playlist $playlistId");
          return Playlist(playlistId: playlistId, json: data);
        })
        .transform(
          StreamTransformer<Playlist, Playlist>.fromHandlers(
            handleError: (error, stackTrace, sink) {
              if (_isPermissionDeniedError(error)) {
                // Denied for a deleted playlist (the owner-only rule reads `resource.data`) or an ended session
                // (handled by AuthBloc). Neither is a rules violation, so treat it like a missing document.
                logger.i('Playlist $playlistId is no longer accessible (deleted, or the session ended)');
                sink.add(Playlist.empty());
                return;
              }
              logger.e('Error in getPlaylistStream', error: error, stackTrace: stackTrace);
            },
          ),
        );
  }

  Stream<Iterable<Playlist>> getPlaylistsStream(String userId) {
    return _instance
        .collection(FirebaseCollectionName.playlists)
        .where(PlaylistKey.userId, isEqualTo: userId)
        .orderBy(PlaylistKey.name)
        .snapshots(includeMetadataChanges: true)
        .where((event) => !event.metadata.hasPendingWrites)
        .map((snapshot) {
          final documents = snapshot.docs;
          if (kDebugMode) {
            logger.d("Got new playlist data with length: ${documents.length}");
          }
          return documents.map(
            (doc) => Playlist(
              playlistId: doc.id,
              json: doc.data(),
            ),
          );
        })
        .handleError(
          _createStreamErrorHandler(
            emptyValue: <Playlist>[],
            context: 'when querying playlists for user $userId',
            errorMessage: 'Error in getPlaylistsStream for user $userId',
          ),
        );
  }

  Future<bool> addNewPlaylist({
    required String playlistName,
    required String userId,
  }) async {
    try {
      final playlistPayload = PlaylistPayload(
        userId: userId,
        name: playlistName,
        musicSheets: const [],
      );
      await _instance.collection(FirebaseCollectionName.playlists).add(playlistPayload);
      logger.i("Uploading new playlist");
      return true;
    } catch (e, stackTrace) {
      _logPlaylistWriteFailure(e, stackTrace, 'adding new playlist for user $userId');
      return false;
    }
  }

  Future<bool> renamePlaylist({
    required String newPlaylistName,
    required Playlist playlist,
  }) async {
    try {
      await _instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).update({
        PlaylistKey.name: newPlaylistName,
      });
      logger.i("Renaming playlist ${playlist.name} to $newPlaylistName");
      return true;
    } catch (e, stackTrace) {
      _logPlaylistWriteFailure(e, stackTrace, 'renaming playlist ${playlist.playlistId} to $newPlaylistName');
      return false;
    }
  }

  Future<bool> deletePlaylist({required Playlist playlist}) async {
    try {
      await _instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).delete();
      logger.i("Removing playlist ${playlist.name} with id ${playlist.playlistId}");
      return true;
    } catch (e, stackTrace) {
      _logPlaylistWriteFailure(e, stackTrace, 'deleting playlist ${playlist.playlistId}');
      return false;
    }
  }

  // MUSIC SHEET OPERATIONS

  Future<bool> uploadMusicSheetRecord({
    required String fileName,
    required String userId,
    required Reference reference,
    required MediaType mediaType,
    required String repositoryId,
  }) async {
    try {
      final firestoreRef = _instance
          .collection(FirebaseCollectionName.repositories)
          .doc(repositoryId)
          .collection(FirebaseCollectionName.musicSheets);

      // Generate a document reference with auto-generated ID
      final docRef = firestoreRef.doc();
      final musicSheetPayload = MusicSheetPayload(
        fileName: fileName,
        fileUrl: await reference.getDownloadURL(),
        originalFileStorageId: reference.fullPath,
        userId: userId,
        mediaType: mediaType,
        sequenceId: fileName.sequenceId,
      );

      // Add the music_sheet_id to the payload before creating the document
      // This ensures the stream receives a complete document from the start
      final payloadWithId = {
        ...musicSheetPayload,
        MusicSheetKey.musicSheetId: docRef.id,
      };

      logger.i("Uploading music sheet record");
      await docRef.set(payloadWithId);
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Error uploading music sheet record for user $userId in repository $repositoryId',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> addMusicSheetsToPlaylist({
    required Playlist playlist,
    required List<MusicSheet> musicSheets,
  }) async {
    try {
      // ENFORCE VALIDATION: Always validate capacity before any operation
      playlist.validateCapacityForAdding(musicSheets.length);

      // Create a copy of the current music sheets list to avoid mutating the original
      final updatedMusicSheets = List<MusicSheet>.of(playlist.musicSheets);

      // Add all new music sheets to the copy
      updatedMusicSheets.addAll(musicSheets);

      // Update Firestore with the complete list in a single atomic operation
      await _instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).update({
        PlaylistKey.musicSheets: updatedMusicSheets.toJsonList(),
      });

      return true;
    } on PlaylistCapacityExceededError {
      // Re-throw validation errors so they can be handled by the caller
      rethrow;
    } catch (e, stackTrace) {
      _logPlaylistWriteFailure(e, stackTrace, 'adding multiple music sheets to playlist ${playlist.playlistId}');
      return false;
    }
  }

  bool renameMusicSheetInPlaylist({
    required MusicSheet musicSheet,
    required String fileName,
    required Playlist playlist,
  }) {
    try {
      _instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).update({
        PlaylistKey.musicSheets: playlist.musicSheets.renameSheet(musicSheet.musicSheetId, fileName).toJsonList(),
      });
      logger.d("musicSheetRename update successful");
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Error renaming music sheet ${musicSheet.musicSheetId} in playlist ${playlist.playlistId} to $fileName',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> updateMusicSheetTransposition({
    required MusicSheet musicSheet,
    required int transposition,
    required Playlist playlist,
  }) async {
    try {
      final updatedMusicSheets = playlist.musicSheets
          .map(
            (sheet) =>
                sheet.musicSheetId == musicSheet.musicSheetId ? sheet.copyWith(transposition: transposition) : sheet,
          )
          .toList();
      await _instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).update({
        PlaylistKey.musicSheets: updatedMusicSheets.toJsonList(),
      });
      logger.d(
        'musicSheetTransposition update successful for music sheet ${musicSheet.musicSheetId} in playlist ${playlist.playlistId}',
      );
      return true;
    } catch (e, stackTrace) {
      _logPlaylistWriteFailure(
        e,
        stackTrace,
        'updating transposition for music sheet ${musicSheet.musicSheetId} in playlist ${playlist.playlistId}',
      );
      return false;
    }
  }

  Future<bool> deleteMusicSheetInPlaylist({
    required MusicSheet musicSheet,
    required Playlist playlist,
  }) async {
    try {
      logger.i("Removing music sheet ${musicSheet.fileName} from playlist");
      await _instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).update({
        PlaylistKey.musicSheets: playlist.musicSheets.removeById(musicSheet.musicSheetId).toJsonList(),
      });
      return true;
    } catch (e, stackTrace) {
      _logPlaylistWriteFailure(
        e,
        stackTrace,
        'deleting music sheet ${musicSheet.musicSheetId} from playlist ${playlist.playlistId}',
      );
      return false;
    }
  }

  Future<bool> musicSheetReorder({required Playlist playlist}) async {
    try {
      await _instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).update({
        PlaylistKey.musicSheets: playlist.musicSheets.toJsonList(),
      });
      logger.d("musicSheetReorder update successful");
      return true;
    } catch (e, stackTrace) {
      _logPlaylistWriteFailure(e, stackTrace, 'reordering music sheets in playlist ${playlist.playlistId}');
      return false;
    }
  }

  Future<bool> deleteMusicSheetFromRepository({
    required MusicSheet musicSheet,
    required String repositoryId,
  }) async {
    try {
      final firestoreRef = _instance
          .collection(FirebaseCollectionName.repositories)
          .doc(repositoryId)
          .collection(FirebaseCollectionName.musicSheets);
      await firestoreRef.doc(musicSheet.musicSheetId).delete();
      logger.i(
        "Removing musicSheet ${musicSheet.fileName} with id ${musicSheet.musicSheetId} from repository $repositoryId",
      );
      return true;
    } catch (e, stackTrace) {
      logger.e('Error deleting music sheet from repository', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> renameMusicSheetInRepository({
    required MusicSheet musicSheet,
    required String fileName,
    required String repositoryId,
  }) async {
    try {
      await _instance
          .collection(FirebaseCollectionName.repositories)
          .doc(repositoryId)
          .collection(FirebaseCollectionName.musicSheets)
          .doc(musicSheet.musicSheetId)
          .update({
            MusicSheetKey.fileName: fileName,
          });
      logger.i(
        "Renaming musicSheet ${musicSheet.fileName} with id ${musicSheet.musicSheetId} to $fileName in repository $repositoryId",
      );
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Error renaming music sheet ${musicSheet.musicSheetId} in repository $repositoryId to $fileName',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // REPOSITORY OPERATIONS

  Stream<Iterable<Repository>> getRepositoriesStream({required String userId}) {
    return _instance
        .collection(FirebaseCollectionName.repositories)
        .where(RepositoryKey.userId, whereIn: [userId, ''])
        .snapshots(includeMetadataChanges: true)
        .where((event) => !event.metadata.hasPendingWrites)
        .map((snapshot) {
          final documents = snapshot.docs;
          if (kDebugMode) {
            logger.d("Got repositories data with length: ${documents.length}");
          }
          return documents.map(
            (doc) => Repository(
              json: {
                ...doc.data(),
                RepositoryKey.repositoryId: doc.id,
              },
            ),
          );
        })
        .handleError(
          _createStreamErrorHandler(
            emptyValue: <Repository>[],
            context: 'when querying repositories for user $userId',
            errorMessage: 'Error in getRepositoriesStream for user $userId',
          ),
        );
  }

  Stream<Iterable<MusicSheet>> getRepositoryMusicSheetsStream(String repositoryId) {
    return _instance
        .collection(FirebaseCollectionName.repositories)
        .doc(repositoryId)
        .collection(FirebaseCollectionName.musicSheets)
        .snapshots(includeMetadataChanges: true)
        .where((event) => !event.metadata.hasPendingWrites)
        .map((snapshot) {
          final documents = snapshot.docs;
          logger.d("Got repository music sheets data for repository: $repositoryId with length: ${documents.length}");
          return documents.map((doc) => MusicSheet(json: doc.data()));
        })
        .handleError(
          _createStreamErrorHandler(
            emptyValue: <MusicSheet>[],
            context: 'when querying music sheets for repository $repositoryId',
            errorMessage: 'Error in getRepositoryMusicSheetsStream for repository $repositoryId',
          ),
        );
  }

  Future<bool> createGlobalRepository({required String name}) {
    return _createRepository(userId: '', name: name);
  }

  Future<int> getUserRepositoriesCount({required String userId}) async {
    try {
      return await _executeWithPermissionHandling(
        operation: () async {
          final snapshot = await _instance
              .collection(FirebaseCollectionName.repositories)
              .where(RepositoryKey.userId, isEqualTo: userId)
              .count()
              .get();
          return snapshot.count ?? 0;
        },
        defaultValue: 0,
        context: 'when getting user repositories count for user $userId',
      );
    } catch (e, stackTrace) {
      _handleRepositoryError(e, stackTrace, 'Error getting user repositories count for user $userId');
      return 0;
    }
  }

  Future<bool> createUserRepository({
    required String userId,
    required String name,
  }) async {
    final count = await getUserRepositoriesCount(userId: userId);
    const maximumRepositoriesCount = AppConstants.maximumRepositoriesCount;
    if (count >= maximumRepositoriesCount) {
      logger.i('User $userId already has $maximumRepositoriesCount repositories, skipping creation');
      throw const MaximumRepositoriesCountExceeded(maximumRepositoriesCount: maximumRepositoriesCount);
    }
    return _createRepository(userId: userId, name: name);
  }

  Future<bool> _createRepository({
    required String userId,
    required String name,
  }) async {
    try {
      final repositoryPayload = RepositoryPayload(
        userId: userId,
        name: name,
      );
      await _instance.collection(FirebaseCollectionName.repositories).add(repositoryPayload);
      return true;
    } catch (e, stackTrace) {
      _handleRepositoryError(e, stackTrace, 'Error creating repository');
      return false;
    }
  }

  Future<bool> renameRepository({
    required String repositoryId,
    required String newName,
    required String currentUserId,
  }) async {
    try {
      // First, get the repository to verify ownership
      final repositoriesCollection = _instance.collection(FirebaseCollectionName.repositories);
      final repositoryDoc = await repositoriesCollection.doc(repositoryId).get();

      if (!repositoryDoc.exists) {
        logger.w('Repository $repositoryId not found');
        throw const RepositoryNotFound();
      }

      final repositoryData = repositoryDoc.data()!;
      final repositoryUserId = repositoryData[RepositoryKey.userId] as String;

      // Security check: only allow renaming if repository belongs to the current user
      if (repositoryUserId.isEmpty) {
        logger.w('Attempt to rename public repository $repositoryId by user $currentUserId');
        throw const RepositoryCannotModifyPublic();
      }

      if (repositoryUserId != currentUserId) {
        logger.w(
          'Unauthorized attempt to rename repository $repositoryId by user $currentUserId (owner: $repositoryUserId)',
        );
        throw const RepositoryCannotModifyOtherUsers();
      }

      // Proceed with rename if validation passes
      await repositoriesCollection
          .doc(repositoryId)
          .update({RepositoryKey.name: newName})
          .timeout(const Duration(seconds: 2));
      logger.i("Renaming repository $repositoryId to $newName by user $currentUserId");
      return true;
    } catch (e, stackTrace) {
      _handleRepositoryError(e, stackTrace, 'Error renaming repository');
      return false;
    }
  }

  Future<bool> deleteRepository({
    required String repositoryId,
    required String currentUserId,
  }) async {
    try {
      // First, get the repository to verify ownership
      final repositoriesCollection = _instance.collection(FirebaseCollectionName.repositories);
      final repositoryDoc = await repositoriesCollection.doc(repositoryId).get();

      if (!repositoryDoc.exists) {
        logger.w('Repository $repositoryId not found');
        throw const RepositoryNotFound();
      }

      final repositoryData = repositoryDoc.data()!;
      final repositoryUserId = repositoryData[RepositoryKey.userId] as String;

      // Security check: only allow deleting if repository belongs to the current user
      if (repositoryUserId.isEmpty) {
        logger.w('Attempt to delete public repository $repositoryId by user $currentUserId');
        throw const RepositoryCannotModifyPublic();
      }

      if (repositoryUserId != currentUserId) {
        logger.w(
          'Unauthorized attempt to delete repository $repositoryId by user $currentUserId (owner: $repositoryUserId)',
        );
        throw const RepositoryCannotModifyOtherUsers();
      }

      // Delete all music sheets in the repository first
      final musicSheetsQuery = await repositoriesCollection
          .doc(repositoryId)
          .collection(FirebaseCollectionName.musicSheets)
          .get();

      // Delete all music sheet documents
      for (final doc in musicSheetsQuery.docs) {
        await doc.reference.delete().timeout(const Duration(seconds: 3));
      }

      // Finally, delete the repository itself
      await repositoriesCollection.doc(repositoryId).delete();

      logger.i("Deleting repository $repositoryId by user $currentUserId");
      return true;
    } catch (e, stackTrace) {
      _handleRepositoryError(e, stackTrace, 'Error deleting repository');
      return false;
    }
  }

  Future<int> getRepositoryMusicSheetsCount(String repositoryId) async {
    try {
      return await _executeWithPermissionHandling(
        operation: () async {
          final AggregateQuerySnapshot snapshot = await _instance
              .collection(FirebaseCollectionName.repositories)
              .doc(repositoryId)
              .collection(FirebaseCollectionName.musicSheets)
              .count()
              .get();
          return snapshot.count ?? 0;
        },
        defaultValue: 0,
        context: 'when getting music sheets count for repository $repositoryId',
      );
    } catch (e, stackTrace) {
      _handleRepositoryError(e, stackTrace, 'Error getting music sheets count for repository $repositoryId');
      return 0;
    }
  }

  /// Firestore error codes that indicate a transient connectivity problem rather than a bug.
  /// `unauthenticated` is included because the Firestore SDK fails a call with UNAUTHENTICATED when the
  /// auth token cannot be refreshed, which is what happens when the device goes offline with an expired token.
  static const Set<String> _transientFirestoreErrorCodes = {'unavailable', 'unknown', 'unauthenticated'};

  bool _isTransientFirestoreError(Object e) {
    if (e is! PlatformException) return false;
    return _transientFirestoreErrorCodes.contains(e.code) ||
        _transientFirestoreErrorCodes.contains(_firestoreErrorCode(e));
  }

  void _handleRepositoryError(Object e, StackTrace stackTrace, String logMessage) {
    if (_isTransientFirestoreError(e)) {
      logger.d('$logMessage: Service unavailable, unauthenticated or unknown platform error (likely transient)');
      throw const RepositoryNetworkException();
    } else if (e is TimeoutException) {
      logger.w('$logMessage: Operation timed out');
      throw const RepositoryNetworkException();
    } else if (e is RepositoryError) {
      throw e;
    }
    logger.e(logMessage, error: e, stackTrace: stackTrace);
    throw const RepositoryGenericException();
  }
}
