import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/config/app_constants.dart';
import 'package:organista/features/show_playlist/error/playlist_error.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/models/playlists/playlist_key.dart';

// Test helper to create playlists with specific number of mocked music sheets
class PlaylistTestHelper {
  static Playlist createPlaylistWithSheets(int sheetCount) {
    final testTimestamp = Timestamp.fromDate(DateTime(2024, 1, 15));

    // Create JSON data for mock music sheets (no need for actual MockMusicSheet objects)
    final mockMusicSheetsJson = List.generate(
      sheetCount,
      (index) => {
        MusicSheetKey.musicSheetId: 'mock-sheet-$index',
        MusicSheetKey.fileName: 'Mock Sheet $index',
        MusicSheetKey.fileUrl: 'mock://url$index',
        MusicSheetKey.originalFileStorageId: 'mock-storage-$index',
        MusicSheetKey.mediaType: 'pdf',
        MusicSheetKey.createdAt: testTimestamp,
      },
    );

    return Playlist(
      playlistId: 'test-playlist-$sheetCount',
      json: {
        PlaylistKey.musicSheets: mockMusicSheetsJson,
      },
    );
  }
}

void main() {
  const maxCapacity = AppConstants.maxPlaylistCapacity;
  const remainingCapacity = maxCapacity - (maxCapacity ~/ 2);

  group('Playlist Validation Tests', () {
    late Playlist emptyPlaylist;
    late Playlist playlistAtCapacity;
    late Playlist playlistWithSomeSheets;

    setUp(() {
      emptyPlaylist = PlaylistTestHelper.createPlaylistWithSheets(0);
      playlistAtCapacity = PlaylistTestHelper.createPlaylistWithSheets(maxCapacity);
      playlistWithSomeSheets = PlaylistTestHelper.createPlaylistWithSheets(maxCapacity ~/ 2);
    });

    group('Capacity Validation', () {
      test('should pass validation when adding sheets within capacity', () {
        // Empty playlist - can add up to maxCapacity
        expect(() => emptyPlaylist.validateCapacityForAdding(1, maxCapacity: maxCapacity), returnsNormally);
        expect(() => emptyPlaylist.validateCapacityForAdding(maxCapacity, maxCapacity: maxCapacity), returnsNormally);

        // Dynamic playlist with some sheets - can add remaining capacity
        expect(
          () => playlistWithSomeSheets.validateCapacityForAdding(remainingCapacity, maxCapacity: maxCapacity),
          returnsNormally,
        );
      });

      test('should throw exception when exceeding capacity', () {
        // Empty playlist - adding more than maxCapacity
        expect(
          () => emptyPlaylist.validateCapacityForAdding(maxCapacity + 1, maxCapacity: maxCapacity),
          throwsA(isA<PlaylistCapacityExceededError>()),
        );

        // Full playlist - adding any amount
        expect(
          () => playlistAtCapacity.validateCapacityForAdding(1, maxCapacity: maxCapacity),
          throwsA(isA<PlaylistCapacityExceededError>()),
        );

        // Dynamic playlist - adding more than remaining capacity
        expect(
          () => playlistWithSomeSheets.validateCapacityForAdding(remainingCapacity + 1, maxCapacity: maxCapacity),
          throwsA(isA<PlaylistCapacityExceededError>()),
        );
      });
    });

    group('Exception Details Validation', () {
      test('should throw exception with correct error details', () {
        try {
          playlistWithSomeSheets.validateCapacityForAdding(remainingCapacity + 1, maxCapacity: maxCapacity);
          fail('Should have thrown PlaylistCapacityExceededError');
        } on PlaylistCapacityExceededError catch (error) {
          expect(error.playlist, equals(playlistWithSomeSheets));
          expect(error.attemptedToAdd, equals(remainingCapacity + 1));
          expect(error.maxCapacity, equals(maxCapacity));
          expect(error.playlist.musicSheets.length, equals(maxCapacity ~/ 2));
        }
      });

      test('should throw exception with correct details for empty playlist', () {
        try {
          emptyPlaylist.validateCapacityForAdding(maxCapacity + 5, maxCapacity: maxCapacity);
          fail('Should have thrown PlaylistCapacityExceededError');
        } on PlaylistCapacityExceededError catch (error) {
          expect(error.playlist, equals(emptyPlaylist));
          expect(error.attemptedToAdd, equals(maxCapacity + 5));
          expect(error.maxCapacity, equals(maxCapacity));
          expect(error.playlist.musicSheets.length, equals(0));
        }
      });
    });

    group('Edge Cases', () {
      test('should handle zero sheets to add', () {
        expect(() => emptyPlaylist.validateCapacityForAdding(0, maxCapacity: maxCapacity), returnsNormally);
        expect(() => playlistAtCapacity.validateCapacityForAdding(0, maxCapacity: maxCapacity), returnsNormally);
      });

      test('should handle negative numbers', () {
        expect(() => emptyPlaylist.validateCapacityForAdding(-1, maxCapacity: maxCapacity), returnsNormally);
        expect(() => playlistAtCapacity.validateCapacityForAdding(-1, maxCapacity: maxCapacity), returnsNormally);
      });

      test('should handle very large numbers', () {
        expect(
          () => emptyPlaylist.validateCapacityForAdding(1000, maxCapacity: maxCapacity),
          throwsA(isA<PlaylistCapacityExceededError>()),
        );
      });

      test('should work with zero capacity', () {
        expect(
          () => emptyPlaylist.validateCapacityForAdding(1, maxCapacity: 0),
          throwsA(isA<PlaylistCapacityExceededError>()),
        );
        expect(() => emptyPlaylist.validateCapacityForAdding(0, maxCapacity: 0), returnsNormally);
      });
    });
  });
}
