import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/models/firebase_common_keys.dart';

@immutable
class MusicSheetKey {
  static const musicSheetId = 'music_sheet_id';
  static const userId = FirebaseCommonKeys.userId;
  static const createdAt = FirebaseCommonKeys.createdAt;
  static const fileUrl = 'file_url';
  static const fileName = 'file_name';
  static const originalFileStorageId = 'original_file_storage_id';
  static const sequenceId = 'sequence_id';

  const MusicSheetKey._();
}
