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
import 'package:organista/models/music_sheets/music_sheet_source.dart';
import 'package:pdfx/pdfx.dart';

/// Result of the usePdfDocument hook
class PdfLoadResult {
  final PdfController? controller;
  final bool isLoading;
  final bool hasError;

  PdfLoadResult({this.controller, this.isLoading = false, this.hasError = false});
}

/// Custom hook to manage PDF loading and coordination with GalleryCubit.
///
/// Accepts both [MusicSheetUrlSource] (fetches via cache/network) and
/// [MusicSheetBytesSource] (opens directly from bytes, no GalleryCubit coordination).
PdfLoadResult usePdfDocument(MusicSheetSource source) {
  final pdfControllerFuture = useState<PdfController?>(null);
  final isLoading = useState(true);
  final hasError = useState(false);
  final context = useContext();
  final cacheManager = context.read<CacheManager>();
  final galleryCubit = useMemoized(() => context.read<GalleryCubit?>(), []);

  Future<PdfDocument> loadDoc() async {
    return switch (source) {
      MusicSheetUrlSource(:final musicSheet) when kIsWeb => PdfDocument.openData(
        (await get(Uri.parse(musicSheet.fileUrl))).bodyBytes,
      ),
      MusicSheetUrlSource(:final musicSheet) => PdfDocument.openFile(
        (await cacheManager.getSingleFile(musicSheet.fileUrl)).path,
      ),
      MusicSheetBytesSource(:final bytes) => PdfDocument.openData(bytes),
    };
  }

  // Stable effect key: URL changes re-trigger loading; bytes sources run once.
  final effectKey = switch (source) {
    MusicSheetUrlSource(:final musicSheet) => musicSheet.fileUrl,
    MusicSheetBytesSource() => 'bytes',
  };

  useEffect(() {
    final completer = Completer<void>();
    () async {
      try {
        final document = await loadDoc();
        if (!completer.isCompleted) {
          int initialPage = 1;
          if (source is MusicSheetUrlSource && galleryCubit != null) {
            if (galleryCubit.state.navigationDirection == GalleryNavigationDirection.backward) {
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

          if (source is MusicSheetUrlSource) {
            galleryCubit?.updateActiveSheet(source.musicSheet.musicSheetId, controller);
          }
          completer.complete();
        }
      } catch (e, stackTrace) {
        if (e is SocketException || e is ClientException || e is OSError) {
          logger.w("Failed to load PDF due to network error (device is offline)", error: e);
        } else {
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
  }, [effectKey]);

  // Handle re-registration when active sheet changes (URL sources in gallery only).
  if (galleryCubit != null && source is MusicSheetUrlSource) {
    final currentId = context.select<GalleryCubit, String?>((cubit) => cubit.state.currentMusicSheetId);
    final isCurrent = currentId == source.musicSheet.musicSheetId;

    useEffect(() {
      if (isCurrent && pdfControllerFuture.value != null) {
        galleryCubit.updateActiveSheet(source.musicSheet.musicSheetId, pdfControllerFuture.value!);
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
