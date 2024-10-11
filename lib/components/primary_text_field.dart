import 'package:flutter/material.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

class PrimaryTextField extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon_;
  final Widget? prefixIcon_;
  final ValueChanged? onChanged;
  final Function(String)? onSubmitted;

  PrimaryTextField({
    required this.labelText,
    this.hintText,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon_,
    this.prefixIcon_ = null,
    this.onChanged,
    this.onSubmitted = null
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword, // To toggle password visibility
      keyboardType: keyboardType,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(),
        suffixIcon: suffixIcon_,
        prefixIcon: prefixIcon_,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppStyles.primaryColor, width: 2.0),
          borderRadius: BorderRadius.circular(8.0)
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 1.0),
          borderRadius: BorderRadius.circular(8.0)
        ),
        focusColor: AppStyles.primaryColor,
        // labelStyle: TextStyle(color: Colors.grey),
        hintStyle: TextStyle(color: Colors.grey),
      ),
      validator: validator,
    );
  }
}