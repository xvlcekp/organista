import 'dart:async';
import 'dart:io' show SocketException, OSError;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/full_screen_gallery/cubit/gallery_cubit.dart';
import 'package:organista/features/full_screen_gallery/cubit/gallery_state.dart';
import 'package:organista/features/show_music_sheet/hooks/pdf_load_result.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/music_sheets/music_sheet_source.dart';
import 'package:pdfx/pdfx.dart';
import 'package:pdfx/src/renderer/interfaces/platform.dart';
import 'package:provider/provider.dart';

class MockCacheManager extends Mock implements CacheManager {}

/// Fake [PdfDocument] used to avoid depending on the real native pdfium plugin in tests.
class FakePdfDocument extends PdfDocument {
  FakePdfDocument({required super.pagesCount}) : super(sourceName: 'fake', id: 'fake-id');

  @override
  Future<void> close() async {}

  @override
  Future<PdfPage> getPage(int pageNumber, {bool autoCloseAndroid = false}) {
    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => identityHashCode(this);
}

/// Fake [PdfxPlatform] that returns [FakePdfDocument]s synchronously, bypassing
/// the native plugin channel that isn't available in the widget test environment.
class FakePdfxPlatform extends PdfxPlatform {
  FakePdfxPlatform({this.pagesCount = 1});

  final int pagesCount;

  @override
  Future<PdfDocument> openData(FutureOr<Uint8List> data, {String? password}) async {
    await data;
    return FakePdfDocument(pagesCount: pagesCount);
  }

  @override
  Future<PdfDocument> openFile(String filePath, {String? password}) async {
    return FakePdfDocument(pagesCount: pagesCount);
  }

