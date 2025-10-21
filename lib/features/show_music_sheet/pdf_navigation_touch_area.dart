import 'package:flutter/material.dart';
import 'package:organista/config/app_constants.dart';

class PdfNavigationTouchArea extends StatelessWidget {
  const PdfNavigationTouchArea({
    super.key,
    required this.direction,
    required this.onTap,
  });

  final NavigationDirection direction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTop = direction == NavigationDirection.top;
    const arrowSize = 20.0;
    const gradientMid = 100;
    const gradientMax = 150;
    const paddingMax = 16.0;
    final greenWithGradientMax = Colors.green.withAlpha(gradientMax);

    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * AppConstants.nextPagetouchAreaHeight,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onTap(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isTop ? Alignment.bottomCenter : Alignment.topCenter,
              end: isTop ? Alignment.topCenter : Alignment.bottomCenter,
              colors: [
                Colors.white.withAlpha(0),
                Colors.green.withAlpha(gradientMid),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (isTop) const Expanded(child: SizedBox()),
                if (!isTop)
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      color: greenWithGradientMax,
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: paddingMax,
                        top: isTop ? 0 : paddingMax,
                        bottom: isTop ? paddingMax : 0,
                      ),
                      child: Icon(
                        isTop ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.green,
                        size: arrowSize,
                      ),
                    ),
                  ],
                ),
                if (isTop)
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      color: greenWithGradientMax,
                    ),
                  ),
                if (!isTop) const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum NavigationDirection { top, bottom }
