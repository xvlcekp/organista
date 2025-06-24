import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';

void main() {
  group('MusicSheet Model Tests', () {
    final testTimestamp = Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30));

    final sampleJson = {
      MusicSheetKey.musicSheetId: 'test-id-123',
      MusicSheetKey.userId: 'user-123',
      MusicSheetKey.createdAt: testTimestamp,
      MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
      MusicSheetKey.fileName: 'Amazing Grace.pdf',
      MusicSheetKey.originalFileStorageId: 'storage-id-123',
      MusicSheetKey.mediaType: 'pdf',
      MusicSheetKey.sequenceId: 5,
    };

    test('should create MusicSheet from valid JSON', () {
      final musicSheet = MusicSheet(json: sampleJson);

      expect(musicSheet.musicSheetId, 'test-id-123');
      expect(musicSheet.userId, 'user-123');
      expect(musicSheet.createdAt, DateTime(2024, 1, 15, 10, 30));
      expect(musicSheet.fileUrl, 'https://example.com/sheet.pdf');
      expect(musicSheet.fileName, 'Amazing Grace.pdf');
      expect(musicSheet.originalFileStorageId, 'storage-id-123');
      expect(musicSheet.mediaType, MediaType.pdf);
      expect(musicSheet.sequenceId, 5);
    });

    test('should create MusicSheet with default values for missing fields', () {
      final minimalJson = {
        MusicSheetKey.createdAt: testTimestamp,
        MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
        MusicSheetKey.fileName: 'test.pdf',
        MusicSheetKey.originalFileStorageId: 'storage-123',
        MusicSheetKey.mediaType: 'pdf',
      };

      final musicSheet = MusicSheet(json: minimalJson);

      expect(musicSheet.musicSheetId, isNotEmpty); // Generated UUID
      expect(musicSheet.userId, ''); // Default empty string
      expect(musicSheet.sequenceId, 0); // Default value
    });

    test('should convert MusicSheet to JSON correctly', () {
      final musicSheet = MusicSheet(json: sampleJson);
      final json = musicSheet.toJson();

      expect(json[MusicSheetKey.musicSheetId], 'test-id-123');
      expect(json[MusicSheetKey.userId], 'user-123');
      expect(json[MusicSheetKey.createdAt], testTimestamp);
      expect(json[MusicSheetKey.fileUrl], 'https://example.com/sheet.pdf');
      expect(json[MusicSheetKey.fileName], 'Amazing Grace.pdf');
      expect(json[MusicSheetKey.originalFileStorageId], 'storage-id-123');
      expect(json[MusicSheetKey.mediaType], 'pdf');
      expect(json[MusicSheetKey.sequenceId], 5);
    });

    test('should create copy with updated fileName', () {
      final musicSheet = MusicSheet(json: sampleJson);
      final copiedSheet = musicSheet.copyWith(fileName: 'New Name.pdf');

      expect(copiedSheet.fileName, 'New Name.pdf');
      expect(copiedSheet.musicSheetId, musicSheet.musicSheetId);
      expect(copiedSheet.userId, musicSheet.userId);
      expect(copiedSheet.createdAt, musicSheet.createdAt);
      expect(copiedSheet.fileUrl, musicSheet.fileUrl);
      expect(copiedSheet.originalFileStorageId, musicSheet.originalFileStorageId);
      expect(copiedSheet.mediaType, musicSheet.mediaType);
      expect(copiedSheet.sequenceId, musicSheet.sequenceId);
    });

    test('should create copy without changes when fileName is null', () {
      final musicSheet = MusicSheet(json: sampleJson);
      final copiedSheet = musicSheet.copyWith();

      expect(copiedSheet.fileName, musicSheet.fileName);
      expect(copiedSheet.musicSheetId, musicSheet.musicSheetId);
      expect(copiedSheet.userId, musicSheet.userId);
    });

    test('should support equality comparison', () {
      final musicSheet1 = MusicSheet(json: sampleJson);
      final musicSheet2 = MusicSheet(json: sampleJson);
      final differentSheet = MusicSheet(json: {
        ...sampleJson,
        MusicSheetKey.fileName: 'Different Name.pdf',
      });

      expect(musicSheet1, equals(musicSheet2));
      expect(musicSheet1, isNot(equals(differentSheet)));
    });

    test('should handle different media types', () {
      final imageJson = {
        ...sampleJson,
        MusicSheetKey.mediaType: 'image',
      };

      final musicSheet = MusicSheet(json: imageJson);
      expect(musicSheet.mediaType, MediaType.image);
    });
  });
}
