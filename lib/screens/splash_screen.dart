import 'package:flutter/material.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) {
    // Duration of splash screen
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(ctx, '/home');
    });

    return Scaffold(
      backgroundColor: AppStyles.primaryColor, // Set your background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Add your logo or any other widgets here
            Image.asset('assets/icon.jpg'), // Add your logo image
            SizedBox(height: 20),
            Text('Move and conquer', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}