import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
import 'package:organista/models/users/user_info_key.dart';
import 'package:organista/models/users/user_info_payload.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/models/repositories/repository_key.dart';
import 'package:organista/services/auth/auth_user.dart';

class FirebaseFirestoreRepository {
  final FirebaseFirestore _instance;

  FirebaseFirestoreRepository({
    required FirebaseFirestore instance,
    bool skipSettingsConfiguration = false,
  }) : _instance = instance {
    if (!skipSettingsConfiguration) {
      _instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
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
        _deleteDocuments(FirebaseCollectionName.users, UserInfoKey.userId, userId),
        _deleteDocuments(FirebaseCollectionName.playlists, PlaylistKey.userId, userId),
        _deleteDocuments(FirebaseCollectionName.repositories, RepositoryKey.userId, userId),
      ]);
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
        .map((snapshot) {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) {
            logger.w("Playlist document does not exist: $playlistId");
            return Playlist.empty();
          }
          logger.i("Got new update for playlist $playlistId");
          return Playlist(playlistId: playlistId, json: data);
        })
        .handleError((error, stackTrace) {
          logger.e('Error in getPlaylistStream', error: error, stackTrace: stackTrace);
          return Playlist.empty();
        });
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
          logger.i("Got new playlist data with length: ${documents.length}");
          return documents.map(
            (doc) => Playlist(
              playlistId: doc.id,
              json: doc.data(),
            ),
          );
        })
        .handleError((error, stackTrace) {
          logger.e('Error in getPlaylistsStream for user $userId', error: error, stackTrace: stackTrace);
          return <Playlist>[];
        });
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
      logger.e('Error adding new playlist for user $userId', error: e, stackTrace: stackTrace);
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
      logger.e(
        'Error renaming playlist ${playlist.playlistId} to $newPlaylistName',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> deletePlaylist({required Playlist playlist}) async {
    try {
      await _instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).delete();
      logger.i("Removing playlist ${playlist.name} with id ${playlist.playlistId}");
      return true;
    } catch (e, stackTrace) {
      logger.e('Error deleting playlist ${playlist.playlistId}', error: e, stackTrace: stackTrace);
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
      logger.e(
        'Error adding multiple music sheets to playlist ${playlist.playlistId}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> renameMusicSheetInPlaylist({
    required MusicSheet musicSheet,
    required String fileName,
    required Playlist playlist,
  }) async {
    try {
      await _instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).update({
        PlaylistKey.musicSheets: playlist.musicSheets.renameSheet(musicSheet.musicSheetId, fileName).toJsonList(),
      });
      logger.i("musicSheetRename update successful");
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
      logger.e(
        'Error deleting music sheet ${musicSheet.musicSheetId} from playlist ${playlist.playlistId}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> musicSheetReorder({required Playlist playlist}) async {
    try {
      await _instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).update({
        PlaylistKey.musicSheets: playlist.musicSheets.toJsonList(),
      });
      logger.i("musicSheetReorder update successful");
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Error reordering music sheets in playlist ${playlist.playlistId}',
        error: e,
        stackTrace: stackTrace,
      );
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

  // REPOSITORY OPERATIONS

  Stream<Iterable<Repository>> getRepositoriesStream({required String userId}) {
    return _instance
        .collection(FirebaseCollectionName.repositories)
        .where(RepositoryKey.userId, whereIn: [userId, ''])
        .snapshots(includeMetadataChanges: true)
        .where((event) => !event.metadata.hasPendingWrites)
        .map((snapshot) {
          final documents = snapshot.docs;
          logger.i("Got repositories data with length: ${documents.length}");
          return documents.map(
            (doc) => Repository(
              json: {
                ...doc.data(),
                RepositoryKey.repositoryId: doc.id,
              },
            ),
          );
        })
        .handleError((error, stackTrace) {
          logger.e('Error in getRepositoriesStream for user $userId', error: error, stackTrace: stackTrace);
          return <Repository>[];
        });
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
          logger.i("Got repository music sheets data for repository: $repositoryId with length: ${documents.length}");
          return documents.map((doc) => MusicSheet(json: doc.data()));
        })
        .handleError((error, stackTrace) {
          logger.e(
            'Error in getRepositoryMusicSheetsStream for repository $repositoryId',
            error: error,
            stackTrace: stackTrace,
          );
          return <MusicSheet>[];
        });
  }

  Future<bool> createGlobalRepository({required String name}) {
    return _createRepository(userId: '', name: name);
  }

  Future<int> getUserRepositoriesCount({required String userId}) async {
    try {
      final snapshot = await _instance
          .collection(FirebaseCollectionName.repositories)
          .where(RepositoryKey.userId, isEqualTo: userId)
          .count()
          .get();
      return snapshot.count ?? 0;
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
      final AggregateQuerySnapshot snapshot = await _instance
          .collection(FirebaseCollectionName.repositories)
          .doc(repositoryId)
          .collection(FirebaseCollectionName.musicSheets)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e, stackTrace) {
      _handleRepositoryError(e, stackTrace, 'Error getting music sheets count for repository $repositoryId');
      return 0;
    }
  }

  void _handleRepositoryError(Object e, StackTrace stackTrace, String logMessage) {
    if (e is PlatformException && e.code == 'firebase_firestore' && e.details['code'] == 'unavailable') {
      logger.w('$logMessage: Service unavailable (offline)');
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
