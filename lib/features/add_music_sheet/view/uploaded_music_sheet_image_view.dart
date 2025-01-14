import 'dart:typed_data';
import 'package:flutter/material.dart';

class UploadedMusicSheetImageView extends StatelessWidget {
  const UploadedMusicSheetImageView({
    super.key,
    required this.image,
  });

  final Uint8List image;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      image,
      fit: BoxFit.fitHeight,
    );
  }
}
