import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:virtualfitnessph/models/race.dart';
import 'package:virtualfitnessph/services/auth_service.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

class RegisterRaceScreen extends StatefulWidget {
  final Race race;

  const RegisterRaceScreen({super.key, required this.race});

  @override
  _RegisterRaceScreenState createState() => _RegisterRaceScreenState();
}

class _RegisterRaceScreenState extends State<RegisterRaceScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final List<String> sizes = ['NONE', 'XS', 'S', 'M', 'L', 'XL', 'XXL'];
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _selectedSize;
  String? _selectedRange;
  String? _selectedRaceType;
  double _selectedRacePrice = 0;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  void _register() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    String? userId = await AuthService().getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in'), backgroundColor: Colors.red),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    var registration = Registration(
      userId: userId,
      raceId: widget.race.raceId,
      racetype: _selectedRaceType ?? 'Default Race Type',
      tshirtSize: _selectedSize ?? 'NONE',
      raceDistance: double.tryParse(_selectedRange ?? '0') ?? 0,
      address: _addressController.text,
      contactNumber: _contactController.text,
      referenceNumber: _referenceController.text,
      agreedToTerms: _agreedToTerms,
      price: _selectedRacePrice,
      approved: false,
      distanceProgress: 0,
      completed: false,
    );

    try {
      final response = await AuthService().registerRace(registration.toJson());
      if (response['status'] == 200) {
        showDialog(
          context: context,
          barrierDismissible: false, // User must tap button to close dialog
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Registration Successful'),
              content: const Text('Your registration is waiting for approval. Please check your email for further details.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Dismiss the dialog
                    Navigator.of(context).pop(); // Go back to the previous page
                  },
                ),
              ],
            );
          },
        );
      } else if (response['status'] == 409) {
        showDialog(
          context: context,
          barrierDismissible: false, // User must tap button to close dialog
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Already Registered'),
              content: const Text('You are already registered for this race.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Dismiss the dialog
                  },
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register for ${widget.race.raceName}')
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildTextField(_firstNameController, 'First Name'),
              buildTextField(_lastNameController, 'Last Name'),
              buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress),
              buildTextField(_addressController, 'Address'),
              buildTextField(_contactController, 'Contact Number', keyboardType: TextInputType.number, validator: _validateContactNumber),
              buildDropdown('T-shirt Size', _selectedSize, sizes, (newValue) {
                setState(() {
                  _selectedSize = newValue;
                });
              }),
              buildDropdown('Race Distance (KM)', _selectedRange, widget.race.distance, (newValue) {
                setState(() {
                  _selectedRange = newValue;
                });
              }),
              buildRaceTypeDropdown(),
              CheckboxListTile(
                title: Row(
                  children: [
                    const Text('I agree to the '),
                    GestureDetector(
                      onTap: _launchTerms,
                      child: const Text('terms and conditions',
                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
                value: _agreedToTerms,
                onChanged: (value) => setState(() => _agreedToTerms = value!),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              ElevatedButton(
                onPressed: _agreedToTerms ? _register : null,
                style: AppStyles.primaryButtonStyle,
                child: const Text('REGISTER'),
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

  Widget buildDropdown(String label, String? currentValue, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      value: currentValue,
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select $label' : null,
      items: items.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
    );
  }

  Widget buildRaceTypeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Race Type'),
      value: _selectedRaceType,
      onChanged: (newValue) {
        setState(() {
          _selectedRaceType = newValue;
          _selectedRacePrice = widget.race.racetypes
              .firstWhere((type) => type.name == newValue)
              .price;
        });
      },
      validator: (value) => value == null ? 'Please select Race Type' : null,
      items: widget.race.racetypes.map((type) {
        return DropdownMenuItem<String>(
          value: type.name,
          child: Text('${type.name} - P${type.price}'),
        );
      }).toList(),
    );
  }

  void _launchTerms() async {
    const url = 'https://virtualfitnessph.com/terms-and-conditions/';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  String? _validateContactNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter Contact Number';
    } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Contact Number must be digits only';
    }
    return null;
  }
}

class Registration {
  String userId;
  int raceId;
  String racetype;
  String contactNumber;
  String address;
  String tshirtSize;
  double raceDistance;
  String referenceNumber;
  bool agreedToTerms;
  bool approved;
  double distanceProgress;
  double price;
  bool completed;

  Registration({
    required this.userId,
    required this.raceId,
    required this.racetype,
    required this.contactNumber,
    required this.address,
    required this.tshirtSize,
    required this.raceDistance,
    required this.referenceNumber,
    required this.agreedToTerms,
    required this.approved,
    required this.distanceProgress,
    required this.price,
    required this.completed,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'raceId': raceId,
      'racetype': racetype,
      'contactNumber': contactNumber,
      'address': address,
      'tshirtSize': tshirtSize,
      'raceDistance': raceDistance,
      'referenceNumber': referenceNumber,
      'agreedToTerms': agreedToTerms,
      'approved': approved,
      'distanceProgress': distanceProgress,
      'price': price,
      'completed': completed,
    };
  }

  static Registration fromJson(Map<String, dynamic> json) {
    return Registration(
      userId: json['userId'],
      raceId: json['raceId'],
      racetype: json['racetype'],
      contactNumber: json['contactNumber'],
      address: json['address'],
      tshirtSize: json['tshirtSize'],
      raceDistance: json['raceDistance'],
      referenceNumber: json['referenceNumber'],
      agreedToTerms: json['agreedToTerms'],
      approved: json['approved'],
      distanceProgress: json['distanceProgress'],
      price: json['price'],
      completed: json['completed'],
    );
  }
}
