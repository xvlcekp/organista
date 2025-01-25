import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist_key.dart';

@immutable
class Playlist extends Equatable {
  final String playlistId;
  final String userId;
  final DateTime createdAt;
  final String name;
  final List<MusicSheet> musicSheets;

  Playlist({
    required this.playlistId,
    required Map<String, dynamic> json,
  })  : userId = json[PlaylistKey.userId],
        createdAt = (json[PlaylistKey.createdAt] as Timestamp).toDate(),
        name = json[PlaylistKey.name],
        musicSheets = (json[PlaylistKey.musicSheets] as List<dynamic>).map((record) => MusicSheet(json: record as Map<String, dynamic>)).toList();

  @override
  String toString() => 'Playlist, id = $playlistId, createdAt = $createdAt';

  @override
  List<Object?> get props => [playlistId, userId, createdAt, name, musicSheets];
}
