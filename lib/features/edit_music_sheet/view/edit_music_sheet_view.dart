import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/dialogs/discard_changes_uploaded_music_sheet_dialog.dart';
import 'package:organista/features/edit_music_sheet/cubit/edit_music_sheet_cubit.dart';
import 'package:organista/features/edit_music_sheet/view/edit_music_sheet_image_view.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';

class EditMusicSheetView extends HookWidget {
  const EditMusicSheetView({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const EditMusicSheetView());
  }

  // TODO: unify Add & Edit music sheet into one Bloc concept istead of 2 cubits
  @override
  Widget build(BuildContext context) {
    final musicSheetNameController = useTextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit the music sheet')),
      body: BlocBuilder<EditMusicSheetCubit, EditMusicSheetState>(
        builder: (context, state) {
          MusicSheet musicSheet = state.musicSheet!;
          musicSheetNameController.text = musicSheet.fileName;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: EditMusicSheetImageView(musicSheet: musicSheet),
                ),
                Expanded(
                  flex: 3,
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
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<AppBloc>().add(
                                  AppEventEditMusicSheet(
                                    musicSheet: musicSheet,
                                    fileName: musicSheetNameController.text,
                                  ),
                                );
                            resetMusicSheetCubitAndPop(context);
                          },
                          child: const Text('Save'),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (musicSheet.fileName != musicSheetNameController.text) {
                              final shouldDiscardChanges = await showDiscardUploadedMusicSheetChangesDialog(context);
                              if (shouldDiscardChanges && context.mounted) {
                                resetMusicSheetCubitAndPop(context);
                              }
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Discard'),
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

  void resetMusicSheetCubitAndPop(BuildContext context) async {
    if (context.mounted) {
      context.read<EditMusicSheetCubit>().resetState();
      Navigator.pop(context);
    }
  }
}
