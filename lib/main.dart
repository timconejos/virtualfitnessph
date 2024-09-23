import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtualfitnessph/screens/splash_screen.dart';
import 'package:virtualfitnessph/services/permissions_service.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissionsOnce();
  runApp(const MyApp());
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
  const MyApp({Key? key}) : super(key: key); // Cleaned constructor

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Virtual Fitness PH',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: AppStyles.scaffoldBgColor,
        textTheme: AppStyles.vifitTextTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: AppStyles.primaryForeground,
          centerTitle: false,
          titleTextStyle: AppStyles.vifitTextTheme.headlineMedium,
        ),
      ),
      home: const SplashScreen(), // Set SplashScreen as the home widget
    );
  }
}