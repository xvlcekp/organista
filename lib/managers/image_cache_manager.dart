import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class ImageCacheManager {
  final Map<Reference, Uint8List> _cache = {};

  Future<Uint8List?> loadImage(Reference reference) async {
    if (_cache.containsKey(reference)) {
      return _cache[reference];
    }

    final data = await reference.getData();

    if (data != null) {
      _cache[reference] = data;
    }
    return data;
  }
}
