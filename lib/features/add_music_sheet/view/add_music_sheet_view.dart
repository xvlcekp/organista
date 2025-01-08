import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
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
    final picker = useMemoized(() => ImagePicker(), [key]);
    final musicSheetNameController = useTextEditingController();
    return Scaffold(
      appBar: AppBar(
          title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey[800], // Background color for the search box
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
      )),
      body: BlocBuilder<AddMusicSheetCubit, AddMusicSheetState>(
        builder: (context, state) {
          musicSheetNameController.text = state.fileName;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(
                  height: 250,
                  width: 500,
                  child: (state.file == null) ? AddImageControllersView(picker: picker) : UploadedMusicSheetImageView(image: state.file!),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: musicSheetNameController,
                        decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey, width: 0.0),
                          ),
                          hintText: 'Music sheet name',
                          hintStyle: TextStyle(color: Colors.black),
                        ),
                        style: const TextStyle(color: Colors.black), // Text color
                        onChanged: (query) {},
                      ),
                    ),
                  ],
                ),
                Row(
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
                            context.read<AddMusicSheetCubit>().resetState();
                            Navigator.pop(context);
                          } else {
                            CustomLogger.instance.e("You have to select an image first");
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Discard'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
