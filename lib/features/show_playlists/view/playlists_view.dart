import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/config/app_theme.dart';
import 'package:organista/dialogs/error_dialog.dart';
import 'package:organista/features/authentication/auth_bloc/auth_bloc.dart';
import 'package:organista/features/show_playlists/cubit/playlist_sort.dart';
import 'package:organista/features/show_playlists/view/add_playlist_dialog.dart';
import 'package:organista/features/show_playlists/view/playlist_sort_sheet.dart';
import 'package:organista/features/show_playlists/view/playlist_tile.dart';
import 'package:organista/features/show_playlist/error/playlist_error.dart';
import 'package:organista/features/show_playlists/cubit/show_playlists_cubit.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/widgets/empty_list_widget.dart';
import 'package:organista/widgets/scroll_aware_fab.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

class PlaylistsView extends HookWidget {
  const PlaylistsView({super.key});

  static const double _searchRowPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    final AuthUser user = context.read<AuthBloc>().state.user!;
    final String userId = user.id;
    final localizations = context.loc;
    final scrollController = useScrollController();

    useEffect(() {
      context.read<ShowPlaylistsCubit>().startSubscribingPlaylists(userId: userId);
      return null;
    }, []);

    return Stack(
      children: [
        BlocConsumer<ShowPlaylistsCubit, ShowPlaylistsState>(
          listener: (context, state) {
            switch (state) {
              case PlaylistsLoadedState(error: final MaximumPlaylistsCountExceeded error):
                showErrorDialog(
                  context: context,
                  text: localizations.maximumPlaylistsCountExceededError(error.maximumPlaylistsCount),
                );
              case PlaylistsLoadedState(error: final PlaylistError _):
                showErrorDialog(context: context, text: localizations.errorUnknownText);
              default:
                break;
            }
          },
          builder: (context, state) {
            if (state.playlists.isEmpty) {
              return EmptyListWidget(
                icon: Icons.music_off,
                title: localizations.noPlaylistsYet,
                subtitle: localizations.createFirstPlaylist,
              );
            }
            final visiblePlaylists = state.visiblePlaylists;
            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(_searchRowPadding),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: localizations.searchPlaylists,
                              prefixIcon: const Icon(Icons.search),
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: context.read<ShowPlaylistsCubit>().search,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.sort),
                          tooltip: localizations.sortPlaylists,
                          onPressed: () => _onSort(context, state.sort),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: visiblePlaylists.isEmpty
                        ? Center(child: Text(localizations.noPlaylistsFound))
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.only(bottom: 20.0),
                            itemCount: visiblePlaylists.length,
                            itemBuilder: (context, index) {
                              return PlaylistTile(
                                playlist: visiblePlaylists[index],
                                user: user,
                                sort: state.sort,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
        Positioned(
          bottom: AppTheme.fabPositionOffset,
          right: AppTheme.fabPositionOffset,
          child: ScrollAwareFab(
            scrollController: scrollController,
            onPressed: () => _onAddPlaylist(context, userId),
            label: localizations.newPlaylist,
          ),
        ),
      ],
    );
  }

  void _onSort(BuildContext context, PlaylistSort current) {
    final playlistsCubit = context.read<ShowPlaylistsCubit>();
    showPlaylistSortSheet(context: context, current: current).then((sort) {
      if (sort != null) {
        playlistsCubit.sortBy(sort);
      }
    });
  }

  void _onAddPlaylist(BuildContext context, String userId) {
    showAddPlaylistDialog(context: context).then((playlistName) {
      if (playlistName != null && context.mounted) {
        context.read<ShowPlaylistsCubit>().addPlaylist(
          playlistName: playlistName,
          userId: userId,
        );
      }
    });
  }
}
