import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/features/show_music_sheet/view/back_button_widget.dart';
import 'package:organista/features/show_music_sheet/view/cached_network_image_widget.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_title_overlay.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/features/show_music_sheet/view/pdf_viewer_widget.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_viewer_widget.dart';

class MusicSheetView extends HookWidget {
  const MusicSheetView({
    super.key,
    required this.musicSheet,
    this.mode = MusicSheetViewMode.thumbnail, // Default to thumbnail
  });

  final MusicSheet musicSheet;
  final MusicSheetViewMode mode;

  @override
  Widget build(BuildContext context) {
    final showTitle = useState(true);

    return Stack(
      children: [
        switch (musicSheet.mediaType) {
          MediaType.image => CachedNetworkImageWidget(musicSheet: musicSheet, mode: mode),
          MediaType.pdf => PdfViewerWidget(musicSheet: musicSheet, mode: mode),
          MediaType.musicxml => MusicXmlViewerWidget(musicSheet: musicSheet),
        },
        if (mode == MusicSheetViewMode.full) const BackButtonWidget(),
        // Show title overlay in full mode
        if (mode == MusicSheetViewMode.full && showTitle.value)
          MusicSheetTitleOverlay(
            fileName: musicSheet.fileName,
            onDismiss: () => showTitle.value = false,
          ),
      ],
    );
  }
}

enum MusicSheetViewMode { thumbnail, preview, full }
