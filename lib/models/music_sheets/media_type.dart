enum MediaType {
  image,
  pdf;

  static MediaType fromString(String mediaType) {
    return MediaType.values.firstWhere(
      (e) => e.name == mediaType,
      orElse: () {
        throw ArgumentError('No matching MediaType for: $mediaType');
      },
    );
  }
}
