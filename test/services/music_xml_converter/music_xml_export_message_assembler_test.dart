import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:organista/services/music_xml_converter/music_xml_export_message_assembler.dart';

void main() {
  group('MusicXmlExportMessageAssembler', () {
    late MusicXmlExportMessageAssembler assembler;

    setUp(() {
      assembler = MusicXmlExportMessageAssembler();
    });

    test('assembles chunked base64 into a single page', () async {
      final pageBytes = [1, 2, 3, 4, 5, 6, 7, 8];
      final base64Page = base64Encode(pageBytes);
      final splitAt = base64Page.length ~/ 2;

      assembler.onMessage('c:${base64Page.substring(0, splitAt)}');
      assembler.onMessage('c:${base64Page.substring(splitAt)}');
      assembler.onMessage('p:');
      assembler.onMessage('d:');

      final pages = await assembler.result;
      expect(pages, hasLength(1));
      expect(pages.single, pageBytes);
    });

    test('assembles multiple pages in order', () async {
      final firstPage = [10, 20, 30];
      final secondPage = [40, 50, 60];

      assembler.onMessage('c:${base64Encode(firstPage)}');
      assembler.onMessage('p:');
      assembler.onMessage('c:${base64Encode(secondPage)}');
      assembler.onMessage('p:');
      assembler.onMessage('d:');

      final pages = await assembler.result;
      expect(pages, hasLength(2));
      expect(pages[0], firstPage);
      expect(pages[1], secondPage);
    });

    test('completes with an error when the export reports a failure', () async {
      assembler.onMessage('x:something went wrong');

      await expectLater(
        assembler.result,
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'message', contains('something went wrong')),
        ),
      );
    });

    test('ignores messages arriving after completion', () async {
      assembler.onMessage('c:${base64Encode([1, 2, 3])}');
      assembler.onMessage('p:');
      assembler.onMessage('d:');
      assembler.onMessage('c:${base64Encode([9, 9, 9])}');
      assembler.onMessage('p:');

      final pages = await assembler.result;
      expect(pages, hasLength(1));
    });
  });
}
