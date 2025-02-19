import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:pdfx/pdfx.dart';

class UploadedMusicSheetFileView extends StatelessWidget {
  const UploadedMusicSheetFileView({
    super.key,
    required this.file,
  });

  final PlatformFile file;

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (MediaType.fromPath(file.name)) {
      case MediaType.image:
        child = Image.memory(
          file.bytes!,
          fit: BoxFit.fitHeight,
        );

      case MediaType.pdf:
        final pdfController = PdfController(
          document: PdfDocument.openData(file.bytes!),
        );
        child = PdfView(
          controller: pdfController,
          renderer: (PdfPage page) => page.render(
            width: page.width * 0.5,
            height: page.height * 0.5,
            format: PdfPageImageFormat.jpeg,
            backgroundColor: '#FFFFFF',
          ),
        );

      default:
        child = const Placeholder();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          child: child,
          onTap: () {
            // Navigator.of(context).push(
            //   MaterialPageRoute(
            //     builder: (context) => MusicSheetFullScreenView(musicSheet: musicSheet),
            //   ),
            // );
          },
        ),
        IconButton(
          onPressed: () => context.read<AddEditMusicSheetCubit>().resetState(),
          icon: Icon(Icons.change_circle),
        ),
      ],
    );
  }
}
