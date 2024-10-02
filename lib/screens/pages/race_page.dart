import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:virtualfitnessph/models/race.dart';
import 'package:virtualfitnessph/screens/pages/race_detail_page.dart';
import 'package:virtualfitnessph/services/auth_service.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

class RacePage extends StatefulWidget {
  const RacePage({super.key});

  @override
  _RacePageState createState() => _RacePageState();
}

class _RacePageState extends State<RacePage> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.scaffoldBgColor,
      body: FutureBuilder<List<Race>>(
        future: _authService.fetchRaces(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppStyles.primaryColor));
          } else if (snapshot.hasError) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 100, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    "Network connection is not available",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Sort races by startDate
          List<Race> races = snapshot.data!;
          races.sort((a, b) => DateTime.parse(a.startDate).compareTo(DateTime.parse(b.startDate)));

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 5, // Space between columns
              mainAxisSpacing: 5, // Space between rows
              padding: EdgeInsets.all(5),
              children: List.generate(races.length, (index) {
                return FutureBuilder<String>(
                  future: _authService.fetchRaceImage(races[index].racePicturePath),
                  builder: (context, imageSnapshot) {
                    if (imageSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (imageSnapshot.hasError) {
                      return raceCard(races[index], 'assets/login.jpg'); // Default image
                    }
                    return raceCard(races[index], imageSnapshot.data!);
                  },
                );
              })
            //   children: [ListView.builder(
            //   itemCount: races.length,
            //   itemBuilder: (context, index) {
            //     return FutureBuilder<String>(
            //       future: _authService.fetchRaceImage(races[index].racePicturePath),
            //       builder: (context, imageSnapshot) {
            //         if (imageSnapshot.connectionState == ConnectionState.waiting) {
            //           return const Center(child: CircularProgressIndicator());
            //         } else if (imageSnapshot.hasError) {
            //           return raceCard(races[index], 'assets/login.jpg'); // Default image
            //         }
            //         return raceCard(races[index], imageSnapshot.data!);
            //       },
            //     );
            //   },
            // ),],
            ),
            
            
            
          );
        },
      ),
    );
  }

  Widget raceCard(Race race, String imageUrl) {
    var startDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(race.startDate));
    var endDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(race.endDate));
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RaceDetailPage(race: race),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 1,
        margin: const EdgeInsets.all(4.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
              child: Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset('assets/login.jpg', height: 150, width: double.infinity, fit: BoxFit.cover);
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(10.0),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              //  spacing: 10, // Horizontal space between items
              //   runSpacing: 1,
              children: [
                Text(race.raceName, style: AppStyles.vifitTextTheme.titleMedium ),
                Text( '$startDate - $endDate', style:  AppStyles.vifitTextTheme.labelMedium)
              ],
            ),
            ),
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            //   child: 
            // ),
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            //   ,
            // ),
          ],
        ),
      ),
    );
  }
}