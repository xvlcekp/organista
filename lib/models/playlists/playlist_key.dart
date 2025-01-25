import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/models/firebase_common_keys.dart';

@immutable
class PlaylistKey {
  static const userId = FirebaseCommonKeys.userId;
  static const createdAt = FirebaseCommonKeys.createdAt;
  static const name = 'name';
  static const musicSheets = 'musicSheets';

  const PlaylistKey._();
}
