import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtualfitnessph/screens/main_page_screen.dart';
import 'package:virtualfitnessph/screens/login_screen.dart';
import 'package:virtualfitnessph/screens/splash_screen.dart';
import 'package:virtualfitnessph/services/permissions_service.dart';
import 'package:virtualfitnessph/services/auth_service.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissionsOnce();
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
  final AuthService _authService = AuthService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Virtual Fitness PH',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: AppStyles.scaffoldBgColor,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => FutureBuilder(
            future: _authService.isUserLoggedIn(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text('Error: ${snapshot.error}'),
                  ),
                );
              } else {
                bool isLoggedIn = snapshot.data as bool;
                return isLoggedIn ? const MainPageScreen() : const LoginScreen();
              }
            },
          ),
      },
      // home: FutureBuilder(
      //   future: _authService.isUserLoggedIn(),
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const Scaffold(
      //         body: Center(
      //           child: CircularProgressIndicator(),
      //         ),
      //       );
      //     } else if (snapshot.hasError) {
      //       return Scaffold(
      //         body: Center(
      //           child: Text('Error: ${snapshot.error}'),
      //         ),
      //       );
      //     } else {
      //       bool isLoggedIn = snapshot.data as bool;
      //       return isLoggedIn ? const MainPageScreen() : const LoginScreen();
      //     }
      //   },
      // ),
    );
  }
}