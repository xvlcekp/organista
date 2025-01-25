import 'package:flutter/foundation.dart' show immutable;

@immutable
class FirebaseCollectionName {
  static const String musicSheets = 'musicSheets';
  static const String users = 'users';
  static const String playlists = 'playlists';
  static const String categories = 'categories';
  const FirebaseCollectionName._();
}

// TODO: Databases

// Categories - multiple tags - JKS, Advent, Vianocne, Postne ...
// Playlists - playlistName, isPublic, userId
// Playlist content - playListId, musicSheetId, sequenceId
// Music sheets - owner, fileUrl, 
