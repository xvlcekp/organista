import 'dart:typed_data';

import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';

sealed class MusicSheetSource {
  const MusicSheetSource();

  MediaType get mediaType;
  String get fileName;
}

final class MusicSheetUrlSource extends MusicSheetSource {
  const MusicSheetUrlSource(this.musicSheet);

  final MusicSheet musicSheet;

  @override
  MediaType get mediaType => musicSheet.mediaType;

  @override
  String get fileName => musicSheet.fileName;
}

final class MusicSheetBytesSource extends MusicSheetSource {
  const MusicSheetBytesSource({
    required this.bytes,
    required this.mediaType,
    required this.fileName,
  });

  final Uint8List bytes;

  @override
  final MediaType mediaType;

  @override
  final String fileName;
}
