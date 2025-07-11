import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:organista/config/app_constants.dart';

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
          fileService: HttpFileService(),
        ),
      );
}
