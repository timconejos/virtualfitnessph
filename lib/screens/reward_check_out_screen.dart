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
    _loadCartItems(); // Load cart items when the screen initializes
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
    });
    _items = await _authService.getCartItems(); // Fetch cart items from AuthService
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _removeItem(RewardsItems rewardItem) async {
    final shouldDelete = await _showConfirmationDialog(
      title: 'Remove item?',
      content: 'Are you sure you want to remove this item?',
    );

    if (shouldDelete) {
      await _authService.removeFromCart(rewardItem); // Remove item from cart using AuthService
      await _loadCartItems(); // Reload cart items after removal
    }
  }

  void _checkOut() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RewardAddAddressScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart (${_items.length})'),
      ),
      backgroundColor: AppStyles.scaffoldBgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        fit: StackFit.expand,
        children: [
          _items.isEmpty
              ? _buildEmptyRewardList()
              : RefreshIndicator(
            onRefresh: _loadCartItems,
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return FutureBuilder(
                  future: _authService.fetchRewardsImage(_items[index].rewardsPicture),
                  builder: (context, imageSnapshot) {
                    if (imageSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (imageSnapshot.hasError) {
                      return _buildItem(_items[index], 'assets/login.jpg'); // Default image
                    }
                    return _buildItem(_items[index], imageSnapshot.data!);
                  },
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: ElevatedButton(
                onPressed: _items.isNotEmpty ? _checkOut : null,
                child: const Text('Check out', textAlign: TextAlign.end),
                // style: _items.isNotEmpty ? AppStyles.primaryButtonStyle : ElevatedButton.styleFrom(
                //   backgroundColor: Colors.grey,
                //   foregroundColor: AppStyles.greyColor
                // ),
              ),
            ),
          ),
        ],
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
          Flexible(
            child: SizedBox(
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
                    return Image.asset('assets/post1.jpg',
                        height: 131, width: double.infinity, fit: BoxFit.cover);
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  reward.rewardsName,
                  style: AppStyles.vifitTextTheme.labelLarge,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 5),
                Text(
                  '₱ ${formatNumber(reward.amount)}',
                  style: AppStyles.vifitTextTheme.titleMedium
                      ?.copyWith(color: AppStyles.secondaryColor),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _removeItem(reward),
            child: const Icon(Icons.close),
          )
        ],
      ),
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