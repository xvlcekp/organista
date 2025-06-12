import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/services/stream_manager.dart';

part 'repositories_state.dart';

class ShowRepositoriesCubit extends Cubit<ShowRepositoriesState> {
  final FirebaseFirestoreRepository firebaseFirestoreRepository;
  ShowRepositoriesCubit({
    required this.firebaseFirestoreRepository,
  }) : super(const InitRepositoryState());

  late final StreamSubscription<Iterable<Repository>> _streamSubscription;

  void resetState() {
    emit(const InitRepositoryState());
  }

  void startSubscribingRepositories({required String userId}) {
    final broadcastStream = StreamManager.instance.getBroadcastStream<Iterable<Repository>>(
      'repositories_$userId',
      () => firebaseFirestoreRepository.getRepositoriesStream(userId: userId),
    );

    // Always subscribe to the broadcast stream (even if reusing existing stream)
    _streamSubscription = broadcastStream.listen((repositories) {
      final publicRepos = repositories.where((repo) => repo.userId.isEmpty).toList();
      final privateRepos = repositories.where((repo) => repo.userId == userId).toList();
      emit(RepositoriesLoadedState(
        publicRepositories: publicRepos,
        privateRepositories: privateRepos,
      ));
    });

    logger.d('Subscribed to repositories stream for user: $userId');
  }

  @override
  Future<void> close() {
    // Cancel the subscription when leaving the page for optimization
    // Cached values will be available when returning
    // Note: StreamManager handles removeListener automatically via onCancel
    _streamSubscription.cancel();
    return super.close();
  }
}
