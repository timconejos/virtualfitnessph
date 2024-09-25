import 'package:flutter/material.dart';
import 'package:virtualfitnessph/services/auth_service.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';
import 'package:virtualfitnessph/components/primary_text_field.dart';
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _forgotPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _authService.forgotPassword(
      _usernameController.text,
      _emailController.text,
    );

    setState(() {
      _isLoading = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password Reset'),
        content: const Text(
            'If the email is valid, you will receive an email to reset your password.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Forgot Password'),
      // ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(50.0, 10.0, 50.0, 0.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Forgot Password', 
                textAlign: TextAlign.start,
                style: AppStyles.vifitTextTheme.headlineMedium?.copyWith(color: AppStyles.primaryColor)),
                const SizedBox(height: 20),
                const Text(
                  'Enter your username and email to reset your password. If the email is valid, you will receive a password reset link.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 16.0),
                PrimaryTextField(
                  labelText: 'Username',
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16.0),
                PrimaryTextField(
                  labelText: 'Email',
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                // TextFormField(
                //   controller: _usernameController,
                //   decoration: const InputDecoration(
                //     labelText: 'Username',
                //     border: OutlineInputBorder(),
                //   ),
                //   validator: (value) {
                //     if (value == null || value.isEmpty) {
                //       return 'Please enter your username';
                //     }
                //     return null;
                //   },
                // ),
                // TextFormField(
                //   controller: _emailController,
                //   decoration: const InputDecoration(
                //     labelText: 'Email',
                //     border: OutlineInputBorder(),
                //   ),
                //   validator: (value) {
                //     if (value == null || value.isEmpty) {
                //       return 'Please enter your email';
                //     }
                //     if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                //       return 'Please enter a valid email address';
                //     }
                //     return null;
                //   },
                // ),
                const SizedBox(height: 16.0),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _forgotPassword,
                  child: const Text('Reset Password'),
                  style: AppStyles.primaryButtonStyle,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "Back to login",
                        style: AppStyles.vifitTextTheme.titleMedium?.copyWith(color: AppStyles.primaryColor),
                      ),
                    ),
                  ],
                ), 
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}