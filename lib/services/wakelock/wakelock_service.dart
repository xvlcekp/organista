import 'package:organista/logger/custom_logger.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Abstract interface for wakelock functionality
abstract class WakelockService {
  /// Enable wakelock to keep the screen on
  Future<void> enable();

  /// Disable wakelock to allow normal screen timeout
  Future<void> disable();

  /// Get current wakelock status
  Future<bool> get isEnabled;
}

/// Implementation of WakelockService using wakelock_plus package
class WakelockPlusService implements WakelockService {
  @override
  Future<void> enable() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      logger.e('Error enabling wakelock', error: e);
      rethrow;
    }
  }

  @override
  Future<void> disable() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      logger.e('Error disabling wakelock', error: e);
      rethrow;
    }
  }

  @override
  Future<bool> get isEnabled async {
    try {
      return await WakelockPlus.enabled;
    } catch (e) {
      logger.e('Error getting wakelock status', error: e);
      return false;
    }
  }
}

/// Mock implementation for testing
class MockWakelockService implements WakelockService {
  bool _isEnabled = false;

  @override
  Future<void> enable() async {
    _isEnabled = true;
  }

  @override
  Future<void> disable() async {
    _isEnabled = false;
  }

  @override
  Future<bool> get isEnabled async => _isEnabled;
}
