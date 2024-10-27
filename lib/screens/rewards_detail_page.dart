import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:virtualfitnessph/models/rewards_items.dart';
import 'package:virtualfitnessph/screens/reward_check_out_screen.dart';
import 'package:virtualfitnessph/services/auth_service.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

class RewardsDetailPage extends StatefulWidget {
  final RewardsItems reward;

  const RewardsDetailPage({super.key, required this.reward});

  @override
  _RewardsDetailPageState createState() => _RewardsDetailPageState();
}

class _RewardsDetailPageState extends State<RewardsDetailPage> {
  late ScrollController _scrollController;
  final AuthService _authService = AuthService();

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

  void _addToCart() async {
    await _authService.addToCart(widget.reward);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.reward.rewardsName} added to cart!')),
    );
  }

  void _checkOut() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RewardCheckOutScreen(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards')
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget> [
                GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImage(
                            imageUrl:
                            'http://97.74.90.63:8080/rewards/images/${widget.reward.rewardsPicture}',
                          ),
                        ),
                      );
                    },
                  child: Image.network(
                    'http://97.74.90.63:8080/rewards/images/${widget.reward.rewardsPicture}',
                      // height: double.,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset('assets/login.jpg',
                          width: double.infinity, fit: BoxFit.cover);
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white
                    ),
                    child:  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('₱ ${formatNumber(widget.reward.amount)}', style: AppStyles.vifitTextTheme.titleLarge?.copyWith(color: AppStyles.secondaryColor),),
                        const SizedBox(height: 5),
                        Text(widget.reward.rewardsName, style: AppStyles.vifitTextTheme.titleMedium)
                      ]
                    ),

                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white
                    ),
                    child:  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: AppStyles.vifitTextTheme.titleLarge
                        ),
                        const SizedBox(height: 10),
                        Text(widget.reward.description,  style: AppStyles.vifitTextTheme.bodyMedium)
                      ]
                    ),

                  ),
              ]
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min, // Add this line
                  children: [
                    ElevatedButton(
                      onPressed: _addToCart,
                      style: ElevatedButton.styleFrom(backgroundColor: AppStyles.buttonColor, foregroundColor: AppStyles.buttonTextColor),
                      child: const Text('Add to cart', textAlign: TextAlign.end,),),
                    const SizedBox(width: 5),
                    ElevatedButton(
                      onPressed: _checkOut, child: const Text('Check out', textAlign: TextAlign.end,),)
                  ],
                ),
              ),
            ),
        ],
      )

    );
  }


  String formatNumber(double price) {
    return NumberFormat('#,###.##').format(price);
  }

}


class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset('assets/login.jpg', fit: BoxFit.contain);
            },
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}