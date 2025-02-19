import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Config {
  static Map<String, dynamic>? _config;

  static Future<void> load() async {
    final jsonString = await rootBundle.loadString('assets/config/credentials.json');
    _config = json.decode(jsonString);
  }

  static String? get(String key) {
    return _config?[key];
  }
}
