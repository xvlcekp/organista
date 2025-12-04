import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// ignore: implementation_imports, Required to mock internal CacheStore type
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/cache_management/cubit/cache_cubit.dart';
import 'package:organista/features/cache_management/cubit/cache_state.dart';

// Mock classes
class MockCacheManager extends Mock implements CacheManager {}

class MockCacheStore extends Mock implements CacheStore {}

class MockConfig extends Mock implements Config {}

class MockCacheInfoRepository extends Mock implements CacheInfoRepository {}

class MockCacheObject extends Mock implements CacheObject {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheCubit', () {
    late CacheCubit cacheCubit;
    late MockCacheManager mockCacheManager;
    late MockCacheStore mockCacheStore;
    late MockConfig mockConfig;
    late MockCacheInfoRepository mockCacheInfoRepository;

    setUp(() {
      mockCacheManager = MockCacheManager();
      mockCacheStore = MockCacheStore();
      mockConfig = MockConfig();
      mockCacheInfoRepository = MockCacheInfoRepository();

      // Setup default mock chain
      when(() => mockCacheManager.store).thenReturn(mockCacheStore);
      when(() => mockCacheManager.config).thenReturn(mockConfig);
      when(() => mockConfig.repo).thenReturn(mockCacheInfoRepository);
    });

    tearDown(() {
      cacheCubit.close();
    });

    group('initial state', () {
      test('should have CacheInitial as initial state', () {
        cacheCubit = CacheCubit(cacheManager: mockCacheManager);
        expect(cacheCubit.state, const CacheInitial());
      });
    });

    group('loadCacheInfo', () {
      blocTest<CacheCubit, CacheState>(
        'emits [CacheLoading, CacheLoaded] when cache info is loaded successfully',
        setUp: () {
          when(() => mockCacheStore.getCacheSize()).thenAnswer((_) async => 5242880); // 5 MB
          when(() => mockCacheInfoRepository.open()).thenAnswer((_) async => true);
          when(() => mockCacheInfoRepository.getAllObjects()).thenAnswer((_) async => [
                MockCacheObject(),
                MockCacheObject(),
                MockCacheObject(),
              ]);
        },
        build: () => CacheCubit(cacheManager: mockCacheManager),
        act: (cubit) => cubit.loadCacheInfo(),
        expect: () => [
          const CacheLoading(),
          const CacheLoaded(totalFiles: 3, sizeInMB: 5.0),
        ],
        verify: (_) {
          verify(() => mockCacheStore.getCacheSize()).called(1);
          verify(() => mockCacheInfoRepository.open()).called(1);
          verify(() => mockCacheInfoRepository.getAllObjects()).called(1);
        },
      );

      blocTest<CacheCubit, CacheState>(
        'emits [CacheLoading, CacheLoaded] with 0 files when cache is empty',
        setUp: () {
          when(() => mockCacheStore.getCacheSize()).thenAnswer((_) async => 0);
          when(() => mockCacheInfoRepository.open()).thenAnswer((_) async => true);
          when(() => mockCacheInfoRepository.getAllObjects()).thenAnswer((_) async => []);
        },
        build: () => CacheCubit(cacheManager: mockCacheManager),
        act: (cubit) => cubit.loadCacheInfo(),
        expect: () => [
          const CacheLoading(),
          const CacheLoaded(totalFiles: 0, sizeInMB: 0.0),
        ],
      );

      blocTest<CacheCubit, CacheState>(
        'emits [CacheLoading, CacheError] when getCacheSize throws exception',
        setUp: () {
          when(() => mockCacheStore.getCacheSize()).thenThrow(Exception('Failed to get cache size'));
        },
        build: () => CacheCubit(cacheManager: mockCacheManager),
        act: (cubit) => cubit.loadCacheInfo(),
        expect: () => [
          const CacheLoading(),
          isA<CacheError>().having(
            (e) => e.message,
            'message',
            contains('Failed to get cache size'),
          ),
        ],
      );

      blocTest<CacheCubit, CacheState>(
        'emits [CacheLoading, CacheError] when getAllObjects throws exception',
        setUp: () {
          when(() => mockCacheStore.getCacheSize()).thenAnswer((_) async => 0);
          when(() => mockCacheInfoRepository.open()).thenAnswer((_) async => true);
          when(() => mockCacheInfoRepository.getAllObjects()).thenThrow(Exception('Database error'));
        },
        build: () => CacheCubit(cacheManager: mockCacheManager),
        act: (cubit) => cubit.loadCacheInfo(),
        expect: () => [
          const CacheLoading(),
          isA<CacheError>().having(
            (e) => e.message,
            'message',
            contains('Database error'),
          ),
        ],
      );

      blocTest<CacheCubit, CacheState>(
        'correctly converts bytes to megabytes',
        setUp: () {
          // 10,485,760 bytes = 10 MB
          when(() => mockCacheStore.getCacheSize()).thenAnswer((_) async => 10485760);
          when(() => mockCacheInfoRepository.open()).thenAnswer((_) async => true);
          when(() => mockCacheInfoRepository.getAllObjects()).thenAnswer((_) async => []);
        },
        build: () => CacheCubit(cacheManager: mockCacheManager),
        act: (cubit) => cubit.loadCacheInfo(),
        expect: () => [
          const CacheLoading(),
          const CacheLoaded(totalFiles: 0, sizeInMB: 10.0),
        ],
      );
    });

