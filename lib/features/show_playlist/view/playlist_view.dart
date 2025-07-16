import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/dialogs/error_dialog.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/show_playlist/error/playlist_error.dart';
import 'package:organista/features/show_repositories/view/repositories_view.dart';
import 'package:organista/loading/loading_screen.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/features/show_playlist/view/music_sheet_list_tile.dart';
import 'package:organista/extensions/buildcontext/loc.dart';

class PlaylistView extends HookWidget {
  const PlaylistView({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (context) => PlaylistView());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditMode = useState(false);
    final localizations = context.loc;
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
              text: localizations.loading,
            );
          } else {
            LoadingScreen.instance().hide();
          }
          if (appState.error != null) {
            _handleError(context, appState.error!);
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
                    color: theme.colorScheme.primary.withAlpha(130),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.noMusicSheetsYet,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary.withAlpha(130),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.addYourFirstMusicSheet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary.withAlpha(130),
                    ),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
              itemCount: playlist.musicSheets.length,
              onReorderStart: (_) => HapticFeedback.heavyImpact(),
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final musicSheet = playlist.musicSheets.removeAt(oldIndex);
                playlist.musicSheets.insert(newIndex, musicSheet);
                context.read<PlaylistBloc>().add(
                  ReorderMusicSheetEvent(playlist: playlist),
                );
              },
              itemBuilder: (context, index) {
                return MusicSheetListTile(
                  key: ValueKey(playlist.musicSheets[index].musicSheetId),
                  index: index,
                  playlist: playlist,
                  isEditMode: isEditMode.value,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleError(BuildContext context, PlaylistError error) {
    final localizations = context.loc;
    var message = '';
    switch (error) {
      case MusicSheetAlreadyInPlaylistError():
        message = localizations.musicSheetAlreadyInPlaylist;
      case InitializationError():
        message = localizations.musicSheetInitializationError;
      default:
        message = localizations.errorUnknownText;
    }
    showErrorDialog(context, message);
  }
}
