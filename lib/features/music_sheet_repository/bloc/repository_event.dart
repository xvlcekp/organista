import 'package:flutter/foundation.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';

sealed class MusicSheetRepositoryEvent {}

class SearchMusicSheets extends MusicSheetRepositoryEvent {
  final String query;
  SearchMusicSheets({required this.query});
}

class DeleteMusicSheet extends MusicSheetRepositoryEvent {
  final MusicSheet musicSheet;
  final String repositoryId;
  DeleteMusicSheet({
    required this.musicSheet,
    required this.repositoryId,
  });
}

@immutable
class InitMusicSheetsRepositoryEvent implements MusicSheetRepositoryEvent {
  final String repositoryId;
  const InitMusicSheetsRepositoryEvent({required this.repositoryId});
}
