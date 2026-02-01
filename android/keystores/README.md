# Android Keystores

## Problem Description

### The Error

When using Google Sign-In on Android, users encountered the following error:

```
GoogleSignInException(code GoogleSignInExceptionCode.canceled, [16] Account reauth failed., null)
```

### Root Cause

This error occurred because Firebase requires SHA-1/SHA-256 certificate fingerprints to be registered for Google Sign-In to work. By default, each developer machine has its own debug keystore with unique fingerprints.

Every time development happened on a new computer, the SHA fingerprints would be different, causing:
- Automatic OAuth cancellation (not user-initiated)
- "[16] Account reauth failed" errors
- Need to repeatedly add new fingerprints to Firebase Console
- Accumulation of multiple OAuth credentials in Firebase/Google Cloud Console

### Solution

Use a **shared debug keystore** committed to the repository, ensuring all developers use the same SHA fingerprints.

## Debug Keystore

The `debug.keystore` file in this directory is a **shared debug keystore** used by all developers.

### Configuration

- **File:** `android/keystores/debug.keystore`
- **Password:** `android`
- **Key Alias:** `androiddebugkey`
- **Key Password:** `android`

### SHA Fingerprints (Debug)

These fingerprints must be registered in the Firebase Console for the Android app:

- **SHA-1:** `D4:45:F3:97:FD:01:90:78:8C:A5:41:6F:3A:CA:9C:77:87:C2:D3:66`
- **SHA-256:** `B2:59:57:A6:E7:66:3E:4C:CB:A6:DC:75:3D:41:E6:D8:86:F9:10:1C:D9:15:D9:15:D1:DB:55:4C:D6:19:B9:AF`

### Security

This debug keystore is safe to commit to the repository because:
1. It's only used for debug builds (never production)
2. Debug builds cannot be published to the Play Store
3. It uses standard Android debug credentials
4. SHA fingerprints are public identifiers (like SSL certificate fingerprints)

## Production/Release Keystore

The production keystore is **NOT** stored in this repository for security reasons. It's configured via environment variables:
- `ANDROID_KEYSTORE_FILE`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

### SHA Fingerprints (Production)

These fingerprints must also be registered in the Firebase Console for the Android app:

- **SHA-1:** `C5:D9:62:62:8E:62:B0:1E:2E:A3:A2:E8:C1:EE:BD:32:F2:03:4C:FF`
- **SHA-256:** `C4:08:FA:3C:4F:5C:CA:91:8E:AC:CC:B2:38:DA:BE:CE:E0:B4:C7:44:41:45:82:44:D6:B8:B8:E3:AA:0D:4C:3D`

## Firebase Console Setup

To configure Firebase with these fingerprints:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Project Settings** (gear icon)
4. Scroll down to **Your apps** section
5. Select the Android app (`sk.anickaapavol.organista`)
6. In the **SHA certificate fingerprints** section, ensure you have:
   - The debug SHA-1 and SHA-256 (above)
   - The production SHA-1 and SHA-256 (above)
7. Remove any old/duplicate fingerprints from previous development machines

## Benefits

✅ Google Sign-In works consistently across all development machines
✅ No need to update Firebase when switching computers
✅ Clean Firebase configuration with only necessary fingerprints
✅ New developers can start working immediately after cloning the repo
