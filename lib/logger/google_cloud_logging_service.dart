import 'package:flutter/foundation.dart';
import 'package:googleapis/logging/v2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:logger/logger.dart';

// Define constants for authentication and project identification
const _serviceAccountCredentials = {
  "type": "service_account",
  "project_id": "organista-project",
  "private_key_id": "5c07b9351403c6a764592294f91d4fcd708f1c31",
  "private_key":
      "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC9lRMI5kZwrWMY\n3AVh4bHkLiI4IAAHKUCKe5A6f9MH+Dh4QeRDsYP5Zg94Btr1SXoVHp17TRVvFPm/\n/uOz2xmUO7xWNH0Lxm+aDYVYnIe74LcU4XKWuJ2wZ4/gU55eYVVQtX9Ekp9XNGIe\n+I08i0aVzKZY1647mJT+Tz2RtS3qRSPPmjF7LlhTy5Kx5MUFtVGv3K3bCGPtTDmn\nlIm3goVy2QpLGkIG04qx9F7k+Ktqnj28vD3HZjNgXqYLCAoIBNIi/lUWfl+ddUP6\nGCsjDOH/iM0fdpuO/K6X9Y5Y2vnVFf5dJmJtGbWjhUZP/FFE0DodFP4uomZ3fCe7\ngsF4ycY1AgMBAAECggEAANbM3hTCQejWqJW8l60Nwje/xIIcF4WfN9kdwO2ryW9M\n1ir2UX+GCIWv6nfZpFn9we6+Pb8QOIlLzRut+fkBtDQxTq9zpKE9zh8kZeL5Lpbj\n6BcuNPA5CcJDWiATPwTydnYDEUXT8P8X12VOkKl2SQcZlzSry/De4gBYPPVPo4Mp\nVLX9xAZRZXn815YwAdoshFx69hXglnu6/mUTAv3QXZvmSGCwhl95t3WHD6EHrn2m\nBbxeyW210ZFk+j0R19t8o6fGIaBm5+mrbBJRUHnm1roghGz2D4KXOujGiyN3KVfO\ng5SY1/SMmyrlaY8sbYSa/t51uzL6PQa8SNtKtgVBoQKBgQDl5TamliGpYlKMgcYe\nbaWgZ0icWm8GHJ1lhaY2ZtE4R+YobUZHM9PJYipTP4Eoa9OA+BEZSJeXxfB8OQdb\nrdmdWqfDRpT/WprUTsqMahmpsyJorJSushMC8w7q7AtdUWvz1K6z+UT6lvQ3kBKE\n3OMSy1lzOCBYbB+t/eOy0jytrwKBgQDTHAIjcRRoA3dhmJD9GkWVH42bCgvpZjBz\nPYIqTiX3b5tTGNWaniT/LPN/IHGqJqu4xcjXKCCSJ1RqMdW9kmNaqJqXO7ixFI1B\nPybGA/sWQXX80x2pxiWwRXnVBsa484dEd5mz6ohIT5P5q4aBqJPwAPcHYWgS4fQH\n62Kdu1vHWwKBgQDXrKkPsasUyIwfCyR9qWoHyL2jCWg8+J1k//RF90FypmkzJgkX\nhXS76h9BCEO4UygSRydra+Hj3ivVrn7LsJaGe+UFWvMveKXmZaC6CFPZE5hFURsP\npToWu0YUeKvUuS0ojC/14fWnjfTBJ6VoBf31xNY/NLmLmqxBw/1Y5slMOwKBgGMn\n3qFC9bC9IA+JF2CqPFCEl4BgwaOIyez20PKJ7i9ADpaDLaEH8pygQmZNmNWwgCuz\nSlg0ksfTDUUrzxbRcTUdyC6McH1MB+TDgrSzHfYgHQj5KA+b8AvRNh4mpqQsTjaM\nbnchC43bQsecFvtDcOjjqyOeTsG/u10U5Cbt33fNAoGAYHTTjEKyAf1+2nfHrIgN\ncPk17jAx9vOea8BJ+a+7IKDYshBXDN92hj9BUWY0wg6wAMUa4jMi1nGNo2Ne+wNy\nDFCM7ZNCUgopZwwzDFZhy0yawc1EPP8IvsvjMIYIm7t5bTaQEnOqS30jx+ub6o6M\n/Baa8ginZSq3GjbP60gv34w=\n-----END PRIVATE KEY-----\n",
  "client_email": "flutter-logger@organista-project.iam.gserviceaccount.com",
  "client_id": "109789965676843001574",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/flutter-logger%40organista-project.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
};
const _projectId = 'organista-project'; // Replace with your project ID from the JSON key file

class GoogleCloudLoggingService {
  late LoggingApi _loggingApi; // Instance variable for Cloud Logging API
  bool _isSetup = false; // Indicator to check if the API setup is complete

  // Method to set up the Cloud Logging API
  Future<void> setupLoggingApi() async {
    if (_isSetup) return;

    try {
      // Create credentials using ServiceAccountCredentials
      final credentials = ServiceAccountCredentials.fromJson(
        _serviceAccountCredentials,
      );

      // Authenticate using ServiceAccountCredentials and obtain an AutoRefreshingAuthClient authorized client
      final authClient = await clientViaServiceAccount(
        credentials,
        [LoggingApi.loggingWriteScope],
      );

      // Initialize the Logging API with the authorized client
      _loggingApi = LoggingApi(authClient);

      // Mark the Logging API setup as complete
      _isSetup = true;
      debugPrint('Cloud Logging API setup for $_projectId');
    } catch (error) {
      debugPrint('Error setting up Cloud Logging API $error');
    }
  }

  void writeLog({required Level level, required String message}) {
    if (!_isSetup) {
      // If Logging API is not setup, return
      debugPrint('Cloud Logging API is not setup');
      return;
    }

    // Define environment and log name
    const env = 'dev';
    const logName = 'projects/$_projectId/logs/$env'; // It should in the format projects/[PROJECT_ID]/logs/[LOG_ID]

    // Create a monitored resource
    final resource = MonitoredResource()..type = 'global'; // A global resource type is used for logs that are not associated with a specific resource

    // Map log levels to severity levels
    final severityFromLevel = switch (level) {
      Level.fatal => 'CRITICAL',
      Level.error => 'ERROR',
      Level.warning => 'WARNING',
      Level.info => 'INFO',
      Level.debug => 'DEBUG',
      _ => 'NOTICE',
    };

    // Create a log entry
    final logEntry = LogEntry()
      ..logName = logName
      ..jsonPayload = {'message': message}
      ..resource = resource
      ..severity = severityFromLevel
      ..labels = {
        'project_id': _projectId, // Must match the project ID with the one in the JSON key file
        'level': level.name.toUpperCase(),
        'environment': env, // Optional but useful to filter logs by environment
        'user_id': 'your-app-user-id', // Useful to filter logs by userID
        'app_instance_id': 'your-app-instance-id', // Useful to filter logs by app instance ID e.g device ID + app version (iPhone-12-ProMax-v1.0.0)
      };

    // Create a write log entries request
    final request = WriteLogEntriesRequest()..entries = [logEntry];

    // Write the log entry using the Logging API and handle errors
    _loggingApi.entries.write(request).catchError((error) {
      debugPrint('Error writing log entry $error');
      return WriteLogEntriesResponse();
    });
  }
}
