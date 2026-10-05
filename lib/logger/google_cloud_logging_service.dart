import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:googleapis/logging/v2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:organista/config/app_constants.dart';
import 'package:organista/config/config_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

class GoogleCloudLoggingService {
  LoggingApi? _loggingApi;
  http.Client? _authClient; // Store to allow cleanup
  String? _projectId;

  /// Cloud Logging is only written in release, so `dev` marks debug/profile builds should that ever change.
  static const String _environment = kReleaseMode ? 'prod' : 'dev';

  /// Identifies one app launch, so all entries of a session can be filtered together in Logs Explorer.
  final String _sessionId = const Uuid().v4();

  /// Firebase uid of the signed-in user, set by `AuthBloc`; null while logged out.
  String? userId;

  /// Labels that are the same for the whole session (app version, platform), resolved during setup.
  Map<String, String> _sessionLabels = const {};

  /// Entries waiting to be sent. Every log line used to be its own authenticated HTTPS request, so entries are
  /// buffered and written in one batch, either when the timer fires or right away for errors.
  final List<LogEntry> _pendingEntries = [];
  Timer? _flushTimer;

  bool get isSetup => _loggingApi != null && _projectId != null;

  Future<void> setupLoggingApi() async {
    if (isSetup) return;

    try {
      await ConfigController.load();
      final credentialsJson = ConfigController.get('googleLoggingToken');

      if (credentialsJson == null || credentialsJson.isEmpty) {
        debugPrint('Google Logging credentials not found in config');
        return;
      }

      final serviceAccountCredentials = jsonDecode(credentialsJson) as Map<String, dynamic>;
      _projectId = serviceAccountCredentials['project_id'] as String?;

      if (_projectId == null || _projectId!.isEmpty) {
        debugPrint('Project ID not found in service account credentials');
        return;
      }

      final credentials = ServiceAccountCredentials.fromJson(serviceAccountCredentials);

      _authClient = await clientViaServiceAccount(
        credentials,
        [LoggingApi.loggingWriteScope],
      );

      _loggingApi = LoggingApi(_authClient!);

      final packageInfo = await PackageInfo.fromPlatform();
      _sessionLabels = {
        'app_version': '${packageInfo.version}+${packageInfo.buildNumber}',
        'platform': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
      };

      debugPrint('Cloud Logging API setup complete for project: $_projectId');
    } catch (error, stackTrace) {
      debugPrint('Error setting up Cloud Logging API: $error\n$stackTrace');
      // Clean up partial state
      dispose();
    }
  }

  void writeLog({required Level level, required String message}) {
    if (!isSetup) {
      debugPrint('Cannot write log: Cloud Logging API is not setup');
      return;
    }

    final labels = <String, String>{
      'project_id': _projectId!,
      'level': level.name.toUpperCase(),
      'environment': _environment,
      'session_id': _sessionId,
      ..._sessionLabels,
    };

    if (userId != null) labels['user_id'] = userId!;

    _pendingEntries.add(
      LogEntry()
        ..logName = 'projects/$_projectId/logs/$_environment'
        ..jsonPayload = {'message': message}
        ..resource = (MonitoredResource()..type = 'global')
        ..severity = _mapLevelToSeverity(level)
        ..labels = labels
        ..timestamp = DateTime.now().toUtc().toIso8601String(),
    );

    if (level.value >= Level.error.value || _pendingEntries.length >= AppConstants.cloudLoggingBatchSize) {
      unawaited(flush());
    } else {
      _flushTimer ??= Timer(AppConstants.cloudLoggingFlushInterval, () => unawaited(flush()));
    }
  }

  /// Sends all buffered entries now. Also called when the app is paused, so entries are not lost if the OS
  /// kills the backgrounded app before the timer fires.
  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_pendingEntries.isEmpty || !isSetup) return;

    final entries = List<LogEntry>.of(_pendingEntries);
    _pendingEntries.clear();

    try {
      await _loggingApi!.entries.write(WriteLogEntriesRequest()..entries = entries);
    } catch (error, stackTrace) {
      debugPrint('Error writing ${entries.length} log entries: $error\n$stackTrace');
    }
  }

  String _mapLevelToSeverity(Level level) {
    return switch (level) {
      Level.fatal => 'CRITICAL',
      Level.error => 'ERROR',
      Level.warning => 'WARNING',
      Level.info => 'INFO',
      Level.debug => 'DEBUG',
      _ => 'NOTICE',
    };
  }

  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _pendingEntries.clear();
    _authClient?.close();
    _authClient = null;
    _loggingApi = null;
    _projectId = null;
  }
}
