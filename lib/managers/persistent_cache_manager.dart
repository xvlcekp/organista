import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:organista/config/app_constants.dart';
import 'package:organista/features/cache_management/utils/persistent_file_system.dart';

/// Custom cache manager that uses PersistentFileSystem for persistent storage.
///
/// Unlike the default CacheManager which uses temporary cache directory,
/// this implementation stores files in custom PersistentFileSystem, preventing
/// the OS from automatically clearing them anytime. More details in PersistentFileSystem.
class PersistentCacheManager extends CacheManager with ImageCacheManager {
  static final PersistentCacheManager _instance = PersistentCacheManager._();

  factory PersistentCacheManager() {
    return _instance;
  }

  PersistentCacheManager._()
    : super(
        Config(
          AppConstants.cacheKey,
          stalePeriod: AppConstants.cacheStalePeriod,
          maxNrOfCacheObjects: AppConstants.maxCacheObjects,
          repo: JsonCacheInfoRepository(databaseName: AppConstants.cacheKey),
          fileSystem: PersistentFileSystem(AppConstants.cacheKey),
          fileService: HttpFileService(),
        ),
      );
}
