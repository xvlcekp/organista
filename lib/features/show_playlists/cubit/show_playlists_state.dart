part of 'show_playlists_cubit.dart';

@immutable
sealed class ShowPlaylistsState extends Equatable {
  const ShowPlaylistsState({
    required this.playlists,
  });

  final List<Playlist> playlists;
}

@immutable
class InitPlaylistState extends ShowPlaylistsState {
  const InitPlaylistState() : super(playlists: const []);

  @override
  List<Object?> get props => [playlists];
}

@immutable
class PlaylistsLoadedState extends ShowPlaylistsState {
  const PlaylistsLoadedState({required super.playlists});

  @override
  List<Object?> get props => [playlists];
}
