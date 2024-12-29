import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/models/music_sheets/music_sheet_key.dart';

@immutable
class MusicSheetPayload extends MapView<String, dynamic> {
  MusicSheetPayload({
    required String fileName,
    required String fileUrl,
    required String originalFileStorageId,
    required int sequenceId,
    required String userId,
  }) : super(
          {
            MusicSheetKey.fileName: fileName,
            MusicSheetKey.fileUrl: fileUrl,
            MusicSheetKey.originalFileStorageId: originalFileStorageId,
            MusicSheetKey.createdAt: FieldValue.serverTimestamp(),
            MusicSheetKey.sequenceId: sequenceId,
            MusicSheetKey.userId: userId,
          },
        );
}
