import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:uuid/uuid.dart';

class FirebaseStorageRepository {
  final Iterable<MusicSheet> musicSheets = [];
  final instance = FirebaseStorage.instance;

  Future<ListResult> listFolderContents(String path) {
    return instance.ref(path).listAll();
  }

  Future<void> deleteFolder(String path) async {
    final folderContents = await listFolderContents(path);
    for (final item in folderContents.items) {
      await item.delete().catchError((_) {}); // maybe handle the error?
    }
    // delete the folder itself
    await deletePath(path);
  }

  Future<void> deletePath(String path) {
    return instance.ref(path).delete().catchError((_) {});
  }

  Reference getReference(String path) {
    return instance.ref(path);
  }

  Future<Reference?> uploadImage({
    required dynamic file, // Accepts either File or Uint8List
    required String userId,
  }) async {
    String uuid = const Uuid().v4();
    final ref = instance.ref(userId).child(uuid);

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
    return ref; // Upload succeeded
  }
}
