// search_user_screen.dart

import 'dart:async'; // Import for Timer (if needed)
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../styles/app_styles.dart';
import 'view_profile_screen.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({Key? key}) : super(key: key);

  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _users = [];
  bool _isLoading = false;
  String _baseUrl = '';

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
  }

  Future<void> _initializeBaseUrl() async {
    String url = await _authService.getBaseUrl();
    setState(() {
      _baseUrl = url;
    });
  }

  void _searchUsers() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a search query.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _users = [];
    });

    List<dynamic> users = await _authService.searchUsers(query);

    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  void _onUserTap(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewProfileScreen(
          userId: user['id'],
          userName: _authService.decryptData(user['username']) ?? 'Unknown',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If baseUrl is not yet initialized, show a loading indicator
    if (_baseUrl.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Search Users'),
          backgroundColor: AppStyles.primaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
        backgroundColor: AppStyles.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by username, name, or email',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
              ),
              onSubmitted: (value) => _searchUsers(),
            ),
            const SizedBox(height: 20),
            // Users List
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
              child: _users.isEmpty
                  ? const Center(child: Text('No users found.'))
                  : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  var user = _users[index];

                  // Decrypt the username
                  String decryptedUsername = _authService.decryptData(user['username']) ?? 'Unknown';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        user['id'] != null
                            ? '$_baseUrl/profiles/${user['id']}.jpg'
                            : 'https://via.placeholder.com/100x100',
                      ),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    title: Text(decryptedUsername),
                    // Optionally, remove the subtitle or keep it if desired
                    // subtitle: Text(
                    //     '${user['firstName']} ${user['middleName']} ${user['lastName']}'),
                    onTap: () => _onUserTap(user),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}