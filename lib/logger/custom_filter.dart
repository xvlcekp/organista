import 'package:logger/logger.dart';

/// This class is use to override the default
/// Logger Filter. So we can log in release mode.
class CustomFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}
