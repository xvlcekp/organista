import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:organista/extensions/hex_color.dart';
import 'package:organista/models/internal/music_sheet_file.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:pdfx/pdfx.dart';

class UploadedMusicSheetFileView extends HookWidget {
  const UploadedMusicSheetFileView({
    super.key,
    required this.file,
  });

  final MusicSheetFile file;

  @override
  Widget build(BuildContext context) {
    const double pdfRenderScale = 2.0;
    final pdfController = useState<PdfController?>(null);
    final isLoadingPdf = useState(true);
    final pdfError = useState(false);

    useEffect(() {
      if (file.mediaType == MediaType.pdf && file.bytes != null) {
        // Load PDF asynchronously to avoid blocking main thread
        PdfDocument.openData(file.bytes!)
            .then((document) {
              if (pdfController.value == null) {
                pdfController.value = PdfController(document: Future.value(document));
                isLoadingPdf.value = false;
              }
            })
            .catchError((error) {
              pdfError.value = true;
              isLoadingPdf.value = false;
            });
      }
      return null;
    }, [file.bytes]);

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
          if (isLoadingPdf.value) {
            child = const Center(child: CircularProgressIndicator());
          } else if (pdfError.value || pdfController.value == null) {
            child = Center(child: Text(context.loc.noFileDataAvailable));
          } else {
            child = PdfView(
              controller: pdfController.value!,
              renderer: (PdfPage page) => page.render(
                width: page.width * pdfRenderScale,
                height: page.height * pdfRenderScale,
                format: PdfPageImageFormat.png,
                backgroundColor: Colors.white.toHex(),
              ),
            );
          }
      }
    }
    return Row(
      children: [
        Expanded(
          child: child,
        ),
      ],
    );
  }
}
