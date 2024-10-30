// lib/components/confirm_pass_points_dialog.dart

import 'package:flutter/material.dart';

class ConfirmPassPointsDialog extends StatelessWidget {
  final String profileImageUrl;
  final String userName;
  final double amount;

  const ConfirmPassPointsDialog({
    Key? key,
    required this.profileImageUrl,
    required this.userName,
    required this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Confirm Pass Points',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enlarged Profile Picture
          Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 224, 224, 224),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.network(
                  profileImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                    return Image.asset('assets/profile.png', height: 100, width: double.infinity, fit: BoxFit.cover);
                  },
              ),
            )
            ),
          // CircleAvatar(
          //   radius: 50, // Adjust the radius as needed
          //   backgroundImage: NetworkImage(profileImageUrl),
          //   backgroundColor: Colors.grey.shade200,
          // ),
          const SizedBox(height: 20),
          // Username Display
          Text(
            userName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          // Confirmation Message
          const Text(
            'Are you sure you want to pass these points to this user?',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'This action cannot be undone.',
            style: TextStyle(color: Colors.red.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Display Points to be Shared
          Text(
            'Amount: $amount coins',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
          onPressed: () {
            Navigator.of(context).pop(false); // User canceled
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, // Red color to indicate caution
          ),
          child: const Text('Confirm'),
          onPressed: () {
            Navigator.of(context).pop(true); // User confirmed
          },
        ),
      ],
    );
  }
}