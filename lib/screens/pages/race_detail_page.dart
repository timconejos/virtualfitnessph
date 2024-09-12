import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'package:virtualfitnessph/models/race.dart';
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
      appBar: AppBar(
        title: Text(widget.race.raceName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 60),
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
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset('assets/login.jpg',
                        height: 200, width: double.infinity, fit: BoxFit.cover);
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  "End of registration",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple),
                ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.race.raceName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.race.startDate))} - ${DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.race.endDate))}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.race.description,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.race.distance.map((d) => '$d KM').join(', '),
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Finisher\'s reward',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                    const Text(
                      'Rules',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                    const Text(
                      'Disclaimer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Apple is not affiliated with this event.',
                      style: TextStyle(
                          fontSize: 14, height: 1.5, color: Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price starts at: P ${widget.race.racetypes.last.price.toString()}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.deepPurple,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RegisterRaceScreen(race: widget.race),
                    ),
                  );
                },
                child: const Text('REGISTER'),
              ),
            ],
          ),
        ),
      ),
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
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.deepPurple),
        ),
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 12, color: Colors.black),
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
