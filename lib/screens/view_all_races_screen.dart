import 'package:flutter/material.dart';

class ViewAllRacesScreen extends StatelessWidget {
  final List<dynamic> joinedRaces;

  const ViewAllRacesScreen({super.key, required this.joinedRaces});

  @override
  Widget build(BuildContext context) {
    List<dynamic> inProgressRaces = joinedRaces.where((race) => race['registration']['completed'] == false).toList();
    List<dynamic> completedRaces = joinedRaces.where((race) => race['registration']['completed'] == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Races'),
      ),
      body: ListView(
        children: [
          if (inProgressRaces.isEmpty)
            const SizedBox(
              height: 100,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run, size: 48, color: Colors.blue),
                  SizedBox(height: 10),
                  Text('No in-progress races yet.'),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('In-Progress Races',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                ...inProgressRaces.map((race) => _buildProgressCard(
                  race['race']['raceName'],
                  race['registration']['distanceProgress'] /
                      race['registration']['raceDistance'],
                  race['registration']['id'],
                )),
              ],
            ),
          if (completedRaces.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Completed Races',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                ...completedRaces.map((race) => _buildProgressCard(
                  race['race']['raceName'],
                  1.0,
                  race['registration']['id'],
                )),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String raceName, double progress, int raceId) {
    progress = progress > 1 ? 1 : progress; // Ensure progress does not overflow past 1.0

    return InkWell(
      onTap: () {
        // Navigate to race detail page
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(raceName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                        color: Colors.red.shade600,
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
          ],
        ),
      ),
    );
  }
}