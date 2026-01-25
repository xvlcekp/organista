import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/full_screen_gallery/cubit/gallery_cubit.dart';
import 'package:organista/features/full_screen_gallery/cubit/gallery_state.dart';
import 'package:pdfx/pdfx.dart';

class MockPdfController extends Mock implements PdfController {}

void main() {
  group('GalleryCubit', () {
    late GalleryCubit galleryCubit;
    late MockPdfController mockPdfController;

    setUp(() {
      galleryCubit = GalleryCubit();
      mockPdfController = MockPdfController();
    });

    tearDown(() {
      galleryCubit.close();
    });

    test('initial state should be GalleryState with default values', () {
      expect(galleryCubit.state, const GalleryState());
      expect(galleryCubit.state.currentController, isNull);
      expect(galleryCubit.state.currentMusicSheetId, isNull);
      expect(galleryCubit.state.navigationDirection, GalleryNavigationDirection.none);
    });

    blocTest<GalleryCubit, GalleryState>(
      'updateActiveSheet emits state with new id and controller',
      build: () => galleryCubit,
      act: (cubit) => cubit.updateActiveSheet('sheet_1', mockPdfController),
      expect: () => [
        GalleryState(
          currentMusicSheetId: 'sheet_1',
          currentController: mockPdfController,
          navigationDirection: GalleryNavigationDirection.none,
        ),
      ],
    );

    blocTest<GalleryCubit, GalleryState>(
      'setNavigationDirection emits state with updated direction',
      build: () => galleryCubit,
      act: (cubit) => cubit.setNavigationDirection(GalleryNavigationDirection.forward),
      expect: () => [
        const GalleryState(
          navigationDirection: GalleryNavigationDirection.forward,
        ),
      ],
    );

    blocTest<GalleryCubit, GalleryState>(
      'setNavigationDirection does not emit if direction is the same',
      build: () => galleryCubit,
      act: (cubit) => cubit.setNavigationDirection(GalleryNavigationDirection.none),
      expect: () => [],
    );

    blocTest<GalleryCubit, GalleryState>(
      'multiple updates update state correctly',
      build: () => galleryCubit,
      act: (cubit) {
        cubit.setNavigationDirection(GalleryNavigationDirection.backward);
        cubit.updateActiveSheet('sheet_2', mockPdfController);
      },
      expect: () => [
        const GalleryState(
          navigationDirection: GalleryNavigationDirection.backward,
        ),
        GalleryState(
          currentMusicSheetId: 'sheet_2',
          currentController: mockPdfController,
          navigationDirection: GalleryNavigationDirection.backward,
        ),
      ],
    );
  });
}
