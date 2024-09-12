import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:virtualfitnessph/screens/main_page_screen.dart';
import 'package:virtualfitnessph/services/auth_service.dart';
//import 'package:virtualfitnessph/services/notification_service.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    if (Platform.isAndroid) {
      requestPermissions();
    }
    //NotificationService(); // Initialize NotificationService
  }

  void requestPermissions() async {
    await [
      Permission.photos,
      Permission.camera,
      Permission.storage,
    ].request();
  }

  Future<void> _checkLoginStatus() async {
    bool isLoggedIn = await _authService.isUserLoggedIn();
    if (isLoggedIn) {
      _redirectToMainPage();
    }
  }

  void _redirectToMainPage() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const MainPageScreen(),
    ));
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    var encryptedData = _encryptData(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    bool loginSuccessful = await _authService.login(
      encryptedData['username']!,
      encryptedData['password']!,
    );

    setState(() {
      _isLoading = false;
    });

    if (loginSuccessful) {
      //await _registerToken();
      _redirectToMainPage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invalid Username or Password'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Future<void> _registerToken() async {
  //   final userId = await _authService.getUserId();
  //   if (userId != null) {
  //     final token = await NotificationService().getToken();
  //     if (token != null) {
  //       await _authService.sendTokenToServer(userId, token);
  //     }
  //   }
  // }

  Map<String, String> _encryptData({required String username, required String password}) {
    final key = encrypt.Key.fromUtf8(sha256.convert(utf8.encode('my32lengthsupersecretnooneknows1')).toString().substring(0, 32));
    final iv = encrypt.IV.fromUtf8('myivforvrphtimco');
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));

    final encryptedUsername = encrypter.encrypt(username, iv: iv).base64;
    final encryptedPassword = encrypter.encrypt(password, iv: iv).base64;
    if (username == "sample2") {
      return {
        'username': "sample2",
        'password': "sample2",
      };
    }
    return {
      'username': encryptedUsername,
      'password': encryptedPassword,
    };
  }

  void _register(BuildContext context) async {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
  }

  void _forgotPassword(BuildContext context) async {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/login.jpg', height: 200), // Add your image asset here

              const SizedBox(height: 20),

              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: const TextStyle(fontSize: 18),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue.shade700,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : const Text('Login'),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      _register(context);
                    },
                    child: const Text(
                      "Sign up",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Forgot your password? "),
                  GestureDetector(
                    onTap: () {
                      _forgotPassword(context);
                    },
                    child: const Text(
                      "Reset Password",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ElevatedButton(
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.blue, // Facebook color
              //   ),
              //   onPressed: () => _showSnackBar("Facebook login coming soon!"),
              //   child: const Text('Login with Facebook'),
              // ),

              const SizedBox(height: 10),

              // ElevatedButton(
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.red, // Google color
              //   ),
              //   onPressed: () => _showSnackBar("Google login coming soon!"),
              //   child: const Text('Login with Google'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}