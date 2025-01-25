part of 'playlist_cubit.dart';

@immutable
sealed class PlaylistState extends Equatable {
  const PlaylistState({
    required this.playlists,
  });

  final List<Playlist> playlists;
}

@immutable
class InitPlaylistState extends PlaylistState {
  const InitPlaylistState() : super(playlists: const []);

  @override
  List<Object?> get props => [playlists];
}

@immutable
class PlaylistsLoadedState extends PlaylistState {
  const PlaylistsLoadedState({required super.playlists});

  @override
  List<Object?> get props => [playlists];
}

@immutable
class AddPlaylistState extends PlaylistState {
  final String playlistName;
  const AddPlaylistState({
    required super.playlists,
    required this.playlistName,
  });

  @override
  List<Object?> get props => [playlists, playlistName];
}

@immutable
class EditPlaylistState extends PlaylistState {
  final String newPlaylistName;
  final Playlist playlist;
  EditPlaylistState({
    required this.newPlaylistName,
    required this.playlist,
  }) : super(playlists: []);

  @override
  List<Object?> get props => [newPlaylistName, playlist];
}
