import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/music_sheets/music_sheet_source.dart';

void main() {
  group('MusicSheetSource', () {
    late MusicSheet testMusicSheet;

    setUp(() {
      testMusicSheet = MusicSheet(
        json: {
          MusicSheetKey.musicSheetId: 'id-1',
          MusicSheetKey.userId: 'user-1',
          MusicSheetKey.createdAt: Timestamp.now(),
          MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
          MusicSheetKey.fileName: 'sheet.pdf',
          MusicSheetKey.originalFileStorageId: 'storage-id',
          MusicSheetKey.mediaType: 'pdf',
          MusicSheetKey.sequenceId: 0,
        },
      );
    });

    test('MusicSheetUrlSource delegates mediaType and fileName to musicSheet', () {
      final source = MusicSheetUrlSource(testMusicSheet);
      expect(source.mediaType, MediaType.pdf);
      expect(source.fileName, 'sheet.pdf');
      expect(source.musicSheet, testMusicSheet);
    });

    test('MusicSheetBytesSource stores bytes, mediaType, and fileName', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final source = MusicSheetBytesSource(
        bytes: bytes,
        mediaType: MediaType.image,
        fileName: 'photo.jpg',
      );
      expect(source.bytes, bytes);
      expect(source.mediaType, MediaType.image);
      expect(source.fileName, 'photo.jpg');
    });

    test('sealed switch is exhaustive over both subtypes', () {
      final MusicSheetSource source = MusicSheetBytesSource(
        bytes: Uint8List(0),
        mediaType: MediaType.image,
        fileName: 'x.png',
      );
      final result = switch (source) {
        MusicSheetUrlSource() => 'url',
        MusicSheetBytesSource() => 'bytes',
      };
      expect(result, 'bytes');
    });
  });
}
