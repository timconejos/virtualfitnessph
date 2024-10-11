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
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
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
              child: ListView.builder(
              itemCount: races.length,
              itemBuilder: (context, index) {
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
              },
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 10.0),
        padding: const EdgeInsets.only(bottom: 10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.6),
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  ClipRRect(
                    child: Image.network(
                      imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset('assets/login.jpg', height: 180, width: double.infinity, fit: BoxFit.cover);
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppStyles.primaryColor.withOpacity(0.2), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(15.0),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child:
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(race.raceName, style: AppStyles.vifitTextTheme.titleLarge?.copyWith(color: AppStyles.textColor), maxLines: 2, overflow: TextOverflow.visible,),
                        Text('$startDate - $endDate', style:  AppStyles.vifitTextTheme.labelMedium?.copyWith(color: AppStyles.greyColor)),
                      ],
                    )),
                    const SizedBox(width: 5),
                    OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => RaceDetailPage(race: race),
                        ),
                      );
                    },
                    icon: const Icon(Icons.directions_run, size: 20),
                    // style: AppStyles.secondaryButtonStyleSmall,
                    style: OutlinedButton.styleFrom(foregroundColor: AppStyles.secondaryColor, side: BorderSide(color: AppStyles.secondaryColor, width: 1)),
                    label: Text('Join', style: AppStyles.vifitTextTheme.titleMedium),
                  )]),
                

              ],
            ),
            ),
             
          ],
          )
      )
    );
  }
}