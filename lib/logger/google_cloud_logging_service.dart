import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:googleapis/logging/v2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:organista/config/config_controller.dart';

class GoogleCloudLoggingService {
  LoggingApi? _loggingApi;
  http.Client? _authClient; // Store to allow cleanup
  String? _projectId;

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

      debugPrint('Cloud Logging API setup complete for project: $_projectId');
    } catch (error, stackTrace) {
      debugPrint('Error setting up Cloud Logging API: $error\n$stackTrace');
      // Clean up partial state
      dispose();
    }
  }

  Future<void> writeLog({
    required Level level,
    required String message,
    String? userId,
    String? appInstanceId,
    String environment = 'dev',
  }) async {
    if (!isSetup) {
      debugPrint('Cannot write log: Cloud Logging API is not setup');
      return;
    }

    try {
      final logName = 'projects/$_projectId/logs/$environment';

      final resource = MonitoredResource()..type = 'global';

      final severity = _mapLevelToSeverity(level);

      final labels = <String, String>{
        'project_id': _projectId!,
        'level': level.name.toUpperCase(),
        'environment': environment,
      };

      if (userId != null) labels['user_id'] = userId;
      if (appInstanceId != null) labels['app_instance_id'] = appInstanceId;

      final logEntry = LogEntry()
        ..logName = logName
        ..jsonPayload = {'message': message}
        ..resource = resource
        ..severity = severity
        ..labels = labels;

      final request = WriteLogEntriesRequest()..entries = [logEntry];

      await _loggingApi!.entries.write(request);
    } catch (error, stackTrace) {
      debugPrint('Error writing log entry: $error\n$stackTrace');
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
    _authClient?.close();
    _authClient = null;
    _loggingApi = null;
    _projectId = null;
  }
}
