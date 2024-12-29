import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_payload.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';

Future<bool> removeImage({
  required Reference file,
}) {
  return file.delete().then((_) => true).catchError((_) => false);
}

Future<bool> removeMusicSheet({
  required MusicSheet musicSheet,
}) {
  return FirebaseFirestore.instance.collection(musicSheet.userId).doc(musicSheet.musicSheetId).delete().then((_) => true).catchError((_) => false);
}

Future<bool> uploadImage({
  required dynamic file, // Accepts either File or Uint8List
  required String fileName,
  required String userId,
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

    final firestoreRef = FirebaseFirestore.instance.collection(userId);
    final musicSheetPayload = MusicSheetPayload(
      fileName: fileName,
      fileUrl: await ref.getDownloadURL(),
      originalFileStorageId: ref.fullPath,
      sequenceId: 1,
      userId: userId,
    );
    await firestoreRef.add(musicSheetPayload);

    return true; // Upload succeeded
  } catch (e) {
    return false; // Upload failed
  }
}
