import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:virtualfitnessph/screens/race_detail_screen.dart';

import '../../services/auth_service.dart';

class AllRacesScreen extends StatefulWidget {
  const AllRacesScreen({super.key});

  @override
  _AllRacesScreenState createState() => _AllRacesScreenState();
}

class _AllRacesScreenState extends State<AllRacesScreen> {
  late List<dynamic> races = [];
  bool isLoading = true;
  final AuthService _authService = AuthService();
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadAllRaces();
  }

  Future<void> _loadAllRaces() async {
    setState(() => isLoading = true);
    userId = await _authService.getUserId();
    const String baseUrl = 'http://97.74.90.63:8080';
    Uri uri = Uri.parse('$baseUrl/api/registrations/user/$userId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          races = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load races');
      }
    } catch (e) {
      print('Error loading races: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Races'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadAllRaces,
        child: ListView.builder(
          itemCount: races.length,
          itemBuilder: (context, index) {
            return _buildRaceCard(races[index]);
          },
        ),
      ),
    );
  }

  Widget _buildRaceCard(Map<String, dynamic> race) {
    double progress = race['registration']['distanceProgress'] / race['registration']['raceDistance'];
    progress = progress.clamp(0.0, 1.0); // Ensure progress does not overflow past 1.0

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RaceDetailScreen(race: race),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              race['race']['raceName'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 20,
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 0,
                  child: Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Completed: ${race['registration']['completed'] == true ? 'Yes' : 'No'}',
              style: TextStyle(color: race['registration']['completed'] == true ? Colors.green : Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}