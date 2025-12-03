import 'package:flutter/material.dart';

/// A visually distinct section header widget for settings and other list views
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
  });

  final String title;
  final IconData? icon;

  static const double _horizontalPadding = 16.0;
  static const double _verticalPadding = 12.0;
  static const double _iconSpacing = 8.0;
  static const double _backgroundOpacity = 0.3;
  static const double _borderOpacity = 0.2;
  static const double _iconSize = 20.0;
  static const double _borderWidth = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Use surfaceContainerHighest for subtle background
    final backgroundColor = colorScheme.surfaceContainerHighest.withValues(
      alpha: _backgroundOpacity,
    );
    final titleStyle = theme.textTheme.titleMedium;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: _verticalPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(
              alpha: _borderOpacity,
            ),
            width: _borderWidth,
          ),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: _iconSize,
              color: colorScheme.primary,
            ),
            const SizedBox(width: _iconSpacing),
          ],
          Text(
            title,
            style: titleStyle,
          ),
        ],
      ),
    );
  }
}

