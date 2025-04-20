import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:organista/config/app_constants.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';

class FirebaseStorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Lists all items in a folder
  Future<ListResult> listFolderContents(String path) {
    return _storage.ref(path).listAll();
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
          logger.e("Error while deleting item ${item.fullPath} in folder $path: $e");
          FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error deleting storage item');
        }
      }

      // Delete all subfolders
      for (final folder in folderContents.prefixes) {
        await deleteFolder(folder.fullPath);
      }

      // Delete the folder itself
      await deletePath(path);
    } catch (e, stackTrace) {
      logger.e("Error deleting folder $path: $e");
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error deleting storage folder');
    }
  }

  /// Deletes a specific path from storage
  Future<void> deletePath(String path) async {
    try {
      await _storage.ref(path).delete();
    } catch (e, stackTrace) {
      logger.e("Error deleting path $path: $e");
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error deleting storage path');
    }
  }

  /// Gets a reference to a storage path
  Reference getReference(String path) {
    return _storage.ref(path);
  }

  /// Uploads a file to Firebase Storage and returns the reference
  Future<Reference?> uploadFile({
    required PlatformFile file,
    required String bucket,
  }) async {
    try {
      // Check file size
      if (file.size > AppConstants.maxFileSizeBytes) {
        logger.e('File ${file.name} is too large. Maximum size is ${AppConstants.maxFileSizeMB}MB.');
        throw Exception('File is too large. Maximum size is ${AppConstants.maxFileSizeMB}MB.');
      }

      final String uuid = const Uuid().v4();
      final Reference ref = _storage.ref(bucket).child(uuid);
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
      logger.e('Error uploading file ${file.name}: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Error uploading file');
      return null;
    }
  }
}
