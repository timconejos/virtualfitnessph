import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:virtualfitnessph/services/auth_service.dart';

import 'add_race_data_screen.dart';

class RaceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> race;

  const RaceDetailScreen({super.key, required this.race});

  @override
  _RaceDetailScreenState createState() => _RaceDetailScreenState();
}

class _RaceDetailScreenState extends State<RaceDetailScreen> {
  late Map<String, dynamic> race;
  late List<dynamic> submissions = [];
  bool isLoading = true;
  final AuthService _authService = AuthService();
  String? userId;

  @override
  void initState() {
    super.initState();
    _fetchRaceDetails();
  }

  Future<void> _fetchRaceDetails() async {
    userId = await _authService.getUserId();
    setState(() {
      isLoading = true;
    });

    try {
      submissions = await _authService.fetchRaceDetails(
          userId!, widget.race['race']['raceId']);
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading submissions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    DateTime date = DateTime.parse(dateStr);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  double get totalDistance =>
      submissions.fold(0, (sum, item) => sum + item['distanceKm']);

  int get totalSeconds => submissions.fold(0, (sum, item) {
    int hours = item['hours'] ?? 0;
    int minutes = item['minutes'] ?? 0;
    int seconds = item['seconds'] ?? 0;
    return sum + hours * 3600 + minutes * 60 + seconds;
  });

  double get averagePace {
    if (totalDistance == 0) return 0.0;
    double totalMinutes = totalSeconds / 60.0;
    return totalMinutes / totalDistance;
  }

  String formatPace(double pace) {
    int minutes = pace.floor();
    int seconds = ((pace - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    double raceDistance = widget.race['registration']['raceDistance'];
    return totalDistance / raceDistance;
  }

  Widget _buildStatsSection() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stats Overview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ProfileStat(
                    icon: Icons.location_on,
                    label: "${totalDistance.toStringAsFixed(2)} KM",
                    subLabel: 'Distance (km)'),
                ProfileStat(
                    icon: Icons.timer,
                    label: formatPace(averagePace),
                    subLabel: 'Pace (min/km)'),
                ProfileStat(
                    icon: Icons.directions_run,
                    label: "${submissions.length}",
                    subLabel: 'Runs'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBarSection() {
    double raceDistance = widget.race['registration']['raceDistance'];
    double approvedDistance = submissions
        .where((submission) => submission['status'] == "APPROVED")
        .fold(0.0, (sum, item) => sum + item['distanceKm']);
    double pendingDistance = submissions
        .where((submission) => submission['status'] == "PENDING")
        .fold(0.0, (sum, item) => sum + item['distanceKm']);

    double approvedProgress = (approvedDistance / raceDistance).clamp(0.0, 1.0);
    double pendingProgress = ((approvedDistance + pendingDistance) / raceDistance).clamp(0.0, 1.0) - approvedProgress;
    double totalProgress = approvedProgress + pendingProgress;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Race Progress',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${(approvedDistance + pendingDistance).toStringAsFixed(2)} KM",
                  style: const TextStyle(color: Colors.black),
                ),
                Text(
                  "${raceDistance.toStringAsFixed(2)} KM",
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                // Background for the progress bar
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Approved progress (Green)
                FractionallySizedBox(
                  widthFactor: approvedProgress,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: approvedProgress < 1
                          ? const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      )
                          : BorderRadius.circular(10),
                    ),
                  ),
                ),
                // Pending progress (Yellow), placed after the green bar
                Positioned(
                  left: approvedProgress * MediaQuery.of(context).size.width,
                  child: FractionallySizedBox(
                    widthFactor: pendingProgress,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        borderRadius: (approvedProgress + pendingProgress) < 1
                            ? const BorderRadius.only(
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        )
                            : BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                // Centered text showing the percentage of the progress
                Positioned.fill(
                  child: Center(
                    child: Text(
                      '${(totalProgress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: totalProgress >= 1.0
                    ? null // Disable the button when progress is 100% or greater
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddRaceDataScreen(
                        initialRaceId: widget.race['race']['raceId'],
                      ),
                    ),
                  );
                },
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Submissions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        submissions.isEmpty
            ? const Center(
          child: Column(
            children: [
              Icon(Icons.insert_drive_file, size: 50, color: Colors.grey),
              Text('No submissions made yet.')
            ],
          ),
        )
            : ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: submissions.length,
          itemBuilder: (context, index) {
            var submission = submissions[index];
            return GestureDetector(
              onTap: () {
                _showImageDialog(
                    'http://97.74.90.63:8080/submissions/proofs/${submission['submissionFilepath']}');
              },
              child: ListTile(
                leading: Image.network(
                  'http://97.74.90.63:8080/submissions/proofs/${submission['submissionFilepath']}',
                  // Proof image URL
                  width: 50,
                  height: 50,
                ),
                title: Text(submission['status']),
                subtitle: Text('${submission['distanceKm']} KM'),
                // Example distance
                trailing: Text(_formatDate(
                    submission['submissionDate'])), // Example date
              ),
            );
          },
        ),
      ],
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.race['race']['raceName']),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child: Image.network(
                        'http://97.74.90.63:8080/races/badges/${widget.race['race']['badgesPicturePath']}',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            'https://via.placeholder.com/100x100',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildStatsSection(),
            _buildProgressBarSection(),
            _buildSubmissionListSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subLabel;

  const ProfileStat(
      {super.key, required this.icon, required this.label, required this.subLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 30),
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(subLabel, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
