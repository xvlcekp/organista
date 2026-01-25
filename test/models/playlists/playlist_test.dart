import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/models/playlists/playlist_key.dart';

void main() {
  group('Playlist Model Tests', () {
    final testTimestamp = Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30));
    final musicSheetTimestamp = Timestamp.fromDate(DateTime(2024, 1, 10, 9, 0));

    final sampleMusicSheetJson = {
      MusicSheetKey.musicSheetId: 'sheet-123',
      MusicSheetKey.userId: 'user-123',
      MusicSheetKey.createdAt: musicSheetTimestamp,
      MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
      MusicSheetKey.fileName: 'Amazing Grace.pdf',
      MusicSheetKey.originalFileStorageId: 'storage-123',
      MusicSheetKey.mediaType: 'pdf',
      MusicSheetKey.sequenceId: 1,
    };

    final samplePlaylistJson = {
      PlaylistKey.userId: 'user-123',
      PlaylistKey.createdAt: testTimestamp,
      PlaylistKey.name: 'Sunday Service',
      PlaylistKey.musicSheets: [sampleMusicSheetJson],
    };

    test('should create Playlist from valid JSON', () {
      final playlist = Playlist(playlistId: 'playlist-123', json: samplePlaylistJson);

      expect(playlist.playlistId, 'playlist-123');
      expect(playlist.userId, 'user-123');
      expect(playlist.createdAt, DateTime(2024, 1, 15, 10, 30));
      expect(playlist.name, 'Sunday Service');
      expect(playlist.musicSheets, hasLength(1));
      expect(playlist.musicSheets.first.fileName, 'Amazing Grace.pdf');
    });

    test('should create empty Playlist using factory constructor', () {
      final playlist = Playlist.empty();

      expect(playlist.playlistId, '1');
      expect(playlist.userId, '');
      expect(playlist.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(playlist.name, '');
      expect(playlist.musicSheets, isEmpty);
    });

    test('should create Playlist with default values for missing fields', () {
      final minimalJson = <String, dynamic>{};
      final playlist = Playlist(playlistId: 'test-id', json: minimalJson);

      expect(playlist.playlistId, 'test-id');
      expect(playlist.userId, '');
      expect(playlist.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(playlist.name, '');
      expect(playlist.musicSheets, isEmpty);
    });

    test('should handle empty music sheets list', () {
      final playlistJson = {
        PlaylistKey.userId: 'user-123',
        PlaylistKey.createdAt: testTimestamp,
        PlaylistKey.name: 'Empty Playlist',
        PlaylistKey.musicSheets: <dynamic>[],
      };

      final playlist = Playlist(playlistId: 'playlist-123', json: playlistJson);
      expect(playlist.musicSheets, isEmpty);
    });

    test('should handle multiple music sheets', () {
      final secondMusicSheetJson = {
        MusicSheetKey.musicSheetId: 'sheet-456',
        MusicSheetKey.userId: 'user-123',
        MusicSheetKey.createdAt: musicSheetTimestamp,
        MusicSheetKey.fileUrl: 'https://example.com/sheet2.pdf',
        MusicSheetKey.fileName: 'How Great Thou Art.pdf',
        MusicSheetKey.originalFileStorageId: 'storage-456',
        MusicSheetKey.mediaType: 'pdf',
        MusicSheetKey.sequenceId: 2,
      };

      final playlistJson = {
        PlaylistKey.userId: 'user-123',
        PlaylistKey.createdAt: testTimestamp,
        PlaylistKey.name: 'Sunday Service',
        PlaylistKey.musicSheets: [sampleMusicSheetJson, secondMusicSheetJson],
      };

      final playlist = Playlist(playlistId: 'playlist-123', json: playlistJson);

      expect(playlist.musicSheets, hasLength(2));
      expect(playlist.musicSheets[0].fileName, 'Amazing Grace.pdf');
      expect(playlist.musicSheets[1].fileName, 'How Great Thou Art.pdf');
    });

    test('should convert music sheets to JSON correctly', () {
      final playlist = Playlist(playlistId: 'playlist-123', json: samplePlaylistJson);
      final musicSheetJsonList = playlist.toMusicSheetJson();

      expect(musicSheetJsonList, hasLength(1));
      expect(musicSheetJsonList.first[MusicSheetKey.musicSheetId], 'sheet-123');
      expect(musicSheetJsonList.first[MusicSheetKey.fileName], 'Amazing Grace.pdf');
    });

    test('should support equality comparison', () {
      final playlist1 = Playlist(playlistId: 'playlist-123', json: samplePlaylistJson);
      final playlist2 = Playlist(playlistId: 'playlist-123', json: samplePlaylistJson);
      final differentPlaylist = Playlist(
        playlistId: 'playlist-456',
        json: {
          ...samplePlaylistJson,
          PlaylistKey.name: 'Different Name',
        },
      );

      expect(playlist1, equals(playlist2));
      expect(playlist1, isNot(equals(differentPlaylist)));
    });

    test('should handle null music sheets list', () {
      final playlistJson = {
        PlaylistKey.userId: 'user-123',
        PlaylistKey.createdAt: testTimestamp,
        PlaylistKey.name: 'Test Playlist',
        // musicSheets field is missing (null)
      };

      final playlist = Playlist(playlistId: 'playlist-123', json: playlistJson);
      expect(playlist.musicSheets, isEmpty);
    });
  });
}
