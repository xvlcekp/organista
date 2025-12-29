import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/internal/music_sheet_file.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';

class FirebaseStorageRepository {
  final FirebaseStorage _storage;

  FirebaseStorageRepository({required FirebaseStorage storage}) : _storage = storage;

  /// Lists all items in a folder
  Future<ListResult> listFolderContents(String path) {
    return getReference(path).listAll();
  }

  /// Recursively deletes a folder and all its contents
  Future<void> deleteFolder(String path) async {
    try {
      final folderContents = await listFolderContents(path);

      // Delete all items in the folder
      for (final item in folderContents.items) {
        try {
          await item.delete();
        } catch (e, stackTrace) {
          logger.e("Error while deleting item ${item.fullPath} in folder $path", error: e, stackTrace: stackTrace);
        }
      }

      // Delete all subfolders
      for (final folder in folderContents.prefixes) {
        await deleteFolder(folder.fullPath);
      }
    } catch (e, stackTrace) {
      logger.e("Error deleting folder $path", error: e, stackTrace: stackTrace);
    }
  }

  /// Gets a reference to a storage path
  Reference getReference(String path) {
    return _storage.ref(path);
  }

  /// Uploads a file to Firebase Storage and returns the reference
  Future<Reference?> uploadFile({
    required MusicSheetFile file,
    required String bucket,
  }) async {
    try {
      final String uuid = const Uuid().v4();
      final Reference ref = getReference(bucket).child(uuid);
      final String? mimeType = lookupMimeType(file.name);

      logger.i('Uploading file ${file.name} with mime type ${mimeType ?? 'unknown'}');

      if (file.bytes == null) {
        logger.e('File bytes are null, cannot upload file ${file.name}');
        return null;
      }

      await ref.putData(
        file.bytes!,
        SettableMetadata(
          contentType: mimeType,
          customMetadata: {
            'originalFileName': file.name,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      logger.i('Successfully uploaded file to ${ref.fullPath}');
      return ref;
    } catch (e, stackTrace) {
      logger.e('Error uploading file ${file.name}', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
