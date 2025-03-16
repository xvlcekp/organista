import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/models/firebase_collection_name.dart';
import 'package:organista/models/firebase_common_keys.dart';

@immutable
class RepositoryKey {
  static const repositoryId = 'repository_id';
  static const name = 'name';
  static const userId = FirebaseCommonKeys.userId;
  static const createdAt = FirebaseCommonKeys.createdAt;
  static const musicSheets = FirebaseCollectionName.musicSheets;

  const RepositoryKey._();
}
