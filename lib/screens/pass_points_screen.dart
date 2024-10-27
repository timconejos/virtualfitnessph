// pass_points_screen.dart

import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:virtualfitnessph/components/primary_text_field.dart';
import '../components/confirm_pass_points_dialog.dart'; // Import the confirmation dialog
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
    _amountController.dispose();
    _searchController.dispose();
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

  Future<void> _sharePoints() async {
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

    String? sourceUserId = await _authService.getUserId();
    String targetUserId = _selectedUserId!;

    if (sourceUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    // Fetch selected user's details from both followers and search results
    var selectedUser = _findUserById(targetUserId);

    if (selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected user not found.')),
      );
      return;
    }

    String userName = _authService.decryptData(selectedUser['username']);
    String profileImageUrl = selectedUser['id'] != null
        ? '$_baseUrl/profiles/${selectedUser['id']}.jpg'
        : 'https://via.placeholder.com/100x100';

    // Show the confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmPassPointsDialog(
        profileImageUrl: profileImageUrl,
        userName: userName,
        amount: amount,
      ),
    );

    // If user confirmed, proceed to share points
    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      bool success = await _authService.sharePoints(sourceUserId, targetUserId, amount);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Points shared successfully!')),
        );

        // Reset the selection and input fields
        setState(() {
          _selectedUserId = null;
          _selectedUserName = null;
          _amountController.clear();
          _searchController.clear();
          _searchResults = [];
        });

        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share points. Please try again.')),
        );
      }
    }
  }

  // Helper function to find user by ID in both lists
  dynamic _findUserById(String userId) {
    try {
      return _followers.firstWhere((user) => user['id'] == userId);
    } catch (e) {
      // If not found in followers, search in searchResults
      try {
        return _searchResults.firstWhere((user) => user['id'] == userId);
      } catch (e) {
        return null;
      }
    }
  }

  void _selectUser(dynamic user) {
    setState(() {
      if (_selectedUserId == user['id']) {
        _selectedUserId = null;
        _selectedUserName = null;
        _searchController.clear();
      } else {
        _selectedUserId = user['id'];
        _selectedUserName = user['username'];
        _searchController.text = _authService.decryptData(user['username']) ?? '';
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchInput(),
          Expanded(
            child: Stack(
              children: [
                // Users List or Loading Indicator
                _isLoading && _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : displayList.isEmpty
                    ? const Center(child: Text('No users found.'))
                    : ListView.builder(
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    var user = displayList[index];
                    return ListTile(
                      leading: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 224, 224, 224),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.network(
                           user['id'] != null
                              ? '$_baseUrl/profiles/${user['id']}.jpg'
                              : 'https://via.placeholder.com/100x100',
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                            return Image.asset('assets/profile.png', height: 40, width: double.infinity, fit: BoxFit.cover);
                          },
                      ),
                    )
                    ),
                      title: Text(_authService.decryptData(user['username'])),
                      trailing: _selectedUserId == user['id']
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () => _selectUser(user),
                      focusColor: Colors.grey,
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
                // Positioned Widget for Amount Input and Share Button
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.6),
                          spreadRadius: 1,
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Add this line
                      children: [
                        PrimaryTextField(
                          controller: _amountController,
                          labelText: 'Amount',
                          prefixIcon_: const Icon(Icons.attach_money),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 20),
                        // Share Points Button
                        _isLoading && !_isSearching
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                          onPressed: _sharePoints,
                          style: AppStyles.primaryButtonStyle,
                          child: Text('Share Points', style: AppStyles.vifitTextTheme.titleMedium),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container (
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.6),
                  spreadRadius: 1,
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ]
            ),
            child: PrimaryTextField(
              labelText: 'Pass points to',
              hintText: 'Search user',
              controller: _searchController,
              prefixIcon_: const Icon(Icons.search),
              suffixIcon_: _isSearching && _searchController.text.length >= 2
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _searchUsers('');
                },
              ): null,
              onChanged: (value) {
                _onSearchChanged(value);
              },
              onSubmitted: (value) {
                if (value.length >= 2) {
                  _searchUsers(value);
                }
              },
            ),
          ),
        ),
      ]
    );
  }
}