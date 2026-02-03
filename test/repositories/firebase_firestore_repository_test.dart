import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/config/app_constants.dart';
import 'package:organista/features/show_playlist/error/playlist_error.dart';
import 'package:organista/features/show_repositories/models/repository_error.dart';
import 'package:organista/models/firebase_collection_name.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/models/playlists/playlist_key.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/models/repositories/repository_key.dart';
import 'package:organista/models/users/user_info_key.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/services/auth/auth_user.dart';

// Mock classes
class MockReference extends Mock implements Reference {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseFirestoreRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FirebaseFirestoreRepository(
      instance: fakeFirestore,
      skipSettingsConfiguration: true,
    );
  });

  // Helper functions for creating test data
  AuthUser createTestAuthUser({
    String id = 'test-user-id',
    String email = 'test@example.com',
    bool isEmailVerified = true,
  }) {
    return AuthUser(
      id: id,
      email: email,
      isEmailVerified: isEmailVerified,
    );
  }

  Map<String, dynamic> createTestMusicSheetJson({
    String musicSheetId = 'sheet-123',
    String userId = 'user-123',
    String fileName = 'Test Sheet.pdf',
    String fileUrl = 'https://example.com/sheet.pdf',
    String originalFileStorageId = 'storage-123',
    MediaType mediaType = MediaType.pdf,
    int sequenceId = 1,
  }) {
    return {
      MusicSheetKey.musicSheetId: musicSheetId,
      MusicSheetKey.userId: userId,
      MusicSheetKey.createdAt: Timestamp.now(),
      MusicSheetKey.fileUrl: fileUrl,
      MusicSheetKey.fileName: fileName,
      MusicSheetKey.originalFileStorageId: originalFileStorageId,
      MusicSheetKey.mediaType: mediaType.name,
      MusicSheetKey.sequenceId: sequenceId,
    };
  }

  MusicSheet createTestMusicSheet({
    String musicSheetId = 'sheet-123',
    String userId = 'user-123',
    String fileName = 'Test Sheet.pdf',
  }) {
    return MusicSheet(
      json: createTestMusicSheetJson(
        musicSheetId: musicSheetId,
        userId: userId,
        fileName: fileName,
      ),
    );
  }

  Map<String, dynamic> createTestPlaylistJson({
    String userId = 'user-123',
    String name = 'Test Playlist',
    List<Map<String, dynamic>>? musicSheets,
  }) {
    return {
      PlaylistKey.userId: userId,
      PlaylistKey.createdAt: Timestamp.now(),
      PlaylistKey.name: name,
      PlaylistKey.musicSheets: musicSheets ?? [],
    };
  }

  Future<Playlist> createTestPlaylist({
    String playlistId = 'playlist-123',
    String userId = 'user-123',
    String name = 'Test Playlist',
    List<Map<String, dynamic>>? musicSheets,
  }) async {
    final playlistJson = createTestPlaylistJson(
      userId: userId,
      name: name,
      musicSheets: musicSheets,
    );
    await fakeFirestore.collection(FirebaseCollectionName.playlists).doc(playlistId).set(playlistJson);
    return Playlist(playlistId: playlistId, json: playlistJson);
  }

  Map<String, dynamic> createTestRepositoryJson({
    String repositoryId = 'repo-123',
    String name = 'Test Repository',
    String userId = '',
  }) {
    return {
      RepositoryKey.repositoryId: repositoryId,
      RepositoryKey.name: name,
      RepositoryKey.userId: userId,
      RepositoryKey.createdAt: Timestamp.now(),
    };
  }

  Future<Repository> createTestRepository({
    String repositoryId = 'repo-123',
    String name = 'Test Repository',
    String userId = '',
  }) async {
    final repoJson = createTestRepositoryJson(
      repositoryId: repositoryId,
      name: name,
      userId: userId,
    );
    await fakeFirestore.collection(FirebaseCollectionName.repositories).doc(repositoryId).set(repoJson);
    return Repository(json: repoJson);
  }

  group('FirebaseFirestoreRepository - User Operations', () {
    group('createUserDocument', () {
      test('should create user document successfully', () async {
        final user = createTestAuthUser();

        await repository.createUserDocument(user: user);

        final userDoc = await fakeFirestore.collection(FirebaseCollectionName.users).doc(user.id).get();

        expect(userDoc.exists, true);
        expect(userDoc.data()?[UserInfoKey.userId], user.id);
        expect(userDoc.data()?[UserInfoKey.email], user.email);
        expect(userDoc.data()?[UserInfoKey.displayName], '');
      });

      test('should handle already existing user document', () async {
        final user = createTestAuthUser();

        // Create user document first
        await fakeFirestore.collection(FirebaseCollectionName.users).doc(user.id).set({
          UserInfoKey.userId: user.id,
          UserInfoKey.email: user.email,
          UserInfoKey.displayName: 'Existing Name',
        });

        // Try to create again - should not throw
        await repository.createUserDocument(user: user);

        // Verify original data is preserved
        final userDoc = await fakeFirestore.collection(FirebaseCollectionName.users).doc(user.id).get();

        expect(userDoc.exists, true);
        expect(userDoc.data()?[UserInfoKey.displayName], 'Existing Name');
      });
    });

    group('deleteUser', () {
      test('should delete user and all associated data successfully', () async {
        const userId = 'user-to-delete';

        // Create user document
        await fakeFirestore.collection(FirebaseCollectionName.users).doc(userId).set({UserInfoKey.userId: userId});

        // Create associated playlists
        await fakeFirestore.collection(FirebaseCollectionName.playlists).add({
          PlaylistKey.userId: userId,
          PlaylistKey.name: 'Playlist 1',
        });
        await fakeFirestore.collection(FirebaseCollectionName.playlists).add({
          PlaylistKey.userId: userId,
          PlaylistKey.name: 'Playlist 2',
        });

        // Create associated repositories
        await fakeFirestore.collection(FirebaseCollectionName.repositories).add({
          RepositoryKey.userId: userId,
          RepositoryKey.name: 'Repo 1',
        });

        final result = await repository.deleteUser(userId: userId);

        expect(result, true);

        // Verify user document is deleted
        final userDocs = await fakeFirestore
            .collection(FirebaseCollectionName.users)
            .where(UserInfoKey.userId, isEqualTo: userId)
            .get();
        expect(userDocs.docs, isEmpty);

        // Verify playlists are deleted
        final playlistDocs = await fakeFirestore
            .collection(FirebaseCollectionName.playlists)
            .where(PlaylistKey.userId, isEqualTo: userId)
            .get();
        expect(playlistDocs.docs, isEmpty);

        // Verify repositories are deleted
        final repoDocs = await fakeFirestore
            .collection(FirebaseCollectionName.repositories)
            .where(RepositoryKey.userId, isEqualTo: userId)
            .get();
        expect(repoDocs.docs, isEmpty);
      });

      test('should return true even when user has no data', () async {
        const userId = 'non-existent-user';

        final result = await repository.deleteUser(userId: userId);

        expect(result, true);
      });
    });
  });

  group('FirebaseFirestoreRepository - Playlist Operations', () {
    group('getPlaylistStream', () {
      test('should return playlist data from stream', () async {
        const playlistId = 'playlist-123';
        final playlist = await createTestPlaylist(playlistId: playlistId);

        final stream = repository.getPlaylistStream(playlistId);

        await expectLater(
          stream.first,
          completion(
            predicate<Playlist>((p) => p.playlistId == playlistId && p.name == playlist.name),
          ),
        );
      });

      test('should return empty playlist when document does not exist', () async {
        const playlistId = 'non-existent';

        final stream = repository.getPlaylistStream(playlistId);

        await expectLater(
          stream.first,
          completion(
            predicate<Playlist>((p) => p.playlistId == '1' && p.name == ''),
          ),
        );
      });
    });

    group('getPlaylistsStream', () {
      test('should return user playlists ordered by name', () async {
        const userId = 'user-123';

        await createTestPlaylist(
          playlistId: 'p1',
          userId: userId,
          name: 'Zebra Playlist',
        );
        await createTestPlaylist(
          playlistId: 'p2',
          userId: userId,
          name: 'Alpha Playlist',
        );
        await createTestPlaylist(
          playlistId: 'p3',
          userId: 'other-user',
          name: 'Other User Playlist',
        );

        final stream = repository.getPlaylistsStream(userId);

        await expectLater(
          stream.first,
          completion(
            predicate<Iterable<Playlist>>((playlists) {
              final list = playlists.toList();
              return list.length == 2 && list[0].name == 'Alpha Playlist' && list[1].name == 'Zebra Playlist';
            }),
          ),
        );
      });

      test('should return empty list when user has no playlists', () async {
        const userId = 'user-with-no-playlists';

        final stream = repository.getPlaylistsStream(userId);

        await expectLater(
          stream.first,
          completion(predicate<Iterable<Playlist>>((p) => p.isEmpty)),
        );
      });
    });

    group('addNewPlaylist', () {
      test('should add new playlist successfully', () async {
        const userId = 'user-123';
        const playlistName = 'New Playlist';

        final result = await repository.addNewPlaylist(
          playlistName: playlistName,
          userId: userId,
        );

        expect(result, true);

        final playlists = await fakeFirestore
            .collection(FirebaseCollectionName.playlists)
            .where(PlaylistKey.userId, isEqualTo: userId)
            .get();

        expect(playlists.docs, hasLength(1));
        expect(playlists.docs.first.data()[PlaylistKey.name], playlistName);
      });
    });

    group('renamePlaylist', () {
      test('should rename playlist successfully', () async {
        final playlist = await createTestPlaylist(name: 'Old Name');
        const newName = 'New Name';

        final result = await repository.renamePlaylist(
          newPlaylistName: newName,
          playlist: playlist,
        );

        expect(result, true);

        final updatedDoc = await fakeFirestore
            .collection(FirebaseCollectionName.playlists)
            .doc(playlist.playlistId)
            .get();

        expect(updatedDoc.data()?[PlaylistKey.name], newName);
      });
    });

    group('deletePlaylist', () {
      test('should delete playlist successfully', () async {
        final playlist = await createTestPlaylist();

        final result = await repository.deletePlaylist(playlist: playlist);

        expect(result, true);

        final doc = await fakeFirestore.collection(FirebaseCollectionName.playlists).doc(playlist.playlistId).get();

        expect(doc.exists, false);
      });
    });
  });

  group('FirebaseFirestoreRepository - Music Sheet Operations', () {
    group('uploadMusicSheetRecord', () {
      test('should upload music sheet record successfully', () async {
        const repositoryId = 'repo-123';
        await createTestRepository(repositoryId: repositoryId);

        final mockReference = MockReference();
        when(() => mockReference.getDownloadURL()).thenAnswer((_) async => 'https://example.com/file.pdf');
        when(() => mockReference.fullPath).thenReturn('storage/path/file.pdf');

        final result = await repository.uploadMusicSheetRecord(
          fileName: 'Test Sheet.pdf',
          userId: 'user-123',
          reference: mockReference,
          mediaType: MediaType.pdf,
          repositoryId: repositoryId,
        );

        expect(result, true);

        final musicSheets = await fakeFirestore
            .collection(FirebaseCollectionName.repositories)
            .doc(repositoryId)
            .collection(FirebaseCollectionName.musicSheets)
            .get();

        expect(musicSheets.docs, hasLength(1));
        final sheetData = musicSheets.docs.first.data();
        expect(sheetData[MusicSheetKey.fileName], 'Test Sheet.pdf');
        expect(sheetData[MusicSheetKey.fileUrl], 'https://example.com/file.pdf');
        expect(sheetData[MusicSheetKey.musicSheetId], isNotEmpty);
      });
    });

    group('addMusicSheetsToPlaylist', () {
      test('should add music sheets to playlist successfully', () async {
        final playlist = await createTestPlaylist();
        final musicSheets = [
          createTestMusicSheet(musicSheetId: 's1', fileName: 'Sheet 1.pdf'),
          createTestMusicSheet(musicSheetId: 's2', fileName: 'Sheet 2.pdf'),
        ];

        final result = await repository.addMusicSheetsToPlaylist(
          playlist: playlist,
          musicSheets: musicSheets,
        );

        expect(result, true);

        final updatedDoc = await fakeFirestore
            .collection(FirebaseCollectionName.playlists)
            .doc(playlist.playlistId)
            .get();

        final updatedSheets = (updatedDoc.data()?[PlaylistKey.musicSheets] as List);
        expect(updatedSheets, hasLength(2));
      });

      test('should throw PlaylistCapacityExceededError when capacity exceeded', () async {
        // Create playlist with music sheets near capacity
        final existingSheets = List.generate(
          AppConstants.maxPlaylistCapacity - 1,
          (i) => createTestMusicSheetJson(musicSheetId: 'existing-$i'),
        );

        final playlist = await createTestPlaylist(musicSheets: existingSheets);

        final newSheets = [
          createTestMusicSheet(musicSheetId: 'new-1'),
          createTestMusicSheet(musicSheetId: 'new-2'),
        ];

        expect(
          () => repository.addMusicSheetsToPlaylist(
            playlist: playlist,
            musicSheets: newSheets,
          ),
          throwsA(isA<PlaylistCapacityExceededError>()),
        );
      });
    });

    group('renameMusicSheetInPlaylist', () {
      test('should rename music sheet in playlist successfully', () async {
        final musicSheetJson = createTestMusicSheetJson(
          musicSheetId: 'sheet-1',
          fileName: 'Old Name.pdf',
        );
        final playlist = await createTestPlaylist(
          musicSheets: [musicSheetJson],
        );
        final musicSheet = MusicSheet(json: musicSheetJson);

        final result = repository.renameMusicSheetInPlaylist(
          musicSheet: musicSheet,
          fileName: 'New Name.pdf',
          playlist: playlist,
        );

        expect(result, true);

        final updatedDoc = await fakeFirestore
            .collection(FirebaseCollectionName.playlists)
            .doc(playlist.playlistId)
            .get();

        final sheets = (updatedDoc.data()?[PlaylistKey.musicSheets] as List);
        expect(sheets.first[MusicSheetKey.fileName], 'New Name.pdf');
      });
    });

    group('deleteMusicSheetInPlaylist', () {
      test('should delete music sheet from playlist successfully', () async {
        final sheet1 = createTestMusicSheetJson(musicSheetId: 'sheet-1');
        final sheet2 = createTestMusicSheetJson(musicSheetId: 'sheet-2');
        final playlist = await createTestPlaylist(
          musicSheets: [sheet1, sheet2],
        );
        final musicSheetToDelete = MusicSheet(json: sheet1);

        final result = await repository.deleteMusicSheetInPlaylist(
          musicSheet: musicSheetToDelete,
          playlist: playlist,
        );

        expect(result, true);

        final updatedDoc = await fakeFirestore
            .collection(FirebaseCollectionName.playlists)
            .doc(playlist.playlistId)
            .get();

        final sheets = (updatedDoc.data()?[PlaylistKey.musicSheets] as List);
        expect(sheets, hasLength(1));
        expect(sheets.first[MusicSheetKey.musicSheetId], 'sheet-2');
      });
    });

    group('musicSheetReorder', () {
      test('should reorder music sheets successfully', () async {
        final sheet1 = createTestMusicSheetJson(musicSheetId: 'sheet-1');
        final sheet2 = createTestMusicSheetJson(musicSheetId: 'sheet-2');
        final playlist = await createTestPlaylist(
          musicSheets: [sheet1, sheet2],
        );

        final result = await repository.musicSheetReorder(playlist: playlist);

        expect(result, true);
      });
    });

    group('deleteMusicSheetFromRepository', () {
      test('should delete music sheet from repository successfully', () async {
        const repositoryId = 'repo-123';
        await createTestRepository(repositoryId: repositoryId);

        final sheetJson = createTestMusicSheetJson(musicSheetId: 'sheet-123');
        await fakeFirestore
            .collection(FirebaseCollectionName.repositories)
            .doc(repositoryId)
            .collection(FirebaseCollectionName.musicSheets)
            .doc('sheet-123')
            .set(sheetJson);

        final musicSheet = MusicSheet(json: sheetJson);

        final result = await repository.deleteMusicSheetFromRepository(
          musicSheet: musicSheet,
          repositoryId: repositoryId,
        );

        expect(result, true);

        final doc = await fakeFirestore
            .collection(FirebaseCollectionName.repositories)
            .doc(repositoryId)
            .collection(FirebaseCollectionName.musicSheets)
            .doc('sheet-123')
            .get();

        expect(doc.exists, false);
      });
    });
  });

  group('FirebaseFirestoreRepository - Repository Operations', () {
    group('getRepositoriesStream', () {
      test('should return repositories for user including public ones', () async {
        const userId = 'user-123';

        await createTestRepository(
          repositoryId: 'public-1',
          name: 'Public Repo',
          userId: '',
        );
        await createTestRepository(
          repositoryId: 'private-1',
          name: 'Private Repo',
          userId: userId,
        );
        await createTestRepository(
          repositoryId: 'other-1',
          name: 'Other User Repo',
          userId: 'other-user',
        );

        final stream = repository.getRepositoriesStream(userId: userId);

        await expectLater(
          stream.first,
          completion(
            predicate<Iterable<Repository>>((repos) {
              final list = repos.toList();
              return list.length == 2 &&
                  list.any((r) => r.repositoryId == 'public-1') &&
                  list.any((r) => r.repositoryId == 'private-1');
            }),
          ),
        );
      });
    });

    group('getRepositoryMusicSheetsStream', () {
      test('should return music sheets for repository', () async {
        const repositoryId = 'repo-123';
        await createTestRepository(repositoryId: repositoryId);

        final sheet1 = createTestMusicSheetJson(musicSheetId: 'sheet-1');
        final sheet2 = createTestMusicSheetJson(musicSheetId: 'sheet-2');

        await fakeFirestore
            .collection(FirebaseCollectionName.repositories)
            .doc(repositoryId)
            .collection(FirebaseCollectionName.musicSheets)
            .doc('sheet-1')
            .set(sheet1);
        await fakeFirestore
            .collection(FirebaseCollectionName.repositories)
            .doc(repositoryId)
            .collection(FirebaseCollectionName.musicSheets)
            .doc('sheet-2')
            .set(sheet2);

        final stream = repository.getRepositoryMusicSheetsStream(repositoryId);

        await expectLater(
          stream.first,
          completion(
            predicate<Iterable<MusicSheet>>((sheets) => sheets.length == 2),
          ),
        );
      });
    });

    group('createGlobalRepository', () {
      test('should create global repository with empty userId', () async {
        const name = 'Global Repository';

        final result = await repository.createGlobalRepository(name: name);

        expect(result, true);

        final repos = await fakeFirestore
            .collection(FirebaseCollectionName.repositories)
            .where(RepositoryKey.userId, isEqualTo: '')
            .get();

        expect(repos.docs, hasLength(1));
        expect(repos.docs.first.data()[RepositoryKey.name], name);
      });
    });

    group('getUserRepositoriesCount', () {
      test('should return correct count of user repositories', () async {
        const userId = 'user-123';

        await createTestRepository(repositoryId: 'r1', userId: userId);
        await createTestRepository(repositoryId: 'r2', userId: userId);
        await createTestRepository(repositoryId: 'r3', userId: 'other-user');

        final count = await repository.getUserRepositoriesCount(userId: userId);

        expect(count, 2);
      });

      test('should return 0 when user has no repositories', () async {
        const userId = 'user-with-no-repos';

        final count = await repository.getUserRepositoriesCount(userId: userId);

        expect(count, 0);
      });
    });

    group('createUserRepository', () {
      test('should create user repository successfully', () async {
        const userId = 'user-123';
        const name = 'My Repository';

        final result = await repository.createUserRepository(
          userId: userId,
          name: name,
        );

        expect(result, true);

        final repos = await fakeFirestore
            .collection(FirebaseCollectionName.repositories)
            .where(RepositoryKey.userId, isEqualTo: userId)
            .get();

        expect(repos.docs, hasLength(1));
        expect(repos.docs.first.data()[RepositoryKey.name], name);
      });

      test('should throw MaximumRepositoriesCounExceeded when limit reached', () async {
        const userId = 'user-123';

        // Create maximum number of repositories
        for (int i = 0; i < AppConstants.maximumRepositoriesCount; i++) {
          await createTestRepository(
            repositoryId: 'repo-$i',
            userId: userId,
            name: 'Repo $i',
          );
        }

        expect(
          () => repository.createUserRepository(
            userId: userId,
            name: 'One Too Many',
          ),
          throwsA(isA<MaximumRepositoriesCountExceeded>()),
        );
      });
    });

    group('renameRepository', () {
      test('should rename user repository successfully', () async {
        const userId = 'user-123';
        const repositoryId = 'repo-123';
        await createTestRepository(
          repositoryId: repositoryId,
          userId: userId,
          name: 'Old Name',
        );

        final result = await repository.renameRepository(
          repositoryId: repositoryId,
          newName: 'New Name',
          currentUserId: userId,
        );

        expect(result, true);

        final doc = await fakeFirestore.collection(FirebaseCollectionName.repositories).doc(repositoryId).get();

        expect(doc.data()?[RepositoryKey.name], 'New Name');
      });

      test('should throw RepositoryNotFound when repository does not exist', () async {
        expect(
          () => repository.renameRepository(
            repositoryId: 'non-existent',
            newName: 'New Name',
            currentUserId: 'user-123',
          ),
          throwsA(isA<RepositoryNotFound>()),
        );
      });

      test('should throw RepositoryCannotModifyPublic for public repository', () async {
        const repositoryId = 'public-repo';
        await createTestRepository(
          repositoryId: repositoryId,
          userId: '',
          name: 'Public Repo',
        );

        expect(
          () => repository.renameRepository(
            repositoryId: repositoryId,
            newName: 'New Name',
            currentUserId: 'user-123',
          ),
          throwsA(isA<RepositoryCannotModifyPublic>()),
        );
      });

      test('should throw RepositoryCannotModifyOtherUsers when not owner', () async {
        const repositoryId = 'repo-123';
        await createTestRepository(
          repositoryId: repositoryId,
          userId: 'owner-user',
          name: 'Owner Repo',
        );

        expect(
          () => repository.renameRepository(
            repositoryId: repositoryId,
            newName: 'New Name',
            currentUserId: 'different-user',
          ),
          throwsA(isA<RepositoryCannotModifyOtherUsers>()),
        );
      });
    });

    group('deleteRepository', () {
      test('should delete repository and all music sheets successfully', () async {
        const userId = 'user-123';
        const repositoryId = 'repo-123';
        await createTestRepository(
          repositoryId: repositoryId,
          userId: userId,
        );

        // Add music sheets to repository
        final sheet1 = createTestMusicSheetJson(musicSheetId: 'sheet-1');
        final sheet2 = createTestMusicSheetJson(musicSheetId: 'sheet-2');
        await fakeFirestore
            .collection(FirebaseCollectionName.repositories)
            .doc(repositoryId)
            .collection(FirebaseCollectionName.musicSheets)
            .doc('sheet-1')
            .set(sheet1);
        await fakeFirestore
            .collection(FirebaseCollectionName.repositories)
            .doc(repositoryId)
            .collection(FirebaseCollectionName.musicSheets)
            .doc('sheet-2')
            .set(sheet2);

        final result = await repository.deleteRepository(
          repositoryId: repositoryId,
          currentUserId: userId,
        );

        expect(result, true);

        // Verify repository is deleted
        final repoDoc = await fakeFirestore.collection(FirebaseCollectionName.repositories).doc(repositoryId).get();
        expect(repoDoc.exists, false);

        // Verify music sheets are deleted
        final musicSheets = await fakeFirestore
            .collection(FirebaseCollectionName.repositories)
            .doc(repositoryId)
            .collection(FirebaseCollectionName.musicSheets)
            .get();
        expect(musicSheets.docs, isEmpty);
      });

      test('should throw RepositoryNotFound when repository does not exist', () async {
        expect(
          () => repository.deleteRepository(
            repositoryId: 'non-existent',
            currentUserId: 'user-123',
          ),
          throwsA(isA<RepositoryNotFound>()),
        );
      });

      test('should throw RepositoryCannotModifyPublic for public repository', () async {
        const repositoryId = 'public-repo';
        await createTestRepository(
          repositoryId: repositoryId,
          userId: '',
        );

        expect(
          () => repository.deleteRepository(
            repositoryId: repositoryId,
            currentUserId: 'user-123',
          ),
          throwsA(isA<RepositoryCannotModifyPublic>()),
        );
      });

      test('should throw RepositoryGenericException when not owner', () async {
        const repositoryId = 'repo-123';
        await createTestRepository(
          repositoryId: repositoryId,
          userId: 'owner-user',
        );

        expect(
          () => repository.deleteRepository(
            repositoryId: repositoryId,
            currentUserId: 'different-user',
          ),
          throwsA(isA<RepositoryCannotModifyOtherUsers>()),
        );
      });
    });

    group('getRepositoryMusicSheetsCount', () {
      test('should return correct count of music sheets', () async {
        const repositoryId = 'repo-123';
        await createTestRepository(repositoryId: repositoryId);

        final sheet1 = createTestMusicSheetJson(musicSheetId: 'sheet-1');
        final sheet2 = createTestMusicSheetJson(musicSheetId: 'sheet-2');
        final sheet3 = createTestMusicSheetJson(musicSheetId: 'sheet-3');

        await fakeFirestore
            .collection(FirebaseCollectionName.repositories)
            .doc(repositoryId)
            .collection(FirebaseCollectionName.musicSheets)
            .doc('sheet-1')
            .set(sheet1);
        await fakeFirestore
            .collection(FirebaseCollectionName.repositories)
            .doc(repositoryId)
            .collection(FirebaseCollectionName.musicSheets)
            .doc('sheet-2')
            .set(sheet2);
        await fakeFirestore
            .collection(FirebaseCollectionName.repositories)
            .doc(repositoryId)
            .collection(FirebaseCollectionName.musicSheets)
            .doc('sheet-3')
            .set(sheet3);

        final count = await repository.getRepositoryMusicSheetsCount(repositoryId);

        expect(count, 3);
      });

      test('should return 0 when repository has no music sheets', () async {
        const repositoryId = 'empty-repo';
        await createTestRepository(repositoryId: repositoryId);

        final count = await repository.getRepositoryMusicSheetsCount(repositoryId);

        expect(count, 0);
      });
    });

    group('_handleRepositoryError', () {
      test('should throw RepositoryOfflineException for PlatformException with UNAVAILABLE message', () async {
        final mockFirestore = MockFirebaseFirestore();
        final repo = FirebaseFirestoreRepository(
          instance: mockFirestore,
          skipSettingsConfiguration: true,
        );

        when(() => mockFirestore.collection(any())).thenThrow(
          PlatformException(
            code: 'firebase_firestore',
            message: 'com.google.firebase.firestore.FirebaseFirestoreException: UNAVAILABLE: Unable to resolve host',
            details: {'code': 'unavailable'},
          ),
        );

        expect(
          () => repo.deleteRepository(repositoryId: 'any', currentUserId: 'any'),
          throwsA(isA<RepositoryNetworkException>()),
        );
      });
    });
  });
}
