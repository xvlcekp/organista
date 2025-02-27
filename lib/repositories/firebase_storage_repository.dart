import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';

class FirebaseStorageRepository {
  final Iterable<MusicSheet> musicSheets = [];
  final instance = FirebaseStorage.instance;

  Future<ListResult> listFolderContents(String path) {
    return instance.ref(path).listAll();
  }

  Future<void> deleteFolder(String path) async {
    final folderContents = await listFolderContents(path);
    for (final item in folderContents.items) {
      await item.delete().catchError((e) {
        logger.e("Error while deleting item in folder");
        logger.e(e);
      }); // maybe handle the error?
    }
    // delete the folder itself
    await deletePath(path);
  }

  Future<void> deletePath(String path) {
    return instance.ref(path).delete().catchError((e) {
      logger.e(e);
    });
  }

  Reference getReference(String path) {
    return instance.ref(path);
  }

  Future<Reference?> uploadFile({
    required PlatformFile file,
    required String bucket,
  }) async {
    String uuid = const Uuid().v4();
    final ref = instance.ref(bucket).child(uuid);
    logger.i('Mime type is ' + (lookupMimeType(file.name) ?? ''));
    await ref.putData(
      file.bytes!,
      SettableMetadata(
        contentType: lookupMimeType(file.name),
      ),
    );

    return ref; // Upload succeeded
  }
}
