import 'package:path/path.dart';

enum MediaType {
  image,
  pdf;

  static MediaType fromPath(String path) {
    final fileExtension = extension(path);
    switch (fileExtension) {
      case '.pdf':
        return MediaType.pdf;
      case '.png':
      case '.jpg':
        return MediaType.image;
      default:
        Exception('Unsupported file extension');
        return MediaType.image;
    }
  }

  static MediaType fromString(String mediaType) {
    return MediaType.values.firstWhere(
      (e) => e.name == mediaType,
      orElse: () {
        throw ArgumentError('No matching MediaType for: $mediaType');
      },
    );
  }
}
