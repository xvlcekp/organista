import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/models/repositories/repository_key.dart';

@immutable
class RepositoryPayload extends MapView<String, dynamic> {
  RepositoryPayload({
    required String name,
    required String userId,
  }) : super(
          {
            RepositoryKey.name: name,
            RepositoryKey.userId: userId,
            RepositoryKey.createdAt: FieldValue.serverTimestamp(),
          },
        );
}
