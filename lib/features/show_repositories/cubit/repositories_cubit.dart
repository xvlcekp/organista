import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart' show immutable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/show_repositories/models/repository_error.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/services/stream_manager.dart';

part 'repositories_state.dart';

class ShowRepositoriesCubit extends Cubit<ShowRepositoriesState> {
  final FirebaseFirestoreRepository _firebaseFirestoreRepository;
  ShowRepositoriesCubit({
    required FirebaseFirestoreRepository firebaseFirestoreRepository,
  }) : _firebaseFirestoreRepository = firebaseFirestoreRepository,
       super(const InitRepositoryState());

  StreamSubscription<Iterable<Repository>>? _streamSubscription;

  void resetState() {
    emit(const InitRepositoryState());
  }

  Future<void> createRepository({
    required String repositoryName,
    required String userId,
  }) async {
    // Emit loading state while preserving current repositories
    emit(
      RepositoriesState(
        publicRepositories: state.publicRepositories,
        privateRepositories: state.privateRepositories,
        isLoading: true,
      ),
    );

    try {
      final success = await _firebaseFirestoreRepository.createUserRepository(
        userId: userId,
        name: repositoryName,
      );

      if (success) {
        // Success state with message
        emit(
          RepositoriesState(
            publicRepositories: state.publicRepositories,
            privateRepositories: state.privateRepositories,
          ),
        );
      } else {
        emit(
          RepositoriesState(
            publicRepositories: state.publicRepositories,
            privateRepositories: state.privateRepositories,
            error: const RepositoryGenericException(),
          ),
        );
      }
    } catch (e) {
      emit(
        RepositoriesState(
          publicRepositories: state.publicRepositories,
          privateRepositories: state.privateRepositories,
          error: e as RepositoryError,
        ),
      );
    }
  }

  Future<void> renameRepository({
    required String repositoryId,
    required String newName,
    required String currentUserId,
  }) async {
    // Emit loading state while preserving current repositories
    emit(
      RepositoriesState(
        publicRepositories: state.publicRepositories,
        privateRepositories: state.privateRepositories,
        isLoading: true,
      ),
    );

    try {
      await _firebaseFirestoreRepository.renameRepository(
        repositoryId: repositoryId,
        newName: newName,
        currentUserId: currentUserId,
      );

      // Success state with message
      emit(
        RepositoriesState(
          publicRepositories: state.publicRepositories,
          privateRepositories: state.privateRepositories,
        ),
      );
    } catch (e) {
      emit(
        RepositoriesState(
          publicRepositories: state.publicRepositories,
          privateRepositories: state.privateRepositories,
          error: e as RepositoryError,
        ),
      );
    }
  }

  Future<void> deleteRepository({
    required String repositoryId,
    required String currentUserId,
  }) async {
    logger.d('deleteRepository was called with repositoryId: $repositoryId');
    // Emit loading state while preserving current repositories
    emit(
      RepositoriesState(
        publicRepositories: state.publicRepositories,
        privateRepositories: state.privateRepositories,
        isLoading: true,
      ),
    );

    try {
      await _firebaseFirestoreRepository.deleteRepository(
        repositoryId: repositoryId,
        currentUserId: currentUserId,
      );

      // Success state with message
      emit(
        RepositoriesState(
          publicRepositories: state.publicRepositories,
          privateRepositories: state.privateRepositories,
        ),
      );
    } catch (e) {
      emit(
        RepositoriesState(
          publicRepositories: state.publicRepositories,
          privateRepositories: state.privateRepositories,
          error: e as RepositoryError,
        ),
      );
    }
  }

  void startSubscribingRepositories({required String userId}) {
    final broadcastStream = StreamManager.instance.getBroadcastStream<Iterable<Repository>>(
      'repositories_$userId',
      () => _firebaseFirestoreRepository.getRepositoriesStream(userId: userId),
    );

    // Always subscribe to the broadcast stream (even if reusing existing stream)
    _streamSubscription = broadcastStream.listen((repositories) {
      final publicRepos = repositories.where((repo) => repo.userId.isEmpty).toList();
      final privateRepos = repositories.where((repo) => repo.userId == userId).toList();
      emit(
        RepositoriesState(
          publicRepositories: publicRepos,
          privateRepositories: privateRepos,
        ),
      );
    });

    logger.d('Subscribed to repositories stream for user: $userId');
  }

  @override
  Future<void> close() {
    // Cancel the subscription when leaving the page for optimization
    // Cached values will be available when returning
    // Note: StreamManager handles removeListener automatically via onCancel
    _streamSubscription?.cancel();
    return super.close();
  }
}
