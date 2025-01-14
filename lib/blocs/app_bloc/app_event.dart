part of 'app_bloc.dart';

@immutable
abstract class AppEvent {
  const AppEvent();
}

@immutable
class AppEventUploadImage implements AppEvent {
  final Uint8List file;
  final String fileName;

  const AppEventUploadImage({
    required this.file,
    required this.fileName,
  });
}

@immutable
class AppEventEditMusicSheet implements AppEvent {
  final MusicSheet musicSheet;
  final String fileName;

  const AppEventEditMusicSheet({
    required this.musicSheet,
    required this.fileName,
  });
}

@immutable
class AppEventDeleteMusicSheet implements AppEvent {
  final MusicSheet musicSheetToDelete;

  const AppEventDeleteMusicSheet({
    required this.musicSheetToDelete,
  });
}

@immutable
class AppEventDeleteAccount implements AppEvent {
  const AppEventDeleteAccount();
}

@immutable
class AppEventLogOut implements AppEvent {
  const AppEventLogOut();
}

@immutable
class AppEventInitialize implements AppEvent {
  const AppEventInitialize();
}

@immutable
class AppEventLogIn implements AppEvent {
  final String email;
  final String password;

  const AppEventLogIn({
    required this.email,
    required this.password,
  });
}

@immutable
class AppEventGoToRegistration implements AppEvent {
  const AppEventGoToRegistration();
}

@immutable
class AppEventGoToLogin implements AppEvent {
  const AppEventGoToLogin();
}

@immutable
class AppEventRegister implements AppEvent {
  final String email;
  final String password;

  const AppEventRegister({
    required this.email,
    required this.password,
  });
}

@immutable
class AppEventReorderMusicSheet implements AppEvent {
  final Iterable<MusicSheet> musicSheets;
  const AppEventReorderMusicSheet({
    required this.musicSheets,
  });
}
