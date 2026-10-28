import 'package:flutter_test/flutter_test.dart';
import 'package:organista/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SettingsRepository repository;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    repository = SettingsRepository(
      await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions()),
    );
  });

  test('last seen version is null on the first run and persists once saved', () async {
    expect(repository.getLastSeenVersion(), isNull);

    await repository.saveLastSeenVersion('1.3.2');

    expect(repository.getLastSeenVersion(), '1.3.2');
  });

  test('clearAll forgets the last seen version', () async {
    await repository.saveLastSeenVersion('1.3.2');

    await repository.clearAll();

    expect(repository.getLastSeenVersion(), isNull);
  });
}
