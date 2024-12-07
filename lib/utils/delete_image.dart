import 'package:firebase_storage/firebase_storage.dart';

Future<bool> removeImage({required Reference file}) => file.delete().then((_) => true).catchError((_) => false);
