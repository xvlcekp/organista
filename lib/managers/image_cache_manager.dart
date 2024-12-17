import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class ImageCacheManager extends ValueNotifier<Map<Reference, Uint8List>> {
  // probably doesn't need to be value notifier
  ImageCacheManager._sharedInstance() : super({});
  static final ImageCacheManager _shared = ImageCacheManager._sharedInstance();
  factory ImageCacheManager() => _shared;

  Future<Uint8List?> loadImage(Reference reference) async {
    if (value.containsKey(reference)) {
      return value[reference];
    }

    final data = await reference.getData();

    if (data != null) {
      value[reference] = data;
    }
    return data;
  }
}
