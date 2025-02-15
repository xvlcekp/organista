import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/views/pdf_viewer_widget.dart';

class EditMusicSheetImageView extends StatelessWidget {
  const EditMusicSheetImageView({
    super.key,
    required this.musicSheet,
  });

  final MusicSheet musicSheet;

  @override
  Widget build(BuildContext context) {
    switch (musicSheet.mediaType) {
      case MediaType.image:
        return CachedNetworkImage(
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          imageUrl: musicSheet.fileUrl,
          fit: BoxFit.fitHeight,
        );
      case MediaType.pdf:
        return PdfViewerWidget(fileUrl: musicSheet.fileUrl);
      default:
        return Placeholder();
    }
  }
}
