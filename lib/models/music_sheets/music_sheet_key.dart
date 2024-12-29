import 'package:flutter/foundation.dart' show immutable;

@immutable
class MusicSheetKey {
  static const userId = 'user_id';
  static const createdAt = 'created_at';
  static const fileUrl = 'file_url';
  static const fileName = 'file_name';
  static const originalFileStorageId = 'original_file_storage_id';
  static const sequenceId = 'sequence_id';

  const MusicSheetKey._();
}
