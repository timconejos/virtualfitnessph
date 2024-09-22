import 'package:flutter/material.dart';

class AppStyles {
  // main color
  static const Color primaryColor = Color(0xFF0302dc);
  static const Color secondaryColor = Color(0xFFd90e0a);
  static const Color unselectedColor = Color(0x800302dc);
  static const Color darkerPrimary = Color(0xFF0000BC);
  static const Color textColor = Color(0xFF1e1e1e);
  static const Color primaryForeground = Colors.white;

  // Button colors
  static const Color buttonColor = Color(0xFFffdb03);
  static const Color buttonTextColor = Color(0xFF1e1e1e);
  static const Color iconColor = Colors.white;

  // Background colorss
  static const Color bgColor = Color(0xFFb4d7ff);
  static const Color scaffoldBgColor = Color(0xFFF7F7F7);

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

  static TextTheme vifitTextTheme = TextTheme(

      displayLarge: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w300, fontSize: 57.0),
      displayMedium: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w300, fontSize: 45.0),
      displaySmall: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w400, fontSize: 36.0),

      headlineLarge: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w700, fontSize: 32.0),
      headlineMedium: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w900, fontSize: 28.0),
      headlineSmall: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w700, fontSize: 24.0),

      titleLarge: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w600, fontSize: 22.0),
      titleMedium: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w700, fontSize: 16.0),
      titleSmall: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w500, fontSize: 14.0),

      labelLarge: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w800, fontSize: 16.0),
      labelMedium: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w700, fontSize: 14.0),
      labelSmall: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w700, fontSize: 12.0),

      bodyLarge: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w700, fontSize: 16.0),
      bodyMedium: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w700, fontSize: 14.0),
      bodySmall: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w500, fontSize: 12.0),

  );

  static ThemeData vifitTheme = ThemeData(
    textTheme: vifitTextTheme,
  );

}