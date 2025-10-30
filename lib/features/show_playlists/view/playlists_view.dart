import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/auth_bloc/auth_bloc.dart';
import 'package:organista/config/app_theme.dart';
import 'package:organista/dialogs/playlists/add_playlist_dialog.dart';
import 'package:organista/dialogs/playlists/delete_playlist_dialog.dart';
import 'package:organista/dialogs/playlists/rename_playlist_dialog.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/show_playlist/view/playlist_view.dart';
import 'package:organista/features/show_playlists/cubit/show_playlists_cubit.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/views/main_popup_menu_button.dart';
import 'package:organista/widgets/empty_list_widget.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

class PlaylistsView extends HookWidget {
  const PlaylistsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthUser user = context.read<AuthBloc>().state.user!;
    final String userId = user.id;
    final theme = Theme.of(context);
    final primaryColorScheme = theme.colorScheme.primary;
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
            Icon(Icons.list_alt, color: primaryColorScheme),
            const SizedBox(width: 8),
            Text(
              localizations.myPlaylists,
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
        actions: const [
          MainPopupMenuButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showAddPlaylistDialog(context: context).then((playlistName) {
            if (playlistName != null && context.mounted) {
              context.read<ShowPlaylistsCubit>().addPlaylist(
                playlistName: playlistName,
                userId: userId,
              );
            }
          });
        },
        icon: const Icon(Icons.add),
        label: Text(localizations.newPlaylist),
        backgroundColor: primaryColorScheme,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: BlocBuilder<ShowPlaylistsCubit, ShowPlaylistsState>(
        builder: (context, state) {
          final surfaceVariantColor = theme.colorScheme.onSurfaceVariant;
          if (state.playlists.isEmpty) {
            return EmptyListWidget(
              icon: Icons.music_off,
              title: localizations.noPlaylistsYet,
              subtitle: localizations.createFirstPlaylist,
            );
          }
          return SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
              itemCount: state.playlists.length,
              itemBuilder: (context, index) {
                Playlist playlist = state.playlists[index];
                return Card(
                  child: Dismissible(
                    key: ValueKey(playlist.playlistId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
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
                        showEditPlaylistDialog(context: context, playlistName: playlist.name).then((newPlaylistName) {
                          if (newPlaylistName != null && context.mounted) {
                            context.read<ShowPlaylistsCubit>().editPlaylistName(
                              newPlaylistName: newPlaylistName,
                              playlist: playlist,
                            );
                          }
                        });
                      },
                      onTap: () {
                        context.read<PlaylistBloc>().add(
                          InitPlaylistEvent(playlist: state.playlists[index], user: user),
                        );
                        Navigator.of(context).push<void>(PlaylistView.route());
                      },
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
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${localizations.musicSheets}: ${playlist.musicSheets.length}",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: surfaceVariantColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: surfaceVariantColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
