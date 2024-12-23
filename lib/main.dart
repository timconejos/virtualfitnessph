import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtualfitnessph/screens/splash_screen.dart';
import 'package:virtualfitnessph/services/permissions_service.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _requestPermissionsOnce();
  runApp(MyApp());
}

Future<void> _requestPermissionsOnce() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isPermissionsRequested = prefs.getBool('isPermissionsRequested') ?? false;

  if (!isPermissionsRequested) {
    var permissionService = PermissionsService();
    await permissionService.requestPermissions();
    prefs.setBool('isPermissionsRequested', true);
  }
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key); // Cleaned constructor

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Virtual Fitness PH',
      theme: ThemeData(
        colorScheme: const ColorScheme(brightness: Brightness.light, 
          primary: AppStyles.primaryColor, 
          onPrimary: AppStyles.primaryForeground, 
          secondary: AppStyles.secondaryColor, 
          onSecondary: AppStyles.primaryForeground, 
          error: Colors.red, 
          onError: Colors.white, 
          surface: Colors.white, 
          onSurface: AppStyles.textColor),
        primaryColor: AppStyles.primaryColor,
        scaffoldBackgroundColor: AppStyles.scaffoldBgColor,
        textTheme: AppStyles.vifitTextTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: AppStyles.primaryForeground,
          centerTitle: true,
          titleTextStyle: AppStyles.vifitTextTheme.titleMedium,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppStyles.darkerPrimary,
          circularTrackColor: AppStyles.lighterPrimary,
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: AppStyles.buttonColor,
        ),
        dividerTheme: const DividerThemeData(
          color: Color.fromARGB(255, 235, 235, 235),
          thickness: 1,
          indent: 3,
          endIndent: 3
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              elevation: 1.0,
              backgroundColor: AppStyles.primaryColor,
              foregroundColor: AppStyles.primaryForeground,
              disabledBackgroundColor: AppStyles.primaryColor.withOpacity(0.4),
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              textStyle: AppStyles.vifitTextTheme.labelLarge,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppStyles.darkerPrimary, // Text color
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(),
          focusColor: AppStyles.primaryColor,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
            borderRadius: BorderRadius.circular(8.0)
          ),
        )

      ),
      home: const SplashScreen(), // Set SplashScreen as the home widget
    );
  }
}