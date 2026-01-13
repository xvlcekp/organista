import 'package:flutter/material.dart';
import 'package:organista/features/show_music_sheet/view/back_button_widget.dart';
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
    return Stack(
      children: [
        PhotoView.customChild(
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.contained * _maxScaleMultiplier,
          initialScale: PhotoViewComputedScale.contained,
          child: child,
        ),
        const BackButtonWidget(),
      ],
    );
  }
}
