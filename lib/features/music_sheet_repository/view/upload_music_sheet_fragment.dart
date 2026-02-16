import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/config/app_constants.dart';
import 'package:organista/dialogs/error_dialog.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/add_edit_music_sheet/view/add_edit_music_sheet_view.dart';
import 'package:organista/models/internal/music_sheet_file.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

class UploadMusicSheetFragment extends StatelessWidget {
  final String repositoryId;

  const UploadMusicSheetFragment({
    super.key,
    required this.repositoryId,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = context.loc;
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min, // Ensures it doesn't take extra space
          children: [
            const SizedBox(height: 16), // Space between buttons
            FloatingActionButton(
              heroTag: 'uploadPdfButton',
              onPressed: () {
                FilePicker.platform
                    .pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'pdf', 'png', 'musicxml', 'xml'],
                      withData: true,
                    )
                    .then((result) {
                      if (result != null) {
                        try {
                          final PlatformFile file = result.files.first;
                          final MusicSheetFile musicSheetFile = MusicSheetFile.fromPlatformFile(file);

                          // Check file size
                          if (file.size > AppConstants.maxFileSizeBytes) {
                            if (context.mounted) {
                              showErrorDialog(
                                context: context,
                                text: localizations.fileTooLarge(AppConstants.maxFileSizeMB),
                              );
                            }
                            return;
                          }

                          if (context.mounted) {
                            context.read<AddEditMusicSheetCubit>().uploadMusicSheet(
                              file: musicSheetFile,
                              repositoryId: repositoryId,
                            );
                            Navigator.of(context).push<void>(AddEditMusicSheetView.route());
                          }
                        } on UnsupportedFileExtensionException {
                          if (context.mounted) {
                            showErrorDialog(context: context, text: localizations.unsupportedFileExtension);
                          }
                        }
                      }
                    });
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
