part of 'playlist_bloc.dart';

@immutable
abstract class PlaylistState extends Equatable {
  final bool isLoading;
  final Playlist playlist;
  final String errorMessage;

  const PlaylistState({
    required this.isLoading,
    required this.playlist,
    this.errorMessage = '',
  });
}

@immutable
class PlaylistInitState extends PlaylistState {
  PlaylistInitState()
      : super(
          isLoading: false,
          playlist: Playlist.empty(),
          errorMessage: '',
        );

  @override
  List<Object?> get props => [isLoading, playlist, errorMessage];
}

@immutable
class PlaylistLoadedState extends PlaylistState {
  const PlaylistLoadedState({
    required super.isLoading,
    required super.playlist,
    super.errorMessage,
  });

  @override
  String toString() => 'PlaylistLoadedState, images.length = ${playlist.musicSheets.length} and is loading = $isLoading';

  @override
  List<Object?> get props => [isLoading, playlist, errorMessage];
}

@immutable
class PlaylistErrorState extends PlaylistState {
  PlaylistErrorState({required String errorMessage})
      : super(
          isLoading: false,
          playlist: Playlist.empty(),
          errorMessage: "Error on initialization",
        );

  @override
  List<Object?> get props => [isLoading, playlist, errorMessage];
}
