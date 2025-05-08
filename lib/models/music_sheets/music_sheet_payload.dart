import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/extensions/string_extensions.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';

@immutable
class MusicSheetPayload extends MapView<String, dynamic> {
  MusicSheetPayload({
    required String fileName,
    required String fileUrl,
    required String originalFileStorageId,
    required String userId,
    required MediaType mediaType,
    required int sequenceId,
  }) : super(
          {
            MusicSheetKey.fileName: fileName,
            MusicSheetKey.fileUrl: fileUrl,
            MusicSheetKey.originalFileStorageId: originalFileStorageId,
            MusicSheetKey.createdAt: FieldValue.serverTimestamp(),
            MusicSheetKey.userId: userId,
            MusicSheetKey.mediaType: mediaType.name,
            MusicSheetKey.sequenceId: fileName.sequenceId,
          },
        );
}
