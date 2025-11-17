import 'package:flutter/material.dart';

class OrganistaLogo extends StatelessWidget {
  const OrganistaLogo({super.key});

  final double logoSize = 80.0;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/organista_icon_200x200.png',
      width: logoSize,
      height: logoSize,
    );
  }
}
