import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart';
import 'package:organista/config/app_constants.dart';
import 'package:organista/extensions/hex_color.dart';
import 'package:organista/features/show_music_sheet/music_sheet_view.dart';
import 'package:organista/features/settings/cubit/settings_cubit.dart';
import 'package:organista/features/settings/cubit/settings_state.dart';
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
      // Web version - process in chunks to avoid blocking
      final response = await get(Uri.parse(musicSheet.fileUrl));
      final document = await PdfDocument.openData(response.bodyBytes);

      // Yield control back to UI thread after processing
      await Future.delayed(Duration.zero);

      return document;
    } else {
      // Mobile version - cache first, then process
      final pdfFile = await _downloadAndCachePdf(musicSheet.fileUrl);

      if (pdfFile == null) {
        throw Exception('Failed to download or cache PDF file');
      }

      final document = await PdfDocument.openFile(pdfFile.path);

      // Yield control back to UI thread after processing
      await Future.delayed(Duration.zero);

      return document;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfController = useState<PdfController?>(null);
    final isLoading = useState(true);
    final hasError = useState(false);

    useEffect(() {
      // Use a completer to handle the async operation properly
      final completer = Completer<void>();

      () async {
        try {
          final document = await _loadPdfDocument();

          if (!completer.isCompleted) {
            pdfController.value = PdfController(document: Future.value(document));
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

    if (hasError.value || pdfController.value == null) {
      return const Center(
        child: Icon(
          Icons.warning_rounded,
          color: Colors.red,
        ),
      );
    }

    return switch (mode) {
      MusicSheetViewMode.full => getPdfFullView(pdfController),
      MusicSheetViewMode.thumbnail => getPdfThumbnailView(pdfController),
      MusicSheetViewMode.preview => getPdfPreview(pdfController),
    };
  }

  PdfView getPdfPreview(ValueNotifier<PdfController?> pdfController) {
    return PdfView(
      controller: pdfController.value!,
      renderer: (PdfPage page) => page.render(
        width: page.width * 0.5,
        height: page.height * 0.5,
        backgroundColor: backgroundColor.toHex(),
      ),
    );
  }

  PdfView getPdfThumbnailView(ValueNotifier<PdfController?> pdfController) {
    return PdfView(
      controller: pdfController.value!,
      renderer: (PdfPage page) => page.render(
        width: page.width * 0.25,
        height: page.height * 0.25,
        backgroundColor: backgroundColor.toHex(),
      ),
    );
  }

  Widget getPdfFullView(ValueNotifier<PdfController?> pdfController) {
    final showTitle = useState(true);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        return SafeArea(
          // needed to use SafeArea because after update to new flutter, it overlays bottom navigation bar
          child: PhotoView.customChild(
            minScale: PhotoViewComputedScale.contained * 1.0,
            maxScale: PhotoViewComputedScale.contained * 3.0,
            initialScale: PhotoViewComputedScale.contained * 1.0,
            child: Stack(
              children: [
                /// PDF Viewer as the base layer
                Positioned.fill(
                  child: PdfView(
                    controller: pdfController.value!,
                    scrollDirection: Axis.vertical,
                  ),
                ),

                /// Music sheet name at the bottom-left
                if (showTitle.value)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => showTitle.value = false,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(153),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DefaultTextStyle(
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          child: Text(musicSheet.fileName),
                        ),
                      ),
                    ),
                  ),

                /// Page number overlay at the bottom-right
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(153),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: PdfPageNumber(
                      controller: pdfController.value!,
                      builder: (_, state, loadingState, pagesCount) => DefaultTextStyle(
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                        child: Text('${pdfController.value!.page}/${pagesCount ?? 0}'),
                      ),
                    ),
                  ),
                ),

                /// Navigation buttons
                if (settingsState.showNavigationArrows)
                  PdfPageNumber(
                    controller: pdfController.value!,
                    builder: (_, state, loadingState, pagesCount) {
                      if (pagesCount == null || pagesCount <= 1) {
                        return const SizedBox.shrink(); // Don't show buttons if only one page
                      }

                      final currentPage = pdfController.value!.page;
                      final canGoPrevious = currentPage > 1;
                      final canGoNext = currentPage < pagesCount;

                      return Stack(
                        children: [
                          // Previous page touch area at the top
                          if (canGoPrevious)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: MediaQuery.of(context).size.height * AppConstants.nextPagetouchAreaHeight,
                              child: Listener(
                                behavior: HitTestBehavior.opaque,
                                onPointerDown: (_) => pdfController.value!.jumpToPage(currentPage - 1),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.white.withAlpha(0),
                                        Colors.green.withAlpha(100),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        const Expanded(child: SizedBox()),
                                        const Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(left: 16, bottom: 16),
                                              child: Icon(
                                                Icons.arrow_upward,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          height: 1,
                                          decoration: BoxDecoration(
                                            color: Colors.green.withAlpha(150),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Next page touch area at the bottom
                          if (canGoNext)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: MediaQuery.of(context).size.height * AppConstants.nextPagetouchAreaHeight,
                              child: Listener(
                                behavior: HitTestBehavior.opaque,
                                onPointerDown: (_) => pdfController.value!.jumpToPage(currentPage + 1),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withAlpha(0),
                                        Colors.green.withAlpha(100),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 1,
                                          decoration: BoxDecoration(
                                            color: Colors.green.withAlpha(150),
                                          ),
                                        ),
                                        const Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(left: 16, top: 16),
                                              child: Icon(
                                                Icons.arrow_downward,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Expanded(child: SizedBox()),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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
