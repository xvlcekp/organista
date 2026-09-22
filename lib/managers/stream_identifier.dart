import 'package:flutter/foundation.dart' show immutable;

/// Identifiers of the Firestore streams shared through `StreamManager`, so that the bloc that opens a stream
/// and the code that has to stop it (e.g. before deleting the document it listens to) agree on the name.
@immutable
class StreamIdentifier {
  const StreamIdentifier._();

  static String playlist(String playlistId) => 'playlist_$playlistId';

  static String playlists(String userId) => 'playlists_$userId';
}
