import 'package:flutter/material.dart';

class SizeUtils {
  /// Calculates dimensions that fit within [maxSide] while maintaining aspect ratio.
  ///
  /// [width] and [height] are the original dimensions.
  /// [maxSide] is the maximum allowed length for either dimension.
  static Size calculateRenderSize(double width, double height, double maxSide) {
    if (width <= 0 || height <= 0) {
      return Size.zero;
    }

    final double aspectRatio = width / height;

    if (width <= maxSide && height <= maxSide) {
      return Size(width, height);
    }

    if (width > height) {
      return Size(maxSide, maxSide / aspectRatio);
    } else {
      return Size(maxSide * aspectRatio, maxSide);
    }
  }
}
