import 'package:flutter/material.dart';

enum SwitchImageSide { left, right }

class SwitchImage extends StatelessWidget {
  final IconData icon;
  final VoidCallback switchImage;
  final SwitchImageSide side;

  const SwitchImage({super.key, required this.icon, required this.switchImage, required this.side});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: side == SwitchImageSide.left ? 16 : null,
      right: side == SwitchImageSide.right ? 16 : null,
      top: MediaQuery.of(context).size.height / 2 - 24,
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 48),
        onPressed: switchImage,
      ),
    );
  }
}
