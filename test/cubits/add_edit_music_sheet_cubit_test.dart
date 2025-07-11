import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/models/internal/music_sheet_file.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/music_sheets/media_type.dart';

void main() {
  group('AddEditMusicSheetCubit', () {
    late AddEditMusicSheetCubit cubit;

    setUp(() {
      cubit = AddEditMusicSheetCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is InitMusicSheetState', () {
      expect(cubit.state, const InitMusicSheetState());
    });

    test('resetState should emit InitMusicSheetState', () {
      // First change to a different state
      final mockPlatformFile = PlatformFile(
        name: 'test.pdf',
        size: 1024,
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );
      final mockFile = MusicSheetFile(
        file: mockPlatformFile,
        mediaType: MediaType.pdf,
      );
      cubit.uploadMusicSheet(file: mockFile, repositoryId: 'repo-123');

      expect(cubit.state, isA<UploadMusicSheetState>());

      // Then reset
      cubit.resetState();
      expect(cubit.state, const InitMusicSheetState());
    });

    test('uploadMusicSheet should emit UploadMusicSheetState with correct data', () {
      final mockPlatformFile = PlatformFile(
        name: 'test.pdf',
        size: 1024,
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );
      final mockFile = MusicSheetFile(
        file: mockPlatformFile,
        mediaType: MediaType.pdf,
      );

      cubit.uploadMusicSheet(file: mockFile, repositoryId: 'repo-123');

      expect(cubit.state, isA<UploadMusicSheetState>());
      final state = cubit.state as UploadMusicSheetState;
      expect(state.file.name, 'test.pdf');
      expect(state.repositoryId, 'repo-123');
    });

    test('editMusicSheetInPlaylist should emit EditMusicSheetState with correct data', () {
      final mockPlaylist = Playlist.empty();
      final mockMusicSheet = MusicSheet(
        json: {
          MusicSheetKey.musicSheetId: 'sheet-123',
          MusicSheetKey.userId: 'user-123',
          MusicSheetKey.createdAt: Timestamp.fromDate(DateTime.now()),
          MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
          MusicSheetKey.fileName: 'test.pdf',
          MusicSheetKey.originalFileStorageId: 'storage-123',
          MusicSheetKey.mediaType: 'pdf',
          MusicSheetKey.sequenceId: 1,
        },
      );

      cubit.editMusicSheetInPlaylist(
        playlist: mockPlaylist,
        musicSheet: mockMusicSheet,
      );

      expect(cubit.state, isA<EditMusicSheetState>());
      final state = cubit.state as EditMusicSheetState;
      expect(state.playlist.playlistId, '1');
      expect(state.musicSheet.musicSheetId, 'sheet-123');
    });

    test('addMusicSheetToPlaylist should emit AddMusicSheetToPlaylistState with correct data', () {
      final mockMusicSheet = MusicSheet(
        json: {
          MusicSheetKey.musicSheetId: 'sheet-456',
          MusicSheetKey.userId: 'user-123',
          MusicSheetKey.createdAt: Timestamp.fromDate(DateTime.now()),
          MusicSheetKey.fileUrl: 'https://example.com/sheet2.pdf',
          MusicSheetKey.fileName: 'test2.pdf',
          MusicSheetKey.originalFileStorageId: 'storage-456',
          MusicSheetKey.mediaType: 'pdf',
          MusicSheetKey.sequenceId: 2,
        },
      );

      cubit.addMusicSheetToPlaylist(musicSheet: mockMusicSheet);

      expect(cubit.state, isA<AddMusicSheetToPlaylistState>());
      final state = cubit.state as AddMusicSheetToPlaylistState;
      expect(state.musicSheet.musicSheetId, 'sheet-456');
    });

    test('state transitions should work correctly', () {
      // Start with initial state
      expect(cubit.state, const InitMusicSheetState());

      // Transition to upload state
      final mockPlatformFile = PlatformFile(
        name: 'test.pdf',
        size: 1024,
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );
      final mockFile = MusicSheetFile(
        file: mockPlatformFile,
        mediaType: MediaType.pdf,
      );
      cubit.uploadMusicSheet(file: mockFile, repositoryId: 'repo-123');
      expect(cubit.state, isA<UploadMusicSheetState>());

      // Reset state
      cubit.resetState();
      expect(cubit.state, const InitMusicSheetState());

      // Transition to add to playlist state
      final mockMusicSheet = MusicSheet(
        json: {
          MusicSheetKey.musicSheetId: 'sheet-789',
          MusicSheetKey.userId: 'user-123',
          MusicSheetKey.createdAt: Timestamp.fromDate(DateTime.now()),
          MusicSheetKey.fileUrl: 'https://example.com/sheet3.pdf',
          MusicSheetKey.fileName: 'test3.pdf',
          MusicSheetKey.originalFileStorageId: 'storage-789',
          MusicSheetKey.mediaType: 'pdf',
          MusicSheetKey.sequenceId: 3,
        },
      );
      cubit.addMusicSheetToPlaylist(musicSheet: mockMusicSheet);
      expect(cubit.state, isA<AddMusicSheetToPlaylistState>());
    });
  });
}
