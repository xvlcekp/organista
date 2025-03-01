import 'package:collection/collection.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/music_sheet_repository/bloc/repository_event.dart';
import 'package:organista/features/music_sheet_repository/bloc/repository_state.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';

class MusicSheetRepositoryBloc extends Bloc<MusicSheetRepositoryEvent, MusicSheetRepositoryState> {
  final FirebaseFirestoreRepository firebaseFirestoreRepository;

  MusicSheetRepositoryBloc({required this.firebaseFirestoreRepository}) : super(MusicSheetRepositoryLoading()) {
    on<LoadMusicSheets>(_onLoadMusicSheets);
    on<SearchMusicSheets>(_onSearchMusicSheets);
  }

  List<MusicSheet> _sortMusicSheetsByAlphabet(List<MusicSheet> musicSheets) {
    musicSheets.sort((a, b) => compareNatural(a.fileName, b.fileName));
    return musicSheets;
  }

  Future<void> _onLoadMusicSheets(LoadMusicSheets event, Emitter<MusicSheetRepositoryState> emit) async {
    emit(MusicSheetRepositoryLoading());
    try {
      final String userId = event.userId;
      final musicSheets = await firebaseFirestoreRepository.getMusicSheetsFromRepository(userId);
      final sortedMusicSheets = _sortMusicSheetsByAlphabet(musicSheets.toList());
      emit(MusicSheetRepositoryLoaded(allMusicSheets: sortedMusicSheets, filteredMusicSheets: sortedMusicSheets));
    } catch (e) {
      emit(MusicSheetRepositoryError("Failed to load music sheets"));
    }
  }

  Future<void> _onSearchMusicSheets(SearchMusicSheets event, Emitter<MusicSheetRepositoryState> emit) async {
    if (state is MusicSheetRepositoryLoaded) {
      final allSheets = (state as MusicSheetRepositoryLoaded).allMusicSheets;
      final normalizedQuery = removeDiacritics(event.query.toLowerCase());
      final filteredSheets = allSheets.where((sheet) {
        final normalizedFileName = removeDiacritics(sheet.fileName.toLowerCase());
        return normalizedFileName.contains(normalizedQuery);
      }).toList();
      emit(MusicSheetRepositoryLoaded(allMusicSheets: allSheets, filteredMusicSheets: filteredSheets));
    }
  }
}
