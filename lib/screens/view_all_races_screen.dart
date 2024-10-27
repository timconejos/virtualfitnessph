import 'package:flutter/material.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

class ViewAllRacesScreen extends StatelessWidget {
  final List<dynamic> joinedRaces;

  const ViewAllRacesScreen({super.key, required this.joinedRaces});

  @override
  Widget build(BuildContext context) {
    List<dynamic> inProgressRaces = joinedRaces.where((race) => race['registration']['completed'] == false).toList();
    List<dynamic> completedRaces = joinedRaces.where((race) => race['registration']['completed'] == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All races'),
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
                  Icon(Icons.directions_run, size: 48, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No in-progress races yet.'),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('In-Progress Races',
                      style: AppStyles.vifitTextTheme.labelMedium),
                ),
                ...inProgressRaces.map((race) => _buildRaceCard(
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Completed Races',
                      style: AppStyles.vifitTextTheme.labelMedium)
                ),
                ...completedRaces.map((race) => _buildRaceCard(
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


  Widget _buildRaceCard(String raceName, double progress, int raceId) {
    progress = progress.clamp(0.0, 1.0); // Ensure progress does not overflow past 1.0

    return InkWell(
      child: Container(
        margin: const EdgeInsets.only(bottom: 5.0),
        padding: const EdgeInsets.symmetric(vertical: 22.0, horizontal: 20.0),
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
            Text(
              raceName,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              'Progress: ${(progress * 100).toStringAsFixed(1)}%',
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
              ],
            ),
          ],
        ),
      ),
    );
  }

}