import 'package:flutter/material.dart';

/// A reusable widget to display an empty state with an icon and two text messages
class EmptyListWidget extends StatelessWidget {
  static const double _iconSize = 64;

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceVariantColor = theme.colorScheme.onSurfaceVariant;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: _iconSize,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: surfaceVariantColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: surfaceVariantColor,
            ),
          ),
        ],
      ),
    );
  }
}
