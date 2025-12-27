import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/utils/size_utils.dart';

void main() {
  group('SizeUtils Logic Tests', () {
    test('calculateRenderSize returns original size if within maxSide', () {
      const pageWidth = 100.0;
      const pageHeight = 150.0;
      const maxSide = 200.0;

      final result = SizeUtils.calculateRenderSize(pageWidth, pageHeight, maxSide);

      expect(result, const Size(pageWidth, pageHeight));
    });

    test('calculateRenderSize scales down correctly for landscape (width > height)', () {
      const pageWidth = 400.0;
      const pageHeight = 200.0;
      const maxSide = 200.0;

      // Aspect ratio = 2.0
      // Width should be maxSide (200), Height should be 200 / 2 = 100
      final result = SizeUtils.calculateRenderSize(pageWidth, pageHeight, maxSide);

      expect(result, const Size(200.0, 100.0));
    });

    test('calculateRenderSize scales down correctly for portrait (height > width)', () {
      const pageWidth = 200.0;
      const pageHeight = 400.0;
      const maxSide = 200.0;

      // Aspect ratio = 0.5
      // Height should be maxSide (200), Width should be 200 * 0.5 = 100
      final result = SizeUtils.calculateRenderSize(pageWidth, pageHeight, maxSide);

      expect(result, const Size(100.0, 200.0));
    });

    test('calculateRenderSize scales down correctly for square', () {
      const pageWidth = 400.0;
      const pageHeight = 400.0;
      const maxSide = 200.0;

      final result = SizeUtils.calculateRenderSize(pageWidth, pageHeight, maxSide);

      expect(result, const Size(200.0, 200.0));
    });

    test('calculateRenderSize handles very large dimensions (OOM prevention)', () {
      const pageWidth = 4000.0;
      const pageHeight = 6000.0;
      const maxSide = 2000.0;

      // Similar to the user's reported OOM scenario
      // Aspect ratio = 4000/6000 = 0.666...
      // Height > Width, so Height = maxSide (2000)
      // Width = 2000 * 0.666... = 1333.333...

      final result = SizeUtils.calculateRenderSize(pageWidth, pageHeight, maxSide);

      expect(result.height, 2000.0);
      expect(result.width, closeTo(1333.33, 0.01));
    });
  });
}
