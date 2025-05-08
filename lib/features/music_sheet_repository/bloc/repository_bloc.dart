import 'dart:async';

import 'package:collection/collection.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/music_sheet_repository/bloc/repository_event.dart';
import 'package:organista/features/music_sheet_repository/bloc/repository_state.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';

class MusicSheetRepositoryBloc extends Bloc<MusicSheetRepositoryEvent, MusicSheetRepositoryState> {
  final FirebaseFirestoreRepository firebaseFirestoreRepository;

  MusicSheetRepositoryBloc({required this.firebaseFirestoreRepository}) : super(MusicSheetRepositoryLoading()) {
    on<SearchMusicSheets>(_onSearchMusicSheets);
    on<DeleteMusicSheet>(_onDeleteMusicSheet);
    on<InitMusicSheetsRepositoryEvent>(_initMusicSheetsRepositoryEvent);
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

  Future<void> _initMusicSheetsRepositoryEvent(event, emit) async {
    try {
      final repositoryId = event.repositoryId;
      logger.i("Init repository was called for repository: $repositoryId");
      emit(MusicSheetRepositoryLoading());

      await for (final musicSheets in firebaseFirestoreRepository.getRepositoryMusicSheetsStream(repositoryId)) {
        final sortedMusicSheets = _sortMusicSheetsByAlphabet(musicSheets.toList());
        emit(MusicSheetRepositoryLoaded(
          allMusicSheets: sortedMusicSheets,
          filteredMusicSheets: sortedMusicSheets,
        ));
      }
    } catch (e) {
      logger.e("Failed to load music sheets", error: e);
      emit(MusicSheetRepositoryError("Failed to load music sheets"));
    }
  }
}
