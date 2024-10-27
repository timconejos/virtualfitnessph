import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:virtualfitnessph/components/circular_progress_bar.dart';
import 'package:virtualfitnessph/screens/view_all_races_screen.dart';
import 'package:virtualfitnessph/screens/view_all_badges_screen.dart';
import 'package:virtualfitnessph/components/outline_button.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';
import 'dart:convert';

import '../services/auth_service.dart';

class ViewProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ViewProfileScreen(
      {super.key, required this.userId, required this.userName});

  @override
  _ViewProfileScreenState createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  final AuthService _authService = AuthService();
  final Map<String, dynamic> _profileData = {};
  List<dynamic> _badges = [];
  final List<dynamic> _trophies = [];
  List<dynamic> _joinedRaces = [];
  List<dynamic> _photos = [];
  List<dynamic> inProgressRaces = [];
  List<dynamic> _followers = [];
  List<dynamic> _following = [];
  String? _profilePicUrl;
  String? _userName;
  bool _isCurrentUser = false;
  bool _isFollowing = false;
  bool _isLoading = false;
  String totalDistance = "0 KM";
  String pace = "0:00";
  String totalRuns = "0";
  static String baseUrl = "";

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    _loadAllData();
    _loadFollowers();
    _loadFollowing();
  }

  Future<void> _checkCurrentUser() async {
    String? currentUserId = await _authService.getUserId();
    if (currentUserId != null && currentUserId == widget.userId) {
      setState(() {
        _isCurrentUser = true;
      });
    }
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    baseUrl = await _authService.getBaseUrl();
    await _loadProfileData();
    await _checkIfFollowing(); // Check if the current user is following this profile
    await _loadProfilePicture();
    await _loadBadges();
    await _loadStats();
    await _loadJoinedRaces();
    await _loadPhotos();
    setState(() => _isLoading = false);
  }

  Future<void> _loadProfileData() async {
    _userName = _authService.decryptData(widget.userName) ?? 'Unknown User';
  }

  Future<void> _loadProfilePicture() async {
    final String profilePicUrl =
        '${baseUrl}/profiles/${widget.userId}.jpg?timestamp=${DateTime.now().millisecondsSinceEpoch}';
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

  Future<void> _loadBadges() async {
    final String userProfileID = widget.userId;
    Uri uri = Uri.parse(
        '${baseUrl}/api/registrations/badges/$userProfileID');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          _badges = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load badges');
      }
    } catch (e) {
      print('Error loading badges: $e');
    }
  }

  Future<void> _loadStats() async {
    Uri uri =
        Uri.parse('${baseUrl}/submissions/stats/${widget.userId}');
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

  Future<void> _loadJoinedRaces() async {
    final String userProfileID = widget.userId;
    Uri uri = Uri.parse(
        '${baseUrl}/api/registrations/user/$userProfileID');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          _joinedRaces = json.decode(response.body);
          inProgressRaces = _joinedRaces
              .where((race) => race['registration']['completed'] == false)
              .toList();
        });
      } else {
        throw Exception('Failed to load race details');
      }
    } catch (e) {
      print('Error loading races: $e');
    }
  }

  Future<void> _loadPhotos() async {
    Uri uri = Uri.parse('${baseUrl}/feed/byUser/${widget.userId}');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          _photos = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load photos');
      }
    } catch (e) {
      print('Error loading photos: $e');
    }
  }

  Future<void> _loadFollowers() async {
    Uri uri = Uri.parse('${baseUrl}/followers/${widget.userId}');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          _followers = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load followers');
      }
    } catch (e) {
      print('Error loading followers: $e');
    }
  }

  Future<void> _loadFollowing() async {
    Uri uri = Uri.parse('${baseUrl}/following/${widget.userId}');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          _following = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load following');
      }
    } catch (e) {
      print('Error loading following: $e');
    }
  }

  Future<void> _checkIfFollowing() async {
    String? currentUserId = await _authService.getUserId();
    if (currentUserId != null) {
      Uri uri = Uri.parse(
          '${baseUrl}/isfollowing?userId=${widget.userId}&followerId=$currentUserId');
      try {
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          setState(() {
            _isFollowing = json.decode(response.body);
          });
        } else {
          throw Exception('Failed to check if following');
        }
      } catch (e) {
        print('Error checking if following: $e');
      }
    }
  }

  Future<void> _toggleFollow() async {
    String? currentUserId = await _authService.getUserId();
    if (currentUserId != null) {
      Uri uri = Uri.parse(
          '${baseUrl}/${_isFollowing ? "unfollow" : "follow"}');
      try {
        final response = await http.post(uri, body: {
          'userId': widget.userId,
          'followerId': currentUserId,
        });
        if (response.statusCode == 200) {
          setState(() {
            _isFollowing = !_isFollowing;
            if (_isFollowing) {
              _followers.add({'userId': currentUserId});
            } else {
              _followers.removeWhere(
                  (follower) => follower['userId'] == currentUserId);
            }
          });
        } else {
          throw Exception('Failed to toggle follow');
        }
      } catch (e) {
        print('Error toggling follow: $e');
      }
    }
  }

  Future<void> _blockUser() async {
    bool confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Block User'),
          content: const Text(
              'Are you sure you want to block this user? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Block'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ??
        false;

    if (confirmed) {
      try {
        String? currentUserId = await _authService.getUserId();
        if (currentUserId != null) {
          bool success = await _authService.blockUser(currentUserId, widget.userId);

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User blocked successfully'),
              ),
            );
            Navigator.of(context).pop(); // Optionally navigate back after blocking
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to block user. Please try again later.'),
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while blocking the user.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: AppStyles.primaryColor,
        title:
            const Text('Profile', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(),
                      // const SizedBox(height: 10),
                      _buildBadgesSection(),
                      _buildStatsSection(),
                      //_buildTrophiesSection(),
                      _buildJoinedRacesSection(),
                      _buildPhotosSection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }


  Widget _buildProfileHeader() {
    return Container(
      height: 200,
      padding: const EdgeInsets.only(left: 25, right: 5, top: 2, bottom: 5),
      decoration: const BoxDecoration(
        color: AppStyles.primaryColor,
        gradient: LinearGradient(
          colors: [AppStyles.primaryColor, AppStyles.unselectedColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Column
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 23),
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppStyles.darkerPrimary,
                    ),
                    child: _profilePicUrl == null
                        ? const CircleAvatar(
                        radius: 45,
                        backgroundImage: AssetImage('assets/profile.png'),
                        backgroundColor: Color.fromARGB(255, 224, 224, 224),
                    )
                        : CircleAvatar(
                      radius: 45,
                      backgroundImage: NetworkImage(_profilePicUrl!),
                    ),
                  ),
                ],
              ),
              // Add some spacing
              // const SizedBox(width: 10),
              // Expanded Widget Moved Here
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 45, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName ?? 'Unknown User',
                        style: AppStyles.vifitTextTheme.titleLarge?.copyWith(
                          color: AppStyles.primaryForeground,
                        ),
                      ),
                      Text(
                        '@${_userName}' ?? 'Unknown User',
                        style: AppStyles.vifitTextTheme.titleMedium?.copyWith(
                          color: AppStyles.primaryForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
              // mainAxisAlignment: MainAxisAlignment.start,
              // crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton<String>(
                  iconColor: AppStyles.primaryForeground,
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'block',
                        child: const ListTile(
                          trailing: Icon(Icons.block), // Icon
                          title: Text('Block user'),
                        ),
                        onTap: () => _blockUser(),
                      ),
                    ];
                  },
                ),
              ]
            ),
            ],
          ),
          const SizedBox(height: 15),
          // Rest of your code...
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Followers and Following
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatColumn(
                        "Followers",
                        _followers.length.toString(),
                      ),
                      const SizedBox(width: 16),
                      _buildStatColumn(
                        "Following",
                        _following.length.toString(),
                      ),
                    ],
                  ),
                ],
              ),
              // Follow/Unfollow Button
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: OutlineButton(
                    text: _isFollowing ? 'Unfollow' : 'Follow',
                    icon: _isFollowing ? Icons.person_remove : Icons.person_add,
                    size: 'small',
                    onPressed: _toggleFollow,
                  ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildStatColumn(String label, String count) {
    return GestureDetector(
      onTap: () {
        // Implement navigation to followers/following list if needed
      },
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


  Widget _buildStatsSection() {
    return Container(
       padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
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
                          badges: _badges,
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
                  _badges.isEmpty
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
                              mainAxisSpacing: 0,
                              crossAxisSpacing: 0,
                               childAspectRatio: 1,
                            ),
                            itemCount: min(_badges.length, 6),
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Card(
                                    color: Colors.white,
                                    // elevation: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                                    child: Padding(padding: EdgeInsets.all(8),
                                    child: CircleAvatar(
                                    radius: 40,
                                    // backgroundColor: Colors.transparent,
                                    backgroundColor: Colors.grey,
                                    child: Column(
                                      children: [
                                        ClipOval(
                                          child: Image.network(
                                            '${baseUrl}/races/badges/${_badges[index]['badgesPicturePath']}',
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



  Widget _buildJoinedRacesSection() {
  List<dynamic> incompleteRaces = _joinedRaces
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
                    builder: (context) => ViewAllRacesScreen(
                          joinedRaces: _joinedRaces,
                        )
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
                    .take(2)
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


  Widget _buildCircularProgressBar(Map<String, dynamic> race) {
    
    double screenWidth = MediaQuery.of(context).size.width;
    double halfScreenWidth = screenWidth / 2.2;

    double progress = race['registration']['distanceProgress'] /
        race['registration']['raceDistance'];
    progress = min(progress, 1.0); // Ensure progress does not overflow past 1.0


    return InkWell(
      onTap: () {
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
                    _photos.isEmpty
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
                      itemCount: _photos.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            _showImageDialog(
                                '${baseUrl}/feed/images/${_photos[index]['imagePath']}');
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              '${baseUrl}/feed/images/${_photos[index]['imagePath']}',
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

}

class ProfileStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subLabel;

  const ProfileStat(
      {super.key,
      required this.icon,
      required this.label,
      required this.subLabel});

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
        Text(subLabel, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}
