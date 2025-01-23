import 'dart:collection' show MapView;

import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/models/users/user_info_key.dart';

@immutable
class UserInfoPayload extends MapView<String, String> {
  UserInfoPayload({
    required String userId,
    required String? displayName,
    required String? email,
  }) : super(
          {
            UserInfoKey.userId: userId,
            UserInfoKey.displayName: displayName ?? '',
            UserInfoKey.email: email ?? '',
          },
        );
}
