import 'dart:async';

import 'package:bloc/bloc.dart';
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
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
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

/// This function must be called before using any Firebase services also in tests
Future<void> firebaseInitialize() async {
  // Firebase.initializeApp must be called before using any Firebase services
  await Firebase.initializeApp(
    options: await DefaultFirebaseOptions.currentPlatform,
  );
}
