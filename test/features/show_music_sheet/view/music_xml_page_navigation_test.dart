import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/settings/cubit/settings_cubit.dart';
import 'package:organista/features/settings/cubit/settings_state.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_viewer_widget.dart';
import 'package:organista/features/show_music_sheet/view/page_counter_badge.dart';
import 'package:organista/features/show_music_sheet/view/pdf_navigation_touch_area.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/music_sheets/music_sheet_source.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class MockCacheManager extends Mock implements CacheManager {}

class MockPlaylistBloc extends MockCubit<PlaylistState> implements PlaylistBloc {}

class MockSettingsCubit extends MockCubit<SettingsState> implements SettingsCubit {}

/// Fake platform whose controller replays [pageMessages] on the `PageChannel`
/// once the viewer calls `initSheet(...)`, the way the page JavaScript does
/// after its first render.
class FakeWebViewPlatform extends WebViewPlatform {
  FakeWebViewPlatform({required this.pageMessages});

  final List<String> pageMessages;
  FakePlatformWebViewController? lastController;

  @override
  PlatformWebViewController createPlatformWebViewController(PlatformWebViewControllerCreationParams params) {
    return lastController = FakePlatformWebViewController(params, pageMessages);
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
  FakePlatformWebViewController(super.params, this.pageMessages) : super.implementation();

  final List<String> pageMessages;
  final Map<String, JavaScriptChannelParams> channels = {};
  FakePlatformNavigationDelegate? navigationDelegate;
  final List<String> runJavaScriptCalls = [];

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
    if (javaScript.startsWith('initSheet')) {
      unawaited(
        Future<void>.microtask(() {
          for (final message in pageMessages) {
            channels['PageChannel']?.onMessageReceived(JavaScriptMessage(message: message));
          }
        }),
      );
    }
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

void main() {
  group('MusicXmlViewerWidget page navigation', () {
    late MockCacheManager mockCacheManager;
    late MockPlaylistBloc mockPlaylistBloc;
    late MockSettingsCubit mockSettingsCubit;
    late MusicSheetUrlSource urlSource;

    const settingsWithArrows = SettingsState(
      themeModeIndex: 0,
      localeString: 'en',
      showNavigationArrows: true,
      keepScreenOn: false,
    );

    setUp(() {
      mockCacheManager = MockCacheManager();
      // The viewer only opens a sheet it could fetch; the page under test is fake, so any bytes will do.
      when(
        () => mockCacheManager.getSingleFile(any()),
      ).thenAnswer((_) async => MemoryFileSystem().file('song.musicxml')..writeAsBytesSync([1, 2, 3]));
      mockPlaylistBloc = MockPlaylistBloc();
      mockSettingsCubit = MockSettingsCubit();
      when(() => mockSettingsCubit.state).thenReturn(settingsWithArrows);

      urlSource = MusicSheetUrlSource(
        MusicSheet(
          json: {
            MusicSheetKey.musicSheetId: 'id-1',
            MusicSheetKey.userId: 'user-1',
            MusicSheetKey.createdAt: Timestamp.now(),
            MusicSheetKey.fileUrl: 'https://example.com/song.musicxml',
            MusicSheetKey.fileName: 'song.musicxml',
            MusicSheetKey.originalFileStorageId: 'storage-id',
            MusicSheetKey.mediaType: 'musicxml',
            MusicSheetKey.sequenceId: 2,
            MusicSheetKey.transposition: 0,
          },
        ),
      );
    });

    Widget buildWidget({Widget? child}) {
      return Provider<CacheManager>.value(
        value: mockCacheManager,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<PlaylistBloc>.value(value: mockPlaylistBloc),
            BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: child ?? MusicXmlViewerWidget(source: urlSource, mode: MusicSheetViewMode.full),
            ),
          ),
        ),
      );
    }

    Future<FakeWebViewPlatform> pumpWithPages(WidgetTester tester, List<String> messages, {Widget? child}) async {
      final platform = FakeWebViewPlatform(pageMessages: messages);
      WebViewPlatform.instance = platform;
      // The file is base64-encoded on a background isolate, which only completes under real async time.
      await tester.runAsync(() async {
        await tester.pumpWidget(buildWidget(child: child));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      return platform;
    }

    testWidgets('shows the counter and both tap areas on a middle page', (tester) async {
      await pumpWithPages(tester, ['p:2/3']);

      expect(find.text('2/3'), findsOneWidget);
      expect(find.byType(PdfNavigationTouchArea), findsNWidgets(2));
    });

    testWidgets('shows only the forward tap area on the first page', (tester) async {
      await pumpWithPages(tester, ['p:1/3']);

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
    });

    testWidgets('tapping the tap areas turns the page in the WebView', (tester) async {
      final platform = await pumpWithPages(tester, ['p:2/3']);

      await tester.tap(find.byIcon(Icons.arrow_downward));
      await tester.tap(find.byIcon(Icons.arrow_upward));

      expect(platform.lastController!.runJavaScriptCalls, containsAll(['nextPage()', 'prevPage()']));
    });

    testWidgets('shows nothing for a single-page sheet', (tester) async {
      await pumpWithPages(tester, ['p:1/1']);

      expect(find.byType(PageCounterBadge), findsNothing);
      expect(find.byType(PdfNavigationTouchArea), findsNothing);
    });

    testWidgets('keeps the counter but hides the tap areas when arrows are disabled', (tester) async {
      when(() => mockSettingsCubit.state).thenReturn(settingsWithArrows.copyWith(showNavigationArrows: false));
      await pumpWithPages(tester, ['p:2/3']);

      expect(find.text('2/3'), findsOneWidget);
      expect(find.byType(PdfNavigationTouchArea), findsNothing);
    });

    testWidgets('a tap on the sheet hides the counter, controls and title, the next tap shows them', (tester) async {
      final platform = await pumpWithPages(
        tester,
        ['p:2/3', 'tap'],
        child: MusicSheetView(source: urlSource, mode: MusicSheetViewMode.full),
      );

      expect(find.text('2/3'), findsNothing);
      expect(find.byIcon(Icons.tune), findsNothing);
      expect(find.text('song.musicxml'), findsNothing);
      // The page-turn areas stay: tapping them turns the page, not the overlays
      expect(find.byType(PdfNavigationTouchArea), findsNWidgets(2));

      platform.lastController!.channels['PageChannel']!.onMessageReceived(const JavaScriptMessage(message: 'tap'));
      await tester.pump();

      expect(find.text('2/3'), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.text('song.musicxml'), findsOneWidget);
    });
  });

  group('MusicXmlViewerWidget.parsePageMessage', () {
    test('parses a well-formed page message', () {
      expect(MusicXmlViewerWidget.parsePageMessage('p:2/3'), (2, 3));
    });

    test('rejects malformed or out-of-range messages', () {
      expect(MusicXmlViewerWidget.parsePageMessage('t:3'), isNull);
      expect(MusicXmlViewerWidget.parsePageMessage('p:2'), isNull);
      expect(MusicXmlViewerWidget.parsePageMessage('p:x/3'), isNull);
      expect(MusicXmlViewerWidget.parsePageMessage('p:4/3'), isNull);
      expect(MusicXmlViewerWidget.parsePageMessage('p:0/3'), isNull);
    });
  });
}
