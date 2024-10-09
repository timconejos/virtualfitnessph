import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:virtualfitnessph/components/primary_app_bar.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

class ViewAllBadgesScreen extends StatelessWidget {
  final List<dynamic> badges;

  const ViewAllBadgesScreen({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(title: 'All Badges'),
      // appBar: AppBar(
      //   title: const Text('All Badges'),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: badges.length,
          itemBuilder: (context, index) {
            var badge = badges[index];
            return ListTile(
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(
                  'http://97.74.90.63:8080/races/badges/${badge['badgesPicturePath']}',
                ),
                backgroundColor: Colors.transparent,
                onBackgroundImageError: (exception, stackTrace) {
                  // Do nothing, Image.network will handle the error
                },
              ),
              title: Text(badge['raceName'], style: AppStyles.vifitTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat('MMM dd, yyyy hh:mm:ss a')
                  .format(DateTime.parse(badge['completeDate'])), style: AppStyles.vifitTextTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenBadge(
                      imageUrl:
                      'http://97.74.90.63:8080/races/badges/${badge['badgesPicturePath']}',
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class FullScreenBadge extends StatelessWidget {
  final String imageUrl;

  const FullScreenBadge({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badge'),
      ),
      body: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Image.network(
              'https://via.placeholder.com/400x400',
              fit: BoxFit.contain,
            );
          },
        ),
      ),
    );
  }
}