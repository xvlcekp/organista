import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:organista/features/add_edit_music_sheet/view/music_sheet_fulscreen_view.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/views/pdf_viewer_widget.dart';

enum MusicSheetViewMode { thumbnail, preview }

class MusicSheetView extends StatelessWidget {
  const MusicSheetView({
    super.key,
    required this.musicSheet,
    this.mode = MusicSheetViewMode.thumbnail, // Default to thumbnail
  });

  final MusicSheet musicSheet;
  final MusicSheetViewMode mode;

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
          filterQuality: mode == MusicSheetViewMode.preview ? FilterQuality.high : FilterQuality.low,
          // memCacheHeight: mode == MusicSheetViewMode.preview ? 500 : 75,
          memCacheWidth: mode == MusicSheetViewMode.preview ? 500 : 75,
        );

      case MediaType.pdf:
        child = PdfViewerWidget(
          fileUrl: musicSheet.fileUrl,
          mode: mode == MusicSheetViewMode.preview ? PdfViewMode.preview : PdfViewMode.thumbnail,
        );

      default:
        child = const Placeholder();
    }
    return GestureDetector(
      child: child,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MusicSheetFullScreenView(musicSheet: musicSheet),
          ),
        );
      },
    );
  }
}
