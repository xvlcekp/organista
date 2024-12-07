import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:organista/managers/image_cache_manager.dart';

class StorageImageView extends StatelessWidget {
  final Reference image;
  final ImageCacheManager cacheManager;

  const StorageImageView({
    super.key,
    required this.image,
    required this.cacheManager,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: cacheManager.loadImage(image),
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
