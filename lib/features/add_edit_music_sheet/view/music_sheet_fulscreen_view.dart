import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/features/pdf_viewer/pdf_viewer_widget.dart';
import 'package:pdfx/pdfx.dart';

class MusicSheetFullScreenView extends StatelessWidget {
  const MusicSheetFullScreenView({
    super.key,
    required this.musicSheet,
  });

  final MusicSheet musicSheet;

  @override
  Widget build(BuildContext context) {
    StatelessWidget child;
    switch (musicSheet.mediaType) {
      case MediaType.image:
        child = CachedNetworkImage(
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.error),
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          imageUrl: musicSheet.fileUrl,
          fit: BoxFit.fitHeight,
        );

      case MediaType.pdf:
        child = PdfViewerWidget(
          fileUrl: musicSheet.fileUrl,
        );

      default:
        child = const Placeholder();
    }
    return PhotoView.customChild(
      minScale: PhotoViewComputedScale.contained * 1.0,
      maxScale: PhotoViewComputedScale.contained * 3.0,
      initialScale: PhotoViewComputedScale.contained * 1.0,
      child: child,
    );
  }
}
