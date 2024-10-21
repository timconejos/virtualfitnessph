import 'package:flutter/material.dart';
import 'dart:async';
import 'package:virtualfitnessph/screens/main_page_screen.dart';
import 'package:virtualfitnessph/screens/login_screen.dart';
import 'package:virtualfitnessph/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key); // Cleaned constructor

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Start the timer and navigate after a delay
    Timer(const Duration(seconds: 3), _navigateToNextScreen);
  }

  Future<void> _navigateToNextScreen() async {
    bool isLoggedIn = await _authService.isUserLoggedIn();
    if (!mounted) return; // Ensure the widget is still mounted
    if (isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainPageScreen(tab: 0)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF1F4), // Set background color to white
      body: Center(
        child: Image.asset(
          'assets/splash2.jpg', // Use your asset name
          fit: BoxFit.fitWidth, // Fit the image to the width of the screen
          width: double.infinity,
          alignment: Alignment.topCenter, // Align image to the top center
        ),
      ),
    );
  }
}