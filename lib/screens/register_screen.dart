import 'package:flutter/material.dart';
import 'package:virtualfitnessph/models/user.dart';
import 'package:virtualfitnessph/screens/verification_screen.dart';
import 'package:virtualfitnessph/services/auth_service.dart';
import 'package:virtualfitnessph/components/primary_text_field.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false; // Track loading state
  bool _isPasswordValid = false;
  final _authService = AuthService();

  void _register() async {
    if (!_validateFields()) return; // Validate fields before proceeding
    setState(() => _isLoading = true);

    try {
      var encryptedData = _encryptData(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      var user = User(
        username: encryptedData['username']!,
        email: encryptedData['email']!,
        password: encryptedData['password']!,
      );

      var response = await _authService.register(user);
      if (response.statusCode == 200) {
        String userId = response.body;
        await _authService.sendVerificationEmail(_emailController.text, userId);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VerificationScreen()));
      } else {
        _showSnackBar('Registration failed: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Registration failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, String> _encryptData({required String username, required String email, required String password}) {
    final key = encrypt.Key.fromUtf8(sha256.convert(utf8.encode('my32lengthsupersecretnooneknows1')).toString().substring(0, 32));
    final iv = encrypt.IV.fromUtf8('myivforvrphtimco');
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));

    final encryptedUsername = encrypter.encrypt(username, iv: iv).base64;
    final encryptedEmail = encrypter.encrypt(email, iv: iv).base64;
    final encryptedPassword = encrypter.encrypt(password, iv: iv).base64;

    return {
      'username': encryptedUsername,
      'email': encryptedEmail,
      'password': encryptedPassword,
    };
  }

  bool _validateFields() {
    if (!_validateEmail(_emailController.text)) {
      _showSnackBar('Invalid email format.');
      return false;
    }

    if (_usernameController.text.length < 4) {
      _showSnackBar('Username must be at least 4 characters long.');
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match.');
      return false;
    }

    if (!_isPasswordValid) {
      _showSnackBar('Password does not meet the requirements.');
      return false;
    }

    return true;
  }

  bool _validateEmail(String email) {
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegExp.hasMatch(email);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  bool _validatePassword(String password) {
    final passwordRegExp = RegExp(
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~]).{7,}$');
    return passwordRegExp.hasMatch(password);
  }

  void _onPasswordChanged() {
    setState(() {
      _isPasswordValid = _validatePassword(_passwordController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   leading: BackButton(onPressed: () => Navigator.pop(context)),
      //   title: const Text('Register'),
      // ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(50.0, 10.0, 50.0, 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Create an account', 
            textAlign: TextAlign.start,
            style: AppStyles.vifitTextTheme.headlineMedium?.copyWith(color: AppStyles.primaryColor)),
            const SizedBox(height: 20),
            PrimaryTextField(
              labelText: 'Enter your email',
              controller: _emailController,
              // decoration: const InputDecoration(labelText: 'Enter your email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            PrimaryTextField(
              labelText: 'Enter a username',
              controller: _usernameController,
              // decoration: const InputDecoration(labelText: 'Enter a username', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            PrimaryTextField(
              labelText: 'Enter a password',
              controller: _passwordController,
              isPassword: true,
              // obscureText: true,
              onChanged: (_) => _onPasswordChanged(),
              // decoration: const InputDecoration(
              //   labelText: 'Enter a password',
              //   border: OutlineInputBorder(),
            ),
            const SizedBox(height: 10),
            PrimaryTextField(
              labelText: 'Confirm Password',
              isPassword: true,
              controller: _confirmPasswordController,
              // obscureText: true,
              // decoration: const InputDecoration(
              //   labelText: 'Confirm Password',
              //   border: OutlineInputBorder(),
              // ),
            ),
            const SizedBox(height: 10),
            _buildPasswordRequirements(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: AppStyles.primaryButtonStyle,
              child: _isLoading ? const Row(
                // mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  Text('Please wait...')
                ],
              ) : Text('Register', style: AppStyles.vifitTextTheme.titleMedium),
            ),
            const SizedBox(height: 30),
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
    );
  }

  Widget _buildPasswordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password must contain:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        _buildPasswordRequirement(
          'At least 7 characters',
          _passwordController.text.length >= 7,
        ),
        _buildPasswordRequirement(
          'An uppercase letter',
          _passwordController.text.contains(RegExp(r'[A-Z]')),
        ),
        _buildPasswordRequirement(
          'A lowercase letter',
          _passwordController.text.contains(RegExp(r'[a-z]')),
        ),
        _buildPasswordRequirement(
          'A number',
          _passwordController.text.contains(RegExp(r'\d')),
        ),
        _buildPasswordRequirement(
          'A special character (e.g., !@#\$&*~)',
          _passwordController.text.contains(RegExp(r'[!@#\$&*~]')),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirement(String requirement, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check : Icons.close,
          color: met ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 10),
        Text(requirement),
      ],
    );
  }
}