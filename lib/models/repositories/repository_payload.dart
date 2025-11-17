import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/models/repositories/repository_key.dart';

@immutable
// Using the dynamic type for a Map<> is considered fine, since there is no better way to declare a type of a JSON payload.
// ignore: avoid-dynamic
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
