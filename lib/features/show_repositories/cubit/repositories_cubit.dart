import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';

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

  void startSubscribingRepositories({required String userId}) async {
    _streamSubscription = firebaseFirestoreRepository.getRepositoriesStream(userId: userId).listen((repositories) {
      emit(RepositoriesLoadedState(repositories: repositories.toList()));
    });
  }

  @override
  Future<void> close() {
    _streamSubscription.cancel();
    return super.close();
  }
}
