import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:organista/extensions/string_extensions.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/firebase_collection_name.dart';
import 'package:organista/models/music_sheets/list_music_sheet_extension.dart';
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
  final instance = FirebaseFirestore.instance;

  FirebaseFirestoreRepository() {
    instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // USER OPERATIONS

  Future<bool> uploadNewUser({
    required AuthUser user,
  }) async {
    try {
      // Check if user already exists
      final existingUserQuery = await instance.collection(FirebaseCollectionName.users).where(UserInfoKey.userId, isEqualTo: user.id).limit(1).get();

      if (existingUserQuery.docs.isNotEmpty) {
        logger.i('User ${user.id} already exists in database, skipping creation');
        return true; // User already exists, no need to create
      }

      // User doesn't exist, create new user
      final userPayload = UserInfoPayload(
        userId: user.id,
        displayName: '',
        email: user.email,
      );
      await instance.collection(FirebaseCollectionName.users).add(userPayload);
      logger.i('Successfully created new user ${user.id} in database');
      return true;
    } catch (e, stackTrace) {
      logger.e('Error uploading new user: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error uploading new user');
      return false;
    }
  }

  Future<bool> deleteUser({required String userId}) async {
    try {
      await _deleteUserData(userId);
      return true;
    } catch (e, stackTrace) {
      logger.e('Error deleting user: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error deleting user');
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
      logger.e('Error in _deleteUserData: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error deleting user data');
      rethrow;
    }
  }

  Future<void> _deleteDocuments(String collectionName, String userKey, String userId) async {
    try {
      final snapshot = await instance.collection(collectionName).where(userKey, isEqualTo: userId).get();
      await Future.wait(snapshot.docs.map((doc) async {
        await doc.reference.delete();
        logger.i('$collectionName document ${doc.id} with user id $userId was deleted.');
      }));
    } catch (e, stackTrace) {
      logger.e('Error deleting documents from $collectionName: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error deleting documents');
      rethrow;
    }
  }

  // PLAYLIST OPERATIONS

  Stream<Playlist> getPlaylistStream(String playlistId) {
    return instance.collection(FirebaseCollectionName.playlists).doc(playlistId).snapshots(includeMetadataChanges: true).map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        logger.w("Playlist document does not exist: $playlistId");
        return Playlist.empty();
      }
      logger.i("Got new update for playlist $playlistId");
      return Playlist(playlistId: playlistId, json: snapshot.data()!);
    }).handleError((error, stackTrace) {
      logger.e('Error in getPlaylistStream: $error');
      FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: 'Error in playlist stream');
      return Playlist.empty();
    });
  }

  Stream<Iterable<Playlist>> getPlaylistsStream(String userId) {
    return instance
        .collection(FirebaseCollectionName.playlists)
        .where(PlaylistKey.userId, isEqualTo: userId)
        .orderBy(PlaylistKey.name)
        .snapshots(includeMetadataChanges: true)
        .where((event) => !event.metadata.hasPendingWrites)
        .map((snapshot) {
      final documents = snapshot.docs;
      logger.i("Got new playlist data with length: ${documents.length}");
      return documents.map((doc) => Playlist(
            playlistId: doc.id,
            json: doc.data(),
          ));
    }).handleError((error, stackTrace) {
      logger.e('Error in getPlaylistsStream: $error');
      FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: 'Error in playlists stream');
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
        musicSheets: [],
      );
      await instance.collection(FirebaseCollectionName.playlists).add(playlistPayload);
      logger.i("Uploading new playlist");
      return true;
    } catch (e, stackTrace) {
      logger.e('Error adding new playlist: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error adding new playlist');
      return false;
    }
  }

  Future<bool> renamePlaylist({
    required String newPlaylistName,
    required Playlist playlist,
  }) async {
    try {
      await instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).update({
        PlaylistKey.name: newPlaylistName,
      });
      logger.i("Renaming playlist ${playlist.name} to $newPlaylistName");
      return true;
    } catch (e, stackTrace) {
      logger.e('Error renaming playlist: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error renaming playlist');
      return false;
    }
  }

  Future<bool> deletePlaylist({required Playlist playlist}) async {
    try {
      await instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).delete();
      logger.i("Removing playlist ${playlist.name} with id ${playlist.playlistId}");
      return true;
    } catch (e, stackTrace) {
      logger.e('Error deleting playlist: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error deleting playlist');
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
      final firestoreRef = instance.collection(FirebaseCollectionName.repositories).doc(repositoryId).collection(FirebaseCollectionName.musicSheets);

      final musicSheetPayload = MusicSheetPayload(
        fileName: fileName,
        fileUrl: await reference.getDownloadURL(),
        originalFileStorageId: reference.fullPath,
        userId: userId,
        mediaType: mediaType,
        sequenceId: fileName.sequenceId,
      );

      var docRef = await firestoreRef.add(musicSheetPayload);
      musicSheetPayload[MusicSheetKey.musicSheetId] = docRef.id;
      logger.i("Uploading music sheet record");
      await firestoreRef.doc(docRef.id).update(musicSheetPayload);
      return true;
    } catch (e, stackTrace) {
      logger.e('Error uploading music sheet record: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error uploading music sheet record');
      return false;
    }
  }

  Future<bool> addMusicSheetToPlaylist({
    required Playlist playlist,
    required MusicSheet musicSheet,
  }) async {
    try {
      playlist.musicSheets.add(musicSheet);
      await instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).update({
        PlaylistKey.musicSheets: playlist.musicSheets.toJsonList(),
      });
      return true;
    } catch (e, stackTrace) {
      logger.e('Error adding music sheet to playlist: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error adding music sheet to playlist');
      return false;
    }
  }

  Future<bool> renameMusicSheetInPlaylist({
    required MusicSheet musicSheet,
    required String fileName,
    required Playlist playlist,
  }) async {
    try {
      await instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).update({
        PlaylistKey.musicSheets: playlist.musicSheets.renameSheet(musicSheet.musicSheetId, fileName).toJsonList(),
      });
      logger.i("musicSheetRename update successful");
      return true;
    } catch (e, stackTrace) {
      logger.e('Error renaming music sheet in playlist: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error renaming music sheet');
      return false;
    }
  }

  Future<bool> deleteMusicSheetInPlaylist({
    required MusicSheet musicSheet,
    required Playlist playlist,
  }) async {
    try {
      logger.i("Removing music sheet ${musicSheet.fileName} from playlist");
      await instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).update({
        PlaylistKey.musicSheets: playlist.musicSheets.removeById(musicSheet.musicSheetId).toJsonList(),
      });
      return true;
    } catch (e, stackTrace) {
      logger.e('Error deleting music sheet from playlist: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error deleting music sheet from playlist');
      return false;
    }
  }

  Future<bool> musicSheetReorder({required Playlist playlist}) async {
    try {
      await instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).update({
        PlaylistKey.musicSheets: playlist.musicSheets.toJsonList(),
      });
      logger.i("musicSheetReorder update successful");
      return true;
    } catch (e, stackTrace) {
      logger.e('Error reordering music sheets: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error reordering music sheets');
      return false;
    }
  }

  Future<bool> deleteMusicSheetFromRepository({
    required MusicSheet musicSheet,
    required String repositoryId,
  }) async {
    try {
      final firestoreRef = instance.collection(FirebaseCollectionName.repositories).doc(repositoryId).collection(FirebaseCollectionName.musicSheets);
      await firestoreRef.doc(musicSheet.musicSheetId).delete();
      logger.i("Removing musicSheet ${musicSheet.fileName} with id ${musicSheet.musicSheetId} from repository $repositoryId");
      return true;
    } catch (e, stackTrace) {
      logger.e('Error deleting music sheet from repository: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error deleting music sheet from repository');
      return false;
    }
  }

  // REPOSITORY OPERATIONS

  Stream<Iterable<Repository>> getRepositoriesStream({required String userId}) {
    return instance
        .collection(FirebaseCollectionName.repositories)
        .where(RepositoryKey.userId, whereIn: [userId, ''])
        .snapshots(includeMetadataChanges: true)
        .where((event) => !event.metadata.hasPendingWrites)
        .map((snapshot) {
          final documents = snapshot.docs;
          logger.i("Got repositories data with length: ${documents.length}");
          return documents.map((doc) => Repository(
                json: {
                  ...doc.data(),
                  RepositoryKey.repositoryId: doc.id,
                },
              ));
        })
        .handleError((error, stackTrace) {
          logger.e('Error in getRepositoriesStream: $error');
          FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: 'Error in repositories stream');
          return <Repository>[];
        });
  }

  Stream<Iterable<MusicSheet>> getRepositoryMusicSheetsStream(String repositoryId) {
    return instance
        .collection(FirebaseCollectionName.repositories)
        .doc(repositoryId)
        .collection(FirebaseCollectionName.musicSheets)
        .snapshots(includeMetadataChanges: true)
        .where((event) => !event.metadata.hasPendingWrites)
        .map((snapshot) {
      final documents = snapshot.docs;
      logger.i("Got repository music sheets data for repository: $repositoryId with length: ${documents.length}");
      return documents.map((doc) => MusicSheet(json: doc.data()));
    }).handleError((error, stackTrace) {
      logger.e('Error in getRepositoryMusicSheetsStream: $error');
      FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: 'Error in repository music sheets stream');
      return <MusicSheet>[];
    });
  }

  Future<bool> createGlobalRepository({required String name}) async {
    return _createRepository(userId: '', name: name);
  }

  Future<bool> createUserRepository({required AuthUser user}) async {
    // Check if user repository already exists
    final existingRepoQuery = await instance.collection(FirebaseCollectionName.repositories).where(RepositoryKey.userId, isEqualTo: user.id).limit(1).get();

    if (existingRepoQuery.docs.isNotEmpty) {
      logger.i('User repository for ${user.id} already exists, skipping creation');
      return true; // Repository already exists, no need to create
    }

    // Repository doesn't exist, create new user repository
    return _createRepository(userId: user.id, name: 'Custom repository - ${user.email}');
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
      await instance.collection(FirebaseCollectionName.repositories).add(repositoryPayload);
      return true;
    } catch (e, stackTrace) {
      logger.e('Error creating repository: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error creating repository');
      return false;
    }
  }

  Future<int> getRepositoryMusicSheetsCount(String repositoryId) async {
    try {
      final AggregateQuerySnapshot snapshot = await instance.collection(FirebaseCollectionName.repositories).doc(repositoryId).collection(FirebaseCollectionName.musicSheets).count().get();
      return snapshot.count ?? 0;
    } catch (e, stackTrace) {
      logger.e('Error getting music sheets count: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error getting music sheets count');
      return 0;
    }
  }
}
