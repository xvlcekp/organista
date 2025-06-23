import 'package:flutter_test/flutter_test.dart';
import 'package:organista/models/music_sheets/media_type.dart';

void main() {
  group('MediaType', () {
    test('should return correct MediaType for PDF files', () {
      expect(MediaType.fromPath('document.pdf'), MediaType.pdf);
      expect(MediaType.fromPath('sheet.PDF'), MediaType.pdf);
      expect(MediaType.fromPath('music.Pdf'), MediaType.pdf);
    });

    test('should return correct MediaType for supported image files', () {
      expect(MediaType.fromPath('image.png'), MediaType.image);
      expect(MediaType.fromPath('photo.jpg'), MediaType.image);
      expect(MediaType.fromPath('scan.JPG'), MediaType.image);
      expect(MediaType.fromPath('graphic.PNG'), MediaType.image);
    });

    test('should throw UnsupportedFileExtensionException for unknown extensions', () {
      expect(
        () => MediaType.fromPath('document.txt'),
        throwsA(isA<UnsupportedFileExtensionException>()),
      );
      expect(
        () => MediaType.fromPath('file.doc'),
        throwsA(isA<UnsupportedFileExtensionException>()),
      );
      expect(
        () => MediaType.fromPath('file.xyz'),
        throwsA(isA<UnsupportedFileExtensionException>()),
      );
    });

    test('should throw UnsupportedFileExtensionException for files without extensions', () {
      expect(
        () => MediaType.fromPath('filename'),
        throwsA(isA<UnsupportedFileExtensionException>()),
      );
      expect(
        () => MediaType.fromPath('file_name'),
        throwsA(isA<UnsupportedFileExtensionException>()),
      );
    });

    test('should throw UnsupportedFileExtensionException for empty strings', () {
      expect(
        () => MediaType.fromPath(''),
        throwsA(isA<UnsupportedFileExtensionException>()),
      );
    });

    test('should return correct MediaType from exact string representation', () {
      expect(MediaType.fromString('pdf'), MediaType.pdf);
      expect(MediaType.fromString('image'), MediaType.image);
    });

    test('should throw NoMatchingMediaTypeException for case-sensitive strings', () {
      expect(
        () => MediaType.fromString('PDF'),
        throwsA(isA<NoMatchingMediaTypeException>()),
      );
      expect(
        () => MediaType.fromString('IMAGE'),
        throwsA(isA<NoMatchingMediaTypeException>()),
      );
    });

    test('should test exception messages', () {
      try {
        MediaType.fromPath('file.txt');
        fail('Expected UnsupportedFileExtensionException');
      } on UnsupportedFileExtensionException catch (e) {
        expect(e.toString(), contains('Unsupported file extension: .txt'));
      }

      try {
        MediaType.fromString('video');
        fail('Expected NoMatchingMediaTypeException');
      } on NoMatchingMediaTypeException catch (e) {
        expect(e.toString(), contains('No matching media type found for: video'));
      }
    });
  });
}
