import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/repositories/repository_key.dart';
import 'package:uuid/uuid.dart';

@immutable
class Repository extends Equatable {
  final String repositoryId;
  final String name;
  final String userId;
  final DateTime createdAt;
  final List<MusicSheet> musicSheets;

  Repository({
    required Map<String, dynamic> json,
  })  : repositoryId = json[RepositoryKey.repositoryId] ?? const Uuid().v4(),
        name = json[RepositoryKey.name] ?? '',
        userId = json[RepositoryKey.userId] ?? '',
        createdAt = (json[RepositoryKey.createdAt] as Timestamp).toDate(),
        musicSheets = (json[RepositoryKey.musicSheets] as List<dynamic>?)?.map((sheet) => MusicSheet(json: sheet as Map<String, dynamic>)).toList() ?? [];

  Map<String, dynamic> toJson() {
    return {
      RepositoryKey.repositoryId: repositoryId,
      RepositoryKey.name: name,
      RepositoryKey.userId: userId,
      RepositoryKey.createdAt: Timestamp.fromDate(createdAt),
      RepositoryKey.musicSheets: musicSheets.map((sheet) => sheet.toJson()).toList(),
    };
  }

  Repository copyWith({
    String? name,
    List<MusicSheet>? musicSheets,
  }) {
    return Repository(
      json: {
        RepositoryKey.repositoryId: repositoryId,
        RepositoryKey.name: name ?? this.name,
        RepositoryKey.userId: userId,
        RepositoryKey.createdAt: Timestamp.fromDate(createdAt),
        RepositoryKey.musicSheets: musicSheets?.map((sheet) => sheet.toJson()).toList() ?? this.musicSheets.map((sheet) => sheet.toJson()).toList(),
      },
    );
  }

  bool get isPrivate => userId != '';

  @override
  String toString() => 'Repository, repositoryId = $repositoryId, name = $name';

  @override
  List<Object?> get props => [
        repositoryId,
        name,
        userId,
        createdAt,
        musicSheets,
      ];
}
