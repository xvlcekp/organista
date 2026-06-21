enum RepositoriesViewMode {
  /// Dedicated screen for selecting music sheets to add to a playlist.
  /// Has its own Scaffold and AppBar; repository tiles are interactive (tap to add to playlist); no add-repository FAB.
  selection,

  /// Overview tab embedded in the main screen for managing repositories.
  /// No own Scaffold; FAB to add new personal repositories; tiles are view-only (no add-to-playlist).
  /// Tiles support rename and delete via long-press for the current user's own repositories.
  management,
}
