import 'package:flutter/material.dart';
import 'package:organista/widgets/custom_text_field.dart';

class PasswordTextField extends CustomTextField {
  PasswordTextField({
    super.key,
    required super.controller,
    required super.hintText,
    required super.obscureText,
    required VoidCallback onToggleVisibility,
  }) : super(
         prefixIcon: Icons.lock_outline,
         suffixIcon: IconButton(
           icon: Icon(
             obscureText ? Icons.visibility_off : Icons.visibility,
             color: Colors.grey,
           ),
           onPressed: onToggleVisibility,
         ),
       );
}
