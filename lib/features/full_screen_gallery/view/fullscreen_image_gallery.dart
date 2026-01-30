import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:pdfx/pdfx.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/full_screen_gallery/cubit/gallery_cubit.dart';
import 'package:organista/features/full_screen_gallery/cubit/gallery_state.dart';
import 'package:organista/features/full_screen_gallery/view/gallery_shortcuts.dart';

class FullScreenImageGallery extends HookWidget {
  final List<MusicSheet> musicSheets;
  final int initialIndex;

  const FullScreenImageGallery({
    super.key,
    required this.musicSheets,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    final galleryPageController = usePageController(initialPage: initialIndex);
    final galleryCubit = useMemoized(() => GalleryCubit());

    useFullScreenMode();

    useEffect(() {
      return () => galleryCubit.close();
    }, [galleryCubit]);

    Future<void> turnPage(Future<void> Function({required Duration duration, required Curve curve}) action) {
      return action(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // Navigation Logic
    void nextPage() {
      final singlePageController = galleryCubit.state.currentController;
      if (singlePageController != null && singlePageController.page < singlePageController.pagesCount!) {
        turnPage(singlePageController.nextPage);
      } else if (galleryPageController.hasClients) {
        final currentIndex = galleryPageController.page?.round() ?? 0;
        if (currentIndex < musicSheets.length - 1) {
          galleryCubit.setNavigationDirection(GalleryNavigationDirection.forward);
          turnPage(galleryPageController.nextPage);
        }
      }
    }

    void previousPage() {
      final singlePageController = galleryCubit.state.currentController;

      if (singlePageController != null && singlePageController.page > 1) {
        turnPage(singlePageController.previousPage);
      } else if (galleryPageController.hasClients) {
        final currentIndex = galleryPageController.page?.round() ?? 0;
        if (currentIndex > 0) {
          // Explicitly set direction so landing page is correct
          galleryCubit.setNavigationDirection(GalleryNavigationDirection.backward);
          turnPage(galleryPageController.previousPage);
        }
      }
    }

    return BlocProvider<GalleryCubit>.value(
      value: galleryCubit,
      child: GalleryShortcuts(
        onNext: nextPage,
        onPrevious: previousPage,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: PhotoViewGallery.builder(
            pageController: galleryPageController,
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (_, int index) {
              logger.i("Index is $index");
              final musicSheet = musicSheets[index];
              return PhotoViewGalleryPageOptions.customChild(
                disableGestures: true,
                child: MusicSheetView(
                  key: ValueKey(musicSheet.musicSheetId),
                  musicSheet: musicSheet,
                  mode: MusicSheetViewMode.full,
                ),
              );
            },
            itemCount: musicSheets.length,
          ),
        ),
      ),
    );
  }
}

/// Custom hook to manage immersive mode (hiding system UI)
void useFullScreenMode() {
  useEffect(() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    return () {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    };
  }, []);
}

// TODO:
// MusicSheetView should be able to handle both PDFs and images and should be able to work with bytes
//.   Replace MusicSheet with other object and pass it to classes (PDFView appears twice in the project)
