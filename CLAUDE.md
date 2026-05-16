# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Organista is a Flutter app for Slovak organists. It lets users manage playlists of music sheets (PDF, image, MusicXML formats), view them full-screen, transpose MusicXML digitally, and export playlists to PDF. Backend is Firebase (Firestore, Storage, Auth, AppCheck, Analytics).

## Common Commands

```bash
# Run the app
flutter run

# Run all tests
flutter test

# Run a single test file
flutter test test/features/show_music_sheet/hooks/pdf_load_result_test.dart

# Analyze code
flutter analyze

# Format code (line-length=120 is enforced by pre-commit hook)
dart format --line-length=120 lib/ test/

# Generate mocks (after adding @GenerateMocks annotations)
dart run build_runner build --delete-conflicting-outputs

# Update Firebase Functions JS dependencies
cd functions/ && npm update

# Regenerate app icons (after changing assets/images/organista_icon.png)
dart run flutter_launcher_icons:generate

# Regenerate native splash screen
dart run flutter_native_splash:create
```

## Architecture

### State Management
BLoC/Cubit pattern throughout. Each feature follows the structure:
- `bloc/` or `cubit/` — state, events, and the bloc/cubit class
- `view/` — Flutter widgets that consume the bloc/cubit
- `error/` — feature-specific error types (where applicable)

Global blocs provided at the `App` level: `AuthBloc`, `PlaylistBloc`, `AddEditMusicSheetCubit`, `SettingsCubit`.

### Layer Structure
```
lib/
  main.dart               — Firebase/Sentry init, entry point
  views/app_repository.dart — Provides repositories via RepositoryProvider
  views/app.dart          — Provides global blocs, routes between Login/Register/PlaylistPage
  features/               — Feature modules (auth, playlists, repositories, music sheets, settings, etc.)
  repositories/           — Firebase data layer (FirebaseFirestoreRepository, FirebaseStorageRepository, SettingsRepository)
  services/               — Auth, wakelock, export-to-PDF services
  managers/               — PersistentCacheManager, StreamManager
  models/                 — Domain models (MusicSheet, Playlist, Repository, MediaType, etc.)
  config/                 — AppTheme, AppConstants, ConfigController
  l10n/                   — Localizations (SK primary, EN secondary)
```

### Key Design Decisions

**Repositories** are injected via `RepositoryProvider` at the top of the widget tree. Features access them with `context.read<FirebaseFirestoreRepository>()`.

**Authentication flow**: `AuthBloc` drives navigation — `AuthStateLoggedOut` → `LoginView`, `AuthStateLoggedIn` → `PlaylistPage`, `AuthStateIsInRegistrationView` → `RegisterView`.

**Music sheet types**: `MediaType` enum (`image`, `pdf`, `musicxml`). MusicXML is rendered in a WebView with transpose controls. PDFs use `pdfx`. Images use `cached_network_image`/`photo_view`.

**Cache management**: `PersistentCacheManager` wraps a patched fork of `flutter_cache_manager` (see `dependency_overrides` in `pubspec.yaml`). Files are stored in the app's files directory (not the OS temp cache) via `PersistentFileSystem` to prevent OS-initiated eviction. Do not upgrade `flutter_cache_manager` without checking the override is still needed.

**Firebase Streams**: `StreamManager.instance` tracks active Firestore listeners so they can all be cancelled before account deletion (prevents permission-denied errors).

**Error tracking**: Sentry. Captured via `Sentry.captureException()` in catch blocks and automatically via `SentryWidget` wrapper. `SentryWidget` wraps the root widget in `main.dart`.

### Testing Patterns
- BLoC logic: `bloc_test` package
- Firebase: `fake_cloud_firestore` for Firestore, `mockito`/`mocktail` for Storage/other services
- Generated mocks: `.mocks.dart` files alongside test files, regenerated via `build_runner`
- `firebaseInitialize()` is factored out of `main()` for reuse in integration tests

## Code Style

- Line length: **120 characters** (enforced by pre-commit hook and formatter config in `analysis_options.yaml`)
- Trailing commas: preserved (formatter config)
- Linting: `flutter_lints` + `bloc_lint/recommended` + `dart_code_metrics` rules (see `analysis_options.yaml`)
- No magic numbers — extract to `AppConstants`
- One class per file

## Releasing

1. Update `CHANGELOG.md`
2. Bump version in `pubspec.yaml`
3. Commit and push, then create a GitHub release tag
4. Codemagic automatically builds and distributes on a release tag (via Shorebird integration)

## Android Signing (local only)

Keystore property files in `android/app/keystore/` are gitignored. Create them locally — see README for exact format. Codemagic uses its own native signing and ignores these.

## Firebase Functions

`functions/index.js` contains a Cloud Function (`deleteStorageFilesOnDocDelete`) that auto-deletes Storage files when a Firestore `musicSheet` document is deleted. After deploying, remove stale artifacts from Google Artifact Registry.

## Credentials in CI

`assets/config/credentials.json` and `android/app/google_services.json` are stored as base64-encoded GitHub secrets (`CREDENTIALS_JSON_BASE64`, `GOOGLE_SERVICES_JSON_BASE64`). After changing either file locally, re-encode it with `openssl base64 < <file> | tr -d '\n'` and update the secret.
