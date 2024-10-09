import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'package:virtualfitnessph/models/race.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';
import '../register_race_screen.dart';

class RaceDetailPage extends StatefulWidget {
  final Race race;

  const RaceDetailPage({super.key, required this.race});

  @override
  _RaceDetailPageState createState() => _RaceDetailPageState();
}

class _RaceDetailPageState extends State<RaceDetailPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inDays)}:${twoDigits(duration.inHours.remainder(24))}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    var endDate = DateTime.parse(widget.race.endDate);
    var now = DateTime.now();
    var remaining = endDate.difference(now).inSeconds;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.race.raceName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(0),
        // Ensure the bottom padding is the height of the bottom bar
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImage(
                        imageUrl:
                            'http://97.74.90.63:8080/races/images/${widget.race.racePicturePath}',
                      ),
                    ),
                  );
                },
                child: Image.network(
                  'http://97.74.90.63:8080/races/images/${widget.race.racePicturePath}',
                  // height: double.,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset('assets/login.jpg',
                        height: 200, width: double.infinity, fit: BoxFit.cover);
                  },
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(child: Text(
                  widget.race.raceName,
                  style: AppStyles.vifitTextTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),)
              ),

              const SizedBox(height: 20),
              Center(
                child: Text(
                  "Registration ends in",
                  style: AppStyles.vifitTextTheme.labelSmall)
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Countdown(
                  seconds: remaining,
                  build: (_, double time) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      buildTimeCard(time, 'days'),
                      buildTimeCard(time, 'hours'),
                      buildTimeCard(time, 'mins'),
                      buildTimeCard(time, 'secs'),
                    ],
                  ),
                  interval: const Duration(seconds: 1),
                  onFinished: () {
                    print('Countdown finished!');
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.calendar_today, size: 30),
                          ],
                        ),
                        const SizedBox(width: 17),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Registration", style: AppStyles.vifitTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: AppStyles.greyColor)),
                            Text( '${DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.race.startDate))} - ${DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.race.endDate))}',
                            style: AppStyles.vifitTextTheme.bodyLarge,
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.directions_run, size: 30),
                          ],
                        ),
                        const SizedBox(width: 17),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Categories", style: AppStyles.vifitTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: AppStyles.greyColor)),
                            Text( widget.race.distance.map((d) => '$d KM').join(', '),
                            style: AppStyles.vifitTextTheme.bodyLarge,
                            ),
                          ],
                        )
                      ],
                    ),

                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.sell, size: 30),
                          ],
                        ),
                        const SizedBox(width: 17),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Price starts at", style: AppStyles.vifitTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: AppStyles.greyColor)),
                            Text( 'P ${widget.race.racetypes.last.price.toString()}',
                            style: AppStyles.vifitTextTheme.titleLarge?.copyWith(color: AppStyles.secondaryColor),
                            ),
                          ],
                        )
                      ],
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RegisterRaceScreen(race: widget.race),
                          ),
                        );
                      },
                      style: AppStyles.secondaryButtonStyle,
                      child: Text('Register', style: AppStyles.vifitTextTheme.titleMedium),
                    ),
                  ),
                  ],
                ),
              ),

              const SizedBox(height: 50),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                decoration: BoxDecoration(
                  color: AppStyles.primaryColor.withOpacity(0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(
                      widget.race.raceName,
                      style: AppStyles.vifitTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppStyles.secondaryColor),
                    ),
                    const SizedBox(height: 10),
                    Text(widget.race.description)

                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    Text(
                      'Finisher\'s reward',
                      style: AppStyles.vifitTextTheme.titleLarge
                    ),
                    const SizedBox(height: 10),
                    widget.race.reward.isNotEmpty
                        ? Text(
                            widget.race.reward,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          )
                        : Container(
                            height: 100, // Placeholder for Finisher's reward
                          ),
                    const SizedBox(height: 20),
                    Text(
                      'Instructions',
                      style: AppStyles.vifitTextTheme.titleLarge
                    ),
                    const SizedBox(height: 10),
                    widget.race.instruction.isNotEmpty
                        ? Text(
                            widget.race.instruction,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          )
                        : Container(
                            height: 100, // Placeholder for Instructions
                          ),
                    const SizedBox(height: 20),
                    Text(
                      'Rules',
                      style: AppStyles.vifitTextTheme.titleLarge
                    ),
                    const SizedBox(height: 10),
                    widget.race.rules.isNotEmpty
                        ? Text(
                            widget.race.rules,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          )
                        : Container(
                            height: 100, // Placeholder for Rules
                          ),
                    const SizedBox(height: 20),
                    Text(
                      'Disclaimer',
                      style: AppStyles.vifitTextTheme.titleLarge
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Apple is not affiliated with this event.',
                      style: TextStyle(
                          fontSize: 14, height: 1.5, color: Colors.red),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: BottomAppBar(
      //   color: Colors.white,
      //   child: Container(
      //     padding: const EdgeInsets.symmetric(horizontal: 16),
      //     height: 60,
      //     child: Row(
      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //       children: [
      //         Text(
      //           'Price starts at: P ${widget.race.racetypes.last.price.toString()}',
      //           style: const TextStyle(
      //             color: Colors.black,
      //             fontSize: 16,
      //           ),
      //         ),
      //         ElevatedButton(
      //           style: ElevatedButton.styleFrom(
      //             foregroundColor: Colors.white,
      //             backgroundColor: Colors.deepPurple,
      //           ),
      //           onPressed: () {
      //             Navigator.push(
      //               context,
      //               MaterialPageRoute(
      //                 builder: (context) =>
      //                     RegisterRaceScreen(race: widget.race),
      //               ),
      //             );
      //           },
      //           child: const Text('REGISTER'),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }

  Widget buildTimeCard(double time, String label) {
    Duration duration = Duration(seconds: time.toInt());
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    var value = twoDigits(label == 'days'
        ? duration.inDays
        : label == 'hours'
            ? duration.inHours.remainder(24)
            : label == 'mins'
                ? duration.inMinutes.remainder(60)
                : duration.inSeconds.remainder(60));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          style: AppStyles.vifitTextTheme.titleLarge?.copyWith(color: AppStyles.secondaryColor),
        ),
        Text(
          label.toUpperCase(),
          style: AppStyles.vifitTextTheme.labelSmall
        ),
      ],
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset('assets/login.jpg', fit: BoxFit.contain);
            },
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
