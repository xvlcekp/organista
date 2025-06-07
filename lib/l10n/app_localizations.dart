import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sk')
  ];

  /// No description provided for @appTitle.
  ///
  /// In sk, this message translates to:
  /// **'Organista'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In sk, this message translates to:
  /// **'Načítanie...'**
  String get loading;

  /// No description provided for @modifyMusicSheet.
  ///
  /// In sk, this message translates to:
  /// **'Upraviť notový záznam'**
  String get modifyMusicSheet;

  /// No description provided for @musicSheetName.
  ///
  /// In sk, this message translates to:
  /// **'Názov notového záznamu'**
  String get musicSheetName;

  /// No description provided for @discard.
  ///
  /// In sk, this message translates to:
  /// **'Zrušiť'**
  String get discard;

  /// No description provided for @save.
  ///
  /// In sk, this message translates to:
  /// **'Uložiť'**
  String get save;

  /// No description provided for @noMusicSheetsYet.
  ///
  /// In sk, this message translates to:
  /// **'Zatiaľ žiadne notové záznamy'**
  String get noMusicSheetsYet;

  /// No description provided for @addYourFirstMusicSheet.
  ///
  /// In sk, this message translates to:
  /// **'Pridajte svoj prvý notový záznam a začnite'**
  String get addYourFirstMusicSheet;

  /// No description provided for @selectImageFirst.
  ///
  /// In sk, this message translates to:
  /// **'Najprv musíte vybrať obrázok'**
  String get selectImageFirst;

  /// No description provided for @discardChanges.
  ///
  /// In sk, this message translates to:
  /// **'Zrušiť zmeny'**
  String get discardChanges;

  /// No description provided for @discardChangesMessage.
  ///
  /// In sk, this message translates to:
  /// **'Ste si istý, že chcete zrušiť zmeny?'**
  String get discardChangesMessage;

  /// No description provided for @yes.
  ///
  /// In sk, this message translates to:
  /// **'Áno'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In sk, this message translates to:
  /// **'Nie'**
  String get no;

  /// No description provided for @cancel.
  ///
  /// In sk, this message translates to:
  /// **'Zrušiť'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In sk, this message translates to:
  /// **'Vytvoriť'**
  String get create;

  /// No description provided for @delete.
  ///
  /// In sk, this message translates to:
  /// **'Vymazať'**
  String get delete;

  /// No description provided for @deleteImage.
  ///
  /// In sk, this message translates to:
  /// **'Vymazať obrázok'**
  String get deleteImage;

  /// No description provided for @deleteImageMessage.
  ///
  /// In sk, this message translates to:
  /// **'Ste si istý, že chcete vymazať tento obrázok? Táto akcia sa nedá vrátiť späť!'**
  String get deleteImageMessage;

  /// No description provided for @logout.
  ///
  /// In sk, this message translates to:
  /// **'Odhlásiť sa'**
  String get logout;

  /// No description provided for @logoutMessage.
  ///
  /// In sk, this message translates to:
  /// **'Ste si istý, že sa chcete odhlásiť?'**
  String get logoutMessage;

  /// No description provided for @deleteAccount.
  ///
  /// In sk, this message translates to:
  /// **'Odstrániť účet'**
  String get deleteAccount;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In sk, this message translates to:
  /// **'Ste si istý, že chcete vymazať svoj účet? Táto akcia sa nedá vrátiť späť.'**
  String get deleteAccountMessage;

  /// No description provided for @forgotPassword.
  ///
  /// In sk, this message translates to:
  /// **'Zabudli ste heslo'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In sk, this message translates to:
  /// **'Obnoviť heslo'**
  String get resetPassword;

  /// No description provided for @email.
  ///
  /// In sk, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In sk, this message translates to:
  /// **'Heslo'**
  String get password;

  /// No description provided for @verifyPassword.
  ///
  /// In sk, this message translates to:
  /// **'Potvrďte heslo'**
  String get verifyPassword;

  /// No description provided for @emailRequired.
  ///
  /// In sk, this message translates to:
  /// **'E-mail je povinný'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In sk, this message translates to:
  /// **'Heslo je povinné'**
  String get passwordRequired;

  /// No description provided for @verifyPasswordRequired.
  ///
  /// In sk, this message translates to:
  /// **'Prosím, potvrďte svoje heslo'**
  String get verifyPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In sk, this message translates to:
  /// **'Heslá sa nezhodujú'**
  String get passwordsDoNotMatch;

  /// No description provided for @login.
  ///
  /// In sk, this message translates to:
  /// **'Prihlásiť sa'**
  String get login;

  /// No description provided for @signInWithGoogle.
  ///
  /// In sk, this message translates to:
  /// **'Prihlásiť sa pomocou Google'**
  String get signInWithGoogle;

  /// No description provided for @register.
  ///
  /// In sk, this message translates to:
  /// **'Registrovať sa'**
  String get register;

  /// No description provided for @playlists.
  ///
  /// In sk, this message translates to:
  /// **'Zoznamy skladieb'**
  String get playlists;

  /// No description provided for @repositories.
  ///
  /// In sk, this message translates to:
  /// **'Repozitáre'**
  String get repositories;

  /// No description provided for @settings.
  ///
  /// In sk, this message translates to:
  /// **'Nastavenia'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In sk, this message translates to:
  /// **'Jazyk'**
  String get language;

  /// No description provided for @english.
  ///
  /// In sk, this message translates to:
  /// **'Angličtina'**
  String get english;

  /// No description provided for @slovak.
  ///
  /// In sk, this message translates to:
  /// **'Slovenčina'**
  String get slovak;

  /// No description provided for @error.
  ///
  /// In sk, this message translates to:
  /// **'Chyba'**
  String get error;

  /// No description provided for @success.
  ///
  /// In sk, this message translates to:
  /// **'Úspech'**
  String get success;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In sk, this message translates to:
  /// **'E-mail na obnovenie hesla bol odoslaný. Prosím, skontrolujte svoju doručenú poštu.'**
  String get passwordResetEmailSent;

  /// No description provided for @invalidEmail.
  ///
  /// In sk, this message translates to:
  /// **'Neplatný e-mail'**
  String get invalidEmail;

  /// No description provided for @userNotFound.
  ///
  /// In sk, this message translates to:
  /// **'Používateľ nebol nájdený'**
  String get userNotFound;

  /// No description provided for @wrongPassword.
  ///
  /// In sk, this message translates to:
  /// **'Nesprávne heslo'**
  String get wrongPassword;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In sk, this message translates to:
  /// **'E-mail je už používaný'**
  String get emailAlreadyInUse;

  /// No description provided for @weakPassword.
  ///
  /// In sk, this message translates to:
  /// **'Slabé heslo'**
  String get weakPassword;

  /// No description provided for @networkError.
  ///
  /// In sk, this message translates to:
  /// **'Chyba siete'**
  String get networkError;

  /// No description provided for @unknownError.
  ///
  /// In sk, this message translates to:
  /// **'Neznáma chyba'**
  String get unknownError;

  /// No description provided for @welcomeBack.
  ///
  /// In sk, this message translates to:
  /// **'Vitajte späť!'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In sk, this message translates to:
  /// **'Prihláste sa, aby ste pokračovali'**
  String get signInToContinue;

  /// No description provided for @noAccount.
  ///
  /// In sk, this message translates to:
  /// **'Nemáte účet?'**
  String get noAccount;

  /// No description provided for @createAccount.
  ///
  /// In sk, this message translates to:
  /// **'Vytvoriť účet'**
  String get createAccount;

  /// No description provided for @signUpToGetStarted.
  ///
  /// In sk, this message translates to:
  /// **'Zaregistrujte sa, aby ste začali'**
  String get signUpToGetStarted;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In sk, this message translates to:
  /// **'Už máte účet?'**
  String get alreadyHaveAccount;

  /// No description provided for @download.
  ///
  /// In sk, this message translates to:
  /// **'Stiahnuť'**
  String get download;

  /// No description provided for @downloadTooltip.
  ///
  /// In sk, this message translates to:
  /// **'Stiahnuť notový zápis'**
  String get downloadTooltip;

  /// No description provided for @deleteTooltip.
  ///
  /// In sk, this message translates to:
  /// **'Vymazať notový zápis'**
  String get deleteTooltip;

  /// No description provided for @renamePlaylist.
  ///
  /// In sk, this message translates to:
  /// **'Premenovať zoznam skladieb'**
  String get renamePlaylist;

  /// No description provided for @rename.
  ///
  /// In sk, this message translates to:
  /// **'Premenovať'**
  String get rename;

  /// No description provided for @ok.
  ///
  /// In sk, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @musicSheet.
  ///
  /// In sk, this message translates to:
  /// **'Notový záznam'**
  String get musicSheet;

  /// No description provided for @musicSheetId.
  ///
  /// In sk, this message translates to:
  /// **'ID notového záznamu'**
  String get musicSheetId;

  /// No description provided for @playlist.
  ///
  /// In sk, this message translates to:
  /// **'Zoznam skladieb'**
  String get playlist;

  /// No description provided for @user.
  ///
  /// In sk, this message translates to:
  /// **'Používateľ'**
  String get user;

  /// No description provided for @category.
  ///
  /// In sk, this message translates to:
  /// **'Kategória'**
  String get category;

  /// No description provided for @repository.
  ///
  /// In sk, this message translates to:
  /// **'Repozitár'**
  String get repository;

  /// No description provided for @displayName.
  ///
  /// In sk, this message translates to:
  /// **'Zobrazované meno'**
  String get displayName;

  /// No description provided for @name.
  ///
  /// In sk, this message translates to:
  /// **'Názov'**
  String get name;

  /// No description provided for @createdAt.
  ///
  /// In sk, this message translates to:
  /// **'Vytvorené'**
  String get createdAt;

  /// No description provided for @fileUrl.
  ///
  /// In sk, this message translates to:
  /// **'URL súboru'**
  String get fileUrl;

  /// No description provided for @fileName.
  ///
  /// In sk, this message translates to:
  /// **'Názov súboru'**
  String get fileName;

  /// No description provided for @mediaType.
  ///
  /// In sk, this message translates to:
  /// **'Typ médiá'**
  String get mediaType;

  /// No description provided for @image.
  ///
  /// In sk, this message translates to:
  /// **'Obrázok'**
  String get image;

  /// No description provided for @pdf.
  ///
  /// In sk, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// No description provided for @unsupportedFileExtension.
  ///
  /// In sk, this message translates to:
  /// **'Nepodporovaná prípona súboru'**
  String get unsupportedFileExtension;

  /// No description provided for @noMatchingMediaType.
  ///
  /// In sk, this message translates to:
  /// **'Žiadny zodpovedajúci typ médiá pre: {mediaType}'**
  String noMatchingMediaType(Object mediaType);

  /// No description provided for @myPlaylists.
  ///
  /// In sk, this message translates to:
  /// **'Moje zoznamy skladieb'**
  String get myPlaylists;

  /// No description provided for @newPlaylist.
  ///
  /// In sk, this message translates to:
  /// **'Nový zoznam skladieb'**
  String get newPlaylist;

  /// No description provided for @noPlaylistsYet.
  ///
  /// In sk, this message translates to:
  /// **'Zatiaľ žiadne zoznamy skladieb'**
  String get noPlaylistsYet;

  /// No description provided for @createFirstPlaylist.
  ///
  /// In sk, this message translates to:
  /// **'Vytvorte svoj prvý zoznam skladieb'**
  String get createFirstPlaylist;

  /// No description provided for @musicSheets.
  ///
  /// In sk, this message translates to:
  /// **'Počet nôt'**
  String get musicSheets;

  /// No description provided for @searchMusicSheets.
  ///
  /// In sk, this message translates to:
  /// **'Vyhľadať noty...'**
  String get searchMusicSheets;

  /// No description provided for @noMusicSheetsFound.
  ///
  /// In sk, this message translates to:
  /// **'Nenašli sa žiadne noty'**
  String get noMusicSheetsFound;

  /// No description provided for @noGlobalRepositories.
  ///
  /// In sk, this message translates to:
  /// **'Žiadne globálne repozitáre nie sú k dispozícii.'**
  String get noGlobalRepositories;

  /// No description provided for @noPersonalRepositories.
  ///
  /// In sk, this message translates to:
  /// **'Žiadne osobné repozitáre nie sú k dispozícii.'**
  String get noPersonalRepositories;

  /// No description provided for @global.
  ///
  /// In sk, this message translates to:
  /// **'Globálne'**
  String get global;

  /// No description provided for @personal.
  ///
  /// In sk, this message translates to:
  /// **'Osobné'**
  String get personal;

  /// No description provided for @sheets.
  ///
  /// In sk, this message translates to:
  /// **'položiek'**
  String get sheets;

  /// No description provided for @addMusicSheet.
  ///
  /// In sk, this message translates to:
  /// **'Pridať notový záznam'**
  String get addMusicSheet;

  /// No description provided for @edit.
  ///
  /// In sk, this message translates to:
  /// **'Upraviť'**
  String get edit;

  /// No description provided for @change.
  ///
  /// In sk, this message translates to:
  /// **'Zmeniť'**
  String get change;

  /// No description provided for @noMusicSheets.
  ///
  /// In sk, this message translates to:
  /// **'Nenašli sa žiadne noty'**
  String get noMusicSheets;

  /// No description provided for @add.
  ///
  /// In sk, this message translates to:
  /// **'Pridať'**
  String get add;

  /// No description provided for @resetPasswordMessage.
  ///
  /// In sk, this message translates to:
  /// **'Zadajte svoju e-mailovú adresu a my vám pošleme odkaz na obnovenie hesla.'**
  String get resetPasswordMessage;

  /// No description provided for @enterEmail.
  ///
  /// In sk, this message translates to:
  /// **'Zadajte svoj e-mail'**
  String get enterEmail;

  /// No description provided for @enterEmailHint.
  ///
  /// In sk, this message translates to:
  /// **'Zadajte svoj e-mail'**
  String get enterEmailHint;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In sk, this message translates to:
  /// **'Prosím, zadajte svoj e-mail'**
  String get pleaseEnterEmail;

  /// No description provided for @passwordResetLinkSent.
  ///
  /// In sk, this message translates to:
  /// **'Odkaz na obnovenie hesla bol odoslaný na váš e-mail'**
  String get passwordResetLinkSent;

  /// No description provided for @playlistName.
  ///
  /// In sk, this message translates to:
  /// **'Názov zoznamu'**
  String get playlistName;

  /// No description provided for @enterPlaylistName.
  ///
  /// In sk, this message translates to:
  /// **'Zadajte názov zoznamu'**
  String get enterPlaylistName;

  /// No description provided for @playlistNameEmpty.
  ///
  /// In sk, this message translates to:
  /// **'Názov zoznamu nemôže byť prázdny'**
  String get playlistNameEmpty;

  /// No description provided for @theme.
  ///
  /// In sk, this message translates to:
  /// **'Téma'**
  String get theme;

  /// No description provided for @darkTheme.
  ///
  /// In sk, this message translates to:
  /// **'Tmavá téma'**
  String get darkTheme;

  /// No description provided for @lightTheme.
  ///
  /// In sk, this message translates to:
  /// **'Svetlá téma'**
  String get lightTheme;

  /// No description provided for @systemTheme.
  ///
  /// In sk, this message translates to:
  /// **'Systémová téma'**
  String get systemTheme;

  /// No description provided for @tapToView.
  ///
  /// In sk, this message translates to:
  /// **'Kliknutím zobrazíte'**
  String get tapToView;

  /// No description provided for @deletePlaylist.
  ///
  /// In sk, this message translates to:
  /// **'Vymazať zoznam skladieb'**
  String get deletePlaylist;

  /// No description provided for @deletePlaylistMessage.
  ///
  /// In sk, this message translates to:
  /// **'Ste si istý, že chcete vymazať tento zoznam? Táto akcia sa nedá vrátiť späť!'**
  String get deletePlaylistMessage;

  /// No description provided for @about.
  ///
  /// In sk, this message translates to:
  /// **'O aplikácii'**
  String get about;

  /// No description provided for @aboutMessage.
  ///
  /// In sk, this message translates to:
  /// **'Aplikácia na správu notových záznamov\nVytvoril Pavol Vlček'**
  String get aboutMessage;

  /// No description provided for @appSettings.
  ///
  /// In sk, this message translates to:
  /// **'Nastavenia aplikácie'**
  String get appSettings;

  /// No description provided for @accountManagement.
  ///
  /// In sk, this message translates to:
  /// **'Správa účtu'**
  String get accountManagement;

  /// No description provided for @version.
  ///
  /// In sk, this message translates to:
  /// **'Verzia'**
  String get version;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In sk, this message translates to:
  /// **'Často kladené otázky'**
  String get frequentlyAskedQuestions;

  /// No description provided for @couldNotOpenUrl.
  ///
  /// In sk, this message translates to:
  /// **'Nepodarilo sa otvoriť URL'**
  String get couldNotOpenUrl;

  /// No description provided for @errorOpeningUrl.
  ///
  /// In sk, this message translates to:
  /// **'Chyba pri otváraní URL: {error}'**
  String errorOpeningUrl(Object error);

  /// No description provided for @fileTooLarge.
  ///
  /// In sk, this message translates to:
  /// **'Súbor je príliš veľký. Maximálna veľkosť je {maxSize}MB.'**
  String fileTooLarge(Object maxSize);

  /// No description provided for @anErrorHappened.
  ///
  /// In sk, this message translates to:
  /// **'Nastala chyba'**
  String get anErrorHappened;

  /// No description provided for @showNavigationArrows.
  ///
  /// In sk, this message translates to:
  /// **'Zobraziť navigačné šípky'**
  String get showNavigationArrows;

  /// No description provided for @authErrorUnknownTitle.
  ///
  /// In sk, this message translates to:
  /// **'Chyba pri prihlásení'**
  String get authErrorUnknownTitle;

  /// No description provided for @authErrorUnknownText.
  ///
  /// In sk, this message translates to:
  /// **'Neznáma chyba'**
  String get authErrorUnknownText;

  /// No description provided for @authGenericExceptionTitle.
  ///
  /// In sk, this message translates to:
  /// **'Chyba pri prihlásení'**
  String get authGenericExceptionTitle;

  /// No description provided for @authGenericExceptionText.
  ///
  /// In sk, this message translates to:
  /// **'Vyskytla sa neznáma chyba'**
  String get authGenericExceptionText;

  /// No description provided for @authErrorUserNotLoggedInTitle.
  ///
  /// In sk, this message translates to:
  /// **'Používateľ nie je prihlásený!'**
  String get authErrorUserNotLoggedInTitle;

  /// No description provided for @authErrorUserNotLoggedInText.
  ///
  /// In sk, this message translates to:
  /// **'Žiadny používateľ nie je momentálne prihlásený!'**
  String get authErrorUserNotLoggedInText;

  /// No description provided for @authErrorRequiresRecentLoginTitle.
  ///
  /// In sk, this message translates to:
  /// **'Vyžaduje sa prihlásenie znova'**
  String get authErrorRequiresRecentLoginTitle;

  /// No description provided for @authErrorRequiresRecentLoginText.
  ///
  /// In sk, this message translates to:
  /// **'Musíte sa odhlásiť a znova prihlásiť, aby ste mohli vykonať túto operáciu'**
  String get authErrorRequiresRecentLoginText;

  /// No description provided for @authErrorOperationNotAllowedTitle.
  ///
  /// In sk, this message translates to:
  /// **'Operácia nie je povolená'**
  String get authErrorOperationNotAllowedTitle;

  /// No description provided for @authErrorOperationNotAllowedText.
  ///
  /// In sk, this message translates to:
  /// **'Nemôžete sa zaregistrovať pomocou tejto metódy v tomto momente!'**
  String get authErrorOperationNotAllowedText;

  /// No description provided for @authErrorUserNotFoundTitle.
  ///
  /// In sk, this message translates to:
  /// **'Používateľ nebol nájdený'**
  String get authErrorUserNotFoundTitle;

  /// No description provided for @authErrorUserNotFoundText.
  ///
  /// In sk, this message translates to:
  /// **'Zadaný používateľ nebol nájdený na serveri!'**
  String get authErrorUserNotFoundText;

  /// No description provided for @authErrorWeakPasswordTitle.
  ///
  /// In sk, this message translates to:
  /// **'Slabé heslo'**
  String get authErrorWeakPasswordTitle;

  /// No description provided for @authErrorWeakPasswordText.
  ///
  /// In sk, this message translates to:
  /// **'Prosím, vyberte silnejšie heslo skladajúce sa z viacerých znakov!'**
  String get authErrorWeakPasswordText;

  /// No description provided for @authErrorInvalidEmailTitle.
  ///
  /// In sk, this message translates to:
  /// **'Neplatný e-mail'**
  String get authErrorInvalidEmailTitle;

  /// No description provided for @authErrorInvalidEmailText.
  ///
  /// In sk, this message translates to:
  /// **'Prosím, skontrolujte svoj e-mail a skúste to znova!'**
  String get authErrorInvalidEmailText;

  /// No description provided for @authErrorEmailAlreadyInUseTitle.
  ///
  /// In sk, this message translates to:
  /// **'Užívateľ s daným emailom už existuje.'**
  String get authErrorEmailAlreadyInUseTitle;

  /// No description provided for @authErrorEmailAlreadyInUseText.
  ///
  /// In sk, this message translates to:
  /// **'Prosím, použite iný e-mail na registráciu!'**
  String get authErrorEmailAlreadyInUseText;

  /// No description provided for @authErrorUserDisabledTitle.
  ///
  /// In sk, this message translates to:
  /// **'Používateľský účet je deaktivovaný'**
  String get authErrorUserDisabledTitle;

  /// No description provided for @authErrorUserDisabledText.
  ///
  /// In sk, this message translates to:
  /// **'Tento používateľský účet bol deaktivovaný. Prosím, kontaktujte podporu pre pomoc.'**
  String get authErrorUserDisabledText;

  /// No description provided for @authErrorInvalidCredentialTitle.
  ///
  /// In sk, this message translates to:
  /// **'Neplatné prihlasovacie údaje'**
  String get authErrorInvalidCredentialTitle;

  /// No description provided for @authErrorInvalidCredentialText.
  ///
  /// In sk, this message translates to:
  /// **'Zadané prihlasovacie údaje sú nesprávne, skontrolujte email a heslo.'**
  String get authErrorInvalidCredentialText;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'sk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'sk': return AppLocalizationsSk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
