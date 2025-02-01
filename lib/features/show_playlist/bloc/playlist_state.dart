part of 'playlist_bloc.dart';

@immutable
abstract class PlaylistState extends Equatable {
  final bool isLoading;
  final Playlist playlist;

  const PlaylistState({
    required this.isLoading,
    required this.playlist,
  });
}

@immutable
class PlaylistInitState extends PlaylistState {
  PlaylistInitState() : super(isLoading: false, playlist: Playlist.empty());

  @override
  List<Object?> get props => [isLoading, playlist];
}

@immutable
class PlaylistLoadedState extends PlaylistState {
  const PlaylistLoadedState({
    required super.isLoading,
    required super.playlist,
  });

  @override
  String toString() => 'PlaylistLoadedState, images.length = ${playlist.musicSheets.length} and is loading = $isLoading';

  @override
  List<Object?> get props => [isLoading, playlist, playlist.musicSheets.length];
}

@immutable
class PlaylistErrorState extends PlaylistState {
  PlaylistErrorState() : super(isLoading: false, playlist: Playlist.empty());

  @override
  List<Object?> get props => [isLoading, playlist];
}
