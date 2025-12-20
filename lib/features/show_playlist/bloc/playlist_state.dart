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
  String toString() =>
      'PlaylistLoadedState, images.length = ${playlist.musicSheets.length} and is loading = $isLoading';

  @override
  List<Object?> get props => [isLoading, playlist];
}

@immutable
class PlaylistErrorState extends PlaylistState {
  final PlaylistError error;

  const PlaylistErrorState({
    required super.playlist,
    super.isLoading = false,
    required this.error,
  });
  @override
  List<Object?> get props => [isLoading, playlist, error];
}

@immutable
class PlaylistReadyToExportState extends PlaylistState {
  final String tempPath;
  final String playlistName;

  const PlaylistReadyToExportState({
    required super.isLoading,
    required super.playlist,
    required this.tempPath,
    required this.playlistName,
  });

  @override
  List<Object?> get props => [isLoading, playlist, tempPath, playlistName];

  @override
  String toString() => 'PlaylistExportedState, tempPath = $tempPath, playlistName = $playlistName';
}

@immutable
class PlaylistExportedState extends PlaylistState {
  const PlaylistExportedState({
    required super.isLoading,
    required super.playlist,
  });

  @override
  List<Object?> get props => [isLoading, playlist];
}

@immutable
class PlaylistExportCancelledState extends PlaylistState {
  const PlaylistExportCancelledState({
    required super.isLoading,
    required super.playlist,
  });

  @override
  List<Object?> get props => [isLoading, playlist];
}
