# Organista

## Google play release

**Compile** - `flutter clean; flutter pub get; flutter build appbundle`

**import debug symbols** - 
/app/build/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib

https://stackoverflow.com/questions/62568757/playstore-error-app-bundle-contains-native-code-and-youve-not-uploaded-debug

## Firebase

**deleteStorageFilesOnDocDelete** - automation on firebase using Firebase Functions. When musicSheet document is deleted, also musicSheet file is deleted in Firebase Storage.  
*After every deployment, artifacts needs to be removed in Google Artifact Repository!*

### Cors issue
https://stackoverflow.com/questions/65849071/flutter-firebase-storage-cors-issue

### Other projects
https://github.com/stanislavbebej/ejks