import 'package:equatable/equatable.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';

sealed class MusicSheetRepositoryState extends Equatable {}

class MusicSheetRepositoryLoading extends MusicSheetRepositoryState {
  @override
  List<Object?> get props => [];
}

class MusicSheetRepositoryLoaded extends MusicSheetRepositoryState {
  final List<MusicSheet> allMusicSheets;
  final List<MusicSheet> filteredMusicSheets;
  MusicSheetRepositoryLoaded({required this.allMusicSheets, required this.filteredMusicSheets});

  @override
  List<Object?> get props => [allMusicSheets, filteredMusicSheets];
}

class MusicSheetRepositoryError extends MusicSheetRepositoryState {
  final String message;
  MusicSheetRepositoryError(this.message);

  @override
  List<Object?> get props => [];
}
