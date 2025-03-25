import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/dialogs/discard_changes_uploaded_music_sheet_dialog.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/add_edit_music_sheet/view/add_image_controllers_view.dart';
import 'package:organista/features/show_music_sheet/music_sheet_view.dart';
import 'package:organista/features/add_edit_music_sheet/view/uploaded_music_sheet_file_view.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/show_playlist/view/playlist_view.dart';
import 'package:organista/logger/custom_logger.dart';

class AddEditMusicSheetView extends HookWidget {
  const AddEditMusicSheetView({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AddEditMusicSheetView());
  }

  @override
  Widget build(BuildContext context) {
    final musicSheetNameController = useTextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Modify music sheet')),
      body: BlocBuilder<AddEditMusicSheetCubit, AddEditMusicSheetState>(
        builder: (context, state) {
          musicSheetNameController.text = state.fileName;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                    flex: 2,
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
                    }),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: musicSheetNameController,
                      decoration: const InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey, width: 0.0),
                        ),
                        hintText: 'Music sheet name',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(color: Colors.black), // Text color
                      onChanged: (query) {},
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final shouldDiscardChanges = await showDiscardUploadedMusicSheetChangesDialog(context);
                            if (shouldDiscardChanges && context.mounted) {
                              resetMusicSheetCubitAndShowPlaylist(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30), // Make the button circular
                            ),
                          ),
                          child: const Text('Discard'),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30), // Make the button circular
                            ),
                          ),
                          onPressed: () {
                            switch (state) {
                              case InitMusicSheetState():
                                logger.e("You have to select an image first");
                              case UploadMusicSheetState():
                                context.read<PlaylistBloc>().add(
                                      UploadNewMusicSheetEvent(
                                        file: state.file,
                                        fileName: musicSheetNameController.text,
                                        user: context.read<AppBloc>().state.user!,
                                        repositoryId: state.repositoryId,
                                      ),
                                    );
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
                                final playlist = context.read<PlaylistBloc>().state.playlist;
                                context.read<PlaylistBloc>().add(AddMusicSheetToPlaylistEvent(
                                      musicSheet: state.musicSheet,
                                      fileName: musicSheetNameController.text,
                                      playlist: playlist,
                                    ));
                                Navigator.of(context).pop();
                                resetMusicSheetCubitAndShowPlaylist(context);
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // TODO: fix these routes

  void resetMusicSheetCubitAndShowPlaylist(BuildContext context) async {
    if (context.mounted) {
      context.read<AddEditMusicSheetCubit>().resetState();
      Navigator.of(context).pop();
      Navigator.of(context).push(PlaylistView.route());
    }
  }

  void resetMusicSheetCubitAndPop(BuildContext context) async {
    if (context.mounted) {
      context.read<AddEditMusicSheetCubit>().resetState();
      Navigator.of(context).pop();
    }
  }
}
