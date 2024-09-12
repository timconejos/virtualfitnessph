class RaceType {
  final int racetypeId;
  final String name;
  final double price;

  RaceType({required this.racetypeId, required this.name, required this.price});

  factory RaceType.fromJson(Map<String, dynamic> json) {
    return RaceType(
      racetypeId: json['racetypeId'],
      name: json['name'],
      price: json['price'].toDouble(),
    );
  }
}