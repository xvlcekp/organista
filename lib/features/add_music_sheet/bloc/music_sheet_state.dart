part of 'music_sheet_bloc.dart';

@immutable
abstract class MusicSheetState {
  final bool isLoading;
  final Iterable<MusicSheet> musicSheets;

  const MusicSheetState({
    required this.isLoading,
    required this.musicSheets,
  });
}

@immutable
class MusicSheetsInitState extends MusicSheetState with EquatableMixin {
  const MusicSheetsInitState() : super(isLoading: false, musicSheets: const []);

  @override
  List<Object?> get props => [isLoading];
}

@immutable
class MusicSheetsLoadedState extends MusicSheetState with EquatableMixin {
  const MusicSheetsLoadedState({
    required super.isLoading,
    required super.musicSheets,
  });

  @override
  String toString() => 'MusicSheetsLoadedState, images.length = ${musicSheets.length} and is loading = $isLoading';

  @override
  List<Object?> get props => [isLoading, musicSheets];
}

@immutable
class MusicSheetsErrorState extends MusicSheetState with EquatableMixin {
  const MusicSheetsErrorState() : super(isLoading: false, musicSheets: const []);

  @override
  List<Object?> get props => [isLoading];
}

extension GetMusicSheets on MusicSheetState {
  Iterable<MusicSheet>? get musicSheets {
    final cls = this;
    if (cls is MusicSheetsLoadedState) {
      return cls.musicSheets;
    } else {
      return null;
    }
  }
}
