import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:organista/logger/custom_filter.dart';
import 'package:organista/logger/google_cloud_logging_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

CustomLogger get logger => CustomLogger.instance;

class CustomLogger extends Logger {
  final _googleCloudLoggingService = GoogleCloudLoggingService();

  // Stack trace configuration for PrettyPrinter
  static const int _noStackTraceMethodCount = 0; // No stack traces for debug/info/warning
  static const int _errorStackTraceMethodCount = 8; // Show stack traces for errors

  CustomLogger._()
    : super(
        filter: CustomFilter(),
        // Use SimplePrinter in release mode to reduce overhead
        printer: kDebugMode
            ? PrettyPrinter(
                methodCount: _noStackTraceMethodCount,
                errorMethodCount: _errorStackTraceMethodCount,
              )
            : SimplePrinter(),
      ) {
    Logger.addOutputListener((event) {
      if (kReleaseMode) {
        // Only write logs to Cloud Logging in release mode
        _googleCloudLoggingService.writeLog(
          level: event.level,
          message: event.lines.join(
            '\n',
          ), // Join the log lines with a new line, so that it is written as a single message
        );
        debugPrint('App will log output to Cloud Logging');
      }
    });
  }

  @override
  void log(
    Level level,
    // ignore: avoid-dynamic, This should be removed, but I am not sure if there are other errors than string
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    super.log(level, message, time: time, error: error, stackTrace: stackTrace);

    // Automatically report to Sentry if level is Error or Fatal
    if (level == Level.error || level == Level.fatal) {
      Sentry.captureException(
        error ?? message,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('logger_level', level.name);
          if (message != null && error != null) {
            scope.setContexts('logger_message', {'content': message.toString()});
          }
        },
      );
    }
  }

  static final instance = CustomLogger._();

  Future<void> setup() async {
    await _googleCloudLoggingService.setupLoggingApi();
  }
}
