import 'dart:ui';

extension HexColor on Color {
  // Constants to avoid magic numbers
  static const int _maxColorValue = 255;
  static const int _hexRadix = 16;
  static const int _hexDigitWidth = 2;
  static const String _paddingChar = '0';

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) =>
      '${leadingHashSign ? '#' : ''}'
      '${(a * _maxColorValue).round().toRadixString(_hexRadix).padLeft(_hexDigitWidth, _paddingChar)}'
      '${(r * _maxColorValue).round().toRadixString(_hexRadix).padLeft(_hexDigitWidth, _paddingChar)}'
      '${(g * _maxColorValue).round().toRadixString(_hexRadix).padLeft(_hexDigitWidth, _paddingChar)}'
      '${(b * _maxColorValue).round().toRadixString(_hexRadix).padLeft(_hexDigitWidth, _paddingChar)}';
}
