// pass_points_screen.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../styles/app_styles.dart';
import '../components/primary_button.dart';

class PassPointsScreen extends StatefulWidget {
  const PassPointsScreen({Key? key}) : super(key: key);

  @override
  _PassPointsScreenState createState() => _PassPointsScreenState();
}

class _PassPointsScreenState extends State<PassPointsScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> _followers = [];
  List<dynamic> _filteredFollowers = [];
  String? _selectedFollowerId;
  String? _selectedFollowerName;
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  bool _isFetchingFollowers = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    setState(() {
      _isFetchingFollowers = true;
    });
    String? userId = await _authService.getUserId();
    if (userId != null) {
      List<dynamic> followers = await _authService.fetchUserList('Following', userId);
      setState(() {
        _followers = followers;
        _filteredFollowers = followers; // Initially, all followers are shown
        _isFetchingFollowers = false;
      });
    } else {
      setState(() {
        _isFetchingFollowers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
    }
  }

  void _filterFollowers(String query) {
    List<dynamic> filtered = _followers.where((follower) {
      String username = follower['username']?.toString().toLowerCase() ?? '';
      return username.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredFollowers = filtered;
    });
  }

  void _sharePoints() async {
    if (_selectedFollowerId == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a follower and enter an amount.')),
      );
      return;
    }

    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? sourceUserId = await _authService.getUserId();
    String targetUserId = _selectedFollowerId!;

    if (sourceUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    bool success = await _authService.sharePoints(sourceUserId, targetUserId, amount);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Points shared successfully!')),
      );
      Navigator.pop(context, true); // Return true to indicate success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share points. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pass Points'),
        backgroundColor: AppStyles.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isFetchingFollowers
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Search Bar
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search Followers',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _filterFollowers(value);
              },
            ),
            const SizedBox(height: 20),
            // Followers List
            Expanded(
              child: _filteredFollowers.isEmpty
                  ? const Center(child: Text('No followers found.'))
                  : ListView.builder(
                itemCount: _filteredFollowers.length,
                itemBuilder: (context, index) {
                  var follower = _filteredFollowers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        follower['profilePictureUrl'] != null
                            ? 'http://97.74.90.63:8080/profiles/${follower['id']}.jpg'
                            : 'https://via.placeholder.com/100x100',
                      ),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    title: Text(_authService.decryptData(follower['username'])),
                    subtitle: Text(follower['fullName'] ?? 'No Name'),
                    trailing: _selectedFollowerId == follower['id']
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        if (_selectedFollowerId == follower['id']) {
                          _selectedFollowerId = null;
                          _selectedFollowerName = null;
                        } else {
                          _selectedFollowerId = follower['id'];
                          _selectedFollowerName = follower['username'];
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Amount Input
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            // Share Points Button
            _isLoading
                ? const CircularProgressIndicator()
                : PrimaryButton(
              text: 'Share Points',
              color: AppStyles.buttonColor,
              textColor: AppStyles.buttonTextColor,
              onPressed: _sharePoints,
            ),
          ],
        ),
      ),
    );
  }
}