import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:virtualfitnessph/screens/followers_following_screen.dart';
import 'package:virtualfitnessph/services/auth_service.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';
import 'package:virtualfitnessph/components/outline_button.dart';
import 'package:virtualfitnessph/components/primary_button.dart';
import 'package:virtualfitnessph/components/circular_progress_bar.dart';
import '../all_races_screen.dart';
import '../edit_profile_screen.dart';
import '../login_screen.dart';
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
  final List<String> mockedFollowers = [
    'Follower 1',
    'Follower 2',
    'Follower 3',
    'Follower 4',
    'Follower 5',
  ];

  final List<String> mockedFollowing = [
    'Following 1',
    'Following 2',
    'Following 3',
    'Following 4',
    'Following 5',
  ];

  bool isLoading = false;
  final AuthService _authService = AuthService();
  String? userId;
  String? userName;
  String? fullName;
  String? _profilePicUrl;
  String totalDistance = "00 KM";
  String pace = "0:00:00";
  String totalRuns = "0";

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
                      // _buildCircularProgressBar(),
                      // _buildTextDisplay(),
                      _buildBadgesSection2(),
                      _buildStatsSection2(),
                      _buildRewardSection(),
                      //_buildTrophiesSection(),
                      _buildJoinedRacesSection2(),
                      _buildPhotosSection2(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader2() {
    return GestureDetector(
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.all(0),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _profilePicUrl == null
                      ? CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.red.shade200,
                    child: const Icon(Icons.person, size: 60),
                  )
                      : CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(_profilePicUrl!),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName ?? 'Unknown User',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStatColumn(
                              "Followers",
                              profileData['followersCount']?.toString() ?? '0',
                                  () => _navigateToList(
                                  context, 'Followers', mockedFollowers),
                            ),
                            SizedBox(width: 16),
                            _buildStatColumn(
                              "Following",
                              profileData['followingCount']?.toString() ?? '0',
                                  () => _navigateToList(
                                  context, 'Following', mockedFollowing),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
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
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
                  padding: EdgeInsets.all(20),
                  child: Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(
                            fullName ?? 'Unknown User',
                            style: AppStyles.vifitTextTheme.titleLarge?.copyWith(color: AppStyles.primaryForeground),
                          ),
                          Text(
                            userName ?? 'Unknown User',
                            style: AppStyles.vifitTextTheme.titleMedium?.copyWith(color: AppStyles.primaryForeground),
                          )
                      ]
                      )
                    ),
                  )
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
                          context, 'Followers', mockedFollowers),
                    ),
                    SizedBox(width: 16),
                    _buildStatColumn(
                      "Following",
                      profileData['followingCount']?.toString() ?? '0',
                          () => _navigateToList(
                          context, 'Following', mockedFollowing),
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

  void _navigateToList(BuildContext context, String title, List<dynamic> users) async {
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
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppStyles.buttonColor,
                          child: const Icon(Icons.monetization_on, size: 50),
                          // backgroundImage: NetworkImage('https://example.com/image.jpg'), // Add your image URL
                        ),
                      ),
                      // CircleAvatar(
                      //   radius: 50,
                      //   backgroundColor: AppStyles.buttonColor,
                      //   child: const Icon(Icons.monetization_on, size: 50),
                      // ),
                    ],),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                         const Text(
                          'Vifit coins: 975',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],),
                      Row(children: [
                        PrimaryButton(text: 'Redeem', color: AppStyles.buttonColor, textColor: AppStyles.buttonTextColor, onPressed: () => null),
                        const SizedBox(width: 7),
                        PrimaryButton(text: 'Pass points',color: AppStyles.buttonColor, textColor: AppStyles.buttonTextColor, onPressed: () => null),
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

  Widget _buildStatsSection2() {
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
                  margin: EdgeInsets.all(1),
                  padding: EdgeInsets.all(10),
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
                            color: Colors.orange,
                          ),
                          _buildStatCard(
                            icon: Icons.timer,
                            value: pace,
                            label: 'Pace (min/km)',
                            color: Colors.orange,
                          ),
                          _buildStatCard(
                            icon: Icons.directions_run,
                            value: totalRuns,
                            label: 'Runs',
                            color: Colors.orange,
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

  Widget _buildTextDisplay() {
    return Column(
            children: [

            Text('displayLarge', style: AppStyles.vifitTheme.textTheme.displayLarge?.copyWith(color: Colors.black)),
            Text('displayMedium', style: AppStyles.vifitTheme.textTheme.displayMedium?.copyWith(color: Colors.black)),
            Text('displaySmall', style: AppStyles.vifitTheme.textTheme.displaySmall?.copyWith(color: Colors.black)),
            Text('headlineLarge', style: AppStyles.vifitTheme.textTheme.headlineLarge?.copyWith(color: Colors.black)),
            Text('headlineMedium', style: AppStyles.vifitTheme.textTheme.headlineMedium?.copyWith(color: Colors.black)),
            Text('headlineSmall', style: AppStyles.vifitTheme.textTheme.headlineSmall?.copyWith(color: Colors.black)),
            Text('titleLarge', style: AppStyles.vifitTheme.textTheme.titleLarge?.copyWith(color: Colors.black)),
            Text('titleMedium', style: AppStyles.vifitTheme.textTheme.titleMedium?.copyWith(color: Colors.black)),
            Text('titleSmall', style: AppStyles.vifitTheme.textTheme.titleSmall?.copyWith(color: Colors.black)),
            Text('bodyLarge', style: AppStyles.vifitTheme.textTheme.bodyLarge?.copyWith(color: Colors.black)),
            Text('bodyMedium', style: AppStyles.vifitTheme.textTheme.bodyMedium?.copyWith(color: Colors.black)),
            Text('bodySmall', style: AppStyles.vifitTheme.textTheme.bodySmall?.copyWith(color: Colors.black)),
            Text('labelLarge', style: AppStyles.vifitTheme.textTheme.labelLarge?.copyWith(color: Colors.black)),
            Text('labelMedium', style: AppStyles.vifitTheme.textTheme.labelMedium?.copyWith(color: Colors.black)),
            Text('labelSmall', style: AppStyles.vifitTheme.textTheme.labelSmall?.copyWith(color: Colors.black)),

            const SizedBox(height: 10),
    ],);
  }
Widget _buildStatsSection() {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stats Overview',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  icon: Icons.location_on,
                  value: totalDistance,
                  label: 'Distance (km)',
                  color: Colors.orange,
                ),
                _buildStatCard(
                  icon: Icons.timer,
                  value: pace,
                  label: 'Pace (min/km)',
                  color: Colors.orange,
                ),
                _buildStatCard(
                  icon: Icons.directions_run,
                  value: totalRuns,
                  label: 'Runs',
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
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
            // shadows: [Shadow(
            //   color: Colors.black.withOpacity(0.3),  
            //   blurRadius: 10,                       
            //   offset: Offset(5, 5),                  
            // ),],
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

  Widget _buildBadgesSection2() {
    return (
      Container(
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
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

  Widget _buildBadgesSection() {
    return Card(
      color: Colors.white,
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
                'My Badges',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              badges.isEmpty
                  ? const SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge, size: 48, color: Colors.blue),
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
                                CircleAvatar(
                                  radius: 50,
                                  // backgroundColor: Colors.transparent,
                                  child: ClipOval(
                                    child: Image.network(
                                      'http://97.74.90.63:8080/races/badges/${badges[index]['badgesPicturePath']}',
                                      width: 100,
                                      height: 100,
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
                                ),
                              ],
                            );
                          },
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
            ],
          ),
        ),
      ),
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

  Widget _buildJoinedRacesSection2() {
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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,  
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

  Widget _buildJoinedRacesSection() {
    List<dynamic> incompleteRaces = joinedRaces
        .where((race) => race['registration']['completed'] == false)
        .toList();

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Races Joined and Progress',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            if (incompleteRaces.isEmpty)
              const SizedBox(
                height: 100,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_run, size: 48, color: Colors.blue),
                    SizedBox(height: 10),
                    Text('No in-progress races yet. Start your journey now!'),
                  ],
                ),
              )
            else
              Column(
                children: incompleteRaces
                    .take(3)
                    .map((race) => _buildCircularProgressBar(race))
                    .toList(),
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
              child: const Text('View All', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection2() {
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

  Widget _buildPhotosSection() {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Photos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              photos.isEmpty
                  ? const SizedBox(
                height: 100,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo, size: 48, color: Colors.blue),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                  child: InteractiveViewer(
                    clipBehavior: Clip.none,
                    minScale: 0.1,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularProgressBar(Map<String, dynamic> race) {
    
    double screenWidth = MediaQuery.of(context).size.width;
    double halfScreenWidth = screenWidth / 2.6;

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
            progress: progress, // Percentage value (0-100)
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
