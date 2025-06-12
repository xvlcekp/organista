import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:diacritic/diacritic.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/services/stream_manager.dart';

part 'repository_event.dart';
part 'repository_state.dart';

class MusicSheetRepositoryBloc extends Bloc<MusicSheetRepositoryEvent, MusicSheetRepositoryState> {
  final FirebaseFirestoreRepository firebaseFirestoreRepository;
  StreamSubscription<Iterable<MusicSheet>>? _musicSheetsSubscription;

  MusicSheetRepositoryBloc({
    required this.firebaseFirestoreRepository,
  }) : super(MusicSheetRepositoryInitial()) {
    on<InitMusicSheetsRepositoryEvent>(_initMusicSheetsRepositoryEvent);
    on<UpdateMusicSheetsEvent>(_onUpdateMusicSheets);
    on<SearchMusicSheets>(_onSearchMusicSheets);
    on<DeleteMusicSheet>(_onDeleteMusicSheet);
  }

  List<MusicSheet> _sortMusicSheetsByAlphabet(List<MusicSheet> musicSheets) {
    musicSheets.sort((a, b) => compareNatural(a.fileName, b.fileName));
    return musicSheets;
  }

  List<MusicSheet> _filterMusicSheets(List<MusicSheet> allMusicSheets, String query) {
    final normalizedQuery = removeDiacritics(query.toLowerCase());
    final filteredSheets = allMusicSheets.where((sheet) {
      final normalizedFileName = removeDiacritics(sheet.fileName.toLowerCase());
      return normalizedFileName.contains(normalizedQuery);
    }).toList();
    return filteredSheets;
  }

  Future<void> _onSearchMusicSheets(SearchMusicSheets event, Emitter<MusicSheetRepositoryState> emit) async {
    if (state is MusicSheetRepositoryLoaded) {
      final allSheets = (state as MusicSheetRepositoryLoaded).allMusicSheets;
      final filteredSheets = _filterMusicSheets(allSheets, event.query);
      emit(MusicSheetRepositoryLoaded(allMusicSheets: allSheets, filteredMusicSheets: filteredSheets));
    }
  }

  Future<void> _onDeleteMusicSheet(DeleteMusicSheet event, Emitter<MusicSheetRepositoryState> emit) async {
    final musicSheetToDelete = event.musicSheet;
    final repositoryId = event.repositoryId;
    await firebaseFirestoreRepository.deleteMusicSheetFromRepository(
      musicSheet: musicSheetToDelete,
      repositoryId: repositoryId,
    );
  }

  void _initMusicSheetsRepositoryEvent(InitMusicSheetsRepositoryEvent event, Emitter<MusicSheetRepositoryState> emit) async {
    emit(MusicSheetRepositoryLoading());

    try {
      final broadcastStream = StreamManager.instance.getBroadcastStream<Iterable<MusicSheet>>(
        'music_sheets_${event.repositoryId}',
        () => firebaseFirestoreRepository.getRepositoryMusicSheetsStream(event.repositoryId),
      );

      // Always subscribe to the broadcast stream (even if reusing existing stream)
      _musicSheetsSubscription = broadcastStream.listen(
        (musicSheets) {
          add(UpdateMusicSheetsEvent(musicSheets));
        },
        onError: (error) {
          logger.e('Error in music sheets stream: $error');
          add(UpdateMusicSheetsEvent([]));
        },
      );

      logger.d('Subscribed to music sheets stream: ${event.repositoryId}');
    } catch (e) {
      logger.e('Error initializing music sheets stream: $e');
      emit(MusicSheetRepositoryError('Failed to load music sheets: $e'));
    }
  }

  void _onUpdateMusicSheets(event, emit) {
    final sortedMusicSheets = _sortMusicSheetsByAlphabet(event.musicSheets.toList());
    if (state is MusicSheetRepositoryLoaded) {
      final currentState = state as MusicSheetRepositoryLoaded;
      final query = currentState.searchQuery;
      final filteredSheets = _filterMusicSheets(sortedMusicSheets, query);
      emit(MusicSheetRepositoryLoaded(
        allMusicSheets: sortedMusicSheets,
        filteredMusicSheets: filteredSheets,
        searchQuery: query,
      ));
    } else {
      emit(MusicSheetRepositoryLoaded(
        allMusicSheets: sortedMusicSheets,
        filteredMusicSheets: sortedMusicSheets,
      ));
    }
  }

  @override
  Future<void> close() {
    // Cancel the subscription when leaving the page for optimization
    // Cached values will be available when returning
    // Note: StreamManager handles removeListener automatically via onCancel
    _musicSheetsSubscription?.cancel();
    return super.close();
  }
}
