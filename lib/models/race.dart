import 'package:virtualfitnessph/models/racetype.dart';

class Race {
  final int raceId;
  final String raceName;
  final String location;
  final String description;
  final String startDate;
  final String endDate;
  final String racePicturePath;
  final String racePictureName;
  final List<RaceType> racetypes;
  final List<String> distance;
  final String reward;
  final String instruction;
  final String rules;

  Race({
    required this.raceId,
    required this.raceName,
    required this.location,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.racetypes,
    required this.racePictureName,
    required this.racePicturePath,
    required this.distance,
    required this.reward,
    required this.instruction,
    required this.rules,
  });

  factory Race.fromJson(Map<String, dynamic> json) {
    var list = json['racetypes'] as List;
    List<RaceType> raceTypeList = list.map((i) => RaceType.fromJson(i)).toList();
    List<String> distances = (json['distances'] as String)
        .split(',')
        .toList();

    return Race(
      raceId: json['raceId'],
      raceName: json['raceName'],
      location: json['location'],
      description: json['description'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      racePicturePath: json['racePicturePath'] ?? '',
      racePictureName: json['racePictureName'] ?? '',
      racetypes: raceTypeList,
      distance: distances,
      reward: json['reward'] ?? '',
      instruction: json['instruction'] ?? '',
      rules: json['rules'] ?? '',
    );
  }
}