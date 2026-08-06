import 'package:file/file.dart' hide FileSystem;
import 'package:file/local.dart';
// ignore: implementation_imports, Required to implement custom FileSystem for persistent caching mentioned below.
import 'package:flutter_cache_manager/src/storage/file_system/file_system.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Custom FileSystem that uses Application Support directory instead of temporary cache.
///
/// This prevents the OS from automatically clearing cached files when storage is low.
/// Files in Application Support directory are:
/// - Persistent (not cleared by OS)
/// - Backed up (on iOS)
/// - Count toward app size in device settings
/// - Fully under application control
class PersistentFileSystem implements FileSystem {
  final Future<Directory> _fileDir;
  final String _cacheKey;

  PersistentFileSystem(this._cacheKey) : _fileDir = createDirectory(_cacheKey);

  /// Creates directory in Application Support instead of temporary cache
  static Future<Directory> createDirectory(String key) async {
    // Use Application Support directory - persistent, not cleared by OS
    final baseDir = await getApplicationSupportDirectory();
    final path = p.join(baseDir.path, key);

    const fs = LocalFileSystem();
    final directory = fs.directory(path);
    await directory.create(recursive: true);
    return directory;
  }

  @override
  Future<File> createFile(String name) async {
    final directory = await _fileDir;

    // Ensure directory still exists
    if (!(await directory.exists())) {
      await createDirectory(_cacheKey);
    }

    return directory.childFile(name);
  }
}
