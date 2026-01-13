import 'package:flutter/material.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

class BackButtonWidget extends StatelessWidget {
  static const double opacity = 0.5;
  static const double padding = 8.0;

  const BackButtonWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + BackButtonWidget.padding,
      left: BackButtonWidget.padding,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: BackButtonWidget.opacity),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: context.loc.back,
        ),
      ),
    );
  }
}
