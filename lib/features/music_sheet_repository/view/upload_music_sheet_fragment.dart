import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/add_edit_music_sheet/view/add_music_sheet_view.dart';

class UploadMusicSheetFragment extends StatelessWidget {
  const UploadMusicSheetFragment({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min, // Ensures it doesn't take extra space
          children: [
            const SizedBox(height: 16), // Space between buttons
            FloatingActionButton(
              heroTag: 'uploadPdfButton',
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'pdf', 'png'],
                  withData: true,
                );
                if (result != null) {
                  if (context.mounted) {
                    final PlatformFile file = result.files.first;
                    context.read<AddEditMusicSheetCubit>().uploadMusicSheet(
                          file: file,
                        );
                    Navigator.of(context).push<void>(AddMusicSheetView.route());
                  }
                }
              },
              child: const Icon(Icons.upload),
            ),
          ],
        ),
      ],
    );
  }
}


// TODO: refactor code
// TODO: handle errors