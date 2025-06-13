import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/auth_bloc/auth_bloc.dart';
import 'package:organista/dialogs/playlists/add_playlist_dialog.dart';
import 'package:organista/dialogs/playlists/delete_playlist_dialog.dart';
import 'package:organista/dialogs/playlists/edit_playlist_dialog.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/show_playlist/view/playlist_view.dart';
import 'package:organista/features/show_playlists/cubit/playlists_cubit.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/views/main_popup_menu_button.dart';
import 'package:organista/extensions/buildcontext/loc.dart';

class PlaylistsView extends HookWidget {
  const PlaylistsView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = useTextEditingController();
    final AuthUser user = context.read<AuthBloc>().state.user!;
    final String userId = user.id;
    final theme = Theme.of(context);
    final localizations = context.loc;

    useEffect(() {
      // initialize stream only once on first creation
      context.read<ShowPlaylistsCubit>().startSubscribingPlaylists(userId: userId);
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.list_alt, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              localizations.myPlaylists,
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
        actions: [
          const MainPopupMenuButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddPlaylistDialog(context: context, controller: controller, userId: userId),
        icon: const Icon(Icons.add),
        label: Text(localizations.newPlaylist),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: BlocBuilder<ShowPlaylistsCubit, ShowPlaylistsState>(
        builder: (context, state) {
          if (state.playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_off,
                    size: 64,
                    color: theme.colorScheme.primary.withAlpha(130),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.noPlaylistsYet,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.createFirstPlaylist,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.playlists.length,
            itemBuilder: (context, index) {
              Playlist playlist = state.playlists[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: ValueKey(playlist.playlistId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: Icon(
                      Icons.delete,
                      color: theme.colorScheme.onError,
                    ),
                  ),
                  confirmDismiss: (DismissDirection direction) async {
                    final shouldDeletePlaylist = await showDeletePlaylistDialog(context);
                    if (shouldDeletePlaylist && context.mounted) {
                      context.read<ShowPlaylistsCubit>().deletePlaylist(
                            playlist: playlist,
                          );
                    }
                    return;
                  },
                  child: InkWell(
                    onLongPress: () {
                      controller.text = playlist.name;
                      showEditPlaylistDialog(
                          context: context, controller: controller, playlist: state.playlists[index]);
                    },
                    onTap: () {
                      context.read<PlaylistBloc>().add(InitPlaylistEvent(playlist: state.playlists[index], user: user));
                      Navigator.of(context).push<void>(PlaylistView.route());
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playlist.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${localizations.musicSheets}: ${playlist.musicSheets.length}",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
