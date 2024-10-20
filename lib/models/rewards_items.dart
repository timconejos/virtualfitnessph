class RewardsItems {
  final int rewardsId;
  final String rewardsName;
  final String description;
  final String rewardsPicture;
  final double amount;
  final String dateAdded;

  RewardsItems({
    required this.rewardsId,
    required this.rewardsName,
    required this.description,
    required this.rewardsPicture,
    required this.amount,
    required this.dateAdded
  });

  factory RewardsItems.fromJson(Map<String, dynamic> json) {
    // var list = json['rewardsItems'] as List;

    return RewardsItems(
      rewardsId: json['id'],
      rewardsName: json['name'],
      description: json['description'],
      rewardsPicture: json['imageUrl'],
      amount: json['amount'],
      dateAdded: json['dateAdded'],
    );
  }
}