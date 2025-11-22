import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart';
import 'package:organista/config/app_theme.dart';
import 'package:organista/extensions/hex_color.dart';
import 'package:organista/features/show_music_sheet/music_sheet_view.dart';
import 'package:organista/features/settings/cubit/settings_cubit.dart';
import 'package:organista/features/settings/cubit/settings_state.dart';
import 'package:organista/features/show_music_sheet/zoomable_music_sheet_viewer.dart';
import 'package:organista/features/show_music_sheet/pdf_navigation_touch_area.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/managers/persistent_cache_manager.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewerWidget extends HookWidget {
  final MusicSheet musicSheet;
  final MusicSheetViewMode mode;
  final Color backgroundColor = Colors.white;

  const PdfViewerWidget({
    super.key,
    required this.musicSheet,
    this.mode = MusicSheetViewMode.full, // Default to full mode
  });

  Future<File?> _downloadAndCachePdf(String url) async {
    try {
      return await PersistentCacheManager().getSingleFile(url);
    } catch (e) {
      logger.e("Failed to load PDF: $e");
      return null;
    }
  }

  /// Load PDF document asynchronously without blocking main thread
  Future<PdfDocument> _loadPdfDocument() async {
    if (kIsWeb) {
      // Web version - download first, then parse
      final response = await get(Uri.parse(musicSheet.fileUrl));
      // Parse PDF asynchronously
      return await PdfDocument.openData(response.bodyBytes);
    } else {
      // Mobile version - cache first, then process
      final pdfFile = await _downloadAndCachePdf(musicSheet.fileUrl);

      if (pdfFile == null) {
        throw Exception('Failed to download or cache PDF file');
      }

      // Parse PDF asynchronously
      return await PdfDocument.openFile(pdfFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfControllerFuture = useState<PdfController?>(null);
    final isLoading = useState(true);
    final hasError = useState(false);

    useEffect(() {
      // Use a completer to handle the async operation properly
      final completer = Completer<void>();

      () async {
        try {
          final document = await _loadPdfDocument();

          if (!completer.isCompleted) {
            pdfControllerFuture.value = PdfController(document: Future.value(document));
            hasError.value = false;
            isLoading.value = false;
            completer.complete();
          }
        } catch (e) {
          if (!completer.isCompleted) {
            logger.e("Error loading PDF: $e");
            hasError.value = true;
            isLoading.value = false;
            completer.complete();
          }
        }
      }();

      return () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      };
    }, [musicSheet.fileUrl]);

    if (isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError.value || pdfControllerFuture.value == null) {
      return const Center(
        child: Icon(
          Icons.warning_rounded,
          color: Colors.red,
        ),
      );
    }
    final pdfController = pdfControllerFuture.value!;

    return switch (mode) {
      MusicSheetViewMode.full => getPdfFullView(pdfController),
      MusicSheetViewMode.thumbnail => getPdfThumbnailView(pdfController),
      MusicSheetViewMode.preview => getPdfPreview(pdfController),
    };
  }

  PdfView getPdfPreview(PdfController pdfController) {
    const double pdfRenderScale = 0.5;
    return PdfView(
      controller: pdfController,
      renderer: (PdfPage page) => page.render(
        width: page.width * pdfRenderScale,
        height: page.height * pdfRenderScale,
        backgroundColor: backgroundColor.toHex(),
      ),
    );
  }

  PdfView getPdfThumbnailView(PdfController pdfController) {
    const double pdfRenderScale = 0.25;
    return PdfView(
      controller: pdfController,
      renderer: (PdfPage page) => page.render(
        width: page.width * pdfRenderScale,
        height: page.height * pdfRenderScale,
        backgroundColor: backgroundColor.toHex(),
      ),
    );
  }

  Widget getPdfFullView(PdfController pdfController) {
    final showTitle = useState(true);
    final boxDecoration = BoxDecoration(
      color: AppTheme.lightTheme.colorScheme.onSurface,
      borderRadius: BorderRadius.circular(AppTheme.inputBorderRadius),
    );
    const symetricPosition = 16.0;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        return SafeArea(
          // needed to use SafeArea because after update to new flutter, it overlays bottom navigation bar
          child: ZoomableMusicSheetViewer(
            child: Stack(
              children: [
                /// PDF Viewer as the base layer
                Positioned.fill(
                  child: PdfView(
                    controller: pdfController,
                    scrollDirection: Axis.vertical,
                  ),
                ),

                /// Music sheet name at the bottom-left
                if (showTitle.value)
                  Positioned(
                    bottom: symetricPosition,
                    left: symetricPosition,
                    child: GestureDetector(
                      onTap: () => showTitle.value = false,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: boxDecoration,
                        child: Text(
                          musicSheet.fileName,
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                /// Page number overlay at the bottom-right
                Positioned(
                  bottom: symetricPosition,
                  right: symetricPosition,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: boxDecoration,
                    child: PdfPageNumber(
                      controller: pdfController,
                      builder: (_, state, loadingState, pagesCount) => DefaultTextStyle(
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                        child: Text('${pdfController.page}/${pagesCount ?? 0}'),
                      ),
                    ),
                  ),
                ),

                /// Navigation buttons
                if (settingsState.showNavigationArrows)
                  PdfPageNumber(
                    controller: pdfController,
                    builder: (_, state, loadingState, pagesCount) {
                      if (pagesCount == null || pagesCount <= 1) {
                        return const SizedBox.shrink(); // Don't show buttons if only one page
                      }

                      final currentPage = pdfController.page;
                      final canGoPrevious = currentPage > 1;
                      final canGoNext = currentPage < pagesCount;

                      return Stack(
                        children: [
                          // Previous page touch area at the top
                          if (canGoPrevious)
                            PdfNavigationTouchArea(
                              direction: NavigationDirection.top,
                              onTap: () => pdfController.jumpToPage(currentPage - 1),
                            ),

                          // Next page touch area at the bottom
                          if (canGoNext)
                            PdfNavigationTouchArea(
                              direction: NavigationDirection.bottom,
                              onTap: () => pdfController.jumpToPage(currentPage + 1),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
