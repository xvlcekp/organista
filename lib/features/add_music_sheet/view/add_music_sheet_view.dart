import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/dialogs/discard_changes_uploaded_music_sheet_dialog.dart';
import 'package:organista/features/add_music_sheet/cubit/add_music_sheet_cubit.dart';
import 'package:organista/features/add_music_sheet/view/add_image_controllers_view.dart';
import 'package:organista/features/add_music_sheet/view/uploaded_music_sheet_image_view.dart';
import 'package:organista/logger/custom_logger.dart';

class AddMusicSheetView extends HookWidget {
  const AddMusicSheetView({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AddMusicSheetView());
  }

  @override
  Widget build(BuildContext context) {
    final musicSheetNameController = useTextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Upload the music sheet')),
      body: BlocBuilder<AddMusicSheetCubit, AddMusicSheetState>(
        builder: (context, state) {
          musicSheetNameController.text = state.fileName;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: (state.file == null) ? const AddImageControllersView() : UploadedMusicSheetImageView(image: state.file!),
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
                            if (state.file != null) {
                              context.read<AppBloc>().add(
                                    AppEventUploadImage(
                                      file: state.file!,
                                      fileName: musicSheetNameController.text,
                                    ),
                                  );
                              resetMusicSheetCubitAndPop(context);
                            } else {
                              CustomLogger.instance.e("You have to select an image first");
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => resetMusicSheetCubitAndPop(context),
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
    final shouldDiscardChanges = await showDiscardUploadedMusicSheetChangesDialog(context);
    if (shouldDiscardChanges && context.mounted) {
      context.read<AddMusicSheetCubit>().resetState();
      Navigator.pop(context);
    }
  }
}
