import 'package:flutter/material.dart';
import 'package:virtualfitnessph/services/auth_service.dart';

class FollowersFollowingScreen extends StatelessWidget {
  final String title;
  final List<dynamic> users;
  final Function(dynamic) onUserTap;
  final AuthService _authService = AuthService();

  FollowersFollowingScreen({
    super.key,
    required this.title,
    required this.users,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<String>(
        future: _authService.getBaseUrl(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading base URL'));
          } else {
            final baseUrl = snapshot.data ?? '';
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      '$baseUrl/profiles/${users[index]['id']}.jpg',
                    ),
                  ),
                  title: Text(_authService.decryptData(users[index]['username'])),
                  onTap: () => onUserTap(users[index]),
                );
              },
            );
          }
        },
      ),
    );
  }
}