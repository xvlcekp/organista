import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/models/users/user_info_key.dart';

@immutable
class UserInfo extends MapView<String, String?> with EquatableMixin {
  final String userId;
  final String displayName;
  final String? email;

  UserInfo({
    required this.userId,
    required this.displayName,
    required this.email,
  }) : super(
          {
            UserInfoKey.userId: userId,
            UserInfoKey.displayName: displayName,
            UserInfoKey.email: email,
          },
        );

  UserInfo.fromJson(
    Map<String, dynamic> json, {
    required String userId,
  }) : this(
          userId: userId,
          displayName: json[UserInfoKey.displayName] ?? '',
          email: json[UserInfoKey.email],
        );

  @override
  List<Object?> get props {
    return [
      userId,
      displayName,
      email,
    ];
  }
}

// TODO: add payload from Vandad's github