    group('clearCache', () {
      blocTest<CacheCubit, CacheState>(
        'emits [CacheLoading, CacheCleared, CacheLoading, CacheLoaded] when cache is cleared successfully',
        setUp: () {
          when(() => mockCacheManager.emptyCache()).thenAnswer((_) async {});
          when(() => mockCacheStore.getCacheSize()).thenAnswer((_) async => 0);
          when(() => mockCacheInfoRepository.open()).thenAnswer((_) async => true);
          when(() => mockCacheInfoRepository.getAllObjects()).thenAnswer((_) async => []);
        },
        build: () => CacheCubit(cacheManager: mockCacheManager),
        act: (cubit) => cubit.clearCache(),
        expect: () => [
          const CacheLoading(),
          const CacheCleared(),
          const CacheLoading(),
          const CacheLoaded(totalFiles: 0, sizeInMB: 0.0),
        ],
        verify: (_) {
          verify(() => mockCacheManager.emptyCache()).called(1);
        },
      );

      blocTest<CacheCubit, CacheState>(
        'emits [CacheLoading, CacheError] when emptyCache throws exception',
        setUp: () {
          when(() => mockCacheManager.emptyCache()).thenThrow(Exception('Failed to clear cache'));
        },
        build: () => CacheCubit(cacheManager: mockCacheManager),
        act: (cubit) => cubit.clearCache(),
        expect: () => [
          const CacheLoading(),
          isA<CacheError>().having(
            (e) => e.message,
            'message',
            contains('Failed to clear cache'),
          ),
        ],
      );

      blocTest<CacheCubit, CacheState>(
        'reloads cache info after successful clear',
        setUp: () {
          when(() => mockCacheManager.emptyCache()).thenAnswer((_) async {});
          when(() => mockCacheStore.getCacheSize()).thenAnswer((_) async => 0);
          when(() => mockCacheInfoRepository.open()).thenAnswer((_) async => true);
          when(() => mockCacheInfoRepository.getAllObjects()).thenAnswer((_) async => []);
        },
        build: () => CacheCubit(cacheManager: mockCacheManager),
        act: (cubit) => cubit.clearCache(),
        verify: (_) {
          // emptyCache should be called once, then loadCacheInfo should be called
          verify(() => mockCacheManager.emptyCache()).called(1);
          verify(() => mockCacheStore.getCacheSize()).called(1);
          verify(() => mockCacheInfoRepository.getAllObjects()).called(1);
        },
      );
    });

    group('bytes conversion', () {
      test('correctly converts 1 KB to MB', () async {
        when(() => mockCacheStore.getCacheSize()).thenAnswer((_) async => 1024);
        when(() => mockCacheInfoRepository.open()).thenAnswer((_) async => true);
        when(() => mockCacheInfoRepository.getAllObjects()).thenAnswer((_) async => []);

        cacheCubit = CacheCubit(cacheManager: mockCacheManager);
        await cacheCubit.loadCacheInfo();

        final state = cacheCubit.state as CacheLoaded;
        expect(state.sizeInMB, closeTo(0.0009765625, 0.0001)); // 1 KB = 1/1024 MB
      });

      test('correctly converts 1 MB to MB', () async {
        when(() => mockCacheStore.getCacheSize()).thenAnswer((_) async => 1048576);
        when(() => mockCacheInfoRepository.open()).thenAnswer((_) async => true);
        when(() => mockCacheInfoRepository.getAllObjects()).thenAnswer((_) async => []);

        cacheCubit = CacheCubit(cacheManager: mockCacheManager);
        await cacheCubit.loadCacheInfo();

        final state = cacheCubit.state as CacheLoaded;
        expect(state.sizeInMB, 1.0);
      });

      test('correctly converts 100 MB to MB', () async {
        when(() => mockCacheStore.getCacheSize()).thenAnswer((_) async => 104857600);
        when(() => mockCacheInfoRepository.open()).thenAnswer((_) async => true);
        when(() => mockCacheInfoRepository.getAllObjects()).thenAnswer((_) async => []);

        cacheCubit = CacheCubit(cacheManager: mockCacheManager);
        await cacheCubit.loadCacheInfo();

        final state = cacheCubit.state as CacheLoaded;
        expect(state.sizeInMB, 100.0);
      });
    });
  });
}
