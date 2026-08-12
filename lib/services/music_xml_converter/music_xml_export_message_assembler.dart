import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show StringCharacters;

/// Reassembles the chunked PNG pages posted by `exportSheetToPng()` in
/// `assets/html/musicXml_display.html` over the `ExportChannel`.
///
/// Message protocol (2-character prefix, matching the viewer's channel style):
/// - `c:<base64 chunk>` — a chunk of the page currently being transferred
/// - `p:` — current page complete
/// - `d:` — all pages transferred
/// - `x:<message>` — export failed in JavaScript
class MusicXmlExportMessageAssembler {
  static const String _chunkPrefix = 'c:';
  static const String _pageDonePrefix = 'p:';
  static const String _allDonePrefix = 'd:';
  static const String _errorPrefix = 'x:';
  static const int _prefixLength = 2;

  final StringBuffer _chunks = StringBuffer();
  final List<Uint8List> _pages = <Uint8List>[];
  final Completer<List<Uint8List>> _completer = Completer<List<Uint8List>>();

  /// Completes with the PNG bytes of every rendered page, or with an error
  /// when the JavaScript side reports a failure.
  Future<List<Uint8List>> get result => _completer.future;

  void onMessage(String message) {
    if (_completer.isCompleted) return;
    if (message.startsWith(_chunkPrefix)) {
      _chunks.write(message.characters.getRange(_prefixLength).string);
    } else if (message.startsWith(_pageDonePrefix)) {
      _pages.add(base64Decode(_chunks.toString()));
      _chunks.clear();
    } else if (message.startsWith(_allDonePrefix)) {
      _completer.complete(List.unmodifiable(_pages));
    } else if (message.startsWith(_errorPrefix)) {
      _completer.completeError(
        Exception('MusicXML export failed: ${message.characters.getRange(_prefixLength).string}'),
      );
    }
  }
}
