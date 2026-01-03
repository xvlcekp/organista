import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

/// A reusable widget to display an empty state with an icon and two text messages
class EmptyListWidget extends StatefulWidget {
  static const double _iconSize = 64;
  static const double _bounceOffset = 12.0;
  static const double _arrowBottomOffset = 130.0;
  static const double _arrowRightPadding = 10.0;
  static const double _textHorizontalPadding = 16.0;

  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyListWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  State<EmptyListWidget> createState() => _EmptyListWidgetState();
}

class _EmptyListWidgetState extends State<EmptyListWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController = AnimationController(
    duration: const Duration(milliseconds: 1000),
    vsync: this,
  )..repeat(reverse: true);

  // ignore: avoid-late-keyword, reason: Animation needs to reference the controller
  late final Animation<double> _bounceAnimation =
      Tween<double>(
        begin: 0.0,
        end: EmptyListWidget._bounceOffset,
      ).animate(
        CurvedAnimation(
          parent: _bounceController,
          curve: Curves.easeInOut,
        ),
      );

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceVariantColor = theme.colorScheme.onSurfaceVariant;
    final primaryColor = theme.colorScheme.primary;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EmptyListWidget._textHorizontalPadding,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: EmptyListWidget._iconSize,
                  color: primaryColor,
                ),
                const SizedBox(height: 16),
                AutoSizeText(
                  widget.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: surfaceVariantColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                AutoSizeText(
                  widget.subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: surfaceVariantColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: EmptyListWidget._arrowBottomOffset,
          right: EmptyListWidget._arrowRightPadding,
          child: AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: child,
              );
            },
            child: Icon(
              Icons.arrow_downward,
              size: EmptyListWidget._iconSize,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
