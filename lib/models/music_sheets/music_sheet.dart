import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:uuid/uuid.dart';

@immutable
class MusicSheet extends Equatable {
  final String musicSheetId;
  final String userId;
  final DateTime createdAt;
  final String fileUrl;
  final String fileName;
  final String originalFileStorageId;
  final int sequenceId;

  // TODO:  Uuid().v4() should be probably removed, because we want to use IDs generated from Firebase
  MusicSheet({
    required Map<String, dynamic> json,
  })  : musicSheetId = json[MusicSheetKey.musicSheetId] ?? Uuid().v4(),
        userId = json[MusicSheetKey.userId] ?? '',
        createdAt = (json[MusicSheetKey.createdAt] as Timestamp).toDate(),
        fileUrl = json[MusicSheetKey.fileUrl],
        fileName = json[MusicSheetKey.fileName],
        originalFileStorageId = json[MusicSheetKey.originalFileStorageId],
        sequenceId = json[MusicSheetKey.sequenceId];

  Map<String, dynamic> toJson() {
    return {
      MusicSheetKey.musicSheetId: musicSheetId,
      MusicSheetKey.userId: userId,
      MusicSheetKey.createdAt: createdAt,
      MusicSheetKey.fileUrl: fileUrl,
      MusicSheetKey.fileName: fileName,
      MusicSheetKey.originalFileStorageId: originalFileStorageId,
      MusicSheetKey.sequenceId: sequenceId
    };
  }

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
