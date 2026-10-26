import 'package:flutter/foundation.dart';

@immutable
sealed class AddEditMusicSheetError {
  const AddEditMusicSheetError();
}

@immutable
class AddEditMusicSheetErrorUnknown extends AddEditMusicSheetError {
  const AddEditMusicSheetErrorUnknown() : super();
}

/// Error when renaming a music sheet fails (typically due to network issues)
@immutable
class RenameMusicSheetFailedError extends AddEditMusicSheetError {
  const RenameMusicSheetFailedError() : super();
}

/// Error when uploading music sheet fails (storage or Firestore)
@immutable
class UploadMusicSheetRecordFailedError extends AddEditMusicSheetError {
  const UploadMusicSheetRecordFailedError() : super();
}

/// The device has no network, so the upload was not even started (Storage would only retry until it times out).
@immutable
class UploadMusicSheetNoInternetError extends AddEditMusicSheetError {
  const UploadMusicSheetNoInternetError() : super();
}
