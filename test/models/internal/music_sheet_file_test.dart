import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:organista/models/internal/music_sheet_file.dart';
import 'package:organista/models/music_sheets/media_type.dart';

void main() {
  group('MusicSheetFile', () {
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

    test('keeps the name, bytes and media type it was created with', () {
      final file = MusicSheetFile(name: 'amazing_grace.pdf', bytes: bytes, mediaType: MediaType.pdf);

      expect(file.name, 'amazing_grace.pdf');
      expect(file.bytes, bytes);
      expect(file.mediaType, MediaType.pdf);
      expect(file.size, 5);
    });

    test('derives the media type from the file name', () {
      expect(MusicSheetFile.fromBytes(name: 'document.pdf', bytes: bytes).mediaType, MediaType.pdf);
      expect(MusicSheetFile.fromBytes(name: 'image.png', bytes: bytes).mediaType, MediaType.image);
      expect(MusicSheetFile.fromBytes(name: 'song.musicxml', bytes: bytes).mediaType, MediaType.musicxml);
    });

    test('accepts uppercase extensions', () {
      expect(MusicSheetFile.fromBytes(name: 'document.PDF', bytes: bytes).mediaType, MediaType.pdf);
      expect(MusicSheetFile.fromBytes(name: 'image.PNG', bytes: bytes).mediaType, MediaType.image);
    });

    test('rejects an unsupported extension', () {
      expect(
        () => MusicSheetFile.fromBytes(name: 'music.xyz', bytes: bytes),
        throwsA(isA<UnsupportedFileExtensionException>()),
      );
    });
  });
}
