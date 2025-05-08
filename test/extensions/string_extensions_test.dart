import 'package:flutter_test/flutter_test.dart';
import 'package:organista/extensions/string_extensions.dart';

void main() {
  group('SequenceId extension', () {
    test('should extract sequence ID from filename starting with numbers', () {
      expect('123_Test_Sheet.pdf'.sequenceId, 123);
      expect('1_Another_Sheet.pdf'.sequenceId, 1);
      expect('42_Sheet.pdf'.sequenceId, 42);
    });

    test('should return 0 for filenames without leading numbers', () {
      expect('Test_Sheet.pdf'.sequenceId, 0);
      expect('Another_Sheet.pdf'.sequenceId, 0);
      expect('Sheet.pdf'.sequenceId, 0);
    });

    test('should handle filenames with numbers in the middle', () {
      expect('Test_123_Sheet.pdf'.sequenceId, 0);
      expect('Sheet_42.pdf'.sequenceId, 0);
      expect('Test_1_2_3.pdf'.sequenceId, 0);
    });

    test('should handle empty strings', () {
      expect(''.sequenceId, 0);
    });

    test('should handle filenames with only numbers', () {
      expect('123.pdf'.sequenceId, 123);
      expect('1.pdf'.sequenceId, 1);
      expect('42.pdf'.sequenceId, 42);
    });

    test('should handle filenames with leading zeros', () {
      expect('001_Test_Sheet.pdf'.sequenceId, 1);
      expect('042_Sheet.pdf'.sequenceId, 42);
      expect('0001.pdf'.sequenceId, 1);
    });

    test('should handle filenames with special characters', () {
      expect('123-Test_Sheet.pdf'.sequenceId, 123);
      expect('42@Sheet.pdf'.sequenceId, 42);
      expect('1#Test.pdf'.sequenceId, 1);
    });
  });
}
