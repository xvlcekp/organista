import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Config {
  static Map<String, dynamic>? _config;

  static Future<void> load() async {
    final jsonString = await rootBundle.loadString('assets/config/credentials.json');
    _config = json.decode(jsonString);
  }

  /// Retrieves a configuration value by key.
  /// If the value is a Map or List, it returns the JSON encoded string.
  /// Otherwise, it returns the string representation of the value.
  static String? get(String key) {
    final value = _config?[key];
    if (value is Map || value is List) {
      // If the value is a Map or List, return the JSON encoded string
      return json.encode(value);
    }
    return value?.toString();
  }
}
