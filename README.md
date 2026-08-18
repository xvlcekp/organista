# Organista

[![Codemagic build status](https://api.codemagic.io/apps/69246add8c4a7a82d015b54e/69246add8c4a7a82d015b54d/status_badge.svg)](https://codemagic.io/app/69246add8c4a7a82d015b54e/69246add8c4a7a82d015b54d/latest_build)

Info about project for organists: https://sites.google.com/view/organista-app/domov

## Novinky (changelog)

Prehľad noviniek a hlavných funkcií aplikácie s obrázkami a videami je v používateľskej príručke:
**https://xvlcekp.github.io/organista/whats-new/**

Zdrojom je súbor [`docs/user-guide/whats-new.md`](docs/user-guide/whats-new.md) — jediné miesto,
kde sa novinky udržiavajú (single source of truth). Pri vydaní novej verzie pridajte novú sekciu tam.

## Releasing a new version

1. **write changes** to `CHANGELOG.md` file
2. **increase app version** + bundle & commit
3. **create a release tag on github** - and set the release as primary
4. **upload to playstore** - on release tag a bundle is created automatically. Just download it and upload to Google Play

### Update JS libraries

In this project we use Firebase functions. As they use 3rd party JS libraries, they need to be regulary updated. To update them run:  
`cd functions/`  
`npm update`

## Android Signing

Android signing is configured via property files in `android/app/keystore/`. Both files are gitignored and must be created locally.

### `android/app/keystore/debug_signing.properties` (debug builds)

```properties
storeFile=keystore/debug.keystore
storePassword=<keystore_password>
keyAlias=androiddebugkey
keyPassword=<key_password>
```

### `android/app/keystore/release_signing.properties` (release builds)

```properties
storeFile=keystore/organista.keystore
storePassword=<keystore_password>
keyAlias=organista
keyPassword=<key_password>
```

### Google Play App Signing (Production)

When the app is published to the Play Store, Google Play may re-sign the app with its own key. The fingerprints for the **Google Play App Signing** key must also be registered in Firebase to allow Google Sign-In for the Play Store version of the app.

**SHA Fingerprints (Google Play):**

- **SHA-1:** `06:F8:40:7B:DE:0E:EA:DD:24:EC:93:01:3B:F7:30:F2:9F:D7:9E:00`
- **SHA-256:** `8C:84:30:D3:AE:0B:8A:85:9D:8A:28:2F:40:E9:1C:B6:D7:CB:3D:BA:2D:EC:6E:12:D3:6F:63:FD:81:67:45:40`

**Security Note:**
It is safe for these SHA fingerprints to be publicly visible. They are public identifiers of the certificate and cannot be used to recreate private keys.

### Codemagic

Codemagic uses its own native code signing and ignores the Gradle signing config. No property files are needed on CI.

If you modify `assets/config/credentials.json`, you need to change it also in the pipeline.

1. Generate new encoded credentials.json file
   `cd assets/config/ && openssl base64 < credentials.json | tr -d '\n' | tee`
1. Upload the key to `CREDENTIALS_JSON_BASE64` repository secret to github.

If you modify `android/app/google_services.json`, you need to change it also in the pipeline.

1. Generate new encoded google_services.json file
   `cd android/app/ && openssl base64 < google-services.json | tr -d '\n' | tee`
2. Upload the key to `GOOGLE_SERVICES_JSON_BASE64` repository secret to github.

## Flutter upgrade

- Go to folder where flutter is installed

### To latest stable version (prefered)

- `flutter upgrade`

### To specific version

- `git fetch`
- `git checkout 3.32.5`

Versions history:

- 3.29.3
- 3.32.5
- 3.38.1
- 3.41.9 - 16.5.2026

### iOS

Reinstall dependencies:

```
cd ios
pod deintegrate (remove all iOS dependencies from workspace)
pod install
```

Release process:

```
flutter build ipa --obfuscate --split-debug-info=build/ios/outputs/symbols
open /Users/palo/Projects/organista/build/ios/archive/Runner.xcarchive
```

Click the **Validate App** button. If any issues are reported, address them and produce another build. You can reuse the same build ID until you upload an archive.
After the archive has been successfully validated, click **Distribute App**.

## Caching PDFs/images

The library [flutter_cache_manager](https://pub.dev/packages/flutter_cache_manager) is not maintained for more then 1 year anymore. Since there is a bug that cache is not removed based on stalePerioad, or maxNrOfCachedFiles, it is overriden by a git commit which is not merged.
Another problem is that the library caches to cache directory which is not under full control of application and can be erased at any time. That is why a new `PersistentFileSystem` is added and necessary files are stored in /files folder. Be careful when updating the library, because there are these "hacks" (also mentioned in `pubspec.yaml`).

## Error Tracking

The app uses **Sentry** for error tracking and crash reporting. Sentry automatically captures:

- Unhandled exceptions and crashes
- BLoC/Cubit errors
- Unknown authentication errors
- Critical repository operations (user deletion, data streams)
- Storage operations (file uploads, deletions)

Errors are reported via `Sentry.captureException()` in catch blocks and automatically through `SentryWidget` wrapper for unhandled exceptions. Debug symbols, obfuscation maps, and source context are uploaded via `sentry_dart_plugin` during build for readable stack traces with source code visibility.

## Shorebird

Shorebird is a tool that allows instant patches for applications on iOS/Android without need reviews on stores. However Shorebird doesn't support obfuscation for iOS yet. They plan to add the support in year 2026.  
This is skipped so far and needs to be fixed in the future:  
`--obfuscate --split-debug-info=build/debug-info --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json`

The Shorebird is used as an integration on Codemagic - tool to auto deploy app to stores.
https://github.com/shorebirdtech/shorebird/issues/1619

## Firebase

**deleteStorageFilesOnDocDelete** - automation on firebase using Firebase Functions. When musicSheet document is deleted, also musicSheet file is deleted in Firebase Storage.  
_After every deployment, artifacts needs to be removed in Google Artifact Repository!_

## How to crop music sheets from multi-sheets PDF

1. Download [PDF Gear](https://www.pdfgear.com/)
2. Split PDF to separate pages. (PDF Gear -> Page -> mark all -> Extract Pages -> All)
3. Manually crop pages and rename them.

### Cors issue

https://stackoverflow.com/questions/65849071/flutter-firebase-storage-cors-issue

### Other projects

https://github.com/stanislavbebej/ejks
