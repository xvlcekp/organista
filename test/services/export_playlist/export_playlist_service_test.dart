import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/models/playlists/playlist_key.dart';
import 'package:organista/services/export_playlist/export_playlist_service.dart';
import 'package:organista/services/music_xml_converter/music_xml_to_png_converter.dart';

import 'export_playlist_service_test.mocks.dart';

@GenerateMocks([CacheManager, MusicXmlToPngConverter])
void main() {
  group('ExportPlaylistService', () {
    late ExportPlaylistService service;
    late MockCacheManager mockCacheManager;
    late MockMusicXmlToPngConverter mockMusicXmlConverter;
    late Playlist testPlaylist;
    late MusicSheet testMusicSheet;
    late Timestamp testTimestamp;

    setUp(() {
      mockCacheManager = MockCacheManager();
      mockMusicXmlConverter = MockMusicXmlToPngConverter();
      service = ExportPlaylistService(
        cacheManager: mockCacheManager,
        musicXmlConverter: mockMusicXmlConverter,
      );
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

      test('downloads MusicXML sheets and passes their bytes to the converter', () async {
        final musicXmlSheet = MusicSheet(
          json: {
            MusicSheetKey.musicSheetId: 'xmlsheet1',
            MusicSheetKey.userId: 'user1',
            MusicSheetKey.createdAt: testTimestamp,
            MusicSheetKey.fileUrl: 'https://example.com/sheet.musicxml',
            MusicSheetKey.fileName: 'Test Sheet',
            MusicSheetKey.originalFileStorageId: 'storage1',
            MusicSheetKey.mediaType: 'musicxml',
            MusicSheetKey.sequenceId: 1,
          },
        );

        final xmlOnlyPlaylist = Playlist(
          playlistId: 'playlist1',
          json: {
            PlaylistKey.userId: 'user1',
            PlaylistKey.createdAt: testTimestamp,
            PlaylistKey.name: 'Test Playlist',
            PlaylistKey.musicSheets: [musicXmlSheet.toJson()],
          },
        );

        final tempDir = await Directory.systemTemp.createTemp('export_service_test');
        addTearDown(() => tempDir.delete(recursive: true));
        final xmlFile = File('${tempDir.path}/sheet.musicxml');
        await xmlFile.writeAsString('<score-partwise/>');
        when(
          mockCacheManager.getSingleFile(musicXmlSheet.fileUrl),
        ).thenAnswer((_) async => const LocalFileSystem().file(xmlFile.path));
        // Conversion fails so the export stops before touching platform channels
        when(
          mockMusicXmlConverter.convertToPngFiles(
            musicSheet: anyNamed('musicSheet'),
            fileBytes: anyNamed('fileBytes'),
          ),
        ).thenThrow(Exception('Mocked conversion failure'));

        final result = await service.exportPlaylistToPdf(playlist: xmlOnlyPlaylist);

        expect(result, isNull);
        verify(mockCacheManager.getSingleFile(musicXmlSheet.fileUrl)).called(1);
        final captured = verify(
          mockMusicXmlConverter.convertToPngFiles(
            musicSheet: anyNamed('musicSheet'),
            fileBytes: captureAnyNamed('fileBytes'),
          ),
        ).captured;
        expect(String.fromCharCodes(captured.single as List<int>), '<score-partwise/>');
      });

      test('downloads every sheet in a mixed playlist and skips the converter for failed downloads', () async {
        final musicXmlSheet = MusicSheet(
          json: {
            MusicSheetKey.musicSheetId: 'xmlsheet1',
            MusicSheetKey.userId: 'user1',
            MusicSheetKey.createdAt: testTimestamp,
            MusicSheetKey.fileUrl: 'https://example.com/sheet.musicxml',
            MusicSheetKey.fileName: 'Test XML Sheet',
            MusicSheetKey.originalFileStorageId: 'storage_xml',
            MusicSheetKey.mediaType: 'musicxml',
            MusicSheetKey.sequenceId: 2,
          },
        );

        final mixedPlaylist = Playlist(
          playlistId: 'playlist1',
          json: {
            PlaylistKey.userId: 'user1',
            PlaylistKey.createdAt: testTimestamp,
            PlaylistKey.name: 'Mixed Playlist',
            PlaylistKey.musicSheets: [
              testMusicSheet.toJson(),
              musicXmlSheet.toJson(),
            ],
          },
        );

        // Both downloads fail so the export stops before touching platform channels
        when(mockCacheManager.getSingleFile(any)).thenThrow(Exception('Mocked download failure'));

        await service.exportPlaylistToPdf(playlist: mixedPlaylist);

        verify(mockCacheManager.getSingleFile(testMusicSheet.fileUrl)).called(1);
        verify(mockCacheManager.getSingleFile(musicXmlSheet.fileUrl)).called(1);
        verifyNever(
          mockMusicXmlConverter.convertToPngFiles(
            musicSheet: anyNamed('musicSheet'),
            fileBytes: anyNamed('fileBytes'),
          ),
        );
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
