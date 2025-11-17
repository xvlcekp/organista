import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';

extension MusicSheetListExtension on List<MusicSheet> {
  /// Convert List(MusicSheet) to a List(Map(String, dynamic)) for Firestore
  List<Map<String, dynamic>> toJsonList() {
    return map((sheet) => sheet.toJson()).toList();
  }

  /// Remove a music sheet by ID
  List<MusicSheet> removeById(String id) {
    return where((sheet) => sheet.musicSheetId != id).toList();
  }

  /// Update a specific music sheet's file name
  List<MusicSheet> renameSheet(String id, String newFileName) {
    return map((sheet) {
      if (sheet.musicSheetId == id) {
        return MusicSheet(
          json: {...sheet.toJson(), MusicSheetKey.fileName: newFileName},
        );
      }
      return sheet;
    }).toList();
  }
}
