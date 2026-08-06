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

/// Opens the [PdfDocument] backing a music sheet. Injectable so tests can
/// exercise the load/dispose lifecycle without the native pdfium bindings.
typedef PdfDocumentOpener = Future<PdfDocument> Function();

/// Custom hook to manage PDF loading and coordination with GalleryCubit.
///
/// Accepts both [MusicSheetUrlSource] (fetches via cache/network) and
/// [MusicSheetBytesSource] (opens directly from bytes, no GalleryCubit coordination).
///
/// The hook owns the [PdfDocument] and [PdfController] it creates and releases
/// both when the widget unmounts or when [source] points at a different file.
PdfLoadResult usePdfDocument(MusicSheetSource source, {PdfDocumentOpener? documentOpener}) {
  final pdfControllerFuture = useState<PdfController?>(null);
  final isLoading = useState(true);
  final hasError = useState(false);
  final context = useContext();
  final cacheManager = context.read<CacheManager>();
  final galleryCubit = useMemoized(() => context.read<GalleryCubit?>(), []);

  Future<PdfDocument> loadDoc() async {
    if (documentOpener != null) {
      return documentOpener();
    }
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
    PdfController? createdController;
    PdfDocument? openedDocument;

    () async {
      // Re-runs (the source now points at a different file) start over from the
      // loading state so nothing can render the controller the cleanup below
      // has just disposed.
      isLoading.value = true;
      hasError.value = false;
      pdfControllerFuture.value = null;

      try {
        final document = await loadDoc();

        // Torn down while loading: nothing will ever render this document, so
        // release it here instead of handing it to a controller.
        if (completer.isCompleted) {
          await document.close();
          return;
        }

        openedDocument = document;

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
        createdController = controller;
        pdfControllerFuture.value = controller;
        hasError.value = false;
        isLoading.value = false;

        if (source is MusicSheetUrlSource) {
          galleryCubit?.updateActiveSheet(source.musicSheet.musicSheetId, controller);
        }
        completer.complete();
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
    return () {
      if (!completer.isCompleted) {
        completer.complete();
      }

      // Drop the gallery's pointer first: its navigation callbacks read
      // state.currentController and would otherwise touch a disposed one.
      if (createdController != null &&
          galleryCubit != null &&
          !galleryCubit.isClosed &&
          galleryCubit.state.currentController == createdController) {
        galleryCubit.clearActiveSheet();
      }

      // PdfController.dispose() only releases its PageController, so the
      // native document has to be closed separately or its fd leaks.
      createdController?.dispose();
      unawaited(openedDocument?.close() ?? Future<void>.value());
    };
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
