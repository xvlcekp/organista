part of 'playlist_bloc.dart';

@immutable
abstract class PlaylistEvent extends Equatable {
  const PlaylistEvent();

  @override
  List<Object?> get props => [];
}

@immutable
class InitPlaylistEvent extends PlaylistEvent {
  final AuthUser user;
  final Playlist playlist;
  const InitPlaylistEvent({required this.user, required this.playlist});

  @override
  List<Object?> get props => [user, playlist];
}

@immutable
class DeleteMusicSheetInPlaylistEvent extends PlaylistEvent {
  final MusicSheet musicSheet;
  final Playlist playlist;

  const DeleteMusicSheetInPlaylistEvent({
    required this.musicSheet,
    required this.playlist,
  });

  @override
  List<Object?> get props => [musicSheet, playlist];
}

@immutable
class ReorderMusicSheetEvent extends PlaylistEvent {
  final Playlist playlist;

  const ReorderMusicSheetEvent({
    required this.playlist,
  });

  @override
  List<Object?> get props => [playlist];
}

@immutable
class AddMusicSheetsToPlaylistEvent extends PlaylistEvent {
  final List<MusicSheet> musicSheets;
  final Playlist playlist;

  const AddMusicSheetsToPlaylistEvent({
    required this.musicSheets,
    required this.playlist,
  });

  @override
  List<Object?> get props => [musicSheets, playlist];
}
