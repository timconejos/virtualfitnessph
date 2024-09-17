import 'package:flutter/material.dart';

class AppStyles {
  // main color
  static const Color primaryColor = Color(0xFF0302dc);
  static const Color secondaryColor = Color(0xFFd90e0a);
  static const Color textColor = Color(0xFF1e1e1e);
  static const Color primaryForeground = Colors.white;

  // Button colors
  static const Color buttonColor = Color(0xFFffdb03);
  static const Color buttonTextColor = Color(0xFF1e1e1e);
  static const Color iconColor = Colors.white;

  // Background colorss
  static const Color bgColor = Color(0xFFb4d7ff);

   // Define text styles
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

   // Define button styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  );

}