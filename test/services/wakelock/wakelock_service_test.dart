import 'package:flutter_test/flutter_test.dart';
import 'package:organista/services/wakelock/wakelock_service.dart';

void main() {
  group('WakelockService', () {
    group('MockWakelockService', () {
      late MockWakelockService mockService;

      setUp(() {
        mockService = MockWakelockService();
      });

      test('implements WakelockService interface', () {
        expect(mockService, isA<WakelockService>());
      });

      test('starts with wakelock disabled', () async {
        expect(await mockService.isEnabled, false);
      });

      test('can enable wakelock', () async {
        await mockService.enable();
        expect(await mockService.isEnabled, true);
      });

      test('can disable wakelock', () async {
        await mockService.enable();
        expect(await mockService.isEnabled, true);

        await mockService.disable();
        expect(await mockService.isEnabled, false);
      });

      test('maintains state correctly through multiple operations', () async {
        // Start disabled
        expect(await mockService.isEnabled, false);

        // Enable
        await mockService.enable();
        expect(await mockService.isEnabled, true);

        // Enable again (should stay enabled)
        await mockService.enable();
        expect(await mockService.isEnabled, true);

        // Disable
        await mockService.disable();
        expect(await mockService.isEnabled, false);

        // Disable again (should stay disabled)
        await mockService.disable();
        expect(await mockService.isEnabled, false);
      });
    });

    group('WakelockPlusService', () {
      test('implements WakelockService interface', () {
        final service = WakelockPlusService();
        expect(service, isA<WakelockService>());
      });

      // Note: We can't easily test the actual WakelockPlus calls without platform channels
      // in a unit test environment. These would be tested through integration tests.
    });
  });
}
