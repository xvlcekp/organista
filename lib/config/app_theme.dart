import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      surfaceColor: Colors.white,
      onSurfaceColor: Colors.black.withAlpha(150),
      hintColor: Colors.grey[600]!,
      labelColor: Colors.grey[800]!,
    );
  }

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      surfaceColor: Colors.black.withAlpha(150),
      onSurfaceColor: Colors.white,
      hintColor: Colors.grey[400]!,
      labelColor: Colors.white,
    );
  }

  static Brightness reverseBrightness(Brightness brightness) {
    switch (brightness) {
      case Brightness.light:
        return Brightness.dark;
      case Brightness.dark:
        return Brightness.light;
    }
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color surfaceColor,
    required Color onSurfaceColor,
    required Color hintColor,
    required Color labelColor,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: brightness,
      surface: surfaceColor,
      onSurface: onSurfaceColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: colorScheme.surface,
          statusBarIconBrightness: reverseBrightness(colorScheme.brightness),
          statusBarBrightness: reverseBrightness(colorScheme.brightness),
          systemNavigationBarColor: colorScheme.surface,
          systemNavigationBarIconBrightness: reverseBrightness(colorScheme.brightness),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          backgroundColor: colorScheme.primary, // Use primary color from color scheme
          foregroundColor: colorScheme.onPrimary, // Use onPrimary color from color scheme
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: surfaceColor,
        hintStyle: TextStyle(
          color: hintColor,
        ),
        labelStyle: TextStyle(
          color: labelColor,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
        ),
      ),
    );
  }
}
