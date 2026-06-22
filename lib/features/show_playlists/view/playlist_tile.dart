import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/config/app_theme.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/show_playlist/view/playlist_view.dart';
import 'package:organista/features/show_playlists/cubit/show_playlists_cubit.dart';
import 'package:organista/features/show_playlists/view/delete_playlist_dialog.dart';
import 'package:organista/features/show_playlists/view/rename_playlist_dialog.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/services/auth/auth_user.dart';

class PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final AuthUser user;

  const PlaylistTile({required this.playlist, required this.user, super.key});

  static const double _iconContainerSize = 44.0;
  static const double _iconContainerBorderRadius = 10.0;

  static const List<Color> _tileColors = [
    Color(0xFFE3F2FD),
    Color(0xFFF3E5F5),
    Color(0xFFE8F5E9),
    Color(0xFFFFF8E1),
    Color(0xFFFCE4EC),
    Color(0xFFE0F2F1),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = context.loc;
    final tileColor = _tileColors[playlist.playlistId.hashCode.abs() % _tileColors.length];
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

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
          child: Icon(Icons.delete, color: theme.colorScheme.onError),
        ),
        confirmDismiss: (_) async {
          final shouldDelete = await showDeletePlaylistDialog(context);
          if (shouldDelete && context.mounted) {
            context.read<ShowPlaylistsCubit>().deletePlaylist(playlist: playlist);
          }
          return false;
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          onLongPress: () {
            showEditPlaylistDialog(context: context, playlistName: playlist.name).then((newName) {
              if (newName != null && context.mounted) {
                context.read<ShowPlaylistsCubit>().editPlaylistName(
                  newPlaylistName: newName,
                  playlist: playlist,
                );
              }
            });
          },
          onTap: () {
            context.read<PlaylistBloc>().add(
              InitPlaylistEvent(playlist: playlist, user: user),
            );
            Navigator.of(context).push<void>(PlaylistView.route());
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: _iconContainerSize,
                  height: _iconContainerSize,
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(_iconContainerBorderRadius),
                  ),
                  child: Icon(Icons.music_note, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${localizations.musicSheets}: ${playlist.musicSheets.length}',
                        style: theme.textTheme.bodySmall?.copyWith(color: onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
