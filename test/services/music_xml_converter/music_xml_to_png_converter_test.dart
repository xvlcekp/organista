import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/services/music_xml_converter/music_xml_to_png_converter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// Fake platform that hands out controllers replaying scripted [channelMessages]
/// once the export JavaScript is invoked.
class FakeWebViewPlatform extends WebViewPlatform {
  FakeWebViewPlatform({required this.channelMessages});

  final List<String> channelMessages;
  FakePlatformWebViewController? lastController;

  @override
  PlatformWebViewController createPlatformWebViewController(PlatformWebViewControllerCreationParams params) {
    return lastController = FakePlatformWebViewController(params, channelMessages);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(PlatformNavigationDelegateCreationParams params) {
    return FakePlatformNavigationDelegate(params);
  }
}

class FakePlatformWebViewController extends PlatformWebViewController {
  FakePlatformWebViewController(super.params, this.channelMessages) : super.implementation();

  final List<String> channelMessages;
  JavaScriptChannelParams? channelParams;
  FakePlatformNavigationDelegate? navigationDelegate;
  final List<String> runJavaScriptCalls = [];

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setOnConsoleMessage(void Function(JavaScriptConsoleMessage consoleMessage) onConsoleMessage) async {}

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams javaScriptChannelParams) async {
    channelParams = javaScriptChannelParams;
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
    if (javaScript.startsWith('exportSheetToPng')) {
      unawaited(
        Future<void>.microtask(() {
          for (final message in channelMessages) {
            channelParams?.onMessageReceived(JavaScriptMessage(message: message));
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

void main() {
  group('MusicXmlToPngConverter', () {
    late Directory tempDir;
    late MusicSheet musicSheet;
    final fileBytes = Uint8List.fromList(utf8.encode('<score-partwise/>'));

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('musicxml_converter_test');

      musicSheet = MusicSheet(
        json: {
          MusicSheetKey.musicSheetId: 'sheet-1',
          MusicSheetKey.userId: 'user-1',
          MusicSheetKey.createdAt: Timestamp.now(),
          MusicSheetKey.fileUrl: 'https://example.com/song.musicxml',
          MusicSheetKey.fileName: 'song.musicxml',
          MusicSheetKey.originalFileStorageId: 'storage-1',
          MusicSheetKey.mediaType: 'musicxml',
          MusicSheetKey.sequenceId: 1,
          MusicSheetKey.transposition: 3,
        },
      );
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('writes one PNG file per rendered page', () async {
      final firstPage = [1, 2, 3];
      final secondPage = [4, 5, 6];
      WebViewPlatform.instance = FakeWebViewPlatform(
        channelMessages: [
          'c:${base64Encode(firstPage)}',
          'p:',
          'c:${base64Encode(secondPage)}',
          'p:',
          'd:',
        ],
      );
      final converter = MusicXmlToPngConverter();

      final paths = await converter.convertToPngFiles(
        musicSheet: musicSheet,
        fileBytes: fileBytes,
        outputDirectory: tempDir,
      );

      expect(paths, hasLength(2));
      expect(await File(paths[0]).readAsBytes(), firstPage);
      expect(await File(paths[1]).readAsBytes(), secondPage);
    });

    test('passes the file data and saved transposition to the export JavaScript', () async {
      final platform = FakeWebViewPlatform(
        channelMessages: [
          'c:${base64Encode([1])}',
          'p:',
          'd:',
        ],
      );
      WebViewPlatform.instance = platform;
      final converter = MusicXmlToPngConverter();

      await converter.convertToPngFiles(musicSheet: musicSheet, fileBytes: fileBytes, outputDirectory: tempDir);

      final exportCall = platform.lastController!.runJavaScriptCalls.single;
      final expectedFileData = 'data:application/octet-stream;base64,${base64Encode(utf8.encode('<score-partwise/>'))}';
      expect(exportCall, startsWith('exportSheetToPng('));
      expect(exportCall, contains(jsonEncode(expectedFileData)));
      expect(exportCall, contains(', 3,'));
    });

    test('throws when the export produces no pages', () async {
      WebViewPlatform.instance = FakeWebViewPlatform(channelMessages: ['d:']);
      final converter = MusicXmlToPngConverter();

      await expectLater(
        converter.convertToPngFiles(musicSheet: musicSheet, fileBytes: fileBytes, outputDirectory: tempDir),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when the JavaScript export reports a failure', () async {
      WebViewPlatform.instance = FakeWebViewPlatform(channelMessages: ['x:OSMD failed']);
      final converter = MusicXmlToPngConverter();

      await expectLater(
        converter.convertToPngFiles(musicSheet: musicSheet, fileBytes: fileBytes, outputDirectory: tempDir),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('OSMD failed'))),
      );
    });
  });
}
