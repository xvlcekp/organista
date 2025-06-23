part of 'playlist_bloc.dart';

@immutable
abstract class PlaylistState extends Equatable {
  final bool isLoading;
  final Playlist playlist;
  final PlaylistError? error;

  const PlaylistState({
    required this.isLoading,
    required this.playlist,
    this.error,
  });
}

@immutable
class PlaylistInitState extends PlaylistState {
  PlaylistInitState()
      : super(
          isLoading: false,
          playlist: Playlist.empty(),
          error: null,
        );

  @override
  List<Object?> get props => [isLoading, playlist, error];
}

@immutable
class PlaylistLoadedState extends PlaylistState {
  const PlaylistLoadedState({
    required super.isLoading,
    required super.playlist,
    super.error,
  });

  @override
  String toString() =>
      'PlaylistLoadedState, images.length = ${playlist.musicSheets.length} and is loading = $isLoading';

  @override
  List<Object?> get props => [isLoading, playlist, error];
}

@immutable
class PlaylistErrorState extends PlaylistState {
  PlaylistErrorState({required String errorMessage})
      : super(
          isLoading: false,
          playlist: Playlist.empty(),
          error: InitializationError(),
        );

  @override
  List<Object?> get props => [isLoading, playlist, error];
}
