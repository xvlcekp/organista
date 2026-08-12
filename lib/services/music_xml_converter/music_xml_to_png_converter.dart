import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/services/music_xml_converter/music_xml_export_message_assembler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Renders a MusicXML document with OSMD in a headless WebView and
/// rasterizes each A4 page to a PNG file, honoring the sheet's saved
/// transposition. The WebView is never attached to the widget tree; the
/// export page lays itself out at a fixed pixel width instead.
class MusicXmlToPngConverter {
  /// Layout width of an exported page in CSS pixels (A4 portrait at ~150 DPI)
  static const int _pageWidthPx = 1240;

  /// Rasterization scale applied on top of the layout width (2 → ~300 DPI)
  static const int _rasterScale = 2;

  /// Maximum time to wait for OSMD to render and rasterize one sheet
  static const Duration _exportTimeout = Duration(minutes: 2);

  /// Renders [fileBytes] — the MusicXML content of [musicSheet] — to one PNG
  /// file per page and returns their paths in page order. Files are written
  /// to [outputDirectory] (the system temporary directory when omitted) and
  /// are overwritten on every export, so repeated exports don't accumulate
  /// files.
  Future<List<String>> convertToPngFiles({
    required MusicSheet musicSheet,
    required Uint8List fileBytes,
    Directory? outputDirectory,
  }) async {
    // Base64-encoded data URL so the WebView can load the file offline
    // encoding runs on a background isolate as in MusicXmlViewerWidget.
    final encoded = await compute(base64Encode, fileBytes);
    final fileData = 'data:application/octet-stream;base64,$encoded';

    final assembler = MusicXmlExportMessageAssembler();
    final controller = WebViewController();
    controller
      // ignore: unawaited_futures Communication with the native platform
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // ignore: unawaited_futures Communication with the native platform
      ..setOnConsoleMessage((message) {
        logger.w('[Export WebView] ${message.message}');
      })
      // ignore: unawaited_futures Communication with the native platform
      ..addJavaScriptChannel(
        'ExportChannel',
        onMessageReceived: (JavaScriptMessage message) => assembler.onMessage(message.message),
      )
      // ignore: unawaited_futures Communication with the native platform
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            controller.runJavaScript(
              'exportSheetToPng(${jsonEncode(fileData)}, ${musicSheet.transposition}, '
              '$_pageWidthPx, $_rasterScale)',
            );
          },
        ),
      )
      // ignore: unawaited_futures Communication with the native platform
      ..loadFlutterAsset('assets/html/musicXml_display.html');

    final pages = await assembler.result.timeout(_exportTimeout);
    if (pages.isEmpty) {
      throw Exception('MusicXML export of "${musicSheet.fileName}" produced no pages');
    }

    final directory = outputDirectory ?? await getTemporaryDirectory();
    final paths = <String>[];
    for (var i = 0; i < pages.length; i++) {
      final file = File('${directory.path}/musicxml_export_${musicSheet.musicSheetId}_$i.png');
      await file.writeAsBytes(pages[i], flush: true);
      paths.add(file.path);
    }
    logger.d('Exported MusicXML "${musicSheet.fileName}" to ${paths.length} PNG page(s)');
    return paths;
  }
}
