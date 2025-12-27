// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Organista';

  @override
  String get loading => 'Loading...';

  @override
  String get modifyMusicSheet => 'Modify music sheet';

  @override
  String get musicSheetName => 'Music sheet name';

  @override
  String get discard => 'Discard';

  @override
  String get save => 'Save';

  @override
  String get noMusicSheetsYet => 'No music sheets yet';

  @override
  String get addYourFirstMusicSheet => 'Add your first music sheet to get started';

  @override
  String get selectImageFirst => 'You have to select an image first';

  @override
  String get discardChanges => 'Discard Changes';

  @override
  String get discardChangesMessage => 'Are you sure you want to discard changes?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get delete => 'Delete';

  @override
  String get deleteImage => 'Delete image';

  @override
  String get deleteImageMessage => 'Are you sure you want to delete this image? You cannot undo this operation!';

  @override
  String get logout => 'Logout';

  @override
  String get logoutMessage => 'Are you sure you want to logout?';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountMessage => 'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get verifyPassword => 'Verify Password';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get verifyPasswordRequired => 'Please verify your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get login => 'Login';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get register => 'Register';

  @override
  String get playlists => 'Playlists';

  @override
  String get repositories => 'Repositories';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get slovak => 'Slovak';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get passwordResetEmailSent => 'Password reset email sent. Please check your inbox.';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get userNotFound => 'User not found';

  @override
  String get wrongPassword => 'Wrong password';

  @override
  String get emailAlreadyInUse => 'Email already in use';

  @override
  String get weakPassword => 'Weak password';

  @override
  String get networkError => 'Network error';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signUpToGetStarted => 'Sign up to get started';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get download => 'Download';

  @override
  String get downloadTooltip => 'Download music sheet';

  @override
  String get deleteTooltip => 'Delete music sheet';

  @override
  String get renamePlaylist => 'Rename playlist';

  @override
  String get rename => 'Rename';

  @override
  String get ok => 'OK';

  @override
  String get musicSheet => 'Music Sheet';

  @override
  String get musicSheetId => 'Music Sheet ID';

  @override
  String get playlist => 'Playlist';

  @override
  String get user => 'User';

  @override
  String get category => 'Category';

  @override
  String get repository => 'Repository';

  @override
  String get displayName => 'Display Name';

  @override
  String get name => 'Name';

  @override
  String get createdAt => 'Created At';

  @override
  String get fileUrl => 'File URL';

  @override
  String get fileName => 'File Name';

  @override
  String get mediaType => 'Media Type';

  @override
  String get image => 'Image';

  @override
  String get pdf => 'PDF';

  @override
  String get unsupportedFileExtension => 'Unsupported file extension';

  @override
  String noMatchingMediaType(Object mediaType) {
    return 'No matching MediaType for: $mediaType';
  }

  @override
  String get myPlaylists => 'My Playlists';

  @override
  String get newPlaylist => 'New Playlist';

  @override
  String get noPlaylistsYet => 'No playlists yet';

  @override
  String get createFirstPlaylist => 'Create your first playlist';

  @override
  String get musicSheets => 'Music sheets';

  @override
  String get searchMusicSheets => 'Search music sheets...';

  @override
  String get noMusicSheetsFound => 'No music sheets found';

  @override
  String get noGlobalRepositories => 'No global repositories available.';

  @override
  String get noPersonalRepositories => 'No personal repositories available.';

  @override
  String get global => 'Global';

  @override
  String get personal => 'Personal';

  @override
  String sheets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sheets',
      one: 'sheet',
    );
    return '$_temp0';
  }

  @override
  String get addMusicSheet => 'Add music sheet';

  @override
  String get edit => 'Edit';

  @override
  String get change => 'Change';

  @override
  String get noMusicSheets => 'No music sheets found';

  @override
  String get add => 'Add';

  @override
  String get resetPasswordMessage => 'Enter your email address and we\'ll send you a link to reset your password.';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterEmailHint => 'Enter your email';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get passwordResetLinkSent => 'Password reset link sent to your email';

  @override
  String get playlistName => 'Playlist name';

  @override
  String get enterPlaylistName => 'Enter playlist name';

  @override
  String get inputCannotBeEmpty => 'Input cannot be empty';

  @override
  String get inputCannotBeSameAsCurrent => 'Input cannot be the same as the current name';

  @override
  String get theme => 'Theme';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get lightTheme => 'Light theme';

  @override
  String get systemTheme => 'System theme';

  @override
  String get tapToView => 'Tap to view';

  @override
  String get deletePlaylist => 'Delete playlist';

  @override
  String get deletePlaylistMessage => 'Are you sure you want to delete this playlist? You cannot undo this operation!';

  @override
  String get about => 'About';

  @override
  String get aboutMessage => 'A music sheet management application\nCreated by Pavol Vlček';

  @override
  String get appSettings => 'App Settings';

  @override
  String get accountManagement => 'Account Management';

  @override
  String get version => 'Version';

  @override
  String get frequentlyAskedQuestions => 'Frequently Asked Questions';

  @override
  String get couldNotOpenUrl => 'Could not open the URL';

  @override
  String errorOpeningUrl(String url) {
    return 'Error opening URL: $url';
  }

  @override
  String fileTooLarge(int maxSize) {
    return 'File is too large. Maximum size is ${maxSize}MB.';
  }

  @override
  String get anErrorHappened => 'An error happened';

  @override
  String get showNavigationArrows => 'Show navigation arrows';

  @override
  String get keepScreenOn => 'Keep screen on';

  @override
  String get errorUnknownText => 'Unknown error';

  @override
  String get authGenericExceptionText => 'An unknown error occurred';

  @override
  String get authErrorUserNotLoggedInText => 'No user is currently logged in!';

  @override
  String get authErrorRequiresRecentLoginText =>
      'You need to log out and log back in again in order to perform this operation';

  @override
  String get authErrorOperationNotAllowedText => 'You cannot register using this method at this moment!';

  @override
  String get authErrorUserNotFoundText => 'The given user was not found on the server!';

  @override
  String get authErrorWeakPasswordText => 'Please choose a stronger password consisting of more characters!';

  @override
  String get authErrorInvalidEmailText => 'Please double check your email and try again!';

  @override
  String get authErrorEmailAlreadyInUseText => 'Please choose another email to register with!';

  @override
  String get authErrorUserDisabledText => 'This user has been disabled. Please contact support for help.';

  @override
  String get authErrorInvalidCredentialText => 'The supplied auth credential is incorrect, malformed or has expired.';

  @override
  String get authErrorGoogleSignInFailedText => 'Google Sign-In failed. Please try again.';

  @override
  String get authErrorAppleSignInFailedText => 'Sign in with Apple failed. Please try again.';

  @override
  String musicSheetAlreadyInPlaylist(String musicSheetName, String playlistName) {
    return 'Music sheet \'$musicSheetName\' already exists in playlist \'$playlistName\'.';
  }

  @override
  String multipleMusicSheetsAlreadyInPlaylist(String musicSheetNames, String playlistName) {
    return 'The following music sheets already exist in playlist \'$playlistName\': $musicSheetNames';
  }

  @override
  String playlistCapacityExceeded(int attemptedToAdd, String playlistName, int currentCount, int maxCapacity) {
    return 'Cannot add $attemptedToAdd music sheets to playlist \'$playlistName\'. Playlist currently has $currentCount/$maxCapacity music sheets. Maximum capacity is $maxCapacity music sheets.';
  }

  @override
  String get musicSheetInitializationError => 'An error happened while initialization.';

  @override
  String get selectAll => 'Select all';

  @override
  String get unselectAll => 'Unselect all';

  @override
  String get repositoryName => 'Repository name';

  @override
  String get enterRepositoryName => 'Enter repository name';

  @override
  String get newRepository => 'New repository';

  @override
  String get renameRepository => 'Rename repository';

  @override
  String get deleteRepository => 'Delete repository';

  @override
  String deleteRepositoryMessage(String repositoryName) {
    return 'Are you sure you want to delete repository \'$repositoryName\'? This will also delete all music sheets in it. This action cannot be undone!';
  }

  @override
  String get repositoryGenericError => 'An error occurred while performing the repository operation';

  @override
  String get repositoryNotFoundError => 'Repository not found';

  @override
  String get repositoryCannotModifyPublicError => 'Cannot modify public repositories';

  @override
  String get repositoryCannotModifyOtherUsersError => 'You can only modify your own repositories';

  @override
  String maximumRepositoriesCountExceededError(int maximumRepositoriesCount) {
    return 'You have reached the maximum number of repositories ($maximumRepositoriesCount). Please delete some repositories before creating new ones.';
  }

  @override
  String get noFileDataAvailable => 'No file data available';

  @override
  String get storageManagement => 'Storage Management';

  @override
  String get storedFiles => 'Stored files';

  @override
  String get storageSize => 'Storage size';

  @override
  String get clearStorage => 'Clear storage';

  @override
  String get clearStorageConfirmTitle => 'Clear Storage?';

  @override
  String clearStorageConfirmMessage(int count, String size) {
    return 'This will delete all stored files ($count files, $size MB). Music sheets will need to be re-downloaded when accessed again.';
  }

  @override
  String get storageClearedSuccess => 'Storage cleared successfully';

  @override
  String get storageSummary => 'Storage Summary';

  @override
  String get aboutStorage => 'About Storage';

  @override
  String get storageDescription => 'Stored files allow faster loading of music sheets you\'ve already viewed.';

  @override
  String storageRemovalInfo(int days, int maxObjects) {
    return 'Files are automatically removed when they haven\'t been accessed for $days days or when the storage reaches its maximum capacity of $maxObjects files.';
  }

  @override
  String get manageStoredMusicSheets => 'Manage stored music sheets';

  @override
  String get exportToPdf => 'Export to PDF';

  @override
  String get exportSuccess => 'Playlist exported successfully';

  @override
  String get exportFailed => 'Failed to export playlist';

  @override
  String get noMusicSheetsToExport => 'No music sheets to export';

  @override
  String get exportErrorSourceFileNotFound => 'Source file not found';

  @override
  String get exportErrorSaveFailed => 'Failed to save file';

  @override
  String get exportCancelled => 'Export cancelled';

  @override
  String get fillAllFields => 'Please fill in all fields';
}
