import 'package:equatable/equatable.dart';
import 'package:pdfx/pdfx.dart';

class GalleryState extends Equatable {
  final PdfController? currentController;
  final String? currentMusicSheetId;
  final GalleryNavigationDirection navigationDirection;

  const GalleryState({
    this.currentController,
    this.currentMusicSheetId,
    this.navigationDirection = GalleryNavigationDirection.none,
  });

  GalleryState copyWith({
    ValueGetter<PdfController?>? currentController,
    ValueGetter<String?>? currentMusicSheetId,
    GalleryNavigationDirection? navigationDirection,
  }) {
    return GalleryState(
      currentController: currentController != null ? currentController() : this.currentController,
      currentMusicSheetId: currentMusicSheetId != null ? currentMusicSheetId() : this.currentMusicSheetId,
      navigationDirection: navigationDirection ?? this.navigationDirection,
    );
  }

  @override
  List<Object?> get props => [currentController, currentMusicSheetId, navigationDirection];
}

// Helper for nullable updates in copyWith
typedef ValueGetter<T> = T Function();

enum GalleryNavigationDirection { forward, backward, none }
