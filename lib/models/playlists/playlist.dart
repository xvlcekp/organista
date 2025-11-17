import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/config/app_constants.dart';
import 'package:organista/features/show_playlist/error/playlist_error.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist_key.dart';

@immutable
class Playlist extends Equatable {
  final String playlistId;
  final String userId;
  final DateTime createdAt;
  final String name;
  final List<MusicSheet> musicSheets;

  // Empty Constructor
  factory Playlist.empty() {
    return Playlist(playlistId: '1', json: const {});
  }

  Playlist({
    required this.playlistId,
    required Map<String, dynamic> json,
  }) : userId = json[PlaylistKey.userId] ?? '',
       createdAt = ((json[PlaylistKey.createdAt] ?? Timestamp(0, 0)) as Timestamp).toDate(),
       name = json[PlaylistKey.name] ?? '',
       // Using the dynamic type for a Map<> is considered fine, since there is no better way to declare a type of a JSON payload.
       // ignore: avoid-dynamic
       musicSheets = ((json[PlaylistKey.musicSheets] ?? []) as List<dynamic>)
           .map((record) => MusicSheet(json: record as Map<String, dynamic>))
           .toList();

  @override
  String toString() => 'Playlist, id = $playlistId, createdAt = $createdAt';

  @override
  List<Object?> get props => [playlistId, userId, createdAt, name, musicSheets];

  List<Map<String, dynamic>> toMusicSheetJson() => musicSheets.map((sheet) => sheet.toJson()).toList();

  /// Validates if adding new music sheets would exceed playlist capacity
  /// Throws PlaylistCapacityExceededError if validation fails
  void validateCapacityForAdding(
    int newMusicSheetsCount, {
    int? maxCapacity,
  }) {
    final currentCount = musicSheets.length;
    final capacity = maxCapacity ?? AppConstants.maxPlaylistCapacity;
    final wouldExceedCapacity = currentCount + newMusicSheetsCount > capacity;

    if (wouldExceedCapacity) {
      throw PlaylistCapacityExceededError(
        playlist: this,
        attemptedToAdd: newMusicSheetsCount,
        maxCapacity: capacity,
      );
    }
  }
}
