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
  static const int maxCacheObjects = 2000;

  /// How long Firebase Storage retries an upload / a metadata operation before failing. The SDK defaults
  /// (10 and 2 minutes) keep the user waiting behind a loader when the network is there but Firebase is not reachable.
  static const Duration storageUploadRetryTime = Duration(minutes: 1);
  static const Duration storageOperationRetryTime = Duration(seconds: 30);

  static const double nextPagetouchAreaHeight = 0.15;

  // App info
  static const String contactEmail = 'rozpravaciaappka@gmail.com';
  static const String faqUrl = 'https://xvlcekp.github.io/organista';
  static const int maximumRepositoriesCount = 10;

  // Playlist limits
  static const int maxPlaylistCapacity = 50;

  // Cloud Logging: entries are buffered and sent in one request per batch
  static const Duration cloudLoggingFlushInterval = Duration(seconds: 5);
  static const int cloudLoggingBatchSize = 50;

  // Debug constants
  static const String debugRegisterEmail = 'test@test.com';
  static const String debugRegisterPassword = 'test123';
}
