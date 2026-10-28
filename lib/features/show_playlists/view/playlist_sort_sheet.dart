import 'package:flutter/material.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:organista/features/show_playlists/cubit/playlist_sort.dart';

/// Bottom sheet with the playlist orders; resolves with the chosen one, or null when dismissed.
Future<PlaylistSort?> showPlaylistSortSheet({required BuildContext context, required PlaylistSort current}) {
  final localizations = context.loc;
  final labels = {
    PlaylistSort.name: localizations.sortByName,
    PlaylistSort.newest: localizations.sortByNewest,
    PlaylistSort.modified: localizations.sortByModified,
  };

  return showModalBottomSheet<PlaylistSort>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: RadioGroup<PlaylistSort>(
        groupValue: current,
        onChanged: (chosen) => Navigator.of(sheetContext).pop(chosen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(localizations.sortPlaylists, style: Theme.of(sheetContext).textTheme.titleMedium)),
            for (final sort in PlaylistSort.values)
              RadioListTile<PlaylistSort>(value: sort, title: Text(labels[sort]!)),
          ],
        ),
      ),
    ),
  );
}
