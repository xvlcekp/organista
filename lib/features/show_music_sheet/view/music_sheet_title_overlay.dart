import 'package:flutter/material.dart';
import 'package:organista/config/app_theme.dart';

class MusicSheetTitleOverlay extends StatelessWidget {
  final String fileName;
  final VoidCallback onDismiss;

  const MusicSheetTitleOverlay({
    super.key,
    required this.fileName,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: AppTheme.symmetricOverlayPadding,
      left: AppTheme.symmetricOverlayPadding,
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.onSurface,
            borderRadius: BorderRadius.circular(AppTheme.inputBorderRadius),
          ),
          child: Text(
            fileName,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
