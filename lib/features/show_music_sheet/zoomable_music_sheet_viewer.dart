import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ZoomableMusicSheetViewer extends StatelessWidget {
  final Widget child;

  const ZoomableMusicSheetViewer({
    super.key,
    required this.child,
  });

  static const double _maxScaleMultiplier = 3.0;

  @override
  Widget build(BuildContext context) {
    return PhotoView.customChild(
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.contained * _maxScaleMultiplier,
      initialScale: PhotoViewComputedScale.contained,
      child: child,
    );
  }
}
