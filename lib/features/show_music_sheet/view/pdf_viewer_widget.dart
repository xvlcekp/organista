import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/extensions/hex_color.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/utils/size_utils.dart';
import 'package:pdfx/pdfx.dart';

import 'package:organista/features/show_music_sheet/hooks/pdf_load_result.dart';
import 'package:organista/features/show_music_sheet/view/pdf_full_view.dart';

class PdfViewerWidget extends HookWidget {
  final MusicSheet musicSheet;
  final MusicSheetViewMode mode;
  final Color backgroundColor = Colors.white;

  /// Max side size for PDF preview rendering
  static const double previewMaxSide = 2000.0;

  /// Max side size for PDF thumbnail rendering
  static const double thumbnailMaxSide = 500.0;

  const PdfViewerWidget({
    super.key,
    required this.musicSheet,
    this.mode = MusicSheetViewMode.full,
  });

  @override
  Widget build(BuildContext context) {
    final loadResult = usePdfDocument(musicSheet);

    if (loadResult.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadResult.hasError || loadResult.controller == null) {
      return const Center(child: Icon(Icons.warning_rounded, color: Colors.red));
    }

    final pdfController = loadResult.controller!;

    return switch (mode) {
      MusicSheetViewMode.full => PdfFullView(musicSheet: musicSheet, controller: pdfController),
      MusicSheetViewMode.thumbnail => _PdfSimpleView(
        controller: pdfController,
        maxSide: thumbnailMaxSide,
        backgroundColor: backgroundColor,
      ),
      MusicSheetViewMode.preview => _PdfSimpleView(
        controller: pdfController,
        maxSide: previewMaxSide,
        backgroundColor: backgroundColor,
      ),
    };
  }
}

class _PdfSimpleView extends StatelessWidget {
  final PdfController controller;
  final double maxSide;
  final Color backgroundColor;

  const _PdfSimpleView({
    required this.controller,
    required this.maxSide,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return PdfView(
      controller: controller,
      renderer: (PdfPage page) {
        final size = SizeUtils.calculateRenderSize(page.width, page.height, maxSide);
        return page.render(
          width: size.width,
          height: size.height,
          backgroundColor: backgroundColor.toHex(),
        );
      },
    );
  }
}
