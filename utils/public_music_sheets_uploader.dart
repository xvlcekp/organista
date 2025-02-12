import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:organista/firebase_options.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final FirebaseFirestoreRepository firebaseFirestoreRepositary = FirebaseFirestoreRepository();
  final FirebaseStorageRepository firebaseStorageRepository = FirebaseStorageRepository();
  try {
    File file = File('C:/Users/Pavol Vlcek/Downloads/todo streda.txt');
    Uint8List fileAsUint8List = file.readAsBytesSync();
    final reference = await firebaseStorageRepository.uploadImage(
      file: fileAsUint8List,
      userId: '',
    );
    if (reference != null) {
      await firebaseFirestoreRepositary.uploadMusicSheetRecord(
        reference: reference,
        userId: '',
        fileName: 'nazov_suboru.pdf',
        mediaType: MediaType.pdf,
      );
    } else {
      throw Exception('Failed to upload image, not uploading MusicSheet record to Firestore');
    }
  } catch (e) {
    CustomLogger.instance.e('Failed to upload image: $e');
  }
}
