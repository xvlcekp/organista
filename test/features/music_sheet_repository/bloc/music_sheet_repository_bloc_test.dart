import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/music_sheet_repository/bloc/music_sheet_repository_bloc.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';

class MockFirebaseFirestoreRepository extends Mock implements FirebaseFirestoreRepository {}

void main() {
  late MockFirebaseFirestoreRepository mockFirestoreRepository;
  late MusicSheet testMusicSheet;

  setUp(() {
    mockFirestoreRepository = MockFirebaseFirestoreRepository();

    testMusicSheet = MusicSheet(
      json: {
        MusicSheetKey.musicSheetId: 'sheet-1',
        MusicSheetKey.userId: 'user-1',
        MusicSheetKey.createdAt: Timestamp.now(),
        MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
        MusicSheetKey.fileName: 'Old Name',
        MusicSheetKey.originalFileStorageId: 'storage-1',
        MusicSheetKey.mediaType: 'pdf',
        MusicSheetKey.sequenceId: 0,
        MusicSheetKey.transposition: 0,
      },
    );
  });

  setUpAll(() {
    registerFallbackValue(
      MusicSheet(
        json: {
          MusicSheetKey.musicSheetId: 'fallback',
          MusicSheetKey.userId: 'fallback-user',
          MusicSheetKey.createdAt: Timestamp.now(),
          MusicSheetKey.fileUrl: 'https://example.com/fallback.pdf',
          MusicSheetKey.fileName: 'Fallback',
          MusicSheetKey.originalFileStorageId: 'fallback-storage',
          MusicSheetKey.mediaType: 'pdf',
          MusicSheetKey.sequenceId: 0,
          MusicSheetKey.transposition: 0,
        },
      ),
    );
  });

  group('MusicSheetRepositoryBloc', () {
    blocTest<MusicSheetRepositoryBloc, MusicSheetRepositoryState>(
      'RenameMusicSheet delegates to renameMusicSheetInRepository',
      build: () {
        when(
          () => mockFirestoreRepository.renameMusicSheetInRepository(
            musicSheet: any(named: 'musicSheet'),
            fileName: any(named: 'fileName'),
            repositoryId: any(named: 'repositoryId'),
          ),
        ).thenAnswer((_) async => true);
        return MusicSheetRepositoryBloc(firebaseFirestoreRepository: mockFirestoreRepository);
      },
      act: (bloc) => bloc.add(
        RenameMusicSheet(
          musicSheet: testMusicSheet,
          fileName: 'New Name',
          repositoryId: 'repo-1',
        ),
      ),
      verify: (_) {
        verify(
          () => mockFirestoreRepository.renameMusicSheetInRepository(
            musicSheet: testMusicSheet,
            fileName: 'New Name',
            repositoryId: 'repo-1',
          ),
        ).called(1);
      },
    );

    blocTest<MusicSheetRepositoryBloc, MusicSheetRepositoryState>(
      'DeleteMusicSheet delegates to deleteMusicSheetFromRepository',
      build: () {
        when(
          () => mockFirestoreRepository.deleteMusicSheetFromRepository(
            musicSheet: any(named: 'musicSheet'),
            repositoryId: any(named: 'repositoryId'),
          ),
        ).thenAnswer((_) async => true);
        return MusicSheetRepositoryBloc(firebaseFirestoreRepository: mockFirestoreRepository);
      },
      act: (bloc) => bloc.add(
        DeleteMusicSheet(
          musicSheet: testMusicSheet,
          repositoryId: 'repo-1',
        ),
      ),
      verify: (_) {
        verify(
          () => mockFirestoreRepository.deleteMusicSheetFromRepository(
            musicSheet: testMusicSheet,
            repositoryId: 'repo-1',
          ),
        ).called(1);
      },
    );
  });
}
