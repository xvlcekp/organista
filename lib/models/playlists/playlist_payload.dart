import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist_key.dart';

@immutable
class PlaylistPayload extends MapView<String, dynamic> {
  PlaylistPayload({
    required String userId,
    required String name,
    required List<MusicSheet> musicSheets,
  }) : super(
         {
           PlaylistKey.userId: userId,
           PlaylistKey.name: name,
           PlaylistKey.createdAt: FieldValue.serverTimestamp(),
           PlaylistKey.musicSheets: musicSheets.map((musicSheet) => musicSheet.toJson()),
         },
       );
}
