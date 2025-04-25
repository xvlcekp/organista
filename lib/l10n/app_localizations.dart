import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (localizations == null) {
      // Return a default instance with Slovak locale if localization is not available yet
      return AppLocalizations(const Locale('sk', ''));
    }
    return localizations;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Add all your strings here
  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get modifyMusicSheet => _localizedValues[locale.languageCode]!['modifyMusicSheet']!;
  String get musicSheetName => _localizedValues[locale.languageCode]!['musicSheetName']!;
  String get discard => _localizedValues[locale.languageCode]!['discard']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get noMusicSheetsYet => _localizedValues[locale.languageCode]!['noMusicSheetsYet']!;
  String get addYourFirstMusicSheet => _localizedValues[locale.languageCode]!['addYourFirstMusicSheet']!;
  String get selectImageFirst => _localizedValues[locale.languageCode]!['selectImageFirst']!;
  String get discardChanges => _localizedValues[locale.languageCode]!['discardChanges']!;
  String get discardChangesMessage => _localizedValues[locale.languageCode]!['discardChangesMessage']!;
  String get yes => _localizedValues[locale.languageCode]!['yes']!;
  String get no => _localizedValues[locale.languageCode]!['no']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get create => _localizedValues[locale.languageCode]!['create']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get deleteImage => _localizedValues[locale.languageCode]!['deleteImage']!;
  String get deleteImageMessage => _localizedValues[locale.languageCode]!['deleteImageMessage']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get logoutMessage => _localizedValues[locale.languageCode]!['logoutMessage']!;
  String get deleteAccount => _localizedValues[locale.languageCode]!['deleteAccount']!;
  String get deleteAccountMessage => _localizedValues[locale.languageCode]!['deleteAccountMessage']!;
  String get forgotPassword => _localizedValues[locale.languageCode]!['forgotPassword']!;
  String get resetPassword => _localizedValues[locale.languageCode]!['resetPassword']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get password => _localizedValues[locale.languageCode]!['password']!;
  String get verifyPassword => _localizedValues[locale.languageCode]!['verifyPassword']!;
  String get emailRequired => _localizedValues[locale.languageCode]!['emailRequired']!;
  String get passwordRequired => _localizedValues[locale.languageCode]!['passwordRequired']!;
  String get verifyPasswordRequired => _localizedValues[locale.languageCode]!['verifyPasswordRequired']!;
  String get passwordsDoNotMatch => _localizedValues[locale.languageCode]!['passwordsDoNotMatch']!;
  String get login => _localizedValues[locale.languageCode]!['login']!;
  String get register => _localizedValues[locale.languageCode]!['register']!;
  String get playlists => _localizedValues[locale.languageCode]!['playlists']!;
  String get repositories => _localizedValues[locale.languageCode]!['repositories']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get english => _localizedValues[locale.languageCode]!['english']!;
  String get slovak => _localizedValues[locale.languageCode]!['slovak']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get success => _localizedValues[locale.languageCode]!['success']!;
  String get passwordResetEmailSent => _localizedValues[locale.languageCode]!['passwordResetEmailSent']!;
  String get invalidEmail => _localizedValues[locale.languageCode]!['invalidEmail']!;
  String get userNotFound => _localizedValues[locale.languageCode]!['userNotFound']!;
  String get wrongPassword => _localizedValues[locale.languageCode]!['wrongPassword']!;
  String get emailAlreadyInUse => _localizedValues[locale.languageCode]!['emailAlreadyInUse']!;
  String get weakPassword => _localizedValues[locale.languageCode]!['weakPassword']!;
  String get networkError => _localizedValues[locale.languageCode]!['networkError']!;
  String get unknownError => _localizedValues[locale.languageCode]!['unknownError']!;
  String get welcomeBack => _localizedValues[locale.languageCode]!['welcomeBack']!;
  String get signInToContinue => _localizedValues[locale.languageCode]!['signInToContinue']!;
  String get noAccount => _localizedValues[locale.languageCode]!['noAccount']!;
  String get createAccount => _localizedValues[locale.languageCode]!['createAccount']!;
  String get signUpToGetStarted => _localizedValues[locale.languageCode]!['signUpToGetStarted']!;
  String get alreadyHaveAccount => _localizedValues[locale.languageCode]!['alreadyHaveAccount']!;
  String get download => _localizedValues[locale.languageCode]!['download']!;
  String get downloadTooltip => _localizedValues[locale.languageCode]!['downloadTooltip']!;
  String get deleteTooltip => _localizedValues[locale.languageCode]!['deleteTooltip']!;
  String get renamePlaylist => _localizedValues[locale.languageCode]!['renamePlaylist']!;
  String get rename => _localizedValues[locale.languageCode]!['rename']!;
  String get ok => _localizedValues[locale.languageCode]!['ok']!;

  // Model-related strings
  String get musicSheet => _localizedValues[locale.languageCode]!['musicSheet']!;
  String get musicSheetId => _localizedValues[locale.languageCode]!['musicSheetId']!;
  String get playlist => _localizedValues[locale.languageCode]!['playlist']!;
  String get user => _localizedValues[locale.languageCode]!['user']!;
  String get category => _localizedValues[locale.languageCode]!['category']!;
  String get repository => _localizedValues[locale.languageCode]!['repository']!;
  String get displayName => _localizedValues[locale.languageCode]!['displayName']!;
  String get name => _localizedValues[locale.languageCode]!['name']!;
  String get createdAt => _localizedValues[locale.languageCode]!['createdAt']!;
  String get fileUrl => _localizedValues[locale.languageCode]!['fileUrl']!;
  String get fileName => _localizedValues[locale.languageCode]!['fileName']!;
  String get mediaType => _localizedValues[locale.languageCode]!['mediaType']!;
  String get image => _localizedValues[locale.languageCode]!['image']!;
  String get pdf => _localizedValues[locale.languageCode]!['pdf']!;
  String get unsupportedFileExtension => _localizedValues[locale.languageCode]!['unsupportedFileExtension']!;
  String get noMatchingMediaType => _localizedValues[locale.languageCode]!['noMatchingMediaType']!;

  // Feature-specific strings
  String get myPlaylists => _localizedValues[locale.languageCode]!['myPlaylists']!;
  String get newPlaylist => _localizedValues[locale.languageCode]!['newPlaylist']!;
  String get noPlaylistsYet => _localizedValues[locale.languageCode]!['noPlaylistsYet']!;
  String get createFirstPlaylist => _localizedValues[locale.languageCode]!['createFirstPlaylist']!;
  String get musicSheets => _localizedValues[locale.languageCode]!['musicSheets']!;
  String get searchMusicSheets => _localizedValues[locale.languageCode]!['searchMusicSheets']!;
  String get noMusicSheetsFound => _localizedValues[locale.languageCode]!['noMusicSheetsFound']!;
  String get noGlobalRepositories => _localizedValues[locale.languageCode]!['noGlobalRepositories']!;
  String get noPersonalRepositories => _localizedValues[locale.languageCode]!['noPersonalRepositories']!;
  String get global => _localizedValues[locale.languageCode]!['global']!;
  String get personal => _localizedValues[locale.languageCode]!['personal']!;
  String get sheets => _localizedValues[locale.languageCode]!['sheets']!;
  String get addMusicSheet => _localizedValues[locale.languageCode]!['addMusicSheet']!;
  String get edit => _localizedValues[locale.languageCode]!['edit']!;
  String get change => _localizedValues[locale.languageCode]!['change']!;
  String get noMusicSheets => _localizedValues[locale.languageCode]!['noMusicSheets']!;
  String get add => _localizedValues[locale.languageCode]!['add']!;
  String get resetPasswordMessage => _localizedValues[locale.languageCode]!['resetPasswordMessage']!;
  String get enterEmail => _localizedValues[locale.languageCode]!['enterEmail']!;
  String get enterEmailHint => _localizedValues[locale.languageCode]!['enterEmailHint']!;
  String get pleaseEnterEmail => _localizedValues[locale.languageCode]!['pleaseEnterEmail']!;
  String get passwordResetLinkSent => _localizedValues[locale.languageCode]!['passwordResetLinkSent']!;
  String get playlistName => _localizedValues[locale.languageCode]!['playlistName']!;
  String get enterPlaylistName => _localizedValues[locale.languageCode]!['enterPlaylistName']!;
  String get playlistNameEmpty => _localizedValues[locale.languageCode]!['playlistNameEmpty']!;
  String get theme => _localizedValues[locale.languageCode]!['theme']!;
  String get darkTheme => _localizedValues[locale.languageCode]!['darkTheme']!;
  String get lightTheme => _localizedValues[locale.languageCode]!['lightTheme']!;
  String get systemTheme => _localizedValues[locale.languageCode]!['systemTheme']!;
  String get tapToView => _localizedValues[locale.languageCode]!['tapToView']!;
  String get deletePlaylist => _localizedValues[locale.languageCode]!['deletePlaylist']!;
  String get deletePlaylistMessage => _localizedValues[locale.languageCode]!['deletePlaylistMessage']!;
  String get about => _localizedValues[locale.languageCode]!['about']!;
  String get aboutMessage => _localizedValues[locale.languageCode]!['aboutMessage']!;
  String get appSettings => _localizedValues[locale.languageCode]!['appSettings']!;
  String get accountManagement => _localizedValues[locale.languageCode]!['accountManagement']!;
  String get version => _localizedValues[locale.languageCode]!['version']!;
  String get frequentlyAskedQuestions => _localizedValues[locale.languageCode]!['frequentlyAskedQuestions']!;
  String get couldNotOpenUrl => _localizedValues[locale.languageCode]!['couldNotOpenUrl']!;
  String get errorOpeningUrl => _localizedValues[locale.languageCode]!['errorOpeningUrl']!;
  String get fileTooLarge => _localizedValues[locale.languageCode]!['fileTooLarge']!;
  String get anErrorHappened => _localizedValues[locale.languageCode]!['anErrorHappened']!;

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Organista',
      'loading': 'Loading...',
      'modifyMusicSheet': 'Modify music sheet',
      'musicSheetName': 'Music sheet name',
      'discard': 'Discard',
      'save': 'Save',
      'noMusicSheetsYet': 'No music sheets yet',
      'addYourFirstMusicSheet': 'Add your first music sheet to get started',
      'selectImageFirst': 'You have to select an image first',
      'discardChanges': 'Discard Changes',
      'discardChangesMessage': 'Are you sure you want to discard changes?',
      'yes': 'Yes',
      'no': 'No',
      'cancel': 'Cancel',
      'create': 'Create',
      'delete': 'Delete',
      'deleteImage': 'Delete image',
      'deleteImageMessage': 'Are you sure you want to delete this image? You cannot undo this operation!',
      'logout': 'Logout',
      'logoutMessage': 'Are you sure you want to logout?',
      'deleteAccount': 'Delete account',
      'deleteAccountMessage': 'Are you sure you want to delete your account? This action cannot be undone.',
      'forgotPassword': 'Forgot Password',
      'resetPassword': 'Reset Password',
      'email': 'Email',
      'password': 'Password',
      'verifyPassword': 'Verify Password',
      'emailRequired': 'Email is required',
      'passwordRequired': 'Password is required',
      'verifyPasswordRequired': 'Please verify your password',
      'passwordsDoNotMatch': 'Passwords do not match',
      'login': 'Login',
      'register': 'Register',
      'playlists': 'Playlists',
      'repositories': 'Repositories',
      'settings': 'Settings',
      'language': 'Language',
      'english': 'English',
      'slovak': 'Slovak',
      'error': 'Error',
      'success': 'Success',
      'passwordResetEmailSent': 'Password reset email sent. Please check your inbox.',
      'invalidEmail': 'Invalid email',
      'userNotFound': 'User not found',
      'wrongPassword': 'Wrong password',
      'emailAlreadyInUse': 'Email already in use',
      'weakPassword': 'Weak password',
      'networkError': 'Network error',
      'unknownError': 'Unknown error',
      'welcomeBack': 'Welcome Back!',
      'signInToContinue': 'Sign in to continue',
      'noAccount': "Don't have an account?",
      'createAccount': 'Create Account',
      'signUpToGetStarted': 'Sign up to get started',
      'alreadyHaveAccount': 'Already have an account?',
      'download': 'Download',
      'downloadTooltip': 'Download music sheet',
      'deleteTooltip': 'Delete music sheet',
      'renamePlaylist': 'Rename playlist',
      'rename': 'Rename',
      'ok': 'OK',

      // Model-related strings
      'musicSheet': 'Music Sheet',
      'musicSheetId': 'Music Sheet ID',
      'playlist': 'Playlist',
      'user': 'User',
      'category': 'Category',
      'repository': 'Repository',
      'displayName': 'Display Name',
      'name': 'Name',
      'createdAt': 'Created At',
      'fileUrl': 'File URL',
      'fileName': 'File Name',
      'mediaType': 'Media Type',
      'image': 'Image',
      'pdf': 'PDF',
      'unsupportedFileExtension': 'Unsupported file extension',
      'noMatchingMediaType': 'No matching MediaType for: {mediaType}',

      // Feature-specific strings
      'myPlaylists': 'My Playlists',
      'newPlaylist': 'New Playlist',
      'noPlaylistsYet': 'No playlists yet',
      'createFirstPlaylist': 'Create your first playlist',
      'musicSheets': 'Music sheets',
      'searchMusicSheets': 'Search music sheets...',
      'noMusicSheetsFound': 'No music sheets found',
      'noGlobalRepositories': 'No global repositories available.',
      'noPersonalRepositories': 'No personal repositories available.',
      'global': 'Global',
      'personal': 'Personal',
      'sheets': 'sheets',
      'addMusicSheet': 'Add music sheet',
      'edit': 'Edit',
      'change': 'Change',
      'noMusicSheets': 'No music sheets found',
      'add': 'Add',
      'resetPasswordMessage': 'Enter your email address and we\'ll send you a link to reset your password.',
      'enterEmail': 'Enter your email',
      'enterEmailHint': 'Enter your email',
      'pleaseEnterEmail': 'Please enter your email',
      'passwordResetLinkSent': 'Password reset link sent to your email',
      'playlistName': 'Playlist name',
      'enterPlaylistName': 'Enter playlist name',
      'playlistNameEmpty': 'Playlist name cannot be empty',
      'theme': 'Theme',
      'darkTheme': 'Dark theme',
      'lightTheme': 'Light theme',
      'systemTheme': 'System theme',
      'tapToView': 'Tap to view',
      'deletePlaylist': 'Delete playlist',
      'deletePlaylistMessage': 'Are you sure you want to delete this playlist? You cannot undo this operation!',
      'about': 'About',
      'aboutMessage': 'A music sheet management application\nCreated by Pavol Vlček',
      'appSettings': 'App Settings',
      'accountManagement': 'Account Management',
      'version': 'Version',
      'frequentlyAskedQuestions': 'Frequently Asked Questions',
      'couldNotOpenUrl': 'Could not open the URL',
      'errorOpeningUrl': 'Error opening URL: {error}',

      'fileTooLarge': 'File is too large. Maximum size is {maxSize}MB.',
      'anErrorHappened': 'An error happened',
    },
    'sk': {
      'appTitle': 'Organista',
      'loading': 'Načítanie...',
      'modifyMusicSheet': 'Upraviť notový záznam',
      'musicSheetName': 'Názov notového záznamu',
      'discard': 'Zrušiť',
      'save': 'Uložiť',
      'noMusicSheetsYet': 'Zatiaľ žiadne notové záznamy',
      'addYourFirstMusicSheet': 'Pridajte svoj prvý notový záznam a začnite',
      'selectImageFirst': 'Najprv musíte vybrať obrázok',
      'discardChanges': 'Zrušiť zmeny',
      'discardChangesMessage': 'Ste si istý, že chcete zrušiť zmeny?',
      'yes': 'Áno',
      'no': 'Nie',
      'cancel': 'Zrušiť',
      'create': 'Vytvoriť',
      'delete': 'Vymazať',
      'deleteImage': 'Vymazať obrázok',
      'deleteImageMessage': 'Ste si istý, že chcete vymazať tento obrázok? Táto akcia sa nedá vrátiť späť!',
      'logout': 'Odhlásiť sa',
      'logoutMessage': 'Ste si istý, že sa chcete odhlásiť?',
      'deleteAccount': 'Odstrániť účet',
      'deleteAccountMessage': 'Ste si istý, že chcete vymazať svoj účet? Táto akcia sa nedá vrátiť späť.',
      'forgotPassword': 'Zabudli ste heslo',
      'resetPassword': 'Obnoviť heslo',
      'email': 'E-mail',
      'password': 'Heslo',
      'verifyPassword': 'Potvrďte heslo',
      'emailRequired': 'E-mail je povinný',
      'passwordRequired': 'Heslo je povinné',
      'verifyPasswordRequired': 'Prosím, potvrďte svoje heslo',
      'passwordsDoNotMatch': 'Heslá sa nezhodujú',
      'login': 'Prihlásiť sa',
      'register': 'Registrovať sa',
      'playlists': 'Zoznamy skladieb',
      'repositories': 'Repozitáre',
      'settings': 'Nastavenia',
      'language': 'Jazyk',
      'english': 'Angličtina',
      'slovak': 'Slovenčina',
      'error': 'Chyba',
      'success': 'Úspech',
      'passwordResetEmailSent': 'E-mail na obnovenie hesla bol odoslaný. Prosím, skontrolujte svoju doručenú poštu.',
      'invalidEmail': 'Neplatný e-mail',
      'userNotFound': 'Používateľ nebol nájdený',
      'wrongPassword': 'Nesprávne heslo',
      'emailAlreadyInUse': 'E-mail je už používaný',
      'weakPassword': 'Slabé heslo',
      'networkError': 'Chyba siete',
      'unknownError': 'Neznáma chyba',
      'welcomeBack': 'Vitajte späť!',
      'signInToContinue': 'Prihláste sa, aby ste pokračovali',
      'noAccount': 'Nemáte účet?',
      'createAccount': 'Vytvoriť účet',
      'signUpToGetStarted': 'Zaregistrujte sa, aby ste začali',
      'alreadyHaveAccount': 'Už máte účet?',
      'download': 'Stiahnuť',
      'downloadTooltip': 'Stiahnuť notový zápis',
      'deleteTooltip': 'Vymazať notový zápis',
      'renamePlaylist': 'Premenovať zoznam skladieb',
      'rename': 'Premenovať',
      'ok': 'OK',

      // Model-related strings
      'musicSheet': 'Notový záznam',
      'musicSheetId': 'ID notového záznamu',
      'playlist': 'Zoznam skladieb',
      'user': 'Používateľ',
      'category': 'Kategória',
      'repository': 'Repozitár',
      'displayName': 'Zobrazované meno',
      'name': 'Názov',
      'createdAt': 'Vytvorené',
      'fileUrl': 'URL súboru',
      'fileName': 'Názov súboru',
      'mediaType': 'Typ médiá',
      'image': 'Obrázok',
      'pdf': 'PDF',
      'unsupportedFileExtension': 'Nepodporovaná prípona súboru',
      'noMatchingMediaType': 'Žiadny zodpovedajúci typ médiá pre: {mediaType}',

      // Feature-specific strings
      'myPlaylists': 'Moje zoznamy skladieb',
      'newPlaylist': 'Nový zoznam skladieb',
      'noPlaylistsYet': 'Zatiaľ žiadne zoznamy skladieb',
      'createFirstPlaylist': 'Vytvorte svoj prvý zoznam skladieb',
      'musicSheets': 'Počet nôt',
      'searchMusicSheets': 'Vyhľadať noty...',
      'noMusicSheetsFound': 'Nenašli sa žiadne noty',
      'noGlobalRepositories': 'Žiadne globálne repozitáre nie sú k dispozícii.',
      'noPersonalRepositories': 'Žiadne osobné repozitáre nie sú k dispozícii.',
      'global': 'Globálne',
      'personal': 'Osobné',
      'sheets': 'položiek',
      'addMusicSheet': 'Pridať notový záznam',
      'edit': 'Upraviť',
      'change': 'Zmeniť',
      'noMusicSheets': 'Nenašli sa žiadne noty',
      'add': 'Pridať',
      'resetPasswordMessage': 'Zadajte svoju e-mailovú adresu a my vám pošleme odkaz na obnovenie hesla.',
      'enterEmail': 'Zadajte svoj e-mail',
      'enterEmailHint': 'Zadajte svoj e-mail',
      'pleaseEnterEmail': 'Prosím, zadajte svoj e-mail',
      'passwordResetLinkSent': 'Odkaz na obnovenie hesla bol odoslaný na váš e-mail',
      'playlistName': 'Názov zoznamu',
      'enterPlaylistName': 'Zadajte názov zoznamu',
      'playlistNameEmpty': 'Názov zoznamu nemôže byť prázdny',
      'theme': 'Téma',
      'darkTheme': 'Tmavá téma',
      'lightTheme': 'Svetlá téma',
      'systemTheme': 'Systémová téma',
      'tapToView': 'Kliknutím zobrazíte',
      'deletePlaylist': 'Vymazať zoznam skladieb',
      'deletePlaylistMessage': 'Ste si istý, že chcete vymazať tento zoznam? Táto akcia sa nedá vrátiť späť!',
      'about': 'O aplikácii',
      'aboutMessage': 'Aplikácia na správu notových záznamov\nVytvoril Pavol Vlček',
      'appSettings': 'Nastavenia aplikácie',
      'accountManagement': 'Správa účtu',
      'version': 'Verzia',
      'frequentlyAskedQuestions': 'Často kladené otázky',
      'couldNotOpenUrl': 'Nepodarilo sa otvoriť URL',
      'errorOpeningUrl': 'Chyba pri otváraní URL: {error}',

      'fileTooLarge': 'Súbor je príliš veľký. Maximálna veľkosť je {maxSize}MB.',
      'anErrorHappened': 'Nastala chyba',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'sk'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
