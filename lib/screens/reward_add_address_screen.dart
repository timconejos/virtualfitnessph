import 'package:flutter/material.dart';
import 'package:virtualfitnessph/screens/order_placed_screen.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

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

  void _saveAddress() async { 
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderPlacedScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
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
              buildTextField(_contactController, 'Contact'),
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

}