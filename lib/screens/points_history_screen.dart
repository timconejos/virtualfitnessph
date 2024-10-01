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

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _fetchBaseUrl();
    await _fetchPointsHistory();
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
      title: Text(description),
      subtitle: Text(displayDescription),
      trailing: Text(
        '${transaction.amount} coins',
        style: TextStyle(
          color: transaction.amount >= 0 ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
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
      appBar: AppBar(
        title: const Text('Points History'),
        backgroundColor: AppStyles.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _navigateToPassPoints,
                  icon: const Icon(Icons.share),
                  label: const Text('Pass Points'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppStyles.buttonTextColor, backgroundColor: AppStyles.buttonColor,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _redeemPoints,
                  icon: const Icon(Icons.currency_exchange),
                  label: const Text('Redeem'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppStyles.buttonTextColor, backgroundColor: AppStyles.secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Points History List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _transactions.isEmpty
                  ? const Center(child: Text('No points history available.'))
                  : ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  return _buildTransactionItem(_transactions[index]);
                },
              ),
            ),
          ],
        ),
      ),
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