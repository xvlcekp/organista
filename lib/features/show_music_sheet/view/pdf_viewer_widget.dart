import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/extensions/hex_color.dart';
import 'package:organista/features/show_music_sheet/view/sheet_load_error.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/features/show_music_sheet/view/pdf_page_counter.dart';
import 'package:organista/features/show_music_sheet/view/pdf_page_navigation.dart';
import 'package:organista/models/music_sheets/music_sheet_source.dart';
import 'package:pdfx/pdfx.dart';

import 'package:organista/features/show_music_sheet/hooks/pdf_load_result.dart';

class PdfViewerWidget extends HookWidget {
  final MusicSheetSource source;
  final MusicSheetViewMode mode;
  final Color backgroundColor = Colors.white;

  /// Quality for PDF full rendering
  static const double fullQuality = 2.0;

  /// Quality for PDF preview rendering
  static const double previewQuality = 1.0;

  /// Quality for PDF thumbnail rendering
  static const double thumbnailQuality = 0.5;

  const PdfViewerWidget({
    super.key,
    required this.source,
    this.mode = MusicSheetViewMode.full,
  });

  /// pdfx's default builders with [_pageBuilder] in place of its page builder.
  @visibleForTesting
  static const PdfViewBuilders<DefaultBuilderOptions> viewBuilders = PdfViewBuilders<DefaultBuilderOptions>(
    options: DefaultBuilderOptions(),
    pageBuilder: _pageBuilder,
  );

  /// Same page as pdfx builds by default, except that a failure of [pageImage] nobody waits for is not
  /// reported as unhandled.
  ///
  /// `PdfView` requests the page again on every rebuild (a rotation is enough), but Flutter loads only the first
  /// of those equal image providers, so the later futures have no listener. When the sheet is left while they
  /// are still queued, the document is closed underneath them and they fail with
  /// `PdfDocumentAlreadyClosedException` (pdfx issue #651), which then surfaces as a fatal in Sentry although
  /// the page is no longer on screen. The image that is actually displayed still receives its own error.
  static PhotoViewGalleryPageOptions _pageBuilder(
    BuildContext context,
    Future<PdfPageImage> pageImage,
    int index,
    PdfDocument document,
  ) {
    pageImage.ignore();
    return PhotoViewGalleryPageOptions(
      imageProvider: PdfPageImageProvider(pageImage, index, document.id),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.contained * _maxPageScale,
      initialScale: PhotoViewComputedScale.contained,
      heroAttributes: PhotoViewHeroAttributes(tag: '${document.id}-$index'),
    );
  }

  /// How far a page can be zoomed in, relative to fitting the screen (pdfx's default).
  static const double _maxPageScale = 3.0;

  @override
  Widget build(BuildContext context) {
    final loadResult = usePdfDocument(source);

    if (loadResult.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadResult.hasError || loadResult.controller == null) {
      return SheetLoadError(mode: mode);
    }

    final pdfController = loadResult.controller!;

    final qualityMultiplier = switch (mode) {
      MusicSheetViewMode.full => fullQuality,
      MusicSheetViewMode.thumbnail => thumbnailQuality,
      MusicSheetViewMode.preview => previewQuality,
    };

    return Stack(
      children: [
        PdfView(
          controller: pdfController,
          scrollDirection: Axis.vertical,
          builders: viewBuilders,
          renderer: (PdfPage page) {
            return page.render(
              width: page.width * qualityMultiplier,
              height: page.height * qualityMultiplier,
              format: PdfPageImageFormat.jpeg,
              backgroundColor: backgroundColor.toHex(),
            );
          },
        ),
        if (mode == MusicSheetViewMode.full) PdfPageCounter(controller: pdfController),
        if (mode == MusicSheetViewMode.full) PdfPageNavigation(controller: pdfController),
      ],
    );
  }
}
