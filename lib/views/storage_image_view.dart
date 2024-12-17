import 'dart:typed_data';

import 'package:flutter/material.dart';

class StorageImageView extends StatelessWidget {
  final Future<Uint8List?> imageFuture;

  const StorageImageView({
    super.key,
    required this.imageFuture,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: imageFuture, // Use the cached future
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
        );
      },
    );
  }
}
