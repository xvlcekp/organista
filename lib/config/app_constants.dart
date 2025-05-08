/// Application-wide constants
class AppConstants {
  /// Maximum file size for uploads (4MB)
  static const int maxFileSizeBytes = 4 * 1024 * 1024;

  /// Maximum file size in MB for display purposes
  static const int maxFileSizeMB = 4;

  /// Cache config
  /// Cache key for persistent storage
  static const String cacheKey = 'persistentCache';

  /// Duration after which cached items become stale (1 year)
  static const Duration cacheStalePeriod = Duration(days: 365);

  /// Maximum number of objects to keep in cache
  static const int maxCacheObjects = 5000;
}
