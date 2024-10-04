// lib/screens/points_history_screen.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../styles/app_styles.dart';
import 'pass_points_screen.dart'; // Import PassPointsScreen

class PointsHistoryScreen extends StatefulWidget {
  const PointsHistoryScreen({Key? key}) : super(key: key);

  @override
  _PointsHistoryScreenState createState() => _PointsHistoryScreenState();
}

class _PointsHistoryScreenState extends State<PointsHistoryScreen> {
  final AuthService _authService = AuthService();
  List<PointsTransaction> _transactions = [];
  bool _isLoading = true;
  String _baseUrl = '';
  String _currentPoints = "0";

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _fetchBaseUrl();
    await _fetchPointsHistory();
    await _fetchCurrentPoints();
  }

  Future<void> _fetchBaseUrl() async {
    String url = await _authService.getBaseUrl();
    setState(() {
      _baseUrl = url;
    });
  }

  Future<void> _fetchPointsHistory() async {
    String? userId = await _authService.getUserId();
    if (userId != null) {
      List<PointsTransaction> transactions = await _authService.getPointsHistory(userId);
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
    }
  }

  Future<void> _fetchCurrentPoints() async {
    String? userId = await _authService.getUserId();
    if (userId != null) {
      String points = await _authService.getCurrentPoints(userId);
      setState(() {
        _currentPoints = points;
      });
    }
  }

  void _navigateToPassPoints() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PassPointsScreen()),
    );
  }

  void _redeemPoints() {
    // Currently not implemented. Show a placeholder dialog.
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Redeem Points'),
          content: const Text('Redeem functionality is coming soon!'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(PointsTransaction transaction) {
    IconData icon;
    Color iconColor;
    String description;

    // Determine icon and color based on the points value
    if (transaction.amount >= 0) {
      icon = Icons.add_circle;
      iconColor = Colors.green;
      description = 'Earned Points';
    } else {
      icon = Icons.remove_circle;
      iconColor = Colors.red;
      description = 'Spent Points';
    }

    // Handle nullable description
    String displayDescription = transaction.description ?? "Point Adjustments Made By Admin";

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(description, style: AppStyles.vifitTextTheme.labelLarge),
      subtitle: Text(displayDescription, style: AppStyles.vifitTextTheme.labelSmall),
      trailing: Text(
        '${transaction.amount} coins',
        style: AppStyles.vifitTextTheme.labelMedium?.copyWith(
          color: transaction.amount >= 0 ? Colors.green : Colors.red,
          fontWeight: FontWeight.w900,
        ),
      ),
      // Optionally, display both description and date:
      /*
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(displayDescription),
          SizedBox(height: 4),
          Text(
            transaction.date != null
                ? _formatDate(transaction.date!)
                : 'Unknown Date',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      */
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown Date';
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.scaffoldBgColor,
      appBar: AppBar(
        title: const Text('Points History'),
        backgroundColor: AppStyles.primaryColor,
      ),
      body: Expanded(
        // padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildCoinsSection(),
                  const SizedBox(height: 20),
                  Text('Points history', style: AppStyles.vifitTextTheme.labelMedium?.copyWith(color: Colors.grey[700])),

                ] 
              ),
            ),
            // Points History List
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _transactions.isEmpty
                    ? const Center(child: Text('No points history available.'))
                    : ListView.separated(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionItem(_transactions[index]);
                      },
                      separatorBuilder: (context, index) {
                        return Divider();
                      },
                    ),
                )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child:Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: AppStyles.darkerPrimary,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ]
            ),
            child: Expanded(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 25),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(13.0), bottom: Radius.circular(0)),
                      color: AppStyles.primaryColor,
                        gradient: const LinearGradient(
                        colors: [Color(0xFFFFFDB03), Color.fromARGB(255, 255, 241, 159)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.2, 0.8]
                      )
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          backgroundColor: AppStyles.buttonColor,
                          backgroundImage: AssetImage('assets/vifit-coin1.png'),
                        ),
                        const SizedBox(width: 15),  
                        Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Coins earned', style: AppStyles.vifitTextTheme.labelSmall?.copyWith(color: AppStyles.textColor)),
                          Text(_currentPoints, style: AppStyles.vifitTextTheme.titleLarge?.copyWith(color: AppStyles.textColor))
                        ]
                      ),
                    ]
                  ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: _navigateToPassPoints, 
                              label: const Text('Pass points'),
                              icon: const Icon(Icons.send),
                              style: TextButton.styleFrom(
                                foregroundColor: AppStyles.primaryForeground, // text and icon color
                              )
                            )
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: _redeemPoints, 
                              label: const Text('Redeem'),
                              icon: const Icon(Icons.redeem),
                              style: TextButton.styleFrom(
                                foregroundColor: AppStyles.primaryForeground, // text and icon color
                              )
                            )
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              )
              
          ))
        ),
      ]
    );
  }
}


// points_transaction.dart (Model)

// lib/models/points_transaction.dart

class PointsTransaction {
  final String type; // 'earned' or 'spent'
  final double amount;
  final DateTime? date; // Nullable
  final String? description; // Nullable

  PointsTransaction({
    required this.type,
    required this.amount,
    this.date, // Nullable
    this.description, // Nullable
  });

  factory PointsTransaction.fromJson(Map<String, dynamic> json) {
    return PointsTransaction(
      type: json['type'] as String? ?? 'unknown', // Default if null
      amount: (json['points'] as num?)?.toDouble() ?? 0.0, // Default to 0.0 if null
      date: json['dateAdded'] != null
          ? DateTime.tryParse(json['dateAdded'] as String)
          : null, // Handle nullable date
      description: json['description'] as String?, // Handle nullable description
    );
  }
}