import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/features/show_music_sheet/view/back_button_widget.dart';
import 'package:organista/features/show_music_sheet/view/image_viewer_widget.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_viewer_widget.dart';
import 'package:organista/config/app_theme.dart';
import 'package:organista/features/show_music_sheet/view/dismissable_title.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet_source.dart';
import 'package:organista/features/show_music_sheet/view/pdf_viewer_widget.dart';

class MusicSheetView extends HookWidget {
  static const int _titleRightPaddingMultiplier = 5;

  const MusicSheetView({
    super.key,
    required this.source,
    this.mode = MusicSheetViewMode.thumbnail,
  });

  final MusicSheetSource source;
  final MusicSheetViewMode mode;

  @override
  Widget build(BuildContext context) {
    final showTitle = useState(true);
    // A tap on a digital sheet hides the overlays covering its bottom lines; the next tap brings them back.
    final showOverlays = useState(true);

    final view = Stack(
      alignment: Alignment.center,
      children: [
        switch (source.mediaType) {
          MediaType.image => ImageViewerWidget(source: source, mode: mode),
          MediaType.pdf => PdfViewerWidget(source: source, mode: mode),
          MediaType.musicxml => MusicXmlViewerWidget(
            source: source,
            mode: mode,
            showOverlays: showOverlays.value,
            onSheetTap: () => showOverlays.value = !showOverlays.value,
          ),
        },
        if (mode == MusicSheetViewMode.full) const BackButtonWidget(),
        if (mode == MusicSheetViewMode.full && showTitle.value && showOverlays.value)
          Positioned(
            bottom: AppTheme.symmetricOverlayPadding,
            left: AppTheme.symmetricOverlayPadding,
            right: AppTheme.symmetricOverlayPadding * _titleRightPaddingMultiplier,
            // Align loosens the Positioned width so the title hugs its text and only ellipsizes when it must.
            child: Align(
              alignment: Alignment.centerLeft,
              child: DismissableTitle(
                title: source.fileName,
                onDismiss: () => showTitle.value = false,
              ),
            ),
          ),
      ],
    );

    // The full-screen view is pushed as a bare route (no Scaffold) from a repository, while the playlist gallery
    // sits in a Scaffold. Supplying the Material here gives the overlays (page counter, title, offline message)
    // the Material text style in both cases; without it Flutter draws its yellow "no DefaultTextStyle" underline.
    return mode == MusicSheetViewMode.full ? Material(type: MaterialType.transparency, child: view) : view;
  }
}

enum MusicSheetViewMode { thumbnail, preview, full }
