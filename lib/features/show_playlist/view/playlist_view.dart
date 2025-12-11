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
import 'package:organista/features/show_playlist/view/music_sheet_list_tile.dart';
import 'package:organista/widgets/empty_list_widget.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

class PlaylistView extends HookWidget {
  const PlaylistView({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (context) => const PlaylistView());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditMode = useState(false);
    final localizations = context.loc;
    final primaryColor = theme.colorScheme.primary;

    return BlocListener<PlaylistBloc, PlaylistState>(
      listener: (context, state) {
        // Handle playlist loading
        if (state.isLoading) {
          LoadingScreen.instance().show(
            context: context,
            text: localizations.loading,
          );
        } else {
          LoadingScreen.instance().hide();
        }

        // Handle export completion: trigger save dialog via bloc
        if (state is PlaylistReadyToExportState) {
          context.read<PlaylistBloc>().add(
            SaveExportedPlaylistEvent(
              tempPath: state.tempPath,
              fileName: '${state.playlistName}.pdf',
            ),
          );
        } else if (state is PlaylistExportedState) {
          _handleNotification(
            context: context,
            message: localizations.exportSuccess,
          );
        } else if (state is PlaylistExportCancelledState) {
          _handleNotification(
            context: context,
            message: localizations.exportCancelled,
          );
        } else if (state is PlaylistErrorState) {
          _handleError(context, state.error);
        }
      },
      child: BlocBuilder<PlaylistBloc, PlaylistState>(
        builder: (context, state) {
          final playlist = state.playlist;
          logger.i("Item count is ${playlist.musicSheets.length}");

          return PopScope(
            canPop: !state.isLoading,
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    Icon(Icons.music_note, color: primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        playlist.name,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      isEditMode.value = !isEditMode.value;
                    },
                    icon: Icon(
                      isEditMode.value ? Icons.check : Icons.edit,
                    ),
                  ),
                  PopupMenuButton<_PlaylistMenuAction>(
                    onSelected: (action) {
                      if (action == _PlaylistMenuAction.exportPdf) {
                        context.read<PlaylistBloc>().add(ExportPlaylistEvent(playlist: playlist));
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<_PlaylistMenuAction>(
                        value: _PlaylistMenuAction.exportPdf,
                        enabled: playlist.musicSheets.isNotEmpty && !state.isLoading,
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf),
                            const SizedBox(width: 8),
                            Expanded(child: Text(localizations.exportToPdf)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: playlist.musicSheets.isEmpty
                  ? EmptyListWidget(
                      icon: Icons.music_off,
                      title: localizations.noMusicSheetsYet,
                      subtitle: localizations.addYourFirstMusicSheet,
                    )
                  : SafeArea(
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
                    ),
              floatingActionButton: !isEditMode.value
                  ? FloatingActionButton(
                      onPressed: () {
                        Navigator.of(context).push<void>(RepositoriesView.route());
                      },
                      backgroundColor: primaryColor,
                      foregroundColor: theme.colorScheme.onPrimary,
                      child: const Icon(Icons.add),
                    )
                  : null,
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
      case MusicSheetsAlreadyInPlaylistError():
        final duplicateNames = error.duplicateMusicSheetNames.join(', ');
        message = localizations.multipleMusicSheetsAlreadyInPlaylist(duplicateNames, error.playlistName);
      case PlaylistCapacityExceededError():
        message = localizations.playlistCapacityExceeded(
          error.attemptedToAdd,
          error.playlist.name,
          error.playlist.musicSheets.length,
          error.maxCapacity,
        );
      case InitializationError():
        message = localizations.musicSheetInitializationError;
      case ExportNoMusicSheetsPlaylistError():
        message = localizations.noMusicSheetsToExport;
      case ExportPlaylistError():
        message = localizations.exportFailed;
      case SourceFileNotFoundPlaylistError():
        message = localizations.exportErrorSourceFileNotFound;
      case ExportSaveFailedPlaylistError():
        message = '${localizations.exportErrorSaveFailed}: ${error.exceptionMessage}';
      default:
        message = localizations.errorUnknownText;
    }
    showErrorDialog(context: context, text: message);
  }

  void _handleNotification({required BuildContext context, required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

enum _PlaylistMenuAction {
  exportPdf,
}
