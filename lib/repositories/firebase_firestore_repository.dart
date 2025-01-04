import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/music_sheets/music_sheet_payload.dart';
import 'package:uuid/uuid.dart';

class FirebaseFirestoreRepository {
  final Iterable<MusicSheet> musicSheets = [];
  final instance = FirebaseFirestore.instance;
  final logger = CustomLogger.instance;

  Stream<Iterable<MusicSheet>> getMusicSheetsStream(String userId) {
    return instance.collection(userId).orderBy(MusicSheetKey.sequenceId, descending: false).snapshots(includeMetadataChanges: true).map((snapshot) {
      logger.i("Got new data");
      final documents = snapshot.docs;
      logger.i("New data documents length: ${documents.length}");
      return documents.where((doc) => !doc.metadata.hasPendingWrites).map((doc) => MusicSheet(
            musicSheetId: doc.id,
            json: doc.data(),
          ));
    });
  }

  Future<bool> musicSheetReorder({required Iterable<MusicSheet> musicSheets}) async {
    final batch = instance.batch();

    for (int i = 0; i < musicSheets.length; i++) {
      final musicSheet = musicSheets.elementAt(i);
      logger.i("Updating ${musicSheet.fileName} to $i");

      // Reference to the document
      final docRef = instance.collection(musicSheet.userId).doc(musicSheet.musicSheetId);

      // Add the update operation to the batch
      batch.update(docRef, {MusicSheetKey.sequenceId: i});
    }

    // Commit the batch
    try {
      await batch.commit();
      logger.i("Batch update successful");
    } catch (e) {
      logger.i("Batch update failed: $e");
    }
    return true;
  }

  Future<bool> removeImage({
    required Reference file,
  }) {
    return file.delete().then((_) => true).catchError((_) => false);
  }

  Future<bool> removeMusicSheet({required MusicSheet musicSheet}) {
    return instance.collection(musicSheet.userId).doc(musicSheet.musicSheetId).delete().then((_) => true).catchError((_) => false);
  }

  Future<bool> uploadImage({
    required dynamic file, // Accepts either File or Uint8List
    required String fileName,
    required String userId,
    required int totalMusicSheets,
  }) async {
    try {
      String uuid = const Uuid().v4();
      final ref = FirebaseStorage.instance.ref(userId).child(uuid);

      // Convert filePath to File
      if (file is String) {
        file = File(file);
      }

      if (file is File) {
        await ref.putFile(file);
      } else if (file is Uint8List) {
        await ref.putData(file);
      } else {
        throw ArgumentError('Unsupported file type: ${file.runtimeType}');
      }

      final firestoreRef = instance.collection(userId);
      final musicSheetPayload = MusicSheetPayload(
        fileName: fileName,
        fileUrl: await ref.getDownloadURL(),
        originalFileStorageId: ref.fullPath,
        sequenceId: totalMusicSheets,
        userId: userId,
      );
      await firestoreRef.add(musicSheetPayload);

      return true; // Upload succeeded
    } catch (e) {
      return false; // Upload failed
    }
  }
}
