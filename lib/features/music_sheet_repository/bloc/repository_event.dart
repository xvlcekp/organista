sealed class MusicSheetRepositoryEvent {}

class LoadMusicSheets extends MusicSheetRepositoryEvent {
  final String userId;
  LoadMusicSheets({required this.userId});
}

class SearchMusicSheets extends MusicSheetRepositoryEvent {
  final String query;
  SearchMusicSheets(this.query);
}
