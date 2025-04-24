import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:organista/models/music_sheets/media_type.dart';

/// A class that represents a music sheet file with its associated metadata.
class MusicSheetFile {
  final PlatformFile file;
  final MediaType mediaType;

  /// Creates a new [MusicSheetFile] instance.
  ///
  /// Requires a [file] and its corresponding [mediaType].
  const MusicSheetFile({
    required this.file,
    required this.mediaType,
  });

  /// Creates a [MusicSheetFile] from a [PlatformFile].
  ///
  /// Automatically determines the [MediaType] from the file's name.
  factory MusicSheetFile.fromPlatformFile(PlatformFile file) {
    final mediaType = MediaType.fromPath(file.name);
    return MusicSheetFile(
      file: file,
      mediaType: mediaType,
    );
  }

  /// The name of the file.
  String get name => file.name;

  /// The size of the file in bytes.
  int get size => file.size;

  /// The file extension.
  String? get extension => file.extension;

  /// The file data as bytes.
  Uint8List? get bytes => file.bytes;

  @override
  String toString() => 'MusicSheetFile(name: $name, mediaType: $mediaType)';
}
