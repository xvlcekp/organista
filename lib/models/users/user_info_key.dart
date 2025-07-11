import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/models/firebase_common_keys.dart';

@immutable
class UserInfoKey {
  static const userId = FirebaseCommonKeys.userId;
  static const createdAt = FirebaseCommonKeys.createdAt;
  static const displayName = 'display_name';
  static const email = 'email';
  const UserInfoKey._();
}
