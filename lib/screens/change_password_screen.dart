import 'package:flutter/material.dart';
import 'package:virtualfitnessph/services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isPasswordValid = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    _userId = await _authService.getUserId();
  }

  void _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final String oldPassword = _oldPasswordController.text;
    final String newPassword = _newPasswordController.text;

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('User not found.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Verify old password
    final verifyResponse = await _authService.verifyPassword(_userId!, oldPassword);
    if (verifyResponse.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Old password is incorrect.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Change password
    final changeResponse = await _authService.changePassword(_userId!, oldPassword, newPassword);
    if (changeResponse.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password changed successfully!'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to change password.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  bool _validatePassword(String password) {
    final passwordRegExp = RegExp(
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~]).{7,}$');
    return passwordRegExp.hasMatch(password);
  }

  void _onPasswordChanged() {
    setState(() {
      _isPasswordValid = _validatePassword(_newPasswordController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _oldPasswordController,
                decoration: InputDecoration(
                  labelText: 'Old Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isOldPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isOldPasswordVisible = !_isOldPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isOldPasswordVisible,
                validator: (value) =>
                value!.isEmpty ? 'Old Password is required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isNewPasswordVisible,
                onChanged: (_) => _onPasswordChanged(),
                validator: (value) =>
                value!.isEmpty ? 'New Password is required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmNewPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isNewPasswordVisible,
                validator: (value) {
                  if (value!.isEmpty) return 'Confirm New Password is required';
                  if (value != _newPasswordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildPasswordRequirements(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _changePassword,
                child: const Text('Change Password'),
              ),
            ],
          ),
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
          _newPasswordController.text.length >= 7,
        ),
        _buildPasswordRequirement(
          'An uppercase letter',
          _newPasswordController.text.contains(RegExp(r'[A-Z]')),
        ),
        _buildPasswordRequirement(
          'A lowercase letter',
          _newPasswordController.text.contains(RegExp(r'[a-z]')),
        ),
        _buildPasswordRequirement(
          'A number',
          _newPasswordController.text.contains(RegExp(r'\d')),
        ),
        _buildPasswordRequirement(
          'A special character (e.g., !@#\$&*~)',
          _newPasswordController.text.contains(RegExp(r'[!@#\$&*~]')),
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