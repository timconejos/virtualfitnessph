import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:virtualfitnessph/models/rewards_items.dart';
import 'package:virtualfitnessph/screens/main_page_screen.dart';
import 'package:virtualfitnessph/screens/reward_check_out_screen.dart';
import 'package:virtualfitnessph/screens/rewards_detail_page.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';
import 'package:virtualfitnessph/services/auth_service.dart';

class RewardsPage extends StatefulWidget {
  // final Function(int) changeTab;

  const RewardsPage({super.key});
  
  @override
  _RewardsPageState createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _rewards = [];
  bool _isLoading = false;
  

  void _searchRewards() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a search query.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _rewards = [];
    });

    List<dynamic> users = await _authService.searchRewards(query);

    setState(() {
      _rewards = users;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
             Navigator.pushAndRemoveUntil(context, 
             MaterialPageRoute(builder: (context) => const MainPageScreen(tab: 0)),
             (Route<dynamic> route) => false);
          }, // Add search button
        ),
        actions: [
          IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () {
             Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RewardCheckOutScreen(),
              ),
            );
          }, // Add search button
        ),
        ],
        title: TextField(
        controller: _searchController,
        autofocus: false,
        style: const TextStyle(color: Colors.white),
        onSubmitted: (value) => _searchRewards(),
        decoration: InputDecoration(
          isDense: true,
          isCollapsed: false,
          filled: true,
          fillColor: AppStyles.darkerPrimary,
          hintText: 'Search rewards...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder:  OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          errorBorder:  OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder:  OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedErrorBorder:  OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          disabledBorder:  OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _searchRewards,
                color: Colors.white,
              ),
        ),
        onChanged: (value) {
          // Implement search logic here
          print("Searching for: $value");
        },
        cursorColor: Colors.white
      ),
      ),
      backgroundColor: AppStyles.scaffoldBgColor,
      body: FutureBuilder<List<RewardsItems>>(
        future: _authService.fetchRewards(false),
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

          List<RewardsItems> rewards = snapshot.data!;
          // Sorting
          // rewards.sort((a, b) => DateTime.parse(a.startDate).compareTo(DateTime.parse(b.startDate)));

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: rewards.isEmpty ? _buildEmptyRewardList() :
             ListView.builder(
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                return FutureBuilder(
                  future: _authService.fetchRewardsImage(rewards[index].rewardsPicture),
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

  Widget rewardCard(RewardsItems reward, String imageUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
           MaterialPageRoute(
            builder: (context) => RewardsDetailPage(reward: reward),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 5.0),
        // height: 170,
        // width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.grey.withOpacity(0.3),
          //     spreadRadius: 1,
          //     blurRadius: 1,
          //     offset: const Offset(0, 1),
          //   ),
          // ]
        ),

        child: Column(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 170,
              width: double.infinity,
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
            Container(
              padding:  const EdgeInsets.all(15.0),
              child: Column (
                crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child:
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reward.rewardsName, style: AppStyles.vifitTextTheme.titleMedium?.copyWith(color: AppStyles.textColor), maxLines: 2, overflow: TextOverflow.visible,),
                      ],
                    )),
                    const SizedBox(width: 15),
                    Text('${formatNumber(reward.amount)} ViFit coins', style: AppStyles.vifitTextTheme.titleMedium?.copyWith(color: AppStyles.secondaryColor))
        
                  ]),
                

              ],
              )
            ),
          ]
          )
      ),
    );
  }

  Widget _buildEmptyRewardList() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.redeem, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'No listing yet',
            style: TextStyle(fontSize: 24, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String formatNumber(double price) {
    return NumberFormat('#,###.##').format(price);
  }
}