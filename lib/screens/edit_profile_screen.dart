import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image/image.dart' as img;
import '../services/auth_service.dart';
import 'change_password_screen.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const EditProfileScreen({super.key, required this.profileData});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  String? _profilePicUrl;
  File? _newProfilePic;

  String userName = "";
  String userId = "";

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightFeetController = TextEditingController();
  final TextEditingController _heightInchesController = TextEditingController();
  final TextEditingController _fitnessGoalsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _loadProfileData();
  }

  Future<void> _loadProfilePicture() async {
    userId = await _authService.getUserId() ?? "";
    if (userId.isNotEmpty) {
      final String profilePicUrl =
          'http://97.74.90.63:8080/profiles/$userId.jpg?timestamp=${DateTime.now().millisecondsSinceEpoch}';
      try {
        final response = await http.head(Uri.parse(profilePicUrl));
        if (response.statusCode == 200) {
          setState(() {
            _profilePicUrl = profilePicUrl;
          });
        } else {
          setState(() {
            _profilePicUrl = null;
          });
        }
      } catch (e) {
        setState(() {
          _profilePicUrl = null;
        });
      }
    }
  }

  Future<File> _correctImageOrientation(File file) async {
    final image = img.decodeImage(await file.readAsBytes())!;
    final height = image.height;
    final width = image.width;

    if (width > height) {
      // Rotate 90 degrees if the image is in portrait mode
      final rotatedImage = img.copyRotate(image, angle: 270);
      await file.writeAsBytes(img.encodeJpg(rotatedImage));
    }

    return file;
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final correctedFile =
      await _correctImageOrientation(File(pickedFile.path));
      final compressedFile = await _compressImage(correctedFile);
      setState(() {
        _newProfilePic = compressedFile;
      });
    }
  }

  Future<File> _compressImage(File file) async {
    final filePath = file.absolute.path;

    // Read the image file
    final image = img.decodeImage(await file.readAsBytes());

    // Define the target size
    const int targetSize = 800;

    // Calculate the aspect ratio
    double aspectRatio = image!.width / image.height;

    // Determine new dimensions while preserving the aspect ratio
    int newWidth, newHeight;
    if (aspectRatio > 1) {
      // Landscape
      newWidth = targetSize;
      newHeight = (targetSize / aspectRatio).round();
    } else {
      // Portrait
      newWidth = (targetSize * aspectRatio).round();
      newHeight = targetSize;
    }

    // Scale down the image, keeping the aspect ratio
    final scaledImage = img.copyResize(image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.cubic);

    // Calculate the cropping area (center crop)
    int offsetX = (scaledImage.width - targetSize) ~/ 2;
    int offsetY = (scaledImage.height - targetSize) ~/ 2;

    // Crop the image
    final croppedImage = img.copyCrop(
      scaledImage,
      x: offsetX,
      y: offsetY,
      width: targetSize,
      height: targetSize,
    );

    // Get the file extension
    final extension = filePath.substring(filePath.lastIndexOf('.'));

    // Create a new file for the cropped image
    final croppedImagePath =
    filePath.replaceFirst(RegExp(r'\.[^\.]+$'), '_cropped$extension');
    final croppedImageFile = File(croppedImagePath);

    // Write the cropped image to the new file
    await croppedImageFile.writeAsBytes(img.encodeJpg(croppedImage));

    return croppedImageFile;
  }

  void _loadProfileData() {
    _firstNameController.text = widget.profileData['firstName'] ?? '';
    _middleNameController.text = widget.profileData['middleName'] ?? '';
    _lastNameController.text = widget.profileData['lastName'] ?? '';
    _addressController.text = widget.profileData['address'] ?? '';
    _phoneNumberController.text = widget.profileData['phoneNumber'] ?? '';
    _ageController.text = widget.profileData['age']?.toString() ?? '';
    _weightController.text = widget.profileData['weight']?.toString() ?? '';
    _heightFeetController.text =
        widget.profileData['heightFeet']?.toString() ?? '';
    _heightInchesController.text =
        widget.profileData['heightInches']?.toString() ?? '';
    _fitnessGoalsController.text = widget.profileData['fitnessGoals'] ?? '';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    userId = await _authService.getUserId() ?? "";
    userName = await _authService.getUserName() ?? "";

    if (userId.isEmpty || userName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('User details are incomplete.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (_newProfilePic != null) {
      String? imagePath =
      await _authService.setProfilePicture(_newProfilePic!, userId);
      if (imagePath != null) {
        setState(() {
          _profilePicUrl = 'http://97.74.90.63:8080/profiles/$imagePath';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to upload profile picture."),
          backgroundColor: Colors.red,
        ));
      }
    }

    final String url =
        'http://97.74.90.63:8080/userdetail/update?userId=$userId';
    final Map<String, dynamic> updatedProfileData = {
      'id': userId,
      'firstName': _firstNameController.text,
      'middleName': _middleNameController.text,
      'lastName': _lastNameController.text,
      'address': _addressController.text,
      'phoneNumber': _phoneNumberController.text,
      'age': int.tryParse(_ageController.text),
      'weight': double.tryParse(_weightController.text),
      'heightFeet': int.tryParse(_heightFeetController.text),
      'heightInches': int.tryParse(_heightInchesController.text),
      'fitnessGoals': _fitnessGoalsController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedProfileData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to update profile.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Widget _buildProfilePictureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        _newProfilePic != null
            ? CircleAvatar(
            radius: 60, backgroundImage: FileImage(_newProfilePic!))
            : (_profilePicUrl == null
            ? CircleAvatar(
          radius: 60,
          backgroundColor: Colors.red.shade200,
          child: const Icon(Icons.person, size: 60),
        )
            : GestureDetector(
              onTap: () => _showUploadOptions(context),
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(_profilePicUrl!))
              )),
        const SizedBox(height: 10),
        TextButton(
          // style: TextButton.styleFrom(foregroundColor: AppStyles.buttonColor, textStyle: AppStyles.vifitTextTheme.titleMedium),
          onPressed: () => _showUploadOptions(context), // Updated onPressed
          child: const Text("Change profile picture", style: TextStyle(color: Colors.blue)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 180,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.only(left: 20),
                child: const Text('Change profile picture', style: TextStyle(color: AppStyles.greyColor))
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take photo'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Choose from library'),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChangePasswordButton() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
        );
      },
      child: const Text('Change password', style: TextStyle(color: AppStyles.primaryColor)),
      // style: AppStyles.primaryButtonStyleInvertSmall,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProfilePictureSection(),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) =>
                value!.isEmpty ? 'First Name is required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _middleNameController,
                decoration: const InputDecoration(labelText: 'Middle Name'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) =>
                value!.isEmpty ? 'Last Name is required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) =>
                value!.isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) =>
                value!.isEmpty ? 'Phone Number is required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                validator: (value) => value!.isEmpty ? 'Age is required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (value) =>
                value!.isEmpty ? 'Weight is required' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightFeetController,
                      decoration: const InputDecoration(labelText: 'Height (Feet)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      validator: (value) =>
                      value!.isEmpty ? 'Feet is required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _heightInchesController,
                      decoration: const InputDecoration(labelText: 'Height (Inches)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      validator: (value) =>
                      value!.isEmpty ? 'Inches is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _fitnessGoalsController,
                decoration: const InputDecoration(labelText: 'Fitness Goals'),
              ),
              const SizedBox(height: 20),
             SizedBox(
              width: double.infinity,
              child:  ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save profile'),
              ),
             ),
              const SizedBox(height: 20),
              _buildChangePasswordButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}