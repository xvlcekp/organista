import 'package:flutter/material.dart';
import 'package:organista/config/app_theme.dart';

/// The "2/3" badge shown on multi-page sheets (PDF and MusicXML alike).
class PageCounterBadge extends StatelessWidget {
  const PageCounterBadge({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  final int currentPage;
  final int pageCount;

  static const double _kHorizontalPadding = 10;
  static const double _kVerticalPadding = 6;
  static const double _kFontSize = 18;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _kHorizontalPadding, vertical: _kVerticalPadding),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.onSurface,
        borderRadius: BorderRadius.circular(AppTheme.inputBorderRadius),
      ),
      child: Text(
        '$currentPage/$pageCount',
        style: const TextStyle(fontSize: _kFontSize, color: Colors.white),
      ),
    );
  }
}
