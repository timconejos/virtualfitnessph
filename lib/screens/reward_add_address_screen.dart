import 'package:flutter/material.dart';
import 'package:virtualfitnessph/screens/order_placed_screen.dart';
import 'package:virtualfitnessph/services/auth_service.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

import '../models/rewards_items.dart';

class RewardAddAddressScreen extends StatefulWidget {
  const RewardAddAddressScreen({super.key});

  @override
  _RewardAddAddressScreenState createState() => _RewardAddAddressScreenState();
}

class _RewardAddAddressScreenState extends State<RewardAddAddressScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final AuthService _authService = AuthService();

  void _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      // Fetch cart items
      final List<RewardsItems> cartItems = await _authService.getCartItems();
      final double totalAmount = cartItems.fold(0, (sum, item) => sum + item.amount);
      final List<int> purchasedItemIds = cartItems.map((item) => item.rewardsId).toList();

      // Get user details (assuming you are storing username and userId in shared preferences)
      final String? userId = await _authService.getUserId();
      final String? username = await _authService.getUserName();

      // Create shop entry
      final success = await _authService.createShopItem(
        userId: userId!,
        username: username!,
        name: _nameController.text,
        email: _emailController.text,
        contactNumber: _contactController.text,
        totalAmount: totalAmount,
        purchasedItems: purchasedItemIds,
      );

      if (success) {
        // If shop item is created, navigate to OrderPlacedScreen
        _authService.clearCart();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OrderPlacedScreen(),
          ),
        );
      } else {
        // Handle error (e.g., show a toast message)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient points.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check out'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please add delivery address'),
              const SizedBox(height: 20),
              buildTextField(_nameController, 'Name'),
              const SizedBox(height: 20),
              buildTextField(_addressController, 'Address'),
              const SizedBox(height: 20),
              buildTextField(_contactController, 'Contact', keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress, validator: _validateEmail),
              const SizedBox(height: 15),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveAddress,
                    style: AppStyles.primaryButtonStyle,
                    child: const Text('Confirm address'),
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String label, {bool readOnly = false, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator ?? (value) => value!.isEmpty ? 'Please enter $label' : null,
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email';
    }
    const emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    final regex = RegExp(emailPattern);
    if (!regex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
}