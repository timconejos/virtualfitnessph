import 'package:flutter/material.dart';
import 'package:virtualfitnessph/services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  // Visibility toggles for password fields
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;

  // Password validation state
  bool _isPasswordValid = false;

  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _newPasswordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    _userId = await _authService.getUserId();
  }

  void _onPasswordChanged() {
    setState(() {
      _isPasswordValid = _validatePassword(_newPasswordController.text);
    });
  }

  bool _validatePassword(String password) {
    final passwordRegExp = RegExp(r'^(?=.*[a-z])(?=.*\d).{7,}$');
    return passwordRegExp.hasMatch(password);
  }

  void _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final String oldPassword = _oldPasswordController.text;
    final String newPassword = _newPasswordController.text;

    if (_userId == null) {
      _showSnackBar('User not found.', isError: true);
      return;
    }

    // Verify old password
    final verifyResponse = await _authService.verifyPassword(_userId!, oldPassword);
    if (verifyResponse.statusCode != 200) {
      _showSnackBar('Old password is incorrect.', isError: true);
      return;
    }

    // Change password
    final changeResponse = await _authService.changePassword(_userId!, oldPassword, newPassword);
    if (changeResponse.statusCode == 200) {
      _showSnackBar('Password changed successfully!', isError: false);
      Navigator.pop(context);
    } else {
      _showSnackBar('Failed to change password.', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
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
          'A lowercase letter',
          _newPasswordController.text.contains(RegExp(r'[a-z]')),
        ),
        _buildPasswordRequirement(
          'A number',
          _newPasswordController.text.contains(RegExp(r'\d')),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool isPasswordVisible,
    required VoidCallback toggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: toggleVisibility,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$labelText is required';
        }
        if (labelText == 'Confirm New Password' && value != _newPasswordController.text) {
          return 'Passwords do not match';
        }
        if (labelText == 'New Password' && !_isPasswordValid) {
          return 'Password does not meet the requirements';
        }
        return null;
      },
    );
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
              _buildPasswordField(
                controller: _oldPasswordController,
                labelText: 'Old Password',
                isPasswordVisible: _isOldPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isOldPasswordVisible = !_isOldPasswordVisible;
                  });
                },
              ),
              const SizedBox(height: 10),
              _buildPasswordField(
                controller: _newPasswordController,
                labelText: 'New Password',
                isPasswordVisible: _isNewPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
              ),
              const SizedBox(height: 10),
              _buildPasswordField(
                controller: _confirmNewPasswordController,
                labelText: 'Confirm New Password',
                isPasswordVisible: _isNewPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
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
}