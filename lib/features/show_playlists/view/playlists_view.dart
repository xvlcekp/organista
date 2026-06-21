import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/config/app_theme.dart';
import 'package:organista/features/authentication/auth_bloc/auth_bloc.dart';
import 'package:organista/features/show_playlists/view/add_playlist_dialog.dart';
import 'package:organista/features/show_playlists/view/playlist_tile.dart';
import 'package:organista/features/show_playlists/cubit/show_playlists_cubit.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/widgets/empty_list_widget.dart';
import 'package:organista/widgets/scroll_aware_fab.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

class PlaylistsView extends HookWidget {
  const PlaylistsView({super.key});

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
        BlocBuilder<ShowPlaylistsCubit, ShowPlaylistsState>(
          builder: (context, state) {
            if (state.playlists.isEmpty) {
              return EmptyListWidget(
                icon: Icons.music_off,
                title: localizations.noPlaylistsYet,
                subtitle: localizations.createFirstPlaylist,
              );
            }
            return SafeArea(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 20.0),
                itemCount: state.playlists.length,
                itemBuilder: (context, index) {
                  return PlaylistTile(
                    playlist: state.playlists[index],
                    user: user,
                  );
                },
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
