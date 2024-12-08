import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';

Future<bool> removeImage({
  required Reference file,
}) =>
    file.delete().then((_) => true).catchError((_) => false);

Future<bool> uploadImage({
  required dynamic file, // Accepts either File or Uint8List
  required String userId,
}) async {
  try {
    final ref = FirebaseStorage.instance.ref(userId).child(const Uuid().v4());

    if (file is File) {
      await ref.putFile(file);
    } else if (file is Uint8List) {
      await ref.putData(file);
    } else {
      throw ArgumentError('Unsupported file type: ${file.runtimeType}');
    }

    return true; // Upload succeeded
  } catch (e) {
    return false; // Upload failed
  }
}
