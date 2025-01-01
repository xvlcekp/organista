import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/models/music_sheets/music_sheet_key.dart';

@immutable
class MusicSheet extends Equatable {
  final String musicSheetId;
  final String userId;
  final DateTime createdAt;
  final String fileUrl;
  final String fileName;
  final String originalFileStorageId;
  final int sequenceId;

  MusicSheet({
    required this.musicSheetId,
    required Map<String, dynamic> json,
  })  : userId = json[MusicSheetKey.userId],
        createdAt = (json[MusicSheetKey.createdAt] as Timestamp).toDate(),
        fileUrl = json[MusicSheetKey.fileUrl],
        fileName = json[MusicSheetKey.fileName],
        originalFileStorageId = json[MusicSheetKey.originalFileStorageId],
        sequenceId = json[MusicSheetKey.sequenceId];

  @override
  String toString() => 'MusicSheet, uid = $userId, createdAt = $createdAt, fileUrl = $fileUrl, fileName = $fileName, originalFileStorageId = $originalFileStorageId, sequenceId = $sequenceId';

  @override
  List<Object?> get props => [
        userId,
        createdAt,
        fileUrl,
        fileName,
        originalFileStorageId,
        sequenceId,
      ];
}
