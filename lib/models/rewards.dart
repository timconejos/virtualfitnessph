import 'package:virtualfitnessph/models/racetype.dart';

class Rewards {
  final int rewardsId;
  final String rewardsName;
  final String points;
  final String rewardsPicture;

  Rewards({
    required this.rewardsId,
    required this.rewardsName,
    required this.points,
    required this.rewardsPicture,
  });

  factory Rewards.fromJson(Map<String, dynamic> json) {
    var list = json['rewards'] as List;

    return Rewards(
      rewardsId: json['rewardsId'],
      rewardsName: json['rewardsName'],
      points: json['points'],
      rewardsPicture: json['rewardsPicture'],
    );
  }
}