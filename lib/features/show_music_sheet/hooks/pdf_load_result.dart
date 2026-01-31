import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' show CacheManager;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart';
import 'package:organista/features/full_screen_gallery/cubit/gallery_cubit.dart';
import 'package:organista/features/full_screen_gallery/cubit/gallery_state.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:pdfx/pdfx.dart';

/// Result of the usePdfDocument hook
class PdfLoadResult {
  final PdfController? controller;
  final bool isLoading;
  final bool hasError;

  PdfLoadResult({this.controller, this.isLoading = false, this.hasError = false});
}

/// Custom hook to manage PDF loading and coordination with GalleryCubit
PdfLoadResult usePdfDocument(MusicSheet musicSheet) {
  final pdfControllerFuture = useState<PdfController?>(null);
  final isLoading = useState(true);
  final hasError = useState(false);
  final context = useContext();
  final cacheManager = context.read<CacheManager>();
  final galleryCubit = useMemoized(() => context.read<GalleryCubit?>(), []);

  // Helper to load document
  Future<PdfDocument> loadDoc() async {
    if (kIsWeb) {
      final response = await get(Uri.parse(musicSheet.fileUrl));
      return await PdfDocument.openData(response.bodyBytes);
    } else {
      final pdfFile = await cacheManager.getSingleFile(musicSheet.fileUrl);
      return await PdfDocument.openFile(pdfFile.path);
    }
  }

  useEffect(() {
    final completer = Completer<void>();
    () async {
      try {
        final document = await loadDoc();
        if (!completer.isCompleted) {
          int initialPage = 1;
          if (galleryCubit != null) {
            final direction = galleryCubit.state.navigationDirection;
            if (direction == GalleryNavigationDirection.backward) {
              initialPage = document.pagesCount;
            }
          }

          final controller = PdfController(
            document: Future.value(document),
            initialPage: initialPage,
          );
          pdfControllerFuture.value = controller;
          hasError.value = false;
          isLoading.value = false;

          galleryCubit?.updateActiveSheet(musicSheet.musicSheetId, controller);
          completer.complete();
        }
      } catch (e, stackTrace) {
        // Network errors are expected when device is offline - don't report to Sentry
        if (e is SocketException || e is ClientException || e is OSError) {
          logger.w("Failed to load PDF due to network error (device is offline)", error: e);
        } else {
          // Real errors should be reported to Sentry
          logger.e("Failed to load PDF", error: e, stackTrace: stackTrace);
        }

        if (!completer.isCompleted) {
          hasError.value = true;
          isLoading.value = false;
          completer.complete();
        }
      }
    }();
    return () => completer.isCompleted ? null : completer.complete();
  }, [musicSheet.fileUrl]);

  // Handle re-registration when active
  if (galleryCubit != null) {
    final currentId = context.select<GalleryCubit, String?>((cubit) => cubit.state.currentMusicSheetId);
    final isCurrent = currentId == musicSheet.musicSheetId;

    useEffect(() {
      if (isCurrent && pdfControllerFuture.value != null) {
        galleryCubit.updateActiveSheet(musicSheet.musicSheetId, pdfControllerFuture.value!);
      }
      return null;
    }, [isCurrent, pdfControllerFuture.value]);
  }

  return PdfLoadResult(
    controller: pdfControllerFuture.value,
    isLoading: isLoading.value,
    hasError: hasError.value,
  );
}
