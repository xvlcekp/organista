import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';

@immutable
class MusicSheet extends Equatable {
  final String musicSheetId;
  final String userId;
  final DateTime createdAt;
  final String fileUrl;
  final String fileName;
  final String originalFileStorageId;
  final MediaType mediaType;
  final int sequenceId;
  final int transposition;

  MusicSheet({
    required Map<String, dynamic> json,
  }) : musicSheetId =
           json[MusicSheetKey.musicSheetId] as String? ??
           (throw ArgumentError('${MusicSheetKey.musicSheetId} is required and must be provided from Firebase')),
       userId = json[MusicSheetKey.userId] ?? '',
       createdAt = (json[MusicSheetKey.createdAt] as Timestamp).toDate(),
       fileUrl = json[MusicSheetKey.fileUrl],
       fileName = json[MusicSheetKey.fileName],
       originalFileStorageId = json[MusicSheetKey.originalFileStorageId],
       mediaType = MediaType.fromString(json[MusicSheetKey.mediaType]),
       sequenceId = json[MusicSheetKey.sequenceId] ?? 0,
       transposition = json[MusicSheetKey.transposition] ?? 0;

  Map<String, dynamic> toJson() {
    return {
      MusicSheetKey.musicSheetId: musicSheetId,
      MusicSheetKey.userId: userId,
      MusicSheetKey.createdAt: Timestamp.fromDate(createdAt),
      MusicSheetKey.fileUrl: fileUrl,
      MusicSheetKey.fileName: fileName,
      MusicSheetKey.originalFileStorageId: originalFileStorageId,
      MusicSheetKey.mediaType: mediaType.name,
      MusicSheetKey.sequenceId: sequenceId,
      MusicSheetKey.transposition: transposition,
    };
  }

  MusicSheet copyWith({String? fileName, int? transposition}) {
    return MusicSheet(
      json: {
        MusicSheetKey.musicSheetId: musicSheetId,
        MusicSheetKey.userId: userId,
        MusicSheetKey.createdAt: Timestamp.fromDate(createdAt),
        MusicSheetKey.fileUrl: fileUrl,
        MusicSheetKey.fileName: fileName ?? this.fileName,
        MusicSheetKey.originalFileStorageId: originalFileStorageId,
        MusicSheetKey.mediaType: mediaType.name,
        MusicSheetKey.sequenceId: sequenceId,
        MusicSheetKey.transposition: transposition ?? this.transposition,
      },
    );
  }

  @override
  String toString() {
    return 'MusicSheet, musicSheetId - $musicSheetId, fileName = $fileName';
  }

  @override
  List<Object?> get props => [
    musicSheetId,
    userId,
    createdAt,
    fileUrl,
    fileName,
    originalFileStorageId,
    mediaType,
    sequenceId,
    transposition,
  ];
}
