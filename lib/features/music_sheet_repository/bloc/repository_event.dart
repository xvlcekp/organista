part of 'repository_bloc.dart';

@immutable
abstract class MusicSheetRepositoryEvent extends Equatable {
  const MusicSheetRepositoryEvent();

  @override
  List<Object> get props => [];
}

class InitMusicSheetsRepositoryEvent extends MusicSheetRepositoryEvent {
  final String repositoryId;

  const InitMusicSheetsRepositoryEvent({required this.repositoryId});

  @override
  List<Object> get props => [repositoryId];
}

class UpdateMusicSheetsEvent extends MusicSheetRepositoryEvent {
  final Iterable<MusicSheet> musicSheets;

  const UpdateMusicSheetsEvent(this.musicSheets);

  @override
  List<Object> get props => [musicSheets];
}

class SearchMusicSheets extends MusicSheetRepositoryEvent {
  final String query;

  const SearchMusicSheets({required this.query});

  @override
  List<Object> get props => [query];
}

class DeleteMusicSheet extends MusicSheetRepositoryEvent {
  final MusicSheet musicSheet;
  final String repositoryId;

  const DeleteMusicSheet({
    required this.musicSheet,
    required this.repositoryId,
  });

  @override
  List<Object> get props => [musicSheet, repositoryId];
}
