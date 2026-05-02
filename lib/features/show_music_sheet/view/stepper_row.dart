import 'package:flutter/material.dart';

class StepperRow extends StatelessWidget {
  const StepperRow({
    super.key,
    required this.icon,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
    required this.onReset,
    required this.colorScheme,
  });

  final IconData icon;
  final String value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onReset;
  final ColorScheme colorScheme;

  static const double _kValueWidth = 36.0;
  static const double _kIconSize = 20.0;
  static const double _kBorderRadius = 4.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.primary, size: _kIconSize),
          IconButton(
            icon: Icon(Icons.remove, color: colorScheme.onSurfaceVariant),
            onPressed: onDecrease,
          ),
          InkWell(
            onTap: onReset,
            borderRadius: BorderRadius.circular(_kBorderRadius),
            child: SizedBox(
              width: _kValueWidth,
              child: Text(
                value,
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: colorScheme.onSurfaceVariant),
            onPressed: onIncrease,
          ),
        ],
      ),
    );
  }
}
