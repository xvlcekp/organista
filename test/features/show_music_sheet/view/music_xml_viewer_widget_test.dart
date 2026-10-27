import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_controls_overlay.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_thumbnail_widget.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_viewer_widget.dart';
import 'package:organista/features/show_music_sheet/view/sheet_load_error.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/music_sheets/music_sheet_source.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart' show WebViewWidget;
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// Fake platform that records the JavaScript the viewer runs and fires `onPageFinished`
/// as soon as the HTML asset is "loaded", so `initSheet` can be asserted on.
class FakeWebViewPlatform extends WebViewPlatform {
  FakePlatformWebViewController? lastController;

  @override
  PlatformWebViewController createPlatformWebViewController(PlatformWebViewControllerCreationParams params) {
    return lastController = FakePlatformWebViewController(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(PlatformNavigationDelegateCreationParams params) {
    return FakePlatformNavigationDelegate(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(PlatformWebViewWidgetCreationParams params) {
    return FakePlatformWebViewWidget(params);
  }
}

class FakePlatformWebViewController extends PlatformWebViewController {
  FakePlatformWebViewController(super.params) : super.implementation();

  FakePlatformNavigationDelegate? navigationDelegate;
  final List<String> runJavaScriptCalls = [];
  final Map<String, JavaScriptChannelParams> channels = {};

  /// Simulates the page posting [message] on the JavaScript channel [name].
  void postChannelMessage(String name, String message) {
    channels[name]!.onMessageReceived(JavaScriptMessage(message: message));
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setOnConsoleMessage(void Function(JavaScriptConsoleMessage consoleMessage) onConsoleMessage) async {}

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams javaScriptChannelParams) async {
    channels[javaScriptChannelParams.name] = javaScriptChannelParams;
  }

  @override
  Future<void> setPlatformNavigationDelegate(PlatformNavigationDelegate handler) async {
    navigationDelegate = handler as FakePlatformNavigationDelegate;
  }

  @override
  Future<void> loadFlutterAsset(String key) async {
    unawaited(Future<void>.microtask(() => navigationDelegate?.onPageFinished?.call(key)));
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    runJavaScriptCalls.add(javaScript);
  }
}

class FakePlatformNavigationDelegate extends PlatformNavigationDelegate {
  FakePlatformNavigationDelegate(super.params) : super.implementation();

  PageEventCallback? onPageFinished;

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    this.onPageFinished = onPageFinished;
  }
}

class FakePlatformWebViewWidget extends PlatformWebViewWidget {
  FakePlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class MockCacheManager extends Mock implements CacheManager {}

class MockPlaylistBloc extends MockCubit<PlaylistState> implements PlaylistBloc {}

void main() {
  group('MusicXmlViewerWidget', () {
    late FakeWebViewPlatform platform;
    late MockCacheManager mockCacheManager;
    late MockPlaylistBloc mockPlaylistBloc;
    late MusicSheet musicSheet;
    late MusicSheetUrlSource urlSource;
    final fileBytes = Uint8List.fromList([1, 2, 3]);
    const fileDataUrl = 'data:application/octet-stream;base64,AQID';
    final bytesSource = MusicSheetBytesSource(
      bytes: fileBytes,
      mediaType: MediaType.musicxml,
      fileName: 'song.musicxml',
    );

    setUp(() {
      WebViewPlatform.instance = platform = FakeWebViewPlatform();
      mockCacheManager = MockCacheManager();
      mockPlaylistBloc = MockPlaylistBloc();
      // The download never finishes, so the url source stays in its loading state.
      when(() => mockCacheManager.getSingleFile(any())).thenAnswer((_) => Completer<File>().future);

      musicSheet = MusicSheet(
        json: {
          MusicSheetKey.musicSheetId: 'id-1',
          MusicSheetKey.userId: 'user-1',
          MusicSheetKey.createdAt: Timestamp.now(),
          MusicSheetKey.fileUrl: 'https://example.com/song.musicxml',
          MusicSheetKey.fileName: 'song.musicxml',
          MusicSheetKey.originalFileStorageId: 'storage-id',
          MusicSheetKey.mediaType: 'musicxml',
          MusicSheetKey.sequenceId: 2,
          MusicSheetKey.transposition: 3,
        },
      );
      urlSource = MusicSheetUrlSource(musicSheet);
      registerFallbackValue(UpdateMusicSheetTranspositionEvent(musicSheet: musicSheet, transposition: 0));
    });

    Widget buildWidget(MusicSheetSource source, MusicSheetViewMode mode) {
      return Provider<CacheManager>.value(
        value: mockCacheManager,
        child: BlocProvider<PlaylistBloc>.value(
          value: mockPlaylistBloc,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: MusicXmlViewerWidget(source: source, mode: mode),
            ),
          ),
        ),
      );
    }

    /// Pumps the viewer and lets the file resolution, the base64 encoding isolate and the
    /// fake page load settle, so the webview has been handed its `initSheet` call.
    Future<FakePlatformWebViewController> pumpUntilLoaded(
      WidgetTester tester,
      MusicSheetSource source,
      MusicSheetViewMode mode,
    ) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(buildWidget(source, mode));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      return platform.lastController!;
    }

    /// Makes the cache manager hand out a real local file holding [fileBytes]. Only synchronous
    /// I/O is used: real async I/O outside `runAsync` never completes under the test clock.
    void stubDownloadedFile() {
      final dir = io.Directory.systemTemp.createTempSync('music_xml_viewer_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = const LocalFileSystem().file('${dir.path}/song.musicxml')..writeAsBytesSync(fileBytes);
      when(() => mockCacheManager.getSingleFile(any())).thenAnswer((_) async => file);
    }

    testWidgets('previews in-memory bytes by loading them into the webview as a data url', (tester) async {
      final controller = await pumpUntilLoaded(tester, bytesSource, MusicSheetViewMode.preview);

      expect(find.text('No file data available'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(controller.runJavaScriptCalls, ['initSheet("$fileDataUrl", 0)']);
    });

    testWidgets('does not persist a transposition for in-memory bytes', (tester) async {
      final controller = await pumpUntilLoaded(tester, bytesSource, MusicSheetViewMode.preview);

      controller.postChannelMessage('TransposeChannel', 't:2');

      verifyNever(() => mockPlaylistBloc.add(any()));
    });

    testWidgets('loads a stored sheet with its saved transposition and persists changes', (tester) async {
      stubDownloadedFile();

      final controller = await pumpUntilLoaded(tester, urlSource, MusicSheetViewMode.preview);
      controller.postChannelMessage('TransposeChannel', 't:5');

      expect(controller.runJavaScriptCalls, ['initSheet("$fileDataUrl", 3)']);
      verify(
        () => mockPlaylistBloc.add(UpdateMusicSheetTranspositionEvent(musicSheet: musicSheet, transposition: 5)),
      ).called(1);
    });

    testWidgets('shows the load error instead of a page that never loads when the download fails', (tester) async {
      // Handing the page the remote URL would leave it on its own spinner forever: the fetch inside the page
      // fails for the same reason the download did.
      when(() => mockCacheManager.getSingleFile(any())).thenAnswer((_) async => throw Exception('offline'));

      await tester.runAsync(() async {
        await tester.pumpWidget(buildWidget(urlSource, MusicSheetViewMode.full));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(find.byType(SheetLoadError), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(WebViewWidget), findsNothing);
    });

    testWidgets('shows thumbnail widget in thumbnail mode for url source', (tester) async {
      await tester.pumpWidget(buildWidget(urlSource, MusicSheetViewMode.thumbnail));

      expect(find.byType(MusicXmlThumbnailWidget), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows loading indicator in full mode before webview is ready', (tester) async {
      await tester.pumpWidget(buildWidget(urlSource, MusicSheetViewMode.full));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(MusicXmlControlsOverlay), findsNothing);
    });

    testWidgets('shows loading indicator in preview mode before webview is ready', (tester) async {
      await tester.pumpWidget(buildWidget(urlSource, MusicSheetViewMode.preview));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
