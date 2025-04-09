import 'package:flutter/material.dart';
import 'package:organista/l10n/app_localizations.dart';
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
        Exception(AppLocalizations.of(navigatorKey.currentContext!).unsupportedFileExtension);
        return MediaType.image;
    }
  }

  static MediaType fromString(String mediaType) {
    return MediaType.values.firstWhere(
      (e) => e.name == mediaType,
      orElse: () {
        throw ArgumentError(AppLocalizations.of(navigatorKey.currentContext!).noMatchingMediaType.replaceAll('{mediaType}', mediaType));
      },
    );
  }
}

// Global navigator key to access context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
