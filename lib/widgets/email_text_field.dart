import 'package:flutter/material.dart';
import 'package:organista/widgets/custom_text_field.dart';

class EmailTextField extends CustomTextField {
  const EmailTextField({
    super.key,
    required super.controller,
    required super.hintText,
  }) : super(
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        );
}
