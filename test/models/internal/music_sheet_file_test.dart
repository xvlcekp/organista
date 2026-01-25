import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:organista/models/internal/music_sheet_file.dart';
import 'package:organista/models/music_sheets/media_type.dart';

void main() {
  group('MusicSheetFile', () {
    test('should create MusicSheetFile with provided file and mediaType', () {
      final platformFile = PlatformFile(
        name: 'test.pdf',
        size: 1024,
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );

      final musicSheetFile = MusicSheetFile(
        file: platformFile,
        mediaType: MediaType.pdf,
      );

      expect(musicSheetFile.file, equals(platformFile));
      expect(musicSheetFile.mediaType, MediaType.pdf);
    });

    test('should create MusicSheetFile from PlatformFile with automatic MediaType detection', () {
      final pdfFile = PlatformFile(
        name: 'document.pdf',
        size: 2048,
        bytes: Uint8List.fromList([5, 6, 7, 8]),
      );

      final musicSheetFile = MusicSheetFile.fromPlatformFile(pdfFile);

      expect(musicSheetFile.file, equals(pdfFile));
      expect(musicSheetFile.mediaType, MediaType.pdf);
    });

    test('should detect image MediaType from PlatformFile', () {
      final imageFile = PlatformFile(
        name: 'image.png',
        size: 512,
        bytes: Uint8List.fromList([9, 10, 11, 12]),
      );

      final musicSheetFile = MusicSheetFile.fromPlatformFile(imageFile);

      expect(musicSheetFile.file, equals(imageFile));
      expect(musicSheetFile.mediaType, MediaType.image);
    });

    test('should provide correct name from underlying file', () {
      final platformFile = PlatformFile(
        name: 'amazing_grace.pdf',
        size: 1024,
      );

      final musicSheetFile = MusicSheetFile(
        file: platformFile,
        mediaType: MediaType.pdf,
      );

      expect(musicSheetFile.name, 'amazing_grace.pdf');
    });

    test('should provide correct size from underlying file', () {
      final platformFile = PlatformFile(
        name: 'test.pdf',
        size: 2048,
      );

      final musicSheetFile = MusicSheetFile(
        file: platformFile,
        mediaType: MediaType.pdf,
      );

      expect(musicSheetFile.size, 2048);
    });

    test('should provide correct extension from underlying file', () {
      final platformFile = PlatformFile(
        name: 'document.pdf',
        size: 1024,
      );

      final musicSheetFile = MusicSheetFile(
        file: platformFile,
        mediaType: MediaType.pdf,
      );

      expect(musicSheetFile.extension, 'pdf');
    });

    test('should provide bytes from underlying file', () {
      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final platformFile = PlatformFile(
        name: 'test.pdf',
        size: 5,
        bytes: testBytes,
      );

      final musicSheetFile = MusicSheetFile(
        file: platformFile,
        mediaType: MediaType.pdf,
      );

      expect(musicSheetFile.bytes, equals(testBytes));
    });
    test('should throw exception for unsupported file types', () {
      final jpegFile = PlatformFile(name: 'music.xyz', size: 1000);

      expect(
        () => MusicSheetFile.fromPlatformFile(jpegFile),
        throwsA(isA<UnsupportedFileExtensionException>()),
      );
    });

    test('should handle files with uppercase extensions', () {
      final pdfFile = PlatformFile(name: 'document.PDF', size: 1200);
      final pngFile = PlatformFile(name: 'image.PNG', size: 800);

      final pdfMusicSheet = MusicSheetFile.fromPlatformFile(pdfFile);
      final pngMusicSheet = MusicSheetFile.fromPlatformFile(pngFile);

      expect(pdfMusicSheet.mediaType, MediaType.pdf);
      expect(pngMusicSheet.mediaType, MediaType.image);
    });
  });
}
