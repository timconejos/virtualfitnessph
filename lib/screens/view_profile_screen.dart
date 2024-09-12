import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:virtualfitnessph/screens/view_all_races_screen.dart';
import 'package:virtualfitnessph/screens/view_all_badges_screen.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title:
            const Text('View Profile', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 10),
                      _buildStatsSection(),
                      _buildBadgesSection(),
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
    return GestureDetector(
      onTap: () {
        if (_isCurrentUser) {
          // Navigate to edit profile page
        }
      },
      child: Card(
        color: Colors.white,
        elevation: 2,
        margin: const EdgeInsets.all(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 200,  // Increase the height of the profile header section
          child: Stack(
            children: [
              Column(
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
                              _userName ?? 'Unknown User',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildStatColumn("Followers", _followers.length.toString()),
                                const SizedBox(width: 16),
                                _buildStatColumn("Following", _following.length.toString()),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!_isCurrentUser)
                Positioned(
                  bottom: 0,  // Ensure the buttons are above the bottom edge of the section
                  right: 0,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isFollowing ? Icons.person_remove : Icons.person_add,
                          color: _isFollowing ? Colors.grey : Colors.blue,
                        ),
                        onPressed: _toggleFollow,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.block, color: Colors.red),
                        onPressed: _blockUser,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
              _badges.isEmpty
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
                          itemCount: min(_badges.length, 6),
                          itemBuilder: (context, index) {
                            return CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(
                                '${baseUrl}/races/badges/${_badges[index]['badgesPicturePath']}',
                              ),
                              backgroundColor: Colors.transparent,
                              onBackgroundImageError: (exception, stackTrace) {
                                // Handle image error
                              },
                            );
                          },
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJoinedRacesSection() {
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
            if (inProgressRaces.isEmpty)
              const SizedBox(
                height: 100,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_run, size: 48, color: Colors.blue),
                    SizedBox(height: 10),
                    Text('No in-progress races yet.'),
                  ],
                ),
              )
            else
              Column(
                children: [
                  ...inProgressRaces.take(3).map((race) => _buildProgressCard(
                        race['race']['raceName'],
                        race['registration']['distanceProgress'] /
                            race['registration']['raceDistance'],
                        race['registration']['id'],
                      )),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewAllRacesScreen(
                            joinedRaces: _joinedRaces,
                          ),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
          ],
        ),
      ),
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
              _photos.isEmpty
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemCount: _photos.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _showImageDialog(
                              '${baseUrl}/feed/images/${_photos[index]['imagePath']}'),
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
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: InteractiveViewer(
                    clipBehavior: Clip.none,
                    minScale: 0.1,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
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

  Widget _buildProgressCard(String raceName, double progress, int raceId) {
    progress = progress > 1
        ? 1
        : progress; // Ensure progress does not overflow past 1.0

    return InkWell(
      onTap: () {
        // Navigate to race detail page
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(raceName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                        color: Colors.red.shade600,
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
