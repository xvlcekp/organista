import 'dart:typed_data';

import 'package:organista/models/music_sheets/media_type.dart';

/// A music sheet file picked for upload: its name, its content and the [MediaType] derived from the name.
class MusicSheetFile {
  final String name;
  final Uint8List bytes;
  final MediaType mediaType;

  const MusicSheetFile({
    required this.name,
    required this.bytes,
    required this.mediaType,
  });

  /// Derives the [MediaType] from [name]; throws [UnsupportedFileExtensionException] for any other extension.
  factory MusicSheetFile.fromBytes({required String name, required Uint8List bytes}) {
    return MusicSheetFile(name: name, bytes: bytes, mediaType: MediaType.fromPath(name));
  }

  /// The size of the file in bytes.
  int get size => bytes.length;

  @override
  String toString() => 'MusicSheetFile(name: $name, mediaType: $mediaType)';
}
