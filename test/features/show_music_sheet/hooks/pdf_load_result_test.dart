import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/show_music_sheet/hooks/pdf_load_result.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/music_sheets/music_sheet_source.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';

class MockCacheManager extends Mock implements CacheManager {}

class MockPdfDocument extends Mock implements PdfDocument {}

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

    group('usePdfDocument Resource Release', () {
      late MockCacheManager mockCacheManager;

      setUp(() {
        mockCacheManager = MockCacheManager();
      });

      MusicSheetSource sourceForUrl(String url) {
        return MusicSheetUrlSource(
          MusicSheet(
            json: {
              MusicSheetKey.musicSheetId: 'test-id',
              MusicSheetKey.userId: 'user-id',
              MusicSheetKey.fileName: 'test.pdf',
              MusicSheetKey.fileUrl: url,
              MusicSheetKey.mediaType: 'pdf',
              MusicSheetKey.originalFileStorageId: 'storage-id',
              MusicSheetKey.sequenceId: 0,
              MusicSheetKey.createdAt: Timestamp.now(),
            },
          ),
        );
      }

      MockPdfDocument openableDocument() {
        final document = MockPdfDocument();
        when(() => document.pagesCount).thenReturn(3);
        when(() => document.close()).thenAnswer((_) async {});
        return document;
      }

      Widget hostWidget(MusicSheetSource source, PdfDocumentOpener opener) {
        return Provider<CacheManager>.value(
          value: mockCacheManager,
          child: MaterialApp(
            home: HookBuilder(
              builder: (context) {
                final result = usePdfDocument(source, documentOpener: opener);
                return Scaffold(
                  body: result.controller != null ? const Text('Loaded') : const SizedBox(),
                );
              },
            ),
          ),
        );
      }

      testWidgets('closes the document when the widget is unmounted', (tester) async {
        final document = openableDocument();

        await tester.pumpWidget(hostWidget(sourceForUrl('https://example.com/a.pdf'), () async => document));
        await tester.pumpAndSettle();

        expect(find.text('Loaded'), findsOneWidget);
        verifyNever(() => document.close());

        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();

        verify(() => document.close()).called(1);
      });

      testWidgets('closes the previous document when the source file changes', (tester) async {
        final first = openableDocument();
        final second = openableDocument();

        await tester.pumpWidget(hostWidget(sourceForUrl('https://example.com/a.pdf'), () async => first));
        await tester.pumpAndSettle();

        await tester.pumpWidget(hostWidget(sourceForUrl('https://example.com/b.pdf'), () async => second));
        await tester.pumpAndSettle();

        verify(() => first.close()).called(1);
        verifyNever(() => second.close());
        expect(find.text('Loaded'), findsOneWidget);
      });

      testWidgets('closes a document that arrives after the widget is gone', (tester) async {
        final document = openableDocument();
        final gate = Completer<PdfDocument>();

        await tester.pumpWidget(hostWidget(sourceForUrl('https://example.com/a.pdf'), () => gate.future));
        await tester.pump();

        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();

        gate.complete(document);
        await tester.pumpAndSettle();

        verify(() => document.close()).called(1);
      });
    });
  });
}
