part of 'playlist_cubit.dart';

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

@immutable
class AddPlaylistState extends ShowPlaylistsState {
  final String playlistName;
  const AddPlaylistState({
    required super.playlists,
    required this.playlistName,
  });

  @override
  List<Object?> get props => [playlists, playlistName];
}

@immutable
class EditPlaylistState extends ShowPlaylistsState {
  final String newPlaylistName;
  final Playlist playlist;
  EditPlaylistState({
    required this.newPlaylistName,
    required this.playlist,
  }) : super(playlists: []);

  @override
  List<Object?> get props => [newPlaylistName, playlist];
}
