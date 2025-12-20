import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' show CacheManager;
import 'package:organista/extensions/num_extensions.dart';
import 'package:organista/features/cache_management/cubit/cache_state.dart';
import 'package:organista/logger/custom_logger.dart';

/// Cubit for managing cache operations
///
/// Handles loading cache information and clearing cache using
/// CacheManager with library's native API.
class CacheCubit extends Cubit<CacheState> {
  final CacheManager _cacheManager;

  CacheCubit({
    required CacheManager cacheManager,
  }) : _cacheManager = cacheManager,
       super(const CacheInitial());

  /// Load cache information (file count and size)
  ///
  /// Uses library's native API to get cache statistics:
  /// - CacheStore.getCacheSize() for total size
  /// - CacheInfoRepository.getAllObjects() for file count
  Future<void> loadCacheInfo() async {
    emit(const CacheLoading());

    try {
      // Use library's built-in getCacheSize() method for total size
      final totalSize = await _cacheManager.store.getCacheSize();

      // Access repository through config to get all objects
      final repository = await _cacheManager.config.repo.open().then((_) => _cacheManager.config.repo);
      final cacheObjects = await repository.getAllObjects();

      // Calculate size in MB
      final sizeInMB = totalSize.bytesToMegaBytes.toDouble();

      emit(
        CacheLoaded(
          totalFiles: cacheObjects.length,
          sizeInMB: sizeInMB,
        ),
      );
    } catch (e, stackTrace) {
      logger.e('Error loading cache info', error: e, stackTrace: stackTrace);
      emit(
        CacheError(
          message: e.toString(),
        ),
      );
    }
  }

  /// Clear all cached files
  Future<void> clearCache() async {
    emit(const CacheLoading());

    try {
      await _cacheManager.emptyCache();
      logger.i('Cache cleared successfully via CacheCubit');

      emit(const CacheCleared());

      // Reload cache info after clearing
      await loadCacheInfo();
    } catch (e, stackTrace) {
      logger.e('Error clearing cache', error: e, stackTrace: stackTrace);
      emit(
        CacheError(
          message: e.toString(),
        ),
      );
    }
  }
}
