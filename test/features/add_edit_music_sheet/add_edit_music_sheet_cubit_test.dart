import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mockito/annotations.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/models/internal/music_sheet_file.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/services/auth/auth_user.dart';

import 'add_edit_music_sheet_cubit_test.mocks.dart';

class FakeReference extends Fake implements Reference {}

class AddEditMusicSheetCubitTest extends AddEditMusicSheetCubit {
  AddEditMusicSheetCubitTest({
    required FirebaseFirestoreRepository firestoreRepository,
    required FirebaseStorageRepository storageRepository,
  }) : super(
         firebaseFirestoreRepository: firestoreRepository,
         firebaseStorageRepository: storageRepository,
       );

  void setTestState(AddEditMusicSheetState state) => emit(state);
}

@GenerateMocks([FirebaseFirestoreRepository, FirebaseStorageRepository])
void main() {
  group('AddEditMusicSheetCubit', () {
    late AddEditMusicSheetCubit cubit;
    late MockFirebaseFirestoreRepository mockFirestoreRepository;
    late MockFirebaseStorageRepository mockStorageRepository;

    setUp(() {
      mockFirestoreRepository = MockFirebaseFirestoreRepository();
      mockStorageRepository = MockFirebaseStorageRepository();
      cubit = AddEditMusicSheetCubit(
        firebaseFirestoreRepository: mockFirestoreRepository,
        firebaseStorageRepository: mockStorageRepository,
      );
    });

    test('uploadNewMusicSheet emits loading false on success', () async {
      final mockPlatformFile = PlatformFile(
        name: 'test.pdf',
        size: 1024,
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );
      final mockFile = MusicSheetFile(
        file: mockPlatformFile,
        mediaType: MediaType.pdf,
      );
      const user = AuthUser(id: 'user-1', email: 'user@test.com', isEmailVerified: true);

      when(
        mockStorageRepository.uploadFile(
          file: anyNamed('file'),
          bucket: anyNamed('bucket'),
        ),
      ).thenAnswer((_) async => FakeReference());

      when(
        mockFirestoreRepository.uploadMusicSheetRecord(
          reference: anyNamed('reference'),
          userId: anyNamed('userId'),
          fileName: anyNamed('fileName'),
          mediaType: anyNamed('mediaType'),
          repositoryId: anyNamed('repositoryId'),
        ),
      ).thenAnswer((_) async => true);

      await cubit.uploadNewMusicSheet(
        user: user,
        file: mockFile,
        fileName: 'new-name.pdf',
        repositoryId: 'repo-1',
      );

      expect(cubit.state, isA<UploadMusicSheetState>());
      final state = cubit.state as UploadMusicSheetState;
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('uploadNewMusicSheet captures error and stops loading', () async {
      final mockPlatformFile = PlatformFile(
        name: 'test.pdf',
        size: 1024,
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );
      final mockFile = MusicSheetFile(
        file: mockPlatformFile,
        mediaType: MediaType.pdf,
      );
      const user = AuthUser(id: 'user-1', email: 'user@test.com', isEmailVerified: true);

      when(
        mockStorageRepository.uploadFile(
          file: anyNamed('file'),
          bucket: anyNamed('bucket'),
        ),
      ).thenAnswer((_) async => null);

      await cubit.uploadNewMusicSheet(
        user: user,
        file: mockFile,
        fileName: 'new-name.pdf',
        repositoryId: 'repo-1',
      );

      expect(cubit.state, isA<UploadMusicSheetState>());
      final state = cubit.state as UploadMusicSheetState;
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });

    test('renameMusicSheetInPlaylist toggles loading and clears error on success', () async {
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

      when(
        mockFirestoreRepository.renameMusicSheetInPlaylist(
          musicSheet: anyNamed('musicSheet'),
          fileName: anyNamed('fileName'),
          playlist: anyNamed('playlist'),
        ),
      ).thenReturn(true);

      cubit.renameMusicSheetInPlaylist(
        playlist: mockPlaylist,
        musicSheet: mockMusicSheet,
        fileName: 'renamed.pdf',
      );

      expect(cubit.state, isA<EditMusicSheetState>());
      final state = cubit.state as EditMusicSheetState;
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('renameMusicSheetInPlaylist captures error and stops loading', () async {
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

      when(
        mockFirestoreRepository.renameMusicSheetInPlaylist(
          musicSheet: anyNamed('musicSheet'),
          fileName: anyNamed('fileName'),
          playlist: anyNamed('playlist'),
        ),
      ).thenReturn(false);

      cubit.renameMusicSheetInPlaylist(
        playlist: mockPlaylist,
        musicSheet: mockMusicSheet,
        fileName: 'renamed.pdf',
      );

      expect(cubit.state, isA<EditMusicSheetState>());
      final state = cubit.state as EditMusicSheetState;
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
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
