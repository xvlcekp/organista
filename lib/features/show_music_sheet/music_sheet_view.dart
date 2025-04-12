import 'package:flutter/material.dart';
import 'package:organista/features/show_music_sheet/cached_network_image_widget.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/features/show_music_sheet/pdf_viewer_widget.dart';

enum MusicSheetViewMode { thumbnail, preview, full }

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
    return switch (musicSheet.mediaType) {
      MediaType.image => CachedNetworkImageWidget(musicSheet: musicSheet, mode: mode),
      MediaType.pdf => PdfViewerWidget(musicSheet: musicSheet, mode: mode),
    };
  }
}
