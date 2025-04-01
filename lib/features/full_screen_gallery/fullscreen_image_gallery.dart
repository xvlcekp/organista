import 'package:flutter/material.dart';
import 'package:organista/features/show_music_sheet/music_sheet_view.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
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
          logger.i("Index is $index");
          final musicSheet = musicSheets[index];

          return PhotoViewGalleryPageOptions.customChild(
            child: MusicSheetView(
              musicSheet: musicSheet,
              mode: MusicSheetViewMode.full,
            ),
          );
        },
        itemCount: musicSheets.length,
      ),
    );
  }
}
