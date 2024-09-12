import 'package:flutter/material.dart';
import 'package:virtualfitnessph/screens/login_screen.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Registration Success!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Please check your email for verification.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()), // Replace MainPage with your main page widget
                        (Route<dynamic> route) => false,
                  );
                },
                child: const Text('Go to Login Page'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
