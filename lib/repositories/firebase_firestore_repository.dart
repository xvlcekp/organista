import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
import 'package:organista/models/users/user_info_key.dart';
import 'package:organista/models/users/user_info_payload.dart';

class FirebaseFirestoreRepository {
  final Iterable<MusicSheet> musicSheets = [];
  final instance = FirebaseFirestore.instance;

  FirebaseFirestoreRepository() {
    instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Stream<Iterable<MusicSheet>> getMusicSheetsStream(String userId) {
  //   return instance
  //       .collection(userId)
  //       // .orderBy(
  //       //   MusicSheetKey.sequenceId,
  //       //   descending: false,
  //       // )
  //       .snapshots(includeMetadataChanges: true)
  //       .where((event) => !event.metadata.hasPendingWrites)
  //       .map((snapshot) {
  //     logger.i("Got new data");
  //     final documents = snapshot.docs;
  //     logger.i("New data documents length: ${documents.length}");
  //     return documents.map((doc) => MusicSheet(
  //           json: doc.data(),
  //         ));
  //   });
  // }

  Future<bool> removeImage({
    required Reference file,
  }) {
    return file.delete().then((_) => true).catchError((_) => false);
  }

  // Nothing to do with playlist, just upload music sheet
  Future<bool> uploadMusicSheetRecord({
    required String fileName,
    required String userId,
    required Reference reference,
    required MediaType mediaType,
  }) async {
    try {
      final firestoreRef = instance.collection(FirebaseCollectionName.musicSheets);
      final musicSheetPayload = MusicSheetPayload(
        fileName: fileName,
        fileUrl: await reference.getDownloadURL(),
        originalFileStorageId: reference.fullPath,
        userId: userId,
        mediaType: mediaType,
      );

      var docRef = await firestoreRef.add(musicSheetPayload);
      musicSheetPayload[MusicSheetKey.musicSheetId] = docRef.id;
      logger.i("Uploading music sheet record");
      await firestoreRef.doc(docRef.id).update(musicSheetPayload);

      return true; // Upload succeeded
    } catch (e) {
      logger.e(e);
      return false; // Upload failed
    }
  }

  Future<bool> uploadNewUser({
    required String userId,
    required String email,
  }) async {
    try {
      final firestoreRef = instance.collection(FirebaseCollectionName.users);
      final userPayload = UserInfoPayload(
        userId: userId,
        displayName: '',
        email: email,
      );
      await firestoreRef.add(userPayload);

      return true; // Upload succeeded
    } catch (e) {
      logger.e(e);
      return false; // Upload failed
    }
  }

  Future<bool> deleteUser({
    required String userId,
  }) async {
    try {
      final firestoreRef = instance.collection(FirebaseCollectionName.users);
      QuerySnapshot querySnapshot = await firestoreRef.where(UserInfoKey.userId, isEqualTo: userId).get();
      await querySnapshot.docs.first.reference.delete();
      logger.i('User with uid $userId was deleted.');

      return true; // Upload succeeded
    } catch (e) {
      logger.e(e);
      return false; // Upload failed
    }
  }

  Stream<Playlist> getPlaylistStream(String playlistId) {
    return instance
        .collection(FirebaseCollectionName.playlists)
        .doc(playlistId)
        .snapshots(
          includeMetadataChanges: true,
        )
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        logger.w("Playlist document does not exist: $playlistId");
        return Playlist.empty(); // Handle missing playlist
      }
      logger.i("Dostal som update na konkretny playlist $playlistId");
      return Playlist(playlistId: playlistId, json: snapshot.data()!);
    });
  }

  Stream<Iterable<Playlist>> getPlaylistsStream(String userId) {
    return instance
        .collection(FirebaseCollectionName.playlists)
        .snapshots(
          includeMetadataChanges: true,
        )
        .where((event) => !event.metadata.hasPendingWrites)
        .map((snapshot) {
      logger.i("Got new playlist data");
      final documents = snapshot.docs;
      logger.i("New playlists documents length: ${documents.length}");
      return documents.map((doc) => Playlist(
            playlistId: doc.id,
            json: doc.data(),
          ));
    });
  }

  Future<bool> addNewPlaylist({
    required String playlistName,
    required String userId,
  }) async {
    try {
      final firestoreRef = instance.collection(FirebaseCollectionName.playlists);
      final playlistPayload = PlaylistPayload(
        userId: userId,
        name: playlistName,
        musicSheets: [],
      );

      await firestoreRef.add(playlistPayload);
      logger.i("Uploading new playlist");

      return true; // Upload succeeded
    } catch (e) {
      logger.e(e);
      return false; // Upload failed
    }
  }

  Future<bool> renamePlaylist({
    required String newPlaylistName,
    required Playlist playlist,
  }) async {
    try {
      final firestoreRef = instance.collection(FirebaseCollectionName.playlists);
      await firestoreRef.doc(playlist.playlistId).update({
        PlaylistKey.name: newPlaylistName,
      });
      logger.i("Renaming playlist ${playlist.name} to $newPlaylistName");

      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }

  Future<bool> deletePlaylist({required Playlist playlist}) async {
    try {
      final firestoreRef = instance.collection(FirebaseCollectionName.playlists);
      await firestoreRef.doc(playlist.playlistId).delete();
      logger.i("Removing playlist ${playlist.name} with id ${playlist.playlistId}");
      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }

  Future<Iterable<MusicSheet>> getMusicSheetsFromRepository(String userId) async {
    final snapshot = await instance.collection(FirebaseCollectionName.musicSheets).where(
      MusicSheetKey.userId,
      whereIn: ['', userId],
    ).get(); // Fetch a single snapshot

    final documents = snapshot.docs;

    // Map each document to a MusicSheet object
    return documents.map((doc) => MusicSheet(
          json: doc.data(),
        ));
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
      return true; // Upload succeeded
    } catch (e, stacktrace) {
      // way how to log errors to crashlytics
      FirebaseCrashlytics.instance.recordError(e, stacktrace);
      return false;
    }
  }

  Future<bool> renameMusicSheetInPlaylist({
    required MusicSheet musicSheet,
    required String fileName,
    required Playlist playlist,
  }) async {
    try {
      final docRef = instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId);
      await docRef.update({
        PlaylistKey.musicSheets: playlist.musicSheets.renameSheet(musicSheet.musicSheetId, fileName).toJsonList(),
      });
      logger.i("musicSheetRename update successful");
      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }

  Future<void> deleteMusicSheetInPlaylist({
    required MusicSheet musicSheet,
    required Playlist playlist,
  }) async {
    logger.e("I want to remove ${musicSheet.fileName}");
    await instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).update({
      PlaylistKey.musicSheets: playlist.musicSheets.removeById(musicSheet.musicSheetId).toJsonList(),
    });
  }

  Future<bool> musicSheetReorder({required Playlist playlist}) async {
    try {
      await instance.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).update({
        PlaylistKey.musicSheets: playlist.musicSheets.toJsonList(),
      });
      logger.i("musicSheetReorder update successful");
    } catch (e) {
      logger.i("musicSheetReorder update failed: $e");
    }
    return true;
  }
}
