import 'package:flutter/material.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:organista/extensions/hex_color.dart';
import 'package:organista/models/internal/music_sheet_file.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:pdfx/pdfx.dart';

class UploadedMusicSheetFileView extends StatelessWidget {
  const UploadedMusicSheetFileView({
    super.key,
    required this.file,
  });

  final MusicSheetFile file;

  @override
  Widget build(BuildContext context) {
    const double pdfRenderScale = 2.0;
    Widget child;
    final bytes = file.bytes;
    if (bytes == null) {
      child = Center(child: Text(context.loc.noFileDataAvailable));
    } else {
      switch (file.mediaType) {
        case MediaType.image:
          child = Image.memory(
            bytes,
            fit: BoxFit.fitHeight,
          );

        case MediaType.pdf:
          final pdfController = PdfController(
            document: PdfDocument.openData(bytes),
          );
          child = PdfView(
            controller: pdfController,
            renderer: (PdfPage page) => page.render(
              width: page.width * pdfRenderScale,
              height: page.height * pdfRenderScale,
              format: PdfPageImageFormat.png,
              backgroundColor: Colors.white.toHex(),
            ),
          );
      }
    }
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            child: child,
            onTap: () {
              // Navigator.of(context).push(
              //   MaterialPageRoute(
              //     builder: (context) => MusicSheetFullScreenView(musicSheet: musicSheet),
              //   ),
              // );
            },
          ),
        ),
      ],
    );
  }
}
