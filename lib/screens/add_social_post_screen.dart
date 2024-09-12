import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';

class AddSocialPostScreen extends StatefulWidget {
  const AddSocialPostScreen({super.key});

  @override
  _AddSocialPostScreenState createState() => _AddSocialPostScreenState();
}

class _AddSocialPostScreenState extends State<AddSocialPostScreen> {
  File? _imageFile;
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final AuthService _authService = AuthService();

  Future<void> pickImage(ImageSource source) async {
    // Calculate the maximum width based on the screen size or a specific view size
    double screenWidth = MediaQuery.of(context).size.width;

    // Pick the image with the maxWidth set to the screen's width for better performance
    final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: screenWidth,
        imageQuality: 50  // Optionally reduce quality to further ensure file size reduction
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> uploadImage() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select an image first."))
      );
      return;
    }

    const String baseUrl = 'http://97.74.90.63:8080';
    Uri uri = Uri.parse('$baseUrl/feed');
    http.MultipartRequest request = http.MultipartRequest('POST', uri);

    // Attach the image file
    request.files.add(
        await http.MultipartFile.fromPath('image', _imageFile!.path)
    );

    // Add other form data
    request.fields['caption'] = _captionController.text;
    request.fields['location'] = _locationController.text;

    // Retrieve the user ID from SharedPreferences and add it to the request
    String? userId = await _authService.getUserId();
    if (userId != null) {
      request.fields['user_id'] = userId;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User Name not found. Please log in again."))
      );
      return;
    }

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        print('Uploaded successfully');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Post uploaded successfully!"))
        );
        Navigator.pop(context); // Optionally return to the previous screen
      } else {
        print('Failed to upload');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to upload post."))
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An error occurred."))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Social Post"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_imageFile != null)
              Image.file(_imageFile!, height: 300, fit: BoxFit.cover),
            const SizedBox(height: 20),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                labelText: 'Caption',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null,  // Allows for any number of lines
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                  onPressed: () => pickImage(ImageSource.camera),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // Light grey
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Gallery"),
                  onPressed: () => pickImage(ImageSource.gallery),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploadImage,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue,
              ),
              child: const Text("Post"),
            ),
          ],
        ),
      ),
    );
  }
}
