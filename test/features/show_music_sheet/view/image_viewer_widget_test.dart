import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/show_music_sheet/view/image_viewer_widget.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/music_sheets/music_sheet_source.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

class MockCacheManager extends Mock implements CacheManager {}

void main() {
  group('ImageViewerWidget', () {
    late MockCacheManager mockCacheManager;
    late MusicSheetUrlSource urlSource;
    final bytesSource = MusicSheetBytesSource(
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      mediaType: MediaType.image,
      fileName: 'photo.jpg',
    );

    setUp(() {
      mockCacheManager = MockCacheManager();
      // Never resolves, keeping CachedNetworkImage in its loading/placeholder state.
      when(
        () => mockCacheManager.getFileStream(
          any(),
          headers: any(named: 'headers'),
          withProgress: any(named: 'withProgress'),
        ),
      ).thenAnswer((_) => const Stream.empty());

      final musicSheet = MusicSheet(
        json: {
          MusicSheetKey.musicSheetId: 'id-1',
          MusicSheetKey.userId: 'user-1',
          MusicSheetKey.createdAt: Timestamp.now(),
          MusicSheetKey.fileUrl: 'https://example.com/sheet.png',
          MusicSheetKey.fileName: 'sheet.png',
          MusicSheetKey.originalFileStorageId: 'storage-id',
          MusicSheetKey.mediaType: 'image',
          MusicSheetKey.sequenceId: 0,
        },
      );
      urlSource = MusicSheetUrlSource(musicSheet);
    });

    Widget buildWidget(MusicSheetSource source, MusicSheetViewMode mode) {
      return Provider<CacheManager>.value(
        value: mockCacheManager,
        child: MaterialApp(
          home: Scaffold(
            body: ImageViewerWidget(source: source, mode: mode),
          ),
        ),
      );
    }

    testWidgets('renders PhotoView with CachedNetworkImageProvider for url source in full mode', (tester) async {
      await tester.pumpWidget(buildWidget(urlSource, MusicSheetViewMode.full));

      final photoView = tester.widget<PhotoView>(find.byType(PhotoView));
      expect(photoView.imageProvider, isA<CachedNetworkImageProvider>());
    });

    testWidgets('renders PhotoView with MemoryImage for bytes source in full mode', (tester) async {
      await tester.pumpWidget(buildWidget(bytesSource, MusicSheetViewMode.full));

      final photoView = tester.widget<PhotoView>(find.byType(PhotoView));
      expect(photoView.imageProvider, isA<MemoryImage>());
    });

    testWidgets('renders CachedNetworkImage for url source in preview mode', (tester) async {
      await tester.pumpWidget(buildWidget(urlSource, MusicSheetViewMode.preview));

      final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(image.memCacheWidth, 500);
      expect(image.filterQuality, FilterQuality.medium);
    });

    testWidgets('renders CachedNetworkImage for url source in thumbnail mode', (tester) async {
      await tester.pumpWidget(buildWidget(urlSource, MusicSheetViewMode.thumbnail));

      final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(image.memCacheWidth, 75);
      expect(image.filterQuality, FilterQuality.low);
    });

    testWidgets('renders Image.memory for bytes source in preview mode', (tester) async {
      await tester.pumpWidget(buildWidget(bytesSource, MusicSheetViewMode.preview));

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<MemoryImage>());
      expect(image.filterQuality, FilterQuality.medium);
    });

    testWidgets('renders Image.memory for bytes source in thumbnail mode', (tester) async {
      await tester.pumpWidget(buildWidget(bytesSource, MusicSheetViewMode.thumbnail));

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<MemoryImage>());
      expect(image.filterQuality, FilterQuality.low);
    });
  });
}
