import 'package:path/path.dart';

enum MediaType {
  image,
  pdf;

  static MediaType fromPath(String path) {
    final fileExtension = extension(path);
    switch (fileExtension.toLowerCase()) {
      case '.pdf':
        return MediaType.pdf;
      case '.png':
      case '.jpg':
      case '.jpeg':
        return MediaType.image;
      default:
        throw UnsupportedFileExtensionException(fileExtension);
    }
  }

  static MediaType fromString(String mediaType) {
    return MediaType.values.firstWhere(
      (e) => e.name == mediaType,
      orElse: () {
        throw NoMatchingMediaTypeException(mediaType);
      },
    );
  }
}

class UnsupportedFileExtensionException implements Exception {
  final String extension;
  UnsupportedFileExtensionException(this.extension);

  @override
  String toString() => 'Unsupported file extension: $extension';
}

class NoMatchingMediaTypeException implements Exception {
  final String mediaType;
  NoMatchingMediaTypeException(this.mediaType);

  @override
  String toString() => 'No matching media type found for: $mediaType';
}
