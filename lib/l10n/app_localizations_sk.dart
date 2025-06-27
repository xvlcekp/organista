// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get appTitle => 'Organista';

  @override
  String get loading => 'Načítanie...';

  @override
  String get modifyMusicSheet => 'Upraviť notový záznam';

  @override
  String get musicSheetName => 'Názov notového záznamu';

  @override
  String get discard => 'Zrušiť';

  @override
  String get save => 'Uložiť';

  @override
  String get noMusicSheetsYet => 'Zatiaľ žiadne notové záznamy';

  @override
  String get addYourFirstMusicSheet => 'Pridajte svoj prvý notový záznam a začnite';

  @override
  String get selectImageFirst => 'Najprv musíte vybrať obrázok';

  @override
  String get discardChanges => 'Zrušiť zmeny';

  @override
  String get discardChangesMessage => 'Ste si istý, že chcete zrušiť zmeny?';

  @override
  String get yes => 'Áno';

  @override
  String get no => 'Nie';

  @override
  String get cancel => 'Zrušiť';

  @override
  String get create => 'Vytvoriť';

  @override
  String get delete => 'Vymazať';

  @override
  String get deleteImage => 'Vymazať obrázok';

  @override
  String get deleteImageMessage => 'Ste si istý, že chcete vymazať tento obrázok? Táto akcia sa nedá vrátiť späť!';

  @override
  String get logout => 'Odhlásiť sa';

  @override
  String get logoutMessage => 'Ste si istý, že sa chcete odhlásiť?';

  @override
  String get deleteAccount => 'Odstrániť účet';

  @override
  String get deleteAccountMessage => 'Ste si istý, že chcete vymazať svoj účet? Táto akcia sa nedá vrátiť späť.';

  @override
  String get forgotPassword => 'Zabudli ste heslo';

  @override
  String get resetPassword => 'Obnoviť heslo';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Heslo';

  @override
  String get verifyPassword => 'Potvrďte heslo';

  @override
  String get emailRequired => 'E-mail je povinný';

  @override
  String get passwordRequired => 'Heslo je povinné';

  @override
  String get verifyPasswordRequired => 'Prosím, potvrďte svoje heslo';

  @override
  String get passwordsDoNotMatch => 'Heslá sa nezhodujú';

  @override
  String get login => 'Prihlásiť sa';

  @override
  String get signInWithGoogle => 'Prihlásiť sa pomocou Google';

  @override
  String get register => 'Registrovať sa';

  @override
  String get playlists => 'Zoznamy skladieb';

  @override
  String get repositories => 'Repozitáre';

  @override
  String get settings => 'Nastavenia';

  @override
  String get language => 'Jazyk';

  @override
  String get english => 'Angličtina';

  @override
  String get slovak => 'Slovenčina';

  @override
  String get error => 'Chyba';

  @override
  String get success => 'Úspech';

  @override
  String get passwordResetEmailSent => 'E-mail na obnovenie hesla bol odoslaný. Prosím, skontrolujte svoju doručenú poštu.';

  @override
  String get invalidEmail => 'Neplatný e-mail';

  @override
  String get userNotFound => 'Používateľ nebol nájdený';

  @override
  String get wrongPassword => 'Nesprávne heslo';

  @override
  String get emailAlreadyInUse => 'E-mail je už používaný';

  @override
  String get weakPassword => 'Slabé heslo';

  @override
  String get networkError => 'Chyba siete';

  @override
  String get unknownError => 'Neznáma chyba';

  @override
  String get welcomeBack => 'Vitajte späť!';

  @override
  String get signInToContinue => 'Prihláste sa, aby ste pokračovali';

  @override
  String get noAccount => 'Nemáte účet?';

  @override
  String get createAccount => 'Vytvoriť účet';

  @override
  String get signUpToGetStarted => 'Zaregistrujte sa, aby ste začali';

  @override
  String get alreadyHaveAccount => 'Už máte účet?';

  @override
  String get download => 'Stiahnuť';

  @override
  String get downloadTooltip => 'Stiahnuť notový zápis';

  @override
  String get deleteTooltip => 'Vymazať notový zápis';

  @override
  String get renamePlaylist => 'Premenovať zoznam skladieb';

  @override
  String get rename => 'Premenovať';

  @override
  String get ok => 'OK';

  @override
  String get musicSheet => 'Notový záznam';

  @override
  String get musicSheetId => 'ID notového záznamu';

  @override
  String get playlist => 'Zoznam skladieb';

  @override
  String get user => 'Používateľ';

  @override
  String get category => 'Kategória';

  @override
  String get repository => 'Repozitár';

  @override
  String get displayName => 'Zobrazované meno';

  @override
  String get name => 'Názov';

  @override
  String get createdAt => 'Vytvorené';

  @override
  String get fileUrl => 'URL súboru';

  @override
  String get fileName => 'Názov súboru';

  @override
  String get mediaType => 'Typ médiá';

  @override
  String get image => 'Obrázok';

  @override
  String get pdf => 'PDF';

  @override
  String get unsupportedFileExtension => 'Nepodporovaná prípona súboru';

  @override
  String noMatchingMediaType(Object mediaType) {
    return 'Žiadny zodpovedajúci typ médiá pre: $mediaType';
  }

  @override
  String get myPlaylists => 'Moje zoznamy skladieb';

  @override
  String get newPlaylist => 'Nový zoznam skladieb';

  @override
  String get noPlaylistsYet => 'Zatiaľ žiadne zoznamy skladieb';

  @override
  String get createFirstPlaylist => 'Vytvorte svoj prvý zoznam skladieb';

  @override
  String get musicSheets => 'Počet nôt';

  @override
  String get searchMusicSheets => 'Vyhľadať noty...';

  @override
  String get noMusicSheetsFound => 'Nenašli sa žiadne noty';

  @override
  String get noGlobalRepositories => 'Žiadne globálne repozitáre nie sú k dispozícii.';

  @override
  String get noPersonalRepositories => 'Žiadne osobné repozitáre nie sú k dispozícii.';

  @override
  String get global => 'Globálne';

  @override
  String get personal => 'Osobné';

  @override
  String get sheets => 'položiek';

  @override
  String get addMusicSheet => 'Pridať notový záznam';

  @override
  String get edit => 'Upraviť';

  @override
  String get change => 'Zmeniť';

  @override
  String get noMusicSheets => 'Nenašli sa žiadne noty';

  @override
  String get add => 'Pridať';

  @override
  String get resetPasswordMessage => 'Zadajte svoju e-mailovú adresu a my vám pošleme odkaz na obnovenie hesla.';

  @override
  String get enterEmail => 'Zadajte svoj e-mail';

  @override
  String get enterEmailHint => 'Zadajte svoj e-mail';

  @override
  String get pleaseEnterEmail => 'Prosím, zadajte svoj e-mail';

  @override
  String get passwordResetLinkSent => 'Odkaz na obnovenie hesla bol odoslaný na váš e-mail';

  @override
  String get playlistName => 'Názov zoznamu';

  @override
  String get enterPlaylistName => 'Zadajte názov zoznamu';

  @override
  String get playlistNameEmpty => 'Názov zoznamu nemôže byť prázdny';

  @override
  String get theme => 'Téma';

  @override
  String get darkTheme => 'Tmavá téma';

  @override
  String get lightTheme => 'Svetlá téma';

  @override
  String get systemTheme => 'Systémová téma';

  @override
  String get tapToView => 'Kliknutím zobrazíte';

  @override
  String get deletePlaylist => 'Vymazať zoznam skladieb';

  @override
  String get deletePlaylistMessage => 'Ste si istý, že chcete vymazať tento zoznam? Táto akcia sa nedá vrátiť späť!';

  @override
  String get about => 'O aplikácii';

  @override
  String get aboutMessage => 'Aplikácia na správu notových záznamov\nVytvoril Pavol Vlček';

  @override
  String get appSettings => 'Nastavenia aplikácie';

  @override
  String get accountManagement => 'Správa účtu';

  @override
  String get version => 'Verzia';

  @override
  String get frequentlyAskedQuestions => 'Často kladené otázky';

  @override
  String get couldNotOpenUrl => 'Nepodarilo sa otvoriť URL';

  @override
  String errorOpeningUrl(Object error) {
    return 'Chyba pri otváraní URL: $error';
  }

  @override
  String fileTooLarge(Object maxSize) {
    return 'Súbor je príliš veľký. Maximálna veľkosť je ${maxSize}MB.';
  }

  @override
  String get anErrorHappened => 'Nastala chyba';

  @override
  String get showNavigationArrows => 'Zobraziť navigačné šípky';

  @override
  String get keepScreenOn => 'Nechať obrazovku zapnutú';

  @override
  String get errorUnknownText => 'Neznáma chyba';

  @override
  String get authGenericExceptionText => 'Vyskytla sa neznáma chyba';

  @override
  String get authErrorUserNotLoggedInText => 'Žiadny používateľ nie je momentálne prihlásený!';

  @override
  String get authErrorRequiresRecentLoginText => 'Musíte sa odhlásiť a znova prihlásiť, aby ste mohli vykonať túto operáciu';

  @override
  String get authErrorOperationNotAllowedText => 'Nemôžete sa zaregistrovať pomocou tejto metódy v tomto momente!';

  @override
  String get authErrorUserNotFoundText => 'Zadaný používateľ nebol nájdený na serveri!';

  @override
  String get authErrorWeakPasswordText => 'Prosím, vyberte silnejšie heslo skladajúce sa z viacerých znakov!';

  @override
  String get authErrorInvalidEmailText => 'Prosím, skontrolujte svoj e-mail a skúste to znova!';

  @override
  String get authErrorEmailAlreadyInUseText => 'Prosím, použite iný e-mail na registráciu!';

  @override
  String get authErrorUserDisabledText => 'Tento používateľský účet bol deaktivovaný. Prosím, kontaktujte podporu pre pomoc.';

  @override
  String get authErrorInvalidCredentialText => 'Zadané prihlasovacie údaje sú nesprávne, skontrolujte email a heslo.';

  @override
  String get musicSheetAlreadyInPlaylist => 'Notový záznam už existuje v zozname skladieb.';

  @override
  String get musicSheetInitializationError => 'Nastala chyba pri inicializácii.';
}
