import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/models/users/user_info_key.dart';

@immutable
class UserInfo with EquatableMixin {
  final String userId;
  final String displayName;
  final String? email;

  UserInfo({
    required this.userId,
    required Map<String, dynamic> json,
  }) : displayName = json[UserInfoKey.displayName] ?? '',
       email = json[UserInfoKey.email] ?? '';

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