  @override
  Future<PdfDocument> openAsset(String name, {String? password}) async {
    return FakePdfDocument(pagesCount: pagesCount);
  }
}

void main() {
  group('PDF Load Error Handling', () {
    bool isNetworkError(Object error) {
      return error is SocketException || error is http.ClientException || error is OSError;
    }

    group('Network Error Detection (Unit Tests)', () {
      final networkErrors = [
        (const SocketException('Network unreachable'), 'SocketException'),
        (http.ClientException('Connection failed'), 'ClientException'),
        (const OSError('No address associated with hostname', 7), 'OSError'),
        (
          const SocketException(
            'Failed host lookup: firebasestorage.googleapis.com',
            osError: OSError('No address associated with hostname', 7),
          ),
          'SocketException with OSError (Sentry scenario)',
        ),
      ];

      for (final (error, description) in networkErrors) {
        test('should identify $description as network error', () {
          expect(isNetworkError(error), isTrue);
        });
      }

      final nonNetworkErrors = [
        (Exception('File not found'), 'generic Exception'),
        (const FormatException('Invalid PDF format'), 'FormatException'),
        (StateError('Invalid state'), 'StateError'),
        ('Error string', 'String'),
      ];

      for (final (error, description) in nonNetworkErrors) {
        test('should not identify $description as network error', () {
          expect(isNetworkError(error), isFalse);
        });
      }
    });

    group('usePdfDocument Hook (Widget Tests)', () {
      late MockCacheManager mockCacheManager;
      late MusicSheetSource testSource;

      setUp(() {
        mockCacheManager = MockCacheManager();
        final testMusicSheet = MusicSheet(
          json: {
            MusicSheetKey.musicSheetId: 'test-id',
            MusicSheetKey.userId: 'user-id',
            MusicSheetKey.fileName: 'test.pdf',
            MusicSheetKey.fileUrl: 'https://example.com/test.pdf',
            MusicSheetKey.mediaType: 'pdf',
            MusicSheetKey.originalFileStorageId: 'storage-id',
            MusicSheetKey.sequenceId: 0,
            MusicSheetKey.createdAt: Timestamp.now(),
          },
        );
        testSource = MusicSheetUrlSource(testMusicSheet);
        registerFallbackValue(Uri.parse('https://example.com/test.pdf'));
      });

      Widget createTestWidget(MusicSheetSource source) {
        return Provider<CacheManager>.value(
          value: mockCacheManager,
          child: MaterialApp(
            home: HookBuilder(
              builder: (context) {
                final result = usePdfDocument(source);
                return Scaffold(
                  body: Column(
                    children: [
                      if (result.isLoading) const CircularProgressIndicator(),
                      if (result.hasError) const Icon(Icons.error),
                      if (result.controller != null) const Text('Loaded'),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }

      testWidgets('should show loading state initially', (tester) async {
        when(() => mockCacheManager.getSingleFile(any())).thenAnswer(
          (_) async => Future.delayed(const Duration(seconds: 10)),
        );

        await tester.pumpWidget(createTestWidget(testSource));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.error), findsNothing);
      });

      testWidgets('should show error icon when network error occurs', (tester) async {
        when(() => mockCacheManager.getSingleFile(any())).thenThrow(
          const SocketException('Failed host lookup'),
        );

        await tester.pumpWidget(createTestWidget(testSource));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('should show error icon when ClientException occurs', (tester) async {
        when(() => mockCacheManager.getSingleFile(any())).thenThrow(
          http.ClientException('Network unreachable'),
        );

        await tester.pumpWidget(createTestWidget(testSource));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('should show error icon for non-network errors', (tester) async {
        when(() => mockCacheManager.getSingleFile(any())).thenThrow(
          Exception('File system error'),
        );

        await tester.pumpWidget(createTestWidget(testSource));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error), findsOneWidget);
      });
    });

    group('usePdfDocument Hook (Successful Load)', () {
      late MockCacheManager mockCacheManager;
      late PdfxPlatform originalPlatform;

      MusicSheet buildMusicSheet(String id) => MusicSheet(
        json: {
          MusicSheetKey.musicSheetId: id,
          MusicSheetKey.userId: 'user-id',
          MusicSheetKey.fileName: 'test.pdf',
          MusicSheetKey.fileUrl: 'https://example.com/$id.pdf',
          MusicSheetKey.mediaType: 'pdf',
          MusicSheetKey.originalFileStorageId: 'storage-id',
          MusicSheetKey.sequenceId: 0,
          MusicSheetKey.createdAt: Timestamp.now(),
        },
      );

      setUp(() {
        mockCacheManager = MockCacheManager();
        registerFallbackValue(Uri.parse('https://example.com/test.pdf'));
        originalPlatform = PdfxPlatform.instance;
      });

      tearDown(() {
        PdfxPlatform.instance = originalPlatform;
      });

      Widget createTestWidget(MusicSheetSource source, {GalleryCubit? galleryCubit}) {
        final cacheManagerProvider = Provider<CacheManager>.value(
          value: mockCacheManager,
          child: HookBuilder(
            builder: (context) {
              final result = usePdfDocument(source);
              return MaterialApp(
                home: Scaffold(
                  body: Column(
                    children: [
                      if (result.isLoading) const CircularProgressIndicator(),
                      if (result.hasError) const Icon(Icons.error),
                      if (result.controller != null) Text('Loaded page ${result.controller!.initialPage}'),
                    ],
                  ),
                ),
              );
            },
          ),
        );

        if (galleryCubit == null) return cacheManagerProvider;
        return BlocProvider<GalleryCubit>.value(value: galleryCubit, child: cacheManagerProvider);
      }

      testWidgets('loads bytes source successfully without a gallery cubit', (tester) async {
        PdfxPlatform.instance = FakePdfxPlatform();
        final source = MusicSheetBytesSource(
          bytes: Uint8List.fromList([1, 2, 3]),
          mediaType: MediaType.pdf,
          fileName: 'bytes.pdf',
        );

        await tester.pumpWidget(createTestWidget(source));
        await tester.pumpAndSettle();

        expect(find.text('Loaded page 1'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsNothing);
      });

      testWidgets('registers the loaded controller as the active sheet on the gallery cubit', (tester) async {
        PdfxPlatform.instance = FakePdfxPlatform();
        when(() => mockCacheManager.getSingleFile(any())).thenAnswer(
          (_) async => const LocalFileSystem().file('test.pdf'),
        );
        final musicSheet = buildMusicSheet('sheet-1');
        final source = MusicSheetUrlSource(musicSheet);
        final galleryCubit = GalleryCubit();
        addTearDown(galleryCubit.close);

        await tester.pumpWidget(createTestWidget(source, galleryCubit: galleryCubit));
        await tester.pumpAndSettle();

        expect(find.text('Loaded page 1'), findsOneWidget);
        expect(galleryCubit.state.currentMusicSheetId, 'sheet-1');
        expect(galleryCubit.state.currentController, isNotNull);
      });

      testWidgets('opens on the last page when navigating backward through the gallery', (tester) async {
        PdfxPlatform.instance = FakePdfxPlatform(pagesCount: 5);
        when(() => mockCacheManager.getSingleFile(any())).thenAnswer(
          (_) async => const LocalFileSystem().file('test.pdf'),
        );
        final musicSheet = buildMusicSheet('sheet-2');
        final source = MusicSheetUrlSource(musicSheet);
        final galleryCubit = GalleryCubit()..setNavigationDirection(GalleryNavigationDirection.backward);
        addTearDown(galleryCubit.close);

        await tester.pumpWidget(createTestWidget(source, galleryCubit: galleryCubit));
        await tester.pumpAndSettle();

        expect(find.text('Loaded page 5'), findsOneWidget);
      });
    });
  });
}
