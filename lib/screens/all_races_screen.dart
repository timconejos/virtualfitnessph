import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:virtualfitnessph/screens/race_detail_screen.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

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

  void _navigateToRaceDetail(Map<String, dynamic> race) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RaceDetailScreen(race: race),
      ),
    );
  }
  
  Widget _buildRaceCard(Map<String, dynamic> race) {
    double progress = race['registration']['distanceProgress'] / race['registration']['raceDistance'];
    progress = progress.clamp(0.0, 1.0); // Ensure progress does not overflow past 1.0

    return InkWell(
      onTap: () => _navigateToRaceDetail(race),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5.0),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          //  RichText(text:  TextSpan(style: const TextStyle(color: AppStyles.textColor, fontSize: 18),
          //               children: [
          //               TextSpan(text: race['race']['raceName'], style: TextStyle(fontWeight: FontWeight.bold)),
          //               TextSpan(text:  'Completed: ${race['registration']['completed'] == true ? 'Yes' : '${(progress * 100).toStringAsFixed(1)}%'}', style: TextStyle(fontWeight: FontWeight.bold)),
          //             ]
          //           )),
            Text(
              race['race']['raceName'],
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              'Completed: ${race['registration']['completed'] == true ? 'Yes' : '${(progress * 100).toStringAsFixed(1)}%'}',
              // style: TextStyle(color: race['registration']['completed'] == true ? Colors.green : Colors.red),
            ),
            const SizedBox(height: 5),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 26,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 26,
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        color: AppStyles.secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                // Positioned(
                //   right: 10,
                //   top: 0,
                //   child: Text(
                //     '${(progress * 100).toStringAsFixed(1)}%',
                //     style: const TextStyle(fontWeight: FontWeight.bold),
                //   ),
                // ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed:  () => _navigateToRaceDetail(race), 
                child: Text('More details...', style: AppStyles.vifitTextTheme.labelMedium?.copyWith(color: AppStyles.secondaryColor)))
              ],
            )
          ],
        ),
      ),
    );
  }
}