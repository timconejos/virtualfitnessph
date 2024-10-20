import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:virtualfitnessph/models/rewards_items.dart';
import 'package:virtualfitnessph/screens/reward_add_address_screen.dart';
import 'package:virtualfitnessph/services/auth_service.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

class RewardCheckOutScreen extends StatefulWidget {
  const RewardCheckOutScreen({super.key});

  @override
  _RewardCheckOutScreenState createState() => _RewardCheckOutScreenState();
}

class _RewardCheckOutScreenState extends State<RewardCheckOutScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  late ScrollController _scrollController;
  List<RewardsItems> _items = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart (${_items.length})'),
      ),
      backgroundColor: AppStyles.scaffoldBgColor,
      body: FutureBuilder<List<RewardsItems>>(
        future: _authService.fetchCart(false),
        builder:  (context, snapshot) { 
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

          return Stack(
            fit:  StackFit.expand,
            children:[
              RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: rewards.isEmpty ? _buildEmptyRewardList() :
                ListView.builder(
                  itemCount: rewards.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder(
                      future: _authService.fetchRewardsImage('filename'), 
                      builder: (context, imageSnapshot) {
                        if (imageSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (imageSnapshot.hasError) {
                          return _buildItem(rewards[index], 'assets/login.jpg'); // Default image
                        }
                        return _buildItem(rewards[index], imageSnapshot.data!);
                      });
                  }),
              ),
              Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Expanded (child:Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min, // Add this line
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RewardAddAddressScreen(),
                                ),
                              );
                        }, child: const Text('Check out', textAlign: TextAlign.end,),)
                      ],
                    ),
                  )),
                ),
            ]
          );
        }
      ),
    );
  }

  Widget _buildItem(RewardsItems reward, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(15),
      height: 131,
      decoration: const BoxDecoration(
          color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Flexible(child: SizedBox(
              height: 131,
              width: 100,
              child: ClipRRect(
                  child: Image.network(
                    imageUrl,
                    height: 131,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset('assets/post1.jpg', height: 131, width: double.infinity, fit: BoxFit.cover);
                    },
                  ),
                ),
            )),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // const SizedBox(height: 15),
                Text(reward.rewardsName, 
                  style: AppStyles.vifitTextTheme.labelLarge, softWrap: true,
                  overflow: TextOverflow.ellipsis, maxLines: 2),
                const SizedBox(height: 5),
                Text('P ${formatNumber(reward.amount)}', style: AppStyles.vifitTextTheme.titleMedium?.copyWith(color: AppStyles.secondaryColor)),
                
              ],
            )),
            GestureDetector(
              onTap: () => _removeItem(reward.rewardsId),
              child: const Icon(Icons.close),
            )
      ],),
    );
  }


  Widget _buildEmptyRewardList() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.remove_shopping_cart, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Cart is empty',
            style: TextStyle(fontSize: 24, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _removeItem(int rewardId) async {
    final shouldDelete = await _showConfirmationDialog(
      title: 'Remove item?',
      content: 'Are you sure you want to remove this item?');

    if(shouldDelete) {
      // Add delete method
    }
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
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  String formatNumber(double price) {
    return NumberFormat('#,###.##').format(price);
  }
}