import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/auth_bloc/auth_bloc.dart';
import 'package:organista/dialogs/discard_changes_uploaded_music_sheet_dialog.dart';
import 'package:organista/extensions/navigation/navigation_extensions.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/add_edit_music_sheet/view/add_image_controllers_view.dart';
import 'package:organista/features/show_music_sheet/music_sheet_view.dart';
import 'package:organista/features/add_edit_music_sheet/view/uploaded_music_sheet_file_view.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/show_playlist/view/playlist_view.dart';
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
      child: Scaffold(
        appBar: AppBar(title: Text(localizations.modifyMusicSheet)),
        body: BlocBuilder<AddEditMusicSheetCubit, AddEditMusicSheetState>(
          builder: (context, state) {
            musicSheetNameController.text = state.fileName;
            return Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                children: [
                  Expanded(
                    flex: previewFlex,
                    child: switch (state) {
                      InitMusicSheetState() => const AddImageControllersView(),
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
                              discardDialog(context);
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
                              switch (state) {
                                case InitMusicSheetState():
                                  logger.e(localizations.selectImageFirst);
                                case UploadMusicSheetState():
                                  final user = context.read<AuthBloc>().state.user;
                                  if (user != null) {
                                    context.read<PlaylistBloc>().add(
                                      UploadNewMusicSheetEvent(
                                        file: state.file,
                                        fileName: musicSheetNameController.text,
                                        user: user,
                                        repositoryId: state.repositoryId,
                                      ),
                                    );
                                  }
                                  resetMusicSheetCubitAndPop(context);
                                case EditMusicSheetState():
                                  context.read<PlaylistBloc>().add(
                                    RenameMusicSheetInPlaylistEvent(
                                      playlist: state.playlist,
                                      musicSheet: state.musicSheet,
                                      fileName: musicSheetNameController.text,
                                    ),
                                  );
                                  resetMusicSheetCubitAndShowPlaylist(context);
                                case AddMusicSheetToPlaylistState():
                                  final playlistBloc = context.read<PlaylistBloc>();
                                  final playlist = playlistBloc.state.playlist;
                                  playlistBloc.add(
                                    AddMusicSheetsToPlaylistEvent(
                                      musicSheets: [state.musicSheet.copyWith(fileName: musicSheetNameController.text)],
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
            );
          },
        ),
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

  void discardDialog(BuildContext context) async {
    final shouldDiscardChanges = await showDiscardUploadedMusicSheetChangesDialog(context);
    if (shouldDiscardChanges && context.mounted) {
      resetMusicSheetCubitAndShowPlaylist(context);
    }
  }
}
