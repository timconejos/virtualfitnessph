// activity_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final AuthService _authService = AuthService();
  List<dynamic> submissions = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    setState(() => isLoading = true);
    const String baseUrl = 'http://97.74.90.63:8080';
    Uri uri = Uri.parse('$baseUrl/submissions/activity');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          submissions = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load submissions');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading submissions: $e');
    }
  }

  String _timeAgo(DateTime date) {
    Duration diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchSubmissions,
        child: submissions.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_run, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                'No activity yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        )
            : Column(
              children: 
                [ ListView.builder(
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    var submission = submissions[index];
                    DateTime submissionDate = DateTime.parse(submission['submissionDate']);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage('http://97.74.90.63:8080/profiles/${submission['userId']}.jpg'),
                      ),
                      title: Text('${submission['username']} submitted ${submission['distanceKm']} KM for ${submission['raceName']} in ${submission['location']}'),
                      trailing: Text(_timeAgo(submissionDate)),
                    );
                  },
                ),
                const Divider()
              ]
        ),
      ),
    );
  }
}