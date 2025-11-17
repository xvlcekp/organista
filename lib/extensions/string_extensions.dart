extension StringExtensions on String {
  int get sequenceId {
    final match = RegExp(r'^(\d+)').firstMatch(this);
    final group = match?.group(1);
    return group != null ? int.parse(group) : 0;
  }
}
