import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';
import '../../services/auth_service.dart';
import '../view_profile_screen.dart';


class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final List<dynamic> _feedItems = [];
  int _offset = 0;
  final int _limit = 10;
  bool _hasMore = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkEULAStatus();
  }

  Future<void> _checkEULAStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasAcceptedEULA = prefs.getBool('acceptedEULA') ?? false;

    if (!hasAcceptedEULA) {
      bool accepted = await _showEULADialog();
      if (!accepted) {
        return; // Do not load feed if EULA not accepted
      } else {
        await prefs.setBool('acceptedEULA', true);
      }
    }

    _loadMoreItems();
  }

  Future<bool> _showEULADialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('End User License Agreement (EULA)'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'By using this application, '
                      'you agree to the terms and conditions. '
                      'There is no tolerance for objectionable content '
                      'or abusive users. Please be respectful when using '
                      'this application. Violations may result in account termination.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Decline'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Accept'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ??
        false;
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

  Future<void> _loadMoreItems() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newItems =
      await _authService.fetchFeedItemsWithLikes(_offset, _limit);
      setState(() {
        if (newItems.isEmpty) {
          _hasMore = false;
        } else {
          _feedItems.addAll(newItems);
          _offset++;
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshFeed() async {
    setState(() {
      _offset = 0;
      _hasMore = true;
      _feedItems.clear();
    });
    _loadMoreItems();
  }

  Future<void> _toggleLike(int feedId, bool isLiked) async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    final url = isLiked
        ? 'http://97.74.90.63:8080/feed/unlike?feed_id=$feedId&user_id=$userId'
        : 'http://97.74.90.63:8080/feed/like?feed_id=$feedId&user_id=$userId';

    try {
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          final feedItem =
          _feedItems.firstWhere((item) => item['feed']['feedId'] == feedId);
          if (isLiked) {
            feedItem['feed']['likes']--;
            feedItem['likedByUser'] = false;
          } else {
            feedItem['feed']['likes']++;
            feedItem['likedByUser'] = true;
          }
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  Future<void> _reportFeed(int feedId) async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    final reasonController = TextEditingController();
    final shouldReport = await _showReportDialog(reasonController);

    if (shouldReport && reasonController.text.isNotEmpty) {
      try {
        final response = await _authService.reportFeed(
            userId, feedId, reasonController.text);
        if (response) {
          _showSnackbar('Report submitted successfully');
        } else {
          _showSnackbar('Admin will check and flag the post in 24 hours. Thank you for your patience');
        }
      } catch (e) {
        print('Error reporting feed: $e');
      }
    }
  }

  Future<bool> _showReportDialog(TextEditingController reasonController) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Report Feed'),
          content: TextField(
            controller: reasonController,
            decoration: InputDecoration(
              hintText: 'Enter the reason for reporting',
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  Future<bool> _showConfirmationDialog(
      {required String title, required String content}) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshFeed,
        child: _feedItems.isEmpty
            ? _buildEmptyFeedMessage()
            : ListView.builder(
          // padding: const EdgeInsets.all(16.0),
          itemCount: _feedItems.length + 1,
          itemBuilder: (context, index) {
            if (index >= _feedItems.length) {
              return _hasMore
                  ? _buildLoadMoreButton()
                  : const SizedBox.shrink();
            }
            return _buildFeedItem2(context, index);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyFeedMessage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'No feed yet',
            style: TextStyle(fontSize: 24, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _loadMoreItems,
        child: const Text('Load More'),
      ),
    );
  }

  Widget _buildFeedItem2(BuildContext context, int index) {
    final feedItem = _feedItems[index]['feed'];
    final isProfileClickable =
        feedItem['userId'] != null && feedItem['username'] != null;
    final profileImageUrl = feedItem['userId']?.isNotEmpty ?? false
        ? 'http://97.74.90.63:8080/profiles/${feedItem['userId']}.jpg'
        : '';
    final name = feedItem['username']?.isNotEmpty ?? false
        ? _authService.decryptData(feedItem['username'])
        : 'Anonymous user';
    final datePosted = DateTime.parse(feedItem['datePosted'])
        .toUtc()
        .add(const Duration(hours: 8));

    return Expanded(
      child:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(10.0),
            child: GestureDetector(
            onTap: isProfileClickable
                ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewProfileScreen(
                  userId: feedItem['userId'],
                  userName: feedItem['username'],
                ),
              ),
            )
                : null,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  radius: 25,
                  backgroundColor: Colors.grey.shade300,
                  child:
                  profileImageUrl.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy hh:mm a').format(datePosted),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                          value: 'report',
                          child: const ListTile(
                            trailing: Icon(Icons.report), // Icon
                            title: Text('Report'),
                          ),
                          onTap: () => _reportFeed(feedItem['feedId']),
                        ),
                        PopupMenuItem<String>(
                          value: 'block',
                          child: const ListTile(
                            trailing: Icon(Icons.block), // Icon
                            title: Text('Block user'),
                          ),
                          onTap: () => _blockUser(feedItem['userId']),
                        ),
                    ];
                  },
                ),
                // IconButton(
                //   icon: const Icon(Icons.flag, color: Colors.grey),
                //   onPressed: () => _reportFeed(feedItem['feedId']),
                // ),
              ],
            ),
            )
          ),
          Padding(padding: EdgeInsets.all(10), child: Text(feedItem['caption'])),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                _showImageDialog(
                    'http://97.74.90.63:8080/feed/images/${feedItem['imagePath']}');
              },
              child: ClipRRect(
                child: Image.network(
                  'http://97.74.90.63:8080/feed/images/${feedItem['imagePath']}',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.all(13.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((feedItem['location']).toUpperCase(), style: AppStyles.vifitTextTheme.labelSmall?.copyWith(color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _feedItems[index]['likedByUser']
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _feedItems[index]['likedByUser']
                            ? Colors.red
                            : Colors.grey,
                      ),
                      onPressed: () {
                        _toggleLike(
                            feedItem['feedId'], _feedItems[index]['likedByUser']);
                      },
                    ),
                    Text(
                        '${feedItem['likes']} Like${feedItem['likes'] == 1 ? '' : 's'}'),
                    // const Spacer(),
                    // IconButton(
                    //   icon: const Icon(Icons.block, color: Colors.grey),
                    //   onPressed: () => _blockUser(feedItem['userId']),
                    // ),
                  ],
                ),
              ]
            )
          ),
          const Divider(),
        ]
      )
      );
  }

  Widget _buildFeedItem(BuildContext context, int index) {
    final feedItem = _feedItems[index]['feed'];
    final isProfileClickable =
        feedItem['userId'] != null && feedItem['username'] != null;
    final profileImageUrl = feedItem['userId']?.isNotEmpty ?? false
        ? 'http://97.74.90.63:8080/profiles/${feedItem['userId']}.jpg'
        : '';
    final name = feedItem['username']?.isNotEmpty ?? false
        ? _authService.decryptData(feedItem['username'])
        : 'Anonymous user';
    final datePosted = DateTime.parse(feedItem['datePosted'])
        .toUtc()
        .add(const Duration(hours: 8));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: isProfileClickable
              ? () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewProfileScreen(
                userId: feedItem['userId'],
                userName: feedItem['username'],
              ),
            ),
          )
              : null,
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : null,
                radius: 25,
                backgroundColor: Colors.grey.shade300,
                child:
                profileImageUrl.isEmpty ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy hh:mm a').format(datePosted),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.flag, color: Colors.grey),
                onPressed: () => _reportFeed(feedItem['feedId']),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            _showImageDialog(
                'http://97.74.90.63:8080/feed/images/${feedItem['imagePath']}');
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              'http://97.74.90.63:8080/feed/images/${feedItem['imagePath']}',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(feedItem['caption']),
        Text(feedItem['location'], style: const TextStyle(color: Colors.grey)),
        Row(
          children: [
            IconButton(
              icon: Icon(
                _feedItems[index]['likedByUser']
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: _feedItems[index]['likedByUser']
                    ? Colors.red
                    : Colors.grey,
              ),
              onPressed: () {
                _toggleLike(
                    feedItem['feedId'], _feedItems[index]['likedByUser']);
              },
            ),
            Text(
                '${feedItem['likes']} Like${feedItem['likes'] == 1 ? '' : 's'}'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.block, color: Colors.grey),
              onPressed: () => _blockUser(feedItem['userId']),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  Future<void> _blockUser(String blockedUserId) async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    final shouldBlock = await _showConfirmationDialog(
      title: 'Block User',
      content: 'Are you sure you want to block this user?',
    );

    if (shouldBlock) {
      try {
        final response = await _authService.blockUser(userId, blockedUserId);
        if (response) {
          _showSnackbar('User blocked successfully');
          _refreshFeed();
        } else {
          _showSnackbar('Admin will block the user in 24 hours. Thank you for your patience');
        }
      } catch (e) {
        print('Error blocking user: $e');
      }
    }
  }
}