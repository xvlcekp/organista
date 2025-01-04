import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:organista/logger/custom_filter.dart';
import 'package:organista/logger/custom_pretty_printer.dart';
import 'package:organista/logger/google_cloud_logging_service.dart';

CustomLogger get logger => CustomLogger.instance;

class CustomLogger extends Logger {
  final _googleCloudLoggingService = GoogleCloudLoggingService();
  CustomLogger._()
      : super(
          filter: CustomFilter(),
          printer: CustomPrettyPrinter(),
        ) {
    Logger.addOutputListener((event) {
      if (kReleaseMode) {
        // Only write logs to Cloud Logging in release mode
        _googleCloudLoggingService.writeLog(
          level: event.level,
          message: event.lines.join('\n'), // Join the log lines with a new line, so that it is written as a single message
        );
        debugPrint('App will log output to Cloud Logging');
      }
    });
  }
  static final instance = CustomLogger._();

  Future<void> setup() async {
    await enableCrashlytics();
    await _googleCloudLoggingService.setupLoggingApi();
  }

  Future<void> enableCrashlytics() async {
    // Enable Firebase crashlytics
    FlutterError.onError = (FlutterErrorDetails details) {
      FirebaseCrashlytics.instance.recordFlutterError(details);
    };
  }
}
