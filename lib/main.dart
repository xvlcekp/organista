import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:organista/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:organista/blocs/simple_bloc_observer.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/views/app_repository.dart';
import 'package:provider/provider.dart';

void main() async {
  await mainInitialize();
  await logger.setup();
  Bloc.observer = SimpleBlocObserver(logger: logger);
  logger.i('App started');

  final prefs = await SharedPreferences.getInstance();
  runApp(
    Provider<SharedPreferences>.value(
      value: prefs,
      child: const AppRepository(),
    ),
  );
}

/// This function must be called before using any Firebase services also in tests
Future<void> mainInitialize() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase.initializeApp must be called before using any Firebase services
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
