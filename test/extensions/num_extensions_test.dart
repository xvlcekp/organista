import 'package:flutter_test/flutter_test.dart';
import 'package:organista/extensions/num_extensions.dart';

void main() {
  group('NumExtensions', () {
    test('bytesToMegaBytes converts bytes to megabytes', () {
      expect(1048576.bytesToMegaBytes, equals(1));
      expect(1572864.bytesToMegaBytes, closeTo(1.5, 1e-9));
    });

    test('megaBytesToBytes converts megabytes to bytes', () {
      expect(1.megaBytesToBytes, equals(1048576));
      expect(1.5.megaBytesToBytes, equals(1572864));
    });

    test('conversion is reversible within precision tolerance', () {
      const bytes = 1234567;
      final megabytes = bytes.bytesToMegaBytes;
      expect(megabytes.megaBytesToBytes, closeTo(bytes, 0.0001));
    });
  });
}
