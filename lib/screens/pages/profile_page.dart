import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:virtualfitnessph/screens/followers_following_screen.dart';
import 'package:virtualfitnessph/services/auth_service.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';
import 'package:virtualfitnessph/components/outline_button.dart';
import 'package:virtualfitnessph/components/primary_button.dart';
import 'package:virtualfitnessph/components/circular_progress_bar.dart';
import 'package:virtualfitnessph/screens/main_page_screen.dart';
import '../all_races_screen.dart';
import '../edit_profile_screen.dart';
import '../login_screen.dart';
import '../pass_points_screen.dart';
import '../race_detail_screen.dart';
import '../view_all_badges_screen.dart'; // Add this import
import 'dart:math';

import '../view_profile_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Map<String, dynamic> profileData = {};
  late List<dynamic> joinedRaces = [];
  late List<dynamic> badges = [];
  late List<dynamic> trophies = [];
  late List<dynamic> photos = [];

  bool isLoading = false;
  final AuthService _authService = AuthService();
  String? userId;
  String? userName;
  String? fullName;
  String? _profilePicUrl;
  String totalDistance = "00 KM";
  String pace = "0:00:00";
  String totalRuns = "0";
  String _currentPoints = "0";

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<List<dynamic>> _fetchUserList(String listType) async {
    final String baseUrl = await _authService.getBaseUrl();
    final String url = listType == 'Followers'
        ? '$baseUrl/followers/$userId'
        : '$baseUrl/following/$userId';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load $listType');
      }
    } catch (e) {
      print('Error loading $listType: $e');
      return [];
    }
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);
    await _loadProfileData();
    await _loadFollowerCount(); // Load follower count
    await _loadFollowingCount(); // Load following count
    await _loadJoinedRaces();
    await _loadProfilePicture();
    await _loadBadges(); // Load badges
    await _loadPhotos();
    _fetchCurrentPoints();
    setState(() => isLoading = false);
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);
    userName = await _authService.getUserName();
    userId = await _authService.getUserId();
    final String baseUrl = await _authService.getBaseUrl();
    Uri uri = Uri.parse('$baseUrl/userdetail/$userId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          profileData = json.decode(response.body);
          fullName = profileData['firstName'] + ' ' + profileData['lastName'];
        });
        await _loadStats(); // Load stats after profile data
      } else {
        throw Exception('Failed to load user details');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading profile data: $e');
    }
  }

  Future<void> _loadProfilePicture() async {
    if (userId != null) {
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

  Future<void> _loadJoinedRaces() async {
    if (userId != null) {
      const String baseUrl = 'http://97.74.90.63:8080';
      Uri uri = Uri.parse('$baseUrl/api/registrations/user/$userId');
      try {
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          setState(() {
            joinedRaces = json.decode(response.body);
            joinedRaces.sort((a, b) => b['registration']['updateDate']
                .compareTo(a['registration']['updateDate']));
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load race details');
        }
      } catch (e) {
        print('Error loading races: $e');
      }
    }
  }

  Future<void> _loadBadges() async {
    if (userId != null) {
      try {
        badges = await _authService.fetchBadges(userId!);
        badges.sort((a, b) => b['completeDate'].compareTo(a['completeDate']));
      } catch (e) {
        print('Error loading badges: $e');
      }
    }
  }

  Future<void> _loadStats() async {
    if (userId != null) {
      const String baseUrl = 'http://97.74.90.63:8080';
      Uri uri = Uri.parse('$baseUrl/submissions/stats/$userId');
      try {
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          Map<String, dynamic> stats = json.decode(response.body);
          setState(() {
            double distance = stats['totalDistance'];
            totalDistance = "${distance.toStringAsFixed(2)} KM";
            pace = stats['pace'];
            totalRuns = stats['totalSubmissions'].toString();
          });
        } else {
          throw Exception('Failed to load stats');
        }
      } catch (e) {
        print('Error loading stats: $e');
      }
    }
  }

  Future<void> _loadPhotos() async {
    if (userId != null) {
      const String baseUrl = 'http://97.74.90.63:8080';
      Uri uri = Uri.parse('$baseUrl/feed/byUser/$userId');
      try {
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          setState(() {
            photos = json.decode(response.body);
          });
        } else {
          throw Exception('Failed to load photos');
        }
      } catch (e) {
        print('Error loading photos: $e');
      }
    }
  }

  Future<void> _loadFollowerCount() async {
    if (userId != null) {
      final String baseUrl = await _authService.getBaseUrl();
      Uri uri = Uri.parse('$baseUrl/followers/$userId');
      try {
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          setState(() {
            profileData['followersCount'] = json.decode(response.body).length;
          });
        } else {
          throw Exception('Failed to load followers count');
        }
      } catch (e) {
        print('Error loading followers count: $e');
      }
    }
  }

  Future<void> _loadFollowingCount() async {
    if (userId != null) {
      final String baseUrl = await _authService.getBaseUrl();
      Uri uri = Uri.parse('$baseUrl/following/$userId');
      try {
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          setState(() {
            profileData['followingCount'] = json.decode(response.body).length;
          });
        } else {
          throw Exception('Failed to load following count');
        }
      } catch (e) {
        print('Error loading following count: $e');
      }
    }
  }

  void _redeemPoints() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const MainPageScreen(tab: 2)));
      // Currently not implemented. Show a placeholder dialog.
      // showDialog(
      //   context: context,
      //   builder: (BuildContext context) {
      //     return AlertDialog(
      //       title: const Text('Redeem Points'),
      //       content: const Text('Redeem functionality is coming soon!'),
      //       actions: <Widget>[
      //         TextButton(
      //           child: const Text('OK'),
      //           onPressed: () {
      //             Navigator.of(context).pop();
      //           },
      //         ),
      //       ],
      //     );
      //   },
      // );
    }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.scaffoldBgColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppStyles.primaryColor))
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(),
                      _buildBadgesSection(),
                      _buildStatsSection(),
                      _buildRewardSection(),
                      _buildJoinedRacesSection(),
                      _buildPhotosSection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _fetchCurrentPoints() async {
    String? userId = await _authService.getUserId();
    if (userId != null) {
      String points = await _authService.getCurrentPoints(userId);
      setState(() {
        _currentPoints = points;
      });
    }
  }
  
  Widget _buildProfileHeader() {
    return Container(
      height: 200,
      padding: EdgeInsets.only(left: 25, right: 25, top: 25, bottom: 5),
      decoration: BoxDecoration(color: AppStyles.primaryColor,
          gradient: LinearGradient(
          colors: [AppStyles.primaryColor, AppStyles.unselectedColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Column(
              children: [
                  Container(
                    padding: EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppStyles.darkerPrimary
                    ),
                    child: 
                      _profilePicUrl == null
                          ? CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.red.shade200,
                        child: const Icon(Icons.person, size: 45),
                      )
                          : CircleAvatar(
                        radius: 45,
                        backgroundImage: NetworkImage(_profilePicUrl!),
                      ),
                  )
              ]
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName ?? 'Unknown User',
                        style: AppStyles.vifitTextTheme.titleLarge?.copyWith(color: AppStyles.primaryForeground),
                      ),
                      Text(
                        '@${userName}' ?? 'Unknown User',
                        style: AppStyles.vifitTextTheme.titleMedium?.copyWith(color: AppStyles.primaryForeground),
                      ),
                    ],
                  ),
                ),
              ]
            )
          ],),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatColumn(
                      "Followers",
                      profileData['followersCount']?.toString() ?? '0',
                          () => _navigateToList(
                          context, 'Followers'),
                    ),
                    SizedBox(width: 16),
                    _buildStatColumn(
                      "Following",
                      profileData['followingCount']?.toString() ?? '0',
                          () => _navigateToList(
                          context, 'Following'),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              children: [
                // const Text("Don't have an account? ")
                OutlineButton(
                  text: 'Edit profile',
                  icon: Icons.edit,
                  size: 'small',
                  onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProfileScreen(profileData: profileData),
                        ),
                      );
                      if (result == true) {
                        _loadAllData();
                      }
                    },)
              ],
            )
          ],)

        ],
      )
       
    );
  }

  Widget _buildStatColumn(String label, String count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: AppStyles.vifitTextTheme.labelLarge?.copyWith(color: AppStyles.primaryForeground),
          ),
          Text(
            label,
            style: AppStyles.vifitTextTheme.labelSmall?.copyWith(color: AppStyles.primaryForeground),
          ),
        ],
      ),
    );
  }

  void _navigateToList(BuildContext context, String title) async {
    List<dynamic> userList = await _fetchUserList(title);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersFollowingScreen(
          title: title,
          users: userList,
          onUserTap: (user) {
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
        ),
      ),
    );
  }

  Widget _buildRewardSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Get rewarded',
                style: AppStyles.vifitTextTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(child: Container(
                margin: EdgeInsets.all(1),
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  // color: Color(0xFFB4D7FF),
                  color: AppStyles.primaryColor,
                    gradient: LinearGradient(
                    colors: [Color(0x80FFDB03), Color(0x30FFDB03)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,  // Make the container circular
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),  // Shadow color
                              spreadRadius: 1,   // How far the shadow spreads
                              blurRadius: 0,     // Softness of the shadow
                              offset: Offset(1, 1),  // Position of the shadow (x, y)
                            ),
                          ],
                        ),
                        child: 
                        // Container(
                        //   width: 50,
                        //   height: 50, 
                        //   decoration: BoxDecoration(
                        //     shape: BoxShape.circle,
                        //     image: DecorationImage(
                        //     image: AssetImage('assets/vifit-coin1.png'),
                        //     fit: BoxFit.fill, // Change to BoxFit.contain, BoxFit.fill, etc. based on your need
                        //   ),
                        // )
                        // )
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppStyles.buttonColor,
                          backgroundImage: AssetImage('assets/vifit-coin1.png'),
                          // child: const Icon(Icons.monetization_on, size: 50),
                          // backgroundImage: NetworkImage('https://example.com/image.jpg'), // Add your image URL
                        ),
                      ),
                    ],),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text(
                          "Vifit coins: $_currentPoints",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],),
                      Row(children: [
                        PrimaryButton(text: 'Redeem', color: AppStyles.buttonColor, textColor: AppStyles.buttonTextColor, onPressed: _redeemPoints),
                        const SizedBox(width: 7),
                        PrimaryButton(text: 'Pass points',color: AppStyles.buttonColor, textColor: AppStyles.buttonTextColor,  onPressed: () async {
                          List<dynamic> followers = await _fetchUserList('Followers');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PassPointsScreen(),
                            ),
                          ).then((_) => _fetchCurrentPoints());
                        },),
                      ],)
                    ],)
                  ]
                ),
              ),
            ),
          ],
        ),
      ]
      )
    );
  }

  Widget _buildStatsSection() {
    return Container(
       padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Stats overview',
                  style: AppStyles.vifitTextTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(child: Container(
                  margin: const EdgeInsets.all(1),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    // color: Color(0xFFB4D7FF),
                    color: AppStyles.primaryColor,
                      gradient: const LinearGradient(
                      colors: [Color(0x80FFDB03), Color(0x30FFDB03)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [ 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            icon: Icons.location_on,
                            value: totalDistance,
                            label: 'Distance (km)',
                          ),
                          _buildStatCard(
                            icon: Icons.timer,
                            value: pace,
                            label: 'Pace (min/km)',
                          ),
                          _buildStatCard(
                            icon: Icons.directions_run,
                            value: totalRuns,
                            label: 'Runs',
                          ),
                        ],
                      ),
                  ],),
                )
              )
            ],
            )
          ]
       )
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(8),
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.grey.withOpacity(0.2),
      //       spreadRadius: 2,
      //       blurRadius: 5,
      //       offset: const Offset(0, 3),
      //     ),
      //   ],
      // ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, 
            color: AppStyles.primaryColor, 
            shadows: [Shadow(
              color: Colors.black.withOpacity(0.3),  
              blurRadius: 10,                       
              offset: const Offset(5, 5),                  
            ),],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppStyles.vifitTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: AppStyles.vifitTextTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    return (
      Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Badges',
                  style: AppStyles.vifitTextTheme.headlineSmall,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewAllBadgesScreen(
                          badges: badges,
                        ),
                      ),
                    );
                  },
                  child: const Text('View All',
                      style: TextStyle(color: Colors.blue)),
                ),
              ],
              
            ),
           SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  badges.isEmpty
                    ? const SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge, size: 48, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('No badges earned yet.'),
                        ],
                      ),
                    )
                    : Column(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                               childAspectRatio: 1,
                            ),
                            itemCount: min(badges.length, 6),
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Card(
                                    color: Colors.white,
                                    // elevation: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    child: Padding(padding: EdgeInsets.all(8),
                                    child: CircleAvatar(
                                    radius: 40,
                                    // backgroundColor: Colors.transparent,
                                    backgroundColor: Colors.grey,
                                    child: Column(
                                      children: [
                                        ClipOval(
                                          child: Image.network(
                                            'http://97.74.90.63:8080/races/badges/${badges[index]['badgesPicturePath']}',
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Image.network(
                                                    'https://via.placeholder.com/100x100',
                                                    width: 100,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              );
                            },
                          ),
                          
                        ],
                      ),
                ],
              ),
            ),
      
          ],
        ),
      )
    );
  }

  Widget _buildTrophiesSection() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Trophies',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              trophies.isEmpty
                  ? const SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events,
                              size: 48, color: Colors.blue),
                          SizedBox(height: 10),
                          Text('No trophies earned yet.'),
                        ],
                      ),
                    )
                  : InkWell(
                      onTap: () {
                        // Navigate to trophies detail page
                      },
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Display trophies here
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJoinedRacesSection() {
    List<dynamic> incompleteRaces = joinedRaces
        .where((race) => race['registration']['completed'] == false)
        .toList();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Races joined',
                style: AppStyles.vifitTextTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllRacesScreen(),
                    ),
                  );
                },
                child: const Text('View All',
                    style: TextStyle(color: Colors.blue)),
              ),
            ]
          ),
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                incompleteRaces.isEmpty?
                  const SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_run, size: 48, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('No in-progress races yet. Start your journey now!'),
                      ],
                    ),
                  ) : Row(
                    mainAxisAlignment: MainAxisAlignment.start,  
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: incompleteRaces
                      .take(3)
                      .map((race) => _buildCircularProgressBar(race))
                      .toList(),
                  )

              ]
            )
          )
        ],
      )
    );
  }

  Widget _buildPhotosSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      child: Column (
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'My Photos',
                style: AppStyles.vifitTextTheme.headlineSmall,
              ),
            ]
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(child: Container(
                margin: EdgeInsets.all(1),
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: Color(0x80FFDB03),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    photos.isEmpty
                        ? const SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo, size: 48, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('No photos uploaded yet.'),
                        ],
                      ),
                    )
                        : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            _showImageDialog(
                                'http://97.74.90.63:8080/feed/images/${photos[index]['imagePath']}');
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              'http://97.74.90.63:8080/feed/images/${photos[index]['imagePath']}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.network(
                                  'https://via.placeholder.com/100x100',
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ]
                )
              ))
            ]
          )
        ]
      )
    );
  }

  void _showImageDialog(String imageUrl) {
      showGeneralDialog(
        context: context,
        // barrierDismissible: true,
        pageBuilder: (BuildContext ctx, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(0.8),
            body: SafeArea (child: Stack(
              children: [
                InteractiveViewer(
                  boundaryMargin: EdgeInsets.zero,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
              ],
            )),
          );
        },
      );
    }
 
  Widget _buildCircularProgressBar(Map<String, dynamic> race) {
    
    double screenWidth = MediaQuery.of(context).size.width;
    double halfScreenWidth = screenWidth / 2.2;

    double progress = race['registration']['distanceProgress'] /
        race['registration']['raceDistance'];
    progress = min(progress, 1.0); // Ensure progress does not overflow past 1.0


    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RaceDetailScreen(race: race),
          ),
        );
      },
      child: Container(
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 15),
      constraints: BoxConstraints(
        maxWidth: halfScreenWidth,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomCircularProgressBar(
            progress: progress * 100, // Percentage value (0-100)
            size: halfScreenWidth,    // Diameter of the progress bar
            strokeWidth: 12,  // Thickness of the progress bar
            color: AppStyles.primaryColor, // Color of the progress bar
          ),
          const SizedBox(height: 5),
          Text(
            race['race']['raceName'],
            textAlign: TextAlign.center,
            style: AppStyles.vifitTextTheme.labelMedium,
          ),
        ]
      )
    )
    );
  }

  Widget _buildProgressCard(Map<String, dynamic> race) {
    double progress = race['registration']['distanceProgress'] /
        race['registration']['raceDistance'];
    progress = min(progress, 1.0); // Ensure progress does not overflow past 1.0

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RaceDetailScreen(race: race),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              race['race']['raceName'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 20,
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 0,
                  child: Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    _authService.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}

class ProfileStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subLabel;

  const ProfileStat(
      {super.key, required this.icon, required this.label, required this.subLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.yellow.shade900),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subLabel,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
