import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:organista/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:organista/logger/simple_bloc_observer.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/views/app_repository.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://a493ac2bef606c18e1d246869c6000c0@o4510482674089984.ingest.de.sentry.io/4510482675728464';
      // Adds request headers and IP for users, for more info visit:
      // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
      options.sendDefaultPii = true;
      options.enableLogs = true;
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;

      // Only capture errors in release mode
      options.environment = kDebugMode ? 'development' : 'production';
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase first (required before any Firebase services)
      await firebaseInitialize();
      final SharedPreferencesWithCache prefs = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(),
      );

      runApp(
        SentryWidget(
          child: Provider<SharedPreferencesWithCache>.value(
            value: prefs,
            child: const AppRepository(),
          ),
        ),
      );

      // Setup logger after app starts (non-blocking)
      // This prevents blocking the UI thread during startup
      unawaited(
        logger
            .setup()
            .then((_) {
              Bloc.observer = SimpleBlocObserver(logger: logger);
              logger.i('App started');
            })
            .catchError((error, stackTrace) {
              // Log error but don't crash - logging is not critical for app functionality
              debugPrint('Logger setup failed: $error');
              unawaited(Sentry.captureException(error, stackTrace: stackTrace));
            }),
      );
    },
  );
}

/// Fixed App Check debug token, supplied via `--dart-define=APP_CHECK_DEBUG_TOKEN=<uuid>`.
///
/// Without it the SDK generates a random token and stores it in local app storage, so a
/// reinstall, a "clear data" or a fresh emulator produces a new one that has to be
/// re-registered in the Firebase Console. Falls back to that behaviour when unset.
const _appCheckDebugToken = bool.hasEnvironment('APP_CHECK_DEBUG_TOKEN')
    ? String.fromEnvironment('APP_CHECK_DEBUG_TOKEN')
    : null;

/// This function must be called before using any Firebase services also in tests
Future<void> firebaseInitialize() async {
  if (Firebase.apps.isEmpty) {
    // No `name:` — every Firebase service in the app resolves via `.instance`, which is the
    // `[DEFAULT]` app. Passing a name creates a secondary app instead, which goes unnoticed on
    // Android/iOS (the native SDK already created `[DEFAULT]`, so this branch never runs) but
    // breaks web, where nothing else creates `[DEFAULT]`.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await FirebaseAppCheck.instance.activate(
    providerWeb: kDebugMode ? WebDebugProvider() : ReCaptchaV3Provider(''),
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider(debugToken: _appCheckDebugToken)
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider(debugToken: _appCheckDebugToken)
        : const AppleDeviceCheckProvider(),
  );
}
