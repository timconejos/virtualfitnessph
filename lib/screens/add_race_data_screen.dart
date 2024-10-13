import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:virtualfitnessph/services/auth_service.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

class AddRaceDataScreen extends StatefulWidget {
  final int? initialRaceId;

  const AddRaceDataScreen({super.key, this.initialRaceId});

  @override
  _AddRaceDataScreenState createState() => _AddRaceDataScreenState();
}

class _AddRaceDataScreenState extends State<AddRaceDataScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late List<dynamic> races = [];
  final List<String> _selectedRaces = [];
  bool isLoading = true;
  bool isSubmitting = false;
  XFile? _image;
  String? userId;
  final AuthService _authService = AuthService();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadJoinedRaces();
  }

  Future<void> _loadJoinedRaces() async {
    userId = await _authService.getUserId();
    setState(() => isLoading = true);
    const String baseUrl = 'http://97.74.90.63:8080';
    Uri uri = Uri.parse('$baseUrl/api/registrations/user/$userId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          races = json.decode(response.body);
          if (widget.initialRaceId != 0 && widget.initialRaceId != null) {
            _selectedRaces.add(widget.initialRaceId.toString());
          }
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load race details');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading races: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    setState(() {
      _image = pickedFile;
    });
    Navigator.pop(context);
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate() || _image == null) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      var result = await _authService.submitRaceData(
        userId: userId!,
        raceIds: _selectedRaces,
        distanceKm: double.parse(_distanceController.text),
        hours: int.parse(_hoursController.text),
        minutes: int.parse(_minutesController.text),
        seconds: int.parse(_secondsController.text),
        location: _locationController.text,
        image: File(_image!.path),
      );

      if (result['submissionId'] != 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Submission Received'),
            content: const Text(
                'Your submission is waiting for admin approval. Please wait for an email within the day.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).pop(); // Go back to the previous screen
                },
              ),
            ],
          ),
        );
      } else {
        throw Exception('Failed to submit race data');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to submit race data. Please try again later.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }


void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 130,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Race Data'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select races to credit this data:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            height: 300,
                            // Increased height for the scrollable section
                            child: Column(
                              children: [
                                const CheckboxListTile(
                                  title: Text(
                                    'Personal Data',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                      'We will automatically credit this run to your personal data'),
                                  value: true,
                                  onChanged: null,
                                ),
                                const Divider(),
                                Expanded(
                                  child: races.isEmpty
                                      ? const Center(
                                          child: Text('No races available'))
                                      : ListView(
                                          children: races.map((race) {
                                            return CheckboxListTile(
                                              title: Text(
                                                race['race']['raceName'],
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              subtitle: Text(
                                                race['race']['description'] ??
                                                    '',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              value: _selectedRaces.contains(
                                                  race['race']['raceId']
                                                      .toString()),
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  if (value == true) {
                                                    _selectedRaces.add(
                                                        race['race']['raceId']
                                                            .toString());
                                                  } else {
                                                    _selectedRaces.remove(
                                                        race['race']['raceId']
                                                            .toString());
                                                  }
                                                });
                                              },
                                            );
                                          }).toList(),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _distanceController,
                        decoration:
                            const InputDecoration(labelText: 'Distance (in km)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter distance' : null,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _hoursController,
                              decoration: const InputDecoration(labelText: 'HH'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter hours';
                                } else if (value.length > 2) {
                                  return 'Max 2 digits';
                                }
                                return null;
                              },
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(2)
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _minutesController,
                              decoration: const InputDecoration(labelText: 'MM'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter minutes';
                                } else if (value.length > 2) {
                                  return 'Max 2 digits';
                                }
                                return null;
                              },
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(2)
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _secondsController,
                              decoration: const InputDecoration(labelText: 'SS'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter seconds';
                                } else if (value.length > 2) {
                                  return 'Max 2 digits';
                                }
                                return null;
                              },
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(2)
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(labelText: 'Location'),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter location' : null,
                      ),
                      const SizedBox(height: 15),
                      const Text('Upload Proof: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,), textAlign: TextAlign.start),
                      const SizedBox(height: 5),
                      GestureDetector(
                        onTap: () => _showUploadOptions(context),
                        child: Container(
                          width: double.infinity,
                          // height: 150,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey, // Border color
                              width: 1.0, // Border width
                            ),
                            borderRadius: BorderRadius.circular(8.0), // Rounded border
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_upload, size: 50, color:  Colors.grey),
                              TextButton(
                                onPressed: () => _showUploadOptions(context), // Updated onPressed
                                child: const Text("Upload photo", style: TextStyle(color: Colors.blue)),
                              ),
                              
                              if (_image != null) Image.file(File(_image!.path)),
                            ],
                          ),
                        ),
                      ),

                      
                      const SizedBox(height: 15),
                      // Column(
                      //   crossAxisAlignment: CrossAxisAlignment.start,
                      //   children: [
                      //     const Text('Upload Proof:',
                      //         style: TextStyle(
                      //             fontSize: 16, fontWeight: FontWeight.bold)),
                      //     Row(
                      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //       children: [
                      //         ElevatedButton.icon(
                      //           onPressed: () => _pickImage(ImageSource.camera),
                      //           style: AppStyles.primaryButtonStyleInvertSmall,
                      //           icon: const Icon(Icons.camera_alt),
                      //           label: const Text('Camera'),
                      //         ),
                      //         ElevatedButton.icon(
                      //           onPressed: () =>
                      //               _pickImage(ImageSource.gallery),
                      //           icon: const Icon(Icons.image),
                      //           style: AppStyles.primaryButtonStyleInvertSmall,
                      //           label: const Text('Gallery'),
                      //         ),
                      //       ],
                      //     ),
                      //   ],
                      // ),
                      const SizedBox(height: 5),
                      isSubmitting
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitData,
                              child: const Text('Submit'),
                            )),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
