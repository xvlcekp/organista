extension E on String {
  String lastChars(int n) => substring(length - n);
}

extension SequenceId on String {
  int get sequenceId {
    final match = RegExp(r'^(\d+)').firstMatch(this);
    return match?.group(1) != null ? int.parse(match!.group(1)!) : 0;
  }
}
