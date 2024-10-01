// pass_points_screen.dart

import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../styles/app_styles.dart';
import '../components/primary_button.dart';
import '../screens/view_profile_screen.dart';

class PassPointsScreen extends StatefulWidget {
  const PassPointsScreen({Key? key}) : super(key: key);

  @override
  _PassPointsScreenState createState() => _PassPointsScreenState();
}

class _PassPointsScreenState extends State<PassPointsScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> _followers = [];
  List<dynamic> _searchResults = [];
  String? _selectedUserId;
  String? _selectedUserName;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isFetchingFollowers = true;
  bool _isSearching = false;
  String _baseUrl = '';
  Timer? _debounce; // Timer for debounce

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Cancel the timer when disposing
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await _fetchBaseUrl();
    await _fetchFollowers();
  }

  Future<void> _fetchBaseUrl() async {
    String url = await _authService.getBaseUrl();
    setState(() {
      _baseUrl = url;
    });
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

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
      _searchResults = [];
    });

    List<dynamic> results = await _authService.searchUsers(query);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchUsers(query);
    });
  }

  void _sharePoints() async {
    if (_selectedUserId == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user and enter an amount.')),
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
    String targetUserId = _selectedUserId!;

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

  void _selectUser(dynamic user) {
    setState(() {
      if (_selectedUserId == user['id']) {
        _selectedUserId = null;
        _selectedUserName = null;
      } else {
        _selectedUserId = user['id'];
        _selectedUserName = user['username'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Decide which list to display based on search state
    List<dynamic> displayList = _isSearching ? _searchResults : _followers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pass Points'),
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
                labelText: 'Search Users',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching && _searchController.text.length >= 2
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchUsers('');
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                _onSearchChanged(value);
              },
              onSubmitted: (value) {
                if (value.length >= 2) {
                  _searchUsers(value);
                }
              },
            ),
            const SizedBox(height: 20),
            // Users List
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
              child: displayList.isEmpty
                  ? const Center(child: Text('No users found.'))
                  : ListView.builder(
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  var user = displayList[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        user['id'] != null
                            ? '$_baseUrl/profiles/${user['id']}.jpg'
                            : 'https://via.placeholder.com/100x100',
                      ),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    title: Text(_authService.decryptData(user['username'])),
                    trailing: _selectedUserId == user['id']
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () => _selectUser(user),
                    onLongPress: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewProfileScreen(
                            userId: user['id'],
                            userName: user['username'],
                          ),
                        ),
                      );
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