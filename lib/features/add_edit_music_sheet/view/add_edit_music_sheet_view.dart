import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/features/authentication/auth_bloc/auth_bloc.dart';
import 'package:organista/features/add_edit_music_sheet/view/discard_changes_uploaded_music_sheet_dialog.dart';
import 'package:organista/extensions/navigation/navigation_extensions.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/show_music_sheet/music_sheet_view.dart';
import 'package:organista/features/add_edit_music_sheet/view/uploaded_music_sheet_file_view.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/show_playlist/view/playlist_view.dart';
import 'package:organista/loading/loading_screen.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

class AddEditMusicSheetView extends HookWidget {
  const AddEditMusicSheetView({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AddEditMusicSheetView());
  }

  @override
  Widget build(BuildContext context) {
    const previewFlex = 2;
    const inputFlex = 3;
    const buttonsFlex = 1;
    const defaultPadding = 8.0;

    final musicSheetNameController = useTextEditingController();
    final theme = Theme.of(context);
    final localizations = context.loc;

    return SafeArea(
      top: false,
      child: BlocConsumer<AddEditMusicSheetCubit, AddEditMusicSheetState>(
        listener: (context, state) {
          if (state.isLoading) {
            LoadingScreen.instance().show(
              context: context,
              text: localizations.loading,
            );
          } else {
            LoadingScreen.instance().hide();
          }

          // Handle successful upload (UploadMusicSheetState with isLoading=false and no error)
          if (state is UploadMusicSheetState && !state.isLoading && state.error == null) {
            resetMusicSheetCubitAndPop(context);
          }

          // Handle successful rename (EditMusicSheetState with isLoading=false and no error)
          if (state is EditMusicSheetState && !state.isLoading && state.error == null) {
            resetMusicSheetCubitAndShowPlaylist(context);
          }

          // Handle errors
          final error = state.error;
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${localizations.anErrorHappened}: $error')),
            );
          }
        },
        builder: (context, state) {
          musicSheetNameController.text = state.fileName;
          return PopScope(
            canPop: !state.isLoading,
            onPopInvokedWithResult: (didPop, _) {
              // If loading, block back navigation and keep the loading overlay visible on this screen
              if (!didPop && state.isLoading) {
                return;
              }
            },
            child: Scaffold(
              appBar: AppBar(title: Text(localizations.modifyMusicSheet)),
              body: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  children: [
                    Expanded(
                      flex: previewFlex,
                      child: switch (state) {
                        InitMusicSheetState() => const CircularProgressIndicator(),
                        UploadMusicSheetState() => UploadedMusicSheetFileView(file: state.file),
                        EditMusicSheetState() => MusicSheetView(
                          musicSheet: state.musicSheet,
                          mode: MusicSheetViewMode.preview,
                        ),
                        AddMusicSheetToPlaylistState() => MusicSheetView(
                          musicSheet: state.musicSheet,
                          mode: MusicSheetViewMode.preview,
                        ),
                      },
                    ),
                    Expanded(
                      flex: inputFlex,
                      child: Padding(
                        padding: const EdgeInsets.all(defaultPadding),
                        child: TextField(
                          controller: musicSheetNameController,
                          decoration: InputDecoration(
                            hintText: localizations.musicSheetName,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: buttonsFlex,
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                showDiscardUploadedMusicSheetChangesDialog(context).then((shouldDiscardChanges) {
                                  if (shouldDiscardChanges && context.mounted) {
                                    resetMusicSheetCubitAndShowPlaylist(context);
                                  }
                                });
                              },
                              style: theme.elevatedButtonTheme.style?.copyWith(
                                backgroundColor: WidgetStateProperty.all(theme.colorScheme.secondary),
                                foregroundColor: WidgetStateProperty.all(theme.colorScheme.onSecondary),
                              ),
                              child: Text(localizations.discard),
                            ),
                          ),
                          const SizedBox(width: defaultPadding),
                          Expanded(
                            child: ElevatedButton(
                              style: theme.elevatedButtonTheme.style,
                              onPressed: () {
                                // Don't allow actions while loading
                                if (state.isLoading) return;

                                switch (state) {
                                  case InitMusicSheetState():
                                    logger.e(localizations.selectImageFirst);
                                  case UploadMusicSheetState():
                                    final user = context.read<AuthBloc>().state.user;
                                    if (user != null) {
                                      context.read<AddEditMusicSheetCubit>().uploadNewMusicSheet(
                                        user: user,
                                        file: state.file,
                                        fileName: musicSheetNameController.text,
                                        repositoryId: state.repositoryId,
                                      );
                                    }
                                  case EditMusicSheetState():
                                    context.read<AddEditMusicSheetCubit>().renameMusicSheetInPlaylist(
                                      playlist: state.playlist,
                                      musicSheet: state.musicSheet,
                                      fileName: musicSheetNameController.text,
                                    );
                                  case AddMusicSheetToPlaylistState():
                                    final playlistBloc = context.read<PlaylistBloc>();
                                    final playlist = playlistBloc.state.playlist;
                                    playlistBloc.add(
                                      AddMusicSheetsToPlaylistEvent(
                                        musicSheets: [
                                          state.musicSheet.copyWith(fileName: musicSheetNameController.text),
                                        ],
                                        playlist: playlist,
                                      ),
                                    );
                                    resetMusicSheetCubitAndShowPlaylist(context);
                                }
                              },
                              child: Text(localizations.save),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void resetMusicSheetCubitAndShowPlaylist(BuildContext context) {
    context.read<AddEditMusicSheetCubit>().resetState();
    Navigator.of(context).popUntilRoute<PlaylistView>(context);
  }

  void resetMusicSheetCubitAndPop(BuildContext context) {
    context.read<AddEditMusicSheetCubit>().resetState();
    Navigator.of(context).pop();
  }
}
