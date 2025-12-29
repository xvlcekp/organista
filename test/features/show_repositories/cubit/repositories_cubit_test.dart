import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/show_repositories/cubit/show_repositories_cubit.dart';
import 'package:organista/features/show_repositories/models/repository_error.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';

class MockFirebaseFirestoreRepository extends Mock implements FirebaseFirestoreRepository {}

void main() {
  group('ShowRepositoriesCubit', () {
    late ShowRepositoriesCubit cubit;
    late MockFirebaseFirestoreRepository mockRepository;
    late StreamController<Iterable<Repository>> repositoriesController;

    setUp(() {
      mockRepository = MockFirebaseFirestoreRepository();
      cubit = ShowRepositoriesCubit(firebaseFirestoreRepository: mockRepository);
      repositoriesController = StreamController<Iterable<Repository>>();
    });

    tearDown(() {
      repositoriesController.close();
      // Don't close cubit here as it causes issues with uninitialized _streamSubscription
      // The cubit will be garbage collected after test completion
    });

    Repository createTestRepository({
      required String id,
      required String name,
      String userId = '',
      DateTime? createdAt,
    }) {
      return Repository(
        json: {
          'repository_id': id,
          'name': name,
          'uid': userId,
          'created_at': Timestamp.fromDate(createdAt ?? DateTime.now()),
        },
      );
    }

    group('initial state', () {
      test('should have InitRepositoryState as initial state', () {
        expect(cubit.state, const InitRepositoryState());
      });
    });

    group('resetState', () {
      blocTest<ShowRepositoriesCubit, ShowRepositoriesState>(
        'should emit InitRepositoryState',
        build: () => cubit,
        act: (cubit) => cubit.resetState(),
        expect: () => [const InitRepositoryState()],
      );
    });

    group('createRepository', () {
      const userId = 'test-user-id';
      const repositoryName = 'Test Repository';

      blocTest<ShowRepositoriesCubit, ShowRepositoriesState>(
        'should emit loading state then success state when repository creation succeeds',
        build: () {
          when(
            () => mockRepository.createUserRepository(
              userId: userId,
              name: repositoryName,
            ),
          ).thenAnswer((_) async => true);
          return cubit;
        },
        act: (cubit) => cubit.createRepository(
          repositoryName: repositoryName,
          userId: userId,
        ),
        expect: () => [
          const RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
            isLoading: true,
          ),
          const RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
            isLoading: false,
          ),
        ],
        verify: (_) {
          verify(
            () => mockRepository.createUserRepository(
              userId: userId,
              name: repositoryName,
            ),
          ).called(1);
        },
      );

      blocTest<ShowRepositoriesCubit, ShowRepositoriesState>(
        'should emit loading state then error state when repository creation fails',
        build: () {
          when(
            () => mockRepository.createUserRepository(
              userId: userId,
              name: repositoryName,
            ),
          ).thenAnswer((_) async => false);
          return cubit;
        },
        act: (cubit) => cubit.createRepository(
          repositoryName: repositoryName,
          userId: userId,
        ),
        expect: () => [
          const RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
            isLoading: true,
          ),
          const RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
            error: RepositoryGenericException(),
            isLoading: false,
          ),
        ],
      );

      blocTest<ShowRepositoriesCubit, ShowRepositoriesState>(
        'should emit loading state then error state when repository creation throws exception',
        build: () {
          when(
            () => mockRepository.createUserRepository(
              userId: userId,
              name: repositoryName,
            ),
          ).thenThrow(const RepositoryNotFound());
          return cubit;
        },
        act: (cubit) => cubit.createRepository(
          repositoryName: repositoryName,
          userId: userId,
        ),
        expect: () => [
          const RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
            isLoading: true,
          ),
          const RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
            error: RepositoryNotFound(),
            isLoading: false,
          ),
        ],
      );

      blocTest<ShowRepositoriesCubit, ShowRepositoriesState>(
        'should emit loading state then error state when maximum repositories count is exceeded',
        build: () {
          when(
            () => mockRepository.createUserRepository(
              userId: userId,
              name: repositoryName,
            ),
          ).thenThrow(const MaximumRepositoriesCountExceeded(maximumRepositoriesCount: 5));
          return cubit;
        },
        act: (cubit) => cubit.createRepository(
          repositoryName: repositoryName,
          userId: userId,
        ),
        expect: () => [
          const RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
            isLoading: true,
          ),
          const RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
            error: MaximumRepositoriesCountExceeded(maximumRepositoriesCount: 5),
            isLoading: false,
          ),
        ],
      );
    });

    group('renameRepository', () {
      const repositoryId = 'test-repo-id';
      const newName = 'New Repository Name';
      const userId = 'test-user-id';

      blocTest<ShowRepositoriesCubit, ShowRepositoriesState>(
        'should emit loading state then success state when repository rename succeeds',
        build: () {
          when(
            () => mockRepository.renameRepository(
              repositoryId: repositoryId,
              newName: newName,
              currentUserId: userId,
            ),
          ).thenAnswer((_) async => true);
          return cubit;
        },
        act: (cubit) => cubit.renameRepository(
          repositoryId: repositoryId,
          newName: newName,
          currentUserId: userId,
        ),
        expect: () => [
          const RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
            isLoading: true,
          ),
          const RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
            isLoading: false,
          ),
        ],
        verify: (_) {
          verify(
            () => mockRepository.renameRepository(
              repositoryId: repositoryId,
              newName: newName,
              currentUserId: userId,
            ),
          ).called(1);
        },
      );

      blocTest<ShowRepositoriesCubit, ShowRepositoriesState>(
        'should emit loading state then error state when repository rename throws exception',
        build: () {
          when(
            () => mockRepository.renameRepository(
              repositoryId: repositoryId,
              newName: newName,
              currentUserId: userId,
            ),
          ).thenThrow(const RepositoryCannotModifyPublic());
          return cubit;
        },
        act: (cubit) => cubit.renameRepository(
          repositoryId: repositoryId,
          newName: newName,
          currentUserId: userId,
        ),
        expect: () => [
          const RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
            isLoading: true,
          ),
          const RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
            error: RepositoryCannotModifyPublic(),
            isLoading: false,
          ),
        ],
      );
    });

    group('deleteRepository', () {
      const repositoryId = 'test-repo-id';
      const userId = 'test-user-id';

      blocTest<ShowRepositoriesCubit, ShowRepositoriesState>(
        'should emit loading state then success state when repository deletion succeeds',
        build: () {
          when(
            () => mockRepository.deleteRepository(
              repositoryId: repositoryId,
              currentUserId: userId,
            ),
          ).thenAnswer((_) async => true);
          return cubit;
        },
        act: (cubit) => cubit.deleteRepository(
          repositoryId: repositoryId,
          currentUserId: userId,
        ),
        expect: () => [
          const RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
            isLoading: true,
          ),
          const RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
            isLoading: false,
          ),
        ],
        verify: (_) {
          verify(
            () => mockRepository.deleteRepository(
              repositoryId: repositoryId,
              currentUserId: userId,
            ),
          ).called(1);
        },
      );

      blocTest<ShowRepositoriesCubit, ShowRepositoriesState>(
        'should emit loading state then error state when repository deletion throws exception',
        build: () {
          when(
            () => mockRepository.deleteRepository(
              repositoryId: repositoryId,
              currentUserId: userId,
            ),
          ).thenThrow(const RepositoryCannotModifyOtherUsers());
          return cubit;
        },
        act: (cubit) => cubit.deleteRepository(
          repositoryId: repositoryId,
          currentUserId: userId,
        ),
        expect: () => [
          const RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
            isLoading: true,
          ),
          const RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
            error: RepositoryCannotModifyOtherUsers(),
            isLoading: false,
          ),
        ],
      );
    });

    group('startSubscribingRepositories', () {
      const userId = 'test-user-id';

      test('should emit RepositoriesState when repositories stream emits data', () async {
        final publicRepo = createTestRepository(id: '1', name: 'Public Repo');
        final privateRepo = createTestRepository(id: '2', name: 'Private Repo', userId: userId);
        final repositories = [publicRepo, privateRepo];

        when(
          () => mockRepository.getRepositoriesStream(userId: userId),
        ).thenAnswer((_) => repositoriesController.stream);

        // Start subscription
        cubit.startSubscribingRepositories(userId: userId);

        // Emit repositories data
        repositoriesController.add(repositories);

        // Wait for the stream to emit
        await Future.delayed(const Duration(milliseconds: 100));

        expect(cubit.state, isA<RepositoriesState>());
        final state = cubit.state as RepositoriesState;
        expect(state.publicRepositories, [publicRepo]);
        expect(state.privateRepositories, [privateRepo]);
      });

      test('should separate public and private repositories correctly', () async {
        final publicRepo1 = createTestRepository(id: '1', name: 'Public Repo 1');
        final publicRepo2 = createTestRepository(id: '2', name: 'Public Repo 2');
        final privateRepo1 = createTestRepository(id: '3', name: 'Private Repo 1', userId: userId);
        final privateRepo2 = createTestRepository(id: '4', name: 'Private Repo 2', userId: userId);
        final otherUserRepo = createTestRepository(id: '5', name: 'Other User Repo', userId: 'other-user');

        final repositories = [publicRepo1, publicRepo2, privateRepo1, privateRepo2, otherUserRepo];

        when(
          () => mockRepository.getRepositoriesStream(userId: userId),
        ).thenAnswer((_) => repositoriesController.stream);

        cubit.startSubscribingRepositories(userId: userId);
        repositoriesController.add(repositories);

        await Future.delayed(const Duration(milliseconds: 100));

        final state = cubit.state as RepositoriesState;
        expect(state.publicRepositories, [publicRepo1, publicRepo2]);
        expect(state.privateRepositories, [privateRepo1, privateRepo2]);
        expect(state.publicRepositories, isNot(contains(otherUserRepo)));
        expect(state.privateRepositories, isNot(contains(otherUserRepo)));
      });
    });
  });
}
