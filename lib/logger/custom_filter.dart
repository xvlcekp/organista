import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Overrides the default Logger filter so we can log in release mode.
///
/// Debug logs are only kept in debug builds: in release they would just be shipped to Cloud Logging as noise.
class CustomFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return kDebugMode || event.level.value >= Level.info.value;
  }
}
