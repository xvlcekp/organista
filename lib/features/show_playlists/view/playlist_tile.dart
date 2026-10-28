import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/config/app_theme.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/show_playlist/view/playlist_view.dart';
import 'package:organista/features/show_playlists/cubit/playlist_sort.dart';
import 'package:organista/features/show_playlists/view/relative_date.dart';
import 'package:organista/features/show_playlists/cubit/show_playlists_cubit.dart';
import 'package:organista/features/show_playlists/view/delete_playlist_dialog.dart';
import 'package:organista/features/show_playlists/view/duplicate_playlist_dialog.dart';
import 'package:organista/features/show_playlists/view/rename_playlist_dialog.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/services/auth/auth_user.dart';

class PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final AuthUser user;

  /// Decides which date the tile shows: the creation date when sorted by newest, the last change otherwise.
  final PlaylistSort sort;

  const PlaylistTile({required this.playlist, required this.user, required this.sort, super.key});

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
    final showCreated = sort == PlaylistSort.newest;
    final dateLabel = showCreated ? localizations.playlistCreated : localizations.playlistModified;
    final date = showCreated ? playlist.createdAt : playlist.modifiedAt;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        onLongPress: () => _showPlaylistContextMenu(context),
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
                    Row(
                      children: [
                        Text(
                          '${localizations.musicSheets}: ${playlist.musicSheets.length}',
                          style: theme.textTheme.bodySmall?.copyWith(color: onSurfaceVariant),
                        ),
                        const Spacer(),
                        // A playlist written offline echoes back without `createdAt` (the epoch) until the server stamps it.
                        if (date.millisecondsSinceEpoch > 0)
                          Text(
                            '$dateLabel: ${formatRelativeDate(date, now: DateTime.now(), localizations: localizations)}',
                            style: theme.textTheme.bodySmall?.copyWith(color: onSurfaceVariant),
                          ),
                      ],
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
    );
  }

  /// Bottom sheet with rename, duplicate and delete. The cubit is read before the sheet opens because the
  /// follow-up dialogs run after the sheet (and its context) is gone.
  void _showPlaylistContextMenu(BuildContext context) {
    final localizations = context.loc;
    final theme = Theme.of(context);
    final playlistsCubit = context.read<ShowPlaylistsCubit>();

    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(localizations.renamePlaylist),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  showEditPlaylistDialog(context: context, playlistName: playlist.name).then((newName) {
                    if (newName != null) {
                      playlistsCubit.editPlaylistName(newPlaylistName: newName, playlist: playlist);
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(localizations.duplicatePlaylist),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  showDuplicatePlaylistDialog(context: context, playlistName: playlist.name).then((newName) {
                    if (newName != null) {
                      playlistsCubit.duplicatePlaylist(newPlaylistName: newName, playlist: playlist);
                    }
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: theme.colorScheme.error),
                title: Text(
                  localizations.deletePlaylist,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  showDeletePlaylistDialog(context).then((shouldDelete) {
                    if (shouldDelete) {
                      // Not awaited: a Firestore write only completes once the server acknowledges it, which offline
                      // may take until the next connection; the tile is removed by the playlists stream anyway.
                      unawaited(playlistsCubit.deletePlaylist(playlist: playlist));
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
