import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/full_screen_gallery/cubit/gallery_state.dart';
import 'package:pdfx/pdfx.dart';

class GalleryCubit extends Cubit<GalleryState> {
  GalleryCubit() : super(const GalleryState());

  void updateActiveSheet(String id, PdfController controller) {
    emit(
      state.copyWith(
        currentMusicSheetId: () => id,
        currentController: () => controller,
      ),
    );
  }

  /// Explicitly set navigation direction (used by buttons before swiping).
  void setNavigationDirection(GalleryNavigationDirection direction) {
    if (state.navigationDirection == direction) return;
    emit(state.copyWith(navigationDirection: direction));
  }
}
