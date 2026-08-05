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

    return Stack(
      alignment: Alignment.center,
      children: [
        switch (source.mediaType) {
          MediaType.image => ImageViewerWidget(source: source, mode: mode),
          MediaType.pdf => PdfViewerWidget(source: source, mode: mode),
          MediaType.musicxml => MusicXmlViewerWidget(source: source, mode: mode),
        },
        if (mode == MusicSheetViewMode.full) const BackButtonWidget(),
        if (mode == MusicSheetViewMode.full && showTitle.value)
          Positioned(
            bottom: AppTheme.symmetricOverlayPadding,
            left: AppTheme.symmetricOverlayPadding,
            right: AppTheme.symmetricOverlayPadding * _titleRightPaddingMultiplier,
            child: DismissableTitle(
              title: source.fileName,
              onDismiss: () => showTitle.value = false,
            ),
          ),
      ],
    );
  }
}

enum MusicSheetViewMode { thumbnail, preview, full }
