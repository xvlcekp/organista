import 'package:flutter_test/flutter_test.dart';
import 'package:organista/features/cache_management/cubit/cache_state.dart';

void main() {
  group('CacheState', () {
    group('CacheInitial', () {
      test('supports value equality', () {
        const state1 = CacheInitial();
        const state2 = CacheInitial();

        expect(state1, equals(state2));
      });

      test('props is empty list', () {
        const state = CacheInitial();
        expect(state.props, isEmpty);
      });
    });

    group('CacheLoading', () {
      test('supports value equality', () {
        const state1 = CacheLoading();
        const state2 = CacheLoading();

        expect(state1, equals(state2));
      });

      test('props is empty list', () {
        const state = CacheLoading();
        expect(state.props, isEmpty);
      });
    });

    group('CacheLoaded', () {
      test('supports value equality', () {
        const state1 = CacheLoaded(totalFiles: 10, sizeInMB: 5.5);
        const state2 = CacheLoaded(totalFiles: 10, sizeInMB: 5.5);

        expect(state1, equals(state2));
      });

      test('supports inequality when totalFiles differs', () {
        const state1 = CacheLoaded(totalFiles: 10, sizeInMB: 5.5);
        const state2 = CacheLoaded(totalFiles: 20, sizeInMB: 5.5);

        expect(state1, isNot(equals(state2)));
      });

      test('supports inequality when sizeInMB differs', () {
        const state1 = CacheLoaded(totalFiles: 10, sizeInMB: 5.5);
        const state2 = CacheLoaded(totalFiles: 10, sizeInMB: 10.0);

        expect(state1, isNot(equals(state2)));
      });

      test('props contains totalFiles and sizeInMB', () {
        const state = CacheLoaded(totalFiles: 10, sizeInMB: 5.5);
        expect(state.props, [10, 5.5]);
      });

      test('copyWith returns new instance with updated totalFiles', () {
        const original = CacheLoaded(totalFiles: 10, sizeInMB: 5.5);
        final updated = original.copyWith(totalFiles: 20);

        expect(updated.totalFiles, 20);
        expect(updated.sizeInMB, 5.5);
      });

      test('copyWith returns new instance with updated sizeInMB', () {
        const original = CacheLoaded(totalFiles: 10, sizeInMB: 5.5);
        final updated = original.copyWith(sizeInMB: 10.0);

        expect(updated.totalFiles, 10);
        expect(updated.sizeInMB, 10.0);
      });

      test('copyWith returns new instance with all values updated', () {
        const original = CacheLoaded(totalFiles: 10, sizeInMB: 5.5);
        final updated = original.copyWith(totalFiles: 20, sizeInMB: 10.0);

        expect(updated.totalFiles, 20);
        expect(updated.sizeInMB, 10.0);
      });

      test('copyWith preserves values when not provided', () {
        const original = CacheLoaded(totalFiles: 10, sizeInMB: 5.5);
        final updated = original.copyWith();

        expect(updated.totalFiles, 10);
        expect(updated.sizeInMB, 5.5);
      });

      test('toString returns formatted string', () {
        const state = CacheLoaded(totalFiles: 10, sizeInMB: 5.567);
        expect(state.toString(), 'CacheLoaded(totalFiles: 10, sizeInMB: 5.57)');
      });

      test('toString respects decimal places constant', () {
        const state = CacheLoaded(totalFiles: 1, sizeInMB: 1.234567);
        // Should round to 2 decimal places
        expect(state.toString(), contains('1.23'));
      });
    });

    group('CacheCleared', () {
      test('supports value equality', () {
        const state1 = CacheCleared();
        const state2 = CacheCleared();

        expect(state1, equals(state2));
      });

      test('props is empty list', () {
        const state = CacheCleared();
        expect(state.props, isEmpty);
      });
    });

    group('CacheError', () {
      test('supports value equality', () {
        const state1 = CacheError(message: 'Test error');
        const state2 = CacheError(message: 'Test error');

        expect(state1, equals(state2));
      });

      test('supports inequality when message differs', () {
        const state1 = CacheError(message: 'Test error 1');
        const state2 = CacheError(message: 'Test error 2');

        expect(state1, isNot(equals(state2)));
      });

      test('props contains message', () {
        const state = CacheError(message: 'Test error');
        expect(state.props, ['Test error']);
      });

      test('toString returns formatted string', () {
        const state = CacheError(message: 'Something went wrong');
        expect(state.toString(), 'CacheError(message: Something went wrong)');
      });
    });

    group('CacheState.decimalPlaces', () {
      test('decimalPlaces constant is 2', () {
        expect(CacheState.decimalPlaces, 2);
      });
    });
  });
}
