part of 'show_playlists_cubit.dart';

@immutable
sealed class ShowPlaylistsState extends Equatable {
  const ShowPlaylistsState({
    required this.playlists,
    this.searchQuery = '',
    this.sort = PlaylistSort.name,
  });

  /// All playlists of the user, in the order the playlists stream delivers them (by name).
  final List<Playlist> playlists;
  final String searchQuery;
  final PlaylistSort sort;

  /// [playlists] narrowed to [searchQuery] (case- and diacritic-insensitive) and ordered by [sort].
  List<Playlist> get visiblePlaylists {
    final query = removeDiacritics(searchQuery.toLowerCase());
    final visible = playlists.where((playlist) => removeDiacritics(playlist.name.toLowerCase()).contains(query));
    return switch (sort) {
      PlaylistSort.name => visible.toList(),
      PlaylistSort.newest => visible.sortedBy((playlist) => playlist.createdAt).reversed.toList(),
      PlaylistSort.modified => visible.sortedBy((playlist) => playlist.modifiedAt).reversed.toList(),
    };
  }
}

@immutable
class InitPlaylistState extends ShowPlaylistsState {
  const InitPlaylistState() : super(playlists: const []);

  @override
  List<Object?> get props => [playlists, searchQuery, sort];
}

@immutable
class PlaylistsLoadedState extends ShowPlaylistsState {
  const PlaylistsLoadedState({required super.playlists, super.searchQuery, super.sort, this.error});

  /// Set when a playlist could not be created, renamed, duplicated or deleted; the list itself stays valid.
  final PlaylistError? error;

  @override
  List<Object?> get props => [playlists, searchQuery, sort, error];
}
