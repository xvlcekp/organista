import 'package:flutter/foundation.dart' show immutable;

@immutable
class UserInfoKey {
  static const userId = 'uid';
  static const displayName = 'display_name';
  static const email = 'email';
  const UserInfoKey._();
}
