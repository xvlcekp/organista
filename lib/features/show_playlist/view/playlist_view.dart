import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/show_repositories/view/repositories_view.dart';
import 'package:organista/loading/loading_screen.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/features/show_playlist/view/music_sheet_list_tile.dart';

class PlaylistView extends HookWidget {
  const PlaylistView({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (context) => PlaylistView());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditMode = useState(false);
    Playlist playlist = context.read<PlaylistBloc>().state.playlist;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.music_note, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                playlist.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!isEditMode.value)
            IconButton(
              onPressed: () {
                Navigator.of(context).push<void>(RepositoriesView.route());
              },
              icon: Icon(
                Icons.add,
                color: theme.colorScheme.primary,
              ),
            ),
          IconButton(
            onPressed: () {
              isEditMode.value = !isEditMode.value;
            },
            icon: Icon(
              isEditMode.value ? Icons.check : Icons.edit,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
      body: BlocConsumer<PlaylistBloc, PlaylistState>(
        listener: (context, appState) {
          if (appState.isLoading) {
            LoadingScreen.instance().show(
              context: context,
              text: 'Loading...',
            );
          } else {
            LoadingScreen.instance().hide();
          }
          if (appState.errorMessage.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(appState.errorMessage),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          var playlist = state.playlist;
          logger.i("Item count is ${playlist.musicSheets.length}");

          if (playlist.musicSheets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_off,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No music sheets yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first music sheet to get started',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView(
            padding: const EdgeInsets.all(16),
            onReorderStart: (_) => HapticFeedback.heavyImpact(),
            onReorder: (int oldIndex, int newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final MusicSheet item = playlist.musicSheets.removeAt(oldIndex);
              playlist.musicSheets.insert(newIndex, item);
              context.read<PlaylistBloc>().add(ReorderMusicSheetEvent(playlist: playlist));
            },
            children: [
              for (int index = 0; index < playlist.musicSheets.length; index += 1)
                MusicSheetListTile(
                  key: Key(playlist.musicSheets.elementAt(index).musicSheetId),
                  index: index,
                  playlist: playlist,
                  isEditMode: isEditMode.value,
                )
            ],
          );
        },
      ),
    );
  }
}
