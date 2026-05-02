import 'package:flutter/material.dart';
import 'package:organista/config/app_theme.dart';

class DismissableTitle extends StatelessWidget {
  final String title;
  final VoidCallback onDismiss;

  const DismissableTitle({
    super.key,
    required this.title,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.onSurface,
          borderRadius: BorderRadius.circular(AppTheme.inputBorderRadius),
        ),
        child: Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
