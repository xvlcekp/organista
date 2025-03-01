import 'package:organista/models/music_sheets/music_sheet.dart';

sealed class MusicSheetRepositoryEvent {}

class LoadMusicSheets extends MusicSheetRepositoryEvent {
  final String userId;
  LoadMusicSheets({required this.userId});
}

class SearchMusicSheets extends MusicSheetRepositoryEvent {
  final String query;
  SearchMusicSheets({required this.query});
}

class DeleteMusicSheet extends MusicSheetRepositoryEvent {
  final MusicSheet musicSheet;
  DeleteMusicSheet({required this.musicSheet});
}
