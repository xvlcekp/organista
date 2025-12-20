extension NumExtensions on num {
  static const num bytesPerMegaByte = 1024 * 1024;
  num get bytesToMegaBytes {
    return this / bytesPerMegaByte;
  }

  num get megaBytesToBytes {
    return this * bytesPerMegaByte;
  }
}
