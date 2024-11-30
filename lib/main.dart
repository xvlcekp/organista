import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:organista/firebase_options.dart';
import 'package:organista/views/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const App(),
  );
}
