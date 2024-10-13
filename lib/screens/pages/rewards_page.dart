import 'package:flutter/material.dart';
import 'package:virtualfitnessph/screens/rewards_detail_page.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';
import 'package:virtualfitnessph/services/auth_service.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});
  
  @override
  _RewardsPageState createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final AuthService _authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.scaffoldBgColor,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _authService.fetchRewards(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
             return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 100, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    "Network connection is not available",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          List<Map<String, dynamic>> rewards = snapshot.data!;
          // Sorting
          // rewards.sort((a, b) => DateTime.parse(a.startDate).compareTo(DateTime.parse(b.startDate)));

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                return FutureBuilder(
                  future: _authService.fetchRewardsImage('filename'), 
                  builder: (context, imageSnapshot) {
                     if (imageSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (imageSnapshot.hasError) {
                      return rewardCard(rewards[index], 'assets/login.jpg'); // Default image
                    }
                    return rewardCard(rewards[index], imageSnapshot.data!);
                  });
              }),
          );
        },
      )
    );
  }

  Widget rewardCard(dynamic rewards, String imageUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
           MaterialPageRoute(
            builder: (context) => RewardsDetailPage(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 5.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ]
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(

              height: 150,
              width: 130,
              child: ClipRRect(
                  child: Image.network(
                    imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset('assets/post1.jpg', height: 100, width: double.infinity, fit: BoxFit.cover);
                    },
                  ),
                ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                Text(rewards['rewardsName'], style: AppStyles.vifitTextTheme.titleMedium),
                Text('P ${rewards['price']}', style: AppStyles.vifitTextTheme.titleLarge?.copyWith(color: AppStyles.secondaryColor)),
              ],
            )
          ]
          )
      ),
    );
  }
}