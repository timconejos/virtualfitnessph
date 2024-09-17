import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:virtualfitnessph/screens/pages/activity_page.dart';
import 'package:virtualfitnessph/screens/pages/feed_page.dart';
import 'package:virtualfitnessph/screens/pages/profile_page.dart';
import 'package:virtualfitnessph/screens/add_race_data_screen.dart';
import 'package:virtualfitnessph/screens/add_social_post_screen.dart';
import 'package:virtualfitnessph/screens/pages/race_page.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

class MainPageScreen extends StatefulWidget {
  const MainPageScreen({super.key});

  @override
  _MainPageScreenState createState() => _MainPageScreenState();
}

class _MainPageScreenState extends State<MainPageScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  static final List<Widget> _widgetOptions = <Widget>[
    const ProfilePage(),
    const FeedPage(),
    const RacePage(),
    const ActivityPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    bool isLoggedIn = await _authService.isUserLoggedIn();
    if (!isLoggedIn) {
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    });
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.directions_run),
                title: const Text('Submit Race Data'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddRaceDataScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Post on your Feed'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddSocialPostScreen()));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotifications() {
    List<String> notifications = []; // This would be fetched from your backend or service

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 200,
          child: notifications.isEmpty
              ? const Center(child: Text("No notifications"))
              : ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(notifications[index]),
              );
            },
          ),
        );
      },
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop();
                _authService.logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  void _deactivateAccount() async {
    final userId = await _authService.getUserId();
    final userName = await _authService.getUserName();

    if (userId == null || userName == null) return;

    final TextEditingController usernameController = TextEditingController();
    bool isUsernameCorrect = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Deactivate Account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This action will permanently delete your account and all associated data. Please enter your username to confirm:',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      errorText: isUsernameCorrect ? null : 'Incorrect username',
                      errorStyle: const TextStyle(color: Colors.red),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isUsernameCorrect ? Colors.grey : Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Deactivate'),
                  onPressed: () async {
                    if (usernameController.text == userName) {
                      bool success = await _authService.deleteUser(userId);

                      if (success) {
                        Navigator.of(context).pop(); // Close the current dialog
                        _showSuccessDialog(); // Show success dialog
                      } else {
                        // Handle failure if needed
                        Navigator.of(context).pop();
                      }
                    } else {
                      setState(() {
                        isUsernameCorrect = false;
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Deactivation Success'),
          content: const Text('Your account has been successfully deactivated.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _authService.logout(); // Log out the user
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: AppStyles.primaryForeground,
        title: const Text('Virtual Fitness PH'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showNotifications,
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 100), // Large blank space at the top
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
            ListTile(
              leading: const Icon(Icons.web),
              title: const Text('Visit Website'),
              onTap: () => _launchURL('https://virtualfitnessph.com'),
            ),
            const Divider(), // Horizontal bar
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Deactivate Account', style: TextStyle(color: Colors.red)),
              onTap: _deactivateAccount,
            ),
          ],
        ),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        tooltip: 'Add Options',
        foregroundColor: Colors.black,
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feed),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Races',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'Activity',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppStyles.buttonColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: AppStyles.primaryColor,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}