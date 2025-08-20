import 'package:flutter/material.dart';

extension NavigationExtensions on NavigatorState {
  /// Generic method to pop until a specific widget type is found
  void popUntilRoute<T extends Widget>(BuildContext context) {
    popUntil((route) {
      if (route is MaterialPageRoute) {
        return route.builder(context) is T;
      }
      return false;
    });
  }
}
