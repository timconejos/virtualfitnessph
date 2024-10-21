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
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers for text fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Loading state for the registration button
  bool _isLoading = false;

  // Password validation state
  bool _isPasswordValid = false;

  // Authentication service instance
  final _authService = AuthService();

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerificationScreen()),
        );
      } else {
        _showSnackBar('Registration failed: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Registration failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, String> _encryptData({
    required String username,
    required String email,
    required String password,
  }) {
    final keyString = sha256
        .convert(utf8.encode('my32lengthsupersecretnooneknows1'))
        .toString()
        .substring(0, 32);
    final key = encrypt.Key.fromUtf8(keyString);
    final iv = encrypt.IV.fromUtf8('myivforvrphtimco');
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );

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
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegExp.hasMatch(email);
  }

  bool _validatePassword(String password) {
    final passwordRegExp = RegExp(r'^(?=.*[a-z])(?=.*\d).{7,}$');
    return passwordRegExp.hasMatch(password);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
    ValueChanged? onChanged,
  }) {
    return PrimaryTextField(
      controller: controller,
      isPassword: obscureText,
      onChanged: onChanged,
      labelText: labelText,
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
          'A lowercase letter',
          _passwordController.text.contains(RegExp(r'[a-z]')),
        ),
        _buildPasswordRequirement(
          'A number',
          _passwordController.text.contains(RegExp(r'\d')),
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
            _buildTextField(
              controller: _emailController,
              labelText: 'Enter your email',
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _usernameController,
              labelText: 'Enter a username',
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _passwordController,
              labelText: 'Enter a password',
              obscureText: true,
              onChanged: (value) {
                 setState(() {
                  _isPasswordValid = _validatePassword(value);
                });
              },
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _confirmPasswordController,
              labelText: 'Confirm password',
              obscureText: true,
            ),
            const SizedBox(height: 10),
            _buildPasswordRequirements(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: AppStyles.primaryButtonStyle,
              child: _isLoading
                  ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  SizedBox(width: 20),
                  Text('Please wait...')
                ],
              )
                  : const Text('Register'),
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
}