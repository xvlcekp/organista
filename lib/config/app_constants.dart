/// Application-wide constants
class AppConstants {
  /// Maximum file size in MB for display purposes
  static const int maxFileSizeMB = 4;

  /// Maximum file size for uploads (4MB)
  static const int maxFileSizeBytes = maxFileSizeMB * 1024 * 1024;

  /// Cache config
  /// Cache key for persistent storage
  static const String cacheKey = 'persistentCache';

  /// Duration after which cached items become stale (1 year)
  static const Duration cacheStalePeriod = Duration(days: 365);

  /// Maximum number of objects to keep in cache
  static const int maxCacheObjects = 5000;

  static const double nextPagetouchAreaHeight = 0.15;

  // App info
  static const String contactEmail = 'rozpravaciaappka@gmail.com';
  static const String faqUrl = 'https://sites.google.com/view/organista-app/casto-kladene-otazky';
  static const int maximumRepositoriesCount = 10;

  // Playlist limits
  static const int maxPlaylistCapacity = 50;
}
