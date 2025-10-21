part of 'music_sheet_repository_bloc.dart';

@immutable
abstract class MusicSheetRepositoryState extends Equatable {
  const MusicSheetRepositoryState();

  @override
  List<Object> get props => [];
}

class MusicSheetRepositoryInitial extends MusicSheetRepositoryState {}

class MusicSheetRepositoryLoading extends MusicSheetRepositoryState {}

class MusicSheetRepositoryLoaded extends MusicSheetRepositoryState {
  final List<MusicSheet> allMusicSheets;
  final List<MusicSheet> filteredMusicSheets;
  final String searchQuery;

  const MusicSheetRepositoryLoaded({
    required this.allMusicSheets,
    required this.filteredMusicSheets,
    this.searchQuery = '',
  });

  @override
  List<Object> get props => [allMusicSheets, filteredMusicSheets, searchQuery];
}

class MusicSheetRepositoryError extends MusicSheetRepositoryState {
  final String message;

  const MusicSheetRepositoryError(this.message);

  @override
  List<Object> get props => [message];
}
