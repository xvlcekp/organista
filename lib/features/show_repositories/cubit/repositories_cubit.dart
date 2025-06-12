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
  String? _currentStreamIdentifier;

  void resetState() {
    emit(const InitRepositoryState());
  }

  void startSubscribingRepositories({required String userId}) {
    final streamIdentifier = 'repositories_$userId';

    // Only remove listener if we're switching to a different stream
    if (_currentStreamIdentifier != null && _currentStreamIdentifier != streamIdentifier) {
      StreamManager.instance.removeListener(_currentStreamIdentifier!);
    }

    _currentStreamIdentifier = streamIdentifier;

    final broadcastStream = StreamManager.instance.getBroadcastStream<Iterable<Repository>>(
      streamIdentifier,
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

    logger.d('Subscribed to broadcast stream for repositories of user: $userId');
  }

  @override
  Future<void> close() {
    // Only remove the listener from StreamManager, never cancel subscriptions
    // Streams will only be canceled on logout/user deletion via StreamManager.cancelAllStreams()
    if (_currentStreamIdentifier != null) {
      StreamManager.instance.removeListener(_currentStreamIdentifier!);
    }
    return super.close();
  }
}
