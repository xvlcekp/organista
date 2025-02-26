import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:organista/features/show_playlist/view/playlist_view.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/features/pdf_viewer/pdf_viewer_widget.dart';
import 'package:pdfx/pdfx.dart';

class FullScreenImageGallery extends StatelessWidget {
  final List<MusicSheet> musicSheets;
  final int initialIndex;

  const FullScreenImageGallery({
    super.key,
    required this.musicSheets,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PhotoViewGallery.builder(
        pageController: PageController(initialPage: initialIndex),
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (_, int index) {
          logger.e("Index is $index");
          final musicSheet = musicSheets[index];

          if (musicSheet.mediaType == MediaType.image) {
            return PhotoViewGalleryPageOptions(
              imageProvider: CachedNetworkImageProvider(
                musicSheet.fileUrl,
              ),
              initialScale: PhotoViewComputedScale.contained * 1.0,
              minScale: PhotoViewComputedScale.contained * 1.0,
            );
          } else {
            return PhotoViewGalleryPageOptions.customChild(
              child: PdfViewerWidget(fileUrl: musicSheet.fileUrl),
              minScale: PhotoViewComputedScale.contained * 1.0,
              maxScale: PhotoViewComputedScale.contained * 3.0,
              initialScale: PhotoViewComputedScale.contained * 1.0,
            );
          }
        },
        itemCount: musicSheets.length,
        loadingBuilder: (context, event) => const Center(
          child: SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
                // value: event == null ? 0 : event.cumulativeBytesLoaded / event.expectedTotalBytes,
                ),
          ),
        ),
      ),
    );
  }
}
