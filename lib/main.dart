import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:organista/services/auth/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:organista/blocs/simple_bloc_observer.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/views/app_repository.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.firebase().initialize();
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
