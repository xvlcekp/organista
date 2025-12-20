import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/models/playlists/playlist_key.dart';
import 'package:organista/services/export_playlist/export_playlist_service.dart';

import 'export_playlist_service_test.mocks.dart';

@GenerateMocks([CacheManager])
void main() {
  group('ExportPlaylistService', () {
    late ExportPlaylistService service;
    late MockCacheManager mockCacheManager;
    late Playlist testPlaylist;
    late MusicSheet testMusicSheet;
    late Timestamp testTimestamp;

    setUp(() {
      mockCacheManager = MockCacheManager();
      service = ExportPlaylistService(cacheManager: mockCacheManager);
      testTimestamp = Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30));

      testMusicSheet = MusicSheet(
        json: {
          MusicSheetKey.musicSheetId: 'sheet1',
          MusicSheetKey.userId: 'user1',
          MusicSheetKey.createdAt: testTimestamp,
          MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
          MusicSheetKey.fileName: 'Test Sheet',
          MusicSheetKey.originalFileStorageId: 'storage1',
          MusicSheetKey.mediaType: 'pdf',
          MusicSheetKey.sequenceId: 1,
        },
      );

      testPlaylist = Playlist(
        playlistId: 'playlist1',
        json: {
          PlaylistKey.userId: 'user1',
          PlaylistKey.createdAt: testTimestamp,
          PlaylistKey.name: 'Test Playlist',
          PlaylistKey.musicSheets: [
            {
              MusicSheetKey.musicSheetId: 'sheet1',
              MusicSheetKey.userId: 'user1',
              MusicSheetKey.createdAt: testTimestamp,
              MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
              MusicSheetKey.fileName: 'Test Sheet',
              MusicSheetKey.originalFileStorageId: 'storage1',
              MusicSheetKey.mediaType: 'pdf',
              MusicSheetKey.sequenceId: 1,
            },
          ],
        },
      );
    });

    group('exportPlaylistToPdf', () {
      test('returns null when playlist has no music sheets', () async {
        final result = await service.exportPlaylistToPdf(playlist: Playlist.empty());

        expect(result, isNull);
        verifyZeroInteractions(mockCacheManager);
      });

      test('calls cache manager for file downloads', () async {
        // Mock the cache manager to throw an exception to avoid PDF creation
        when(mockCacheManager.getSingleFile(testMusicSheet.fileUrl)).thenThrow(Exception('Mocked download failure'));

        final result = await service.exportPlaylistToPdf(playlist: testPlaylist);

        expect(result, isNull);
        verify(mockCacheManager.getSingleFile(testMusicSheet.fileUrl)).called(1);
      });

      test('handles multiple music sheets', () async {
        final additionalSheet = MusicSheet(
          json: {
            MusicSheetKey.musicSheetId: 'sheet2',
            MusicSheetKey.userId: 'user1',
            MusicSheetKey.createdAt: testTimestamp,
            MusicSheetKey.fileUrl: 'https://example.com/sheet2.pdf',
            MusicSheetKey.fileName: 'Test Sheet 2',
            MusicSheetKey.originalFileStorageId: 'storage2',
            MusicSheetKey.mediaType: 'pdf',
            MusicSheetKey.sequenceId: 2,
          },
        );

        final multiSheetPlaylist = Playlist(
          playlistId: 'playlist1',
          json: {
            PlaylistKey.userId: 'user1',
            PlaylistKey.createdAt: testTimestamp,
            PlaylistKey.name: 'Test Playlist',
            PlaylistKey.musicSheets: [
              {
                MusicSheetKey.musicSheetId: 'sheet1',
                MusicSheetKey.userId: 'user1',
                MusicSheetKey.createdAt: testTimestamp,
                MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
                MusicSheetKey.fileName: 'Test Sheet',
                MusicSheetKey.originalFileStorageId: 'storage1',
                MusicSheetKey.mediaType: 'pdf',
                MusicSheetKey.sequenceId: 1,
              },
              {
                MusicSheetKey.musicSheetId: 'sheet2',
                MusicSheetKey.userId: 'user1',
                MusicSheetKey.createdAt: testTimestamp,
                MusicSheetKey.fileUrl: 'https://example.com/sheet2.pdf',
                MusicSheetKey.fileName: 'Test Sheet 2',
                MusicSheetKey.originalFileStorageId: 'storage2',
                MusicSheetKey.mediaType: 'pdf',
                MusicSheetKey.sequenceId: 2,
              },
            ],
          },
        );

        // Mock all downloads to fail to avoid PDF creation
        when(mockCacheManager.getSingleFile(any)).thenThrow(Exception('Mocked download failure'));

        final result = await service.exportPlaylistToPdf(playlist: multiSheetPlaylist);

        expect(result, isNull);
        verify(mockCacheManager.getSingleFile(testMusicSheet.fileUrl)).called(1);
        verify(mockCacheManager.getSingleFile(additionalSheet.fileUrl)).called(1);
      });
    });

    // Note: _sanitizeFileName is tested indirectly through exportPlaylistToPdf tests
  });
}
