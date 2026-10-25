class HeatItem {
  final String id;
  final String name;
  final String date;
  final String time;
  final String topResult;
  final String type; // HEAT | RACE

  HeatItem({
    required this.id,
    required this.name,
    required this.date,
    required this.time,
    required this.topResult,
    this.type = 'HEAT',
  });

  bool get isRace => type == 'RACE';

  factory HeatItem.fromJson(Map<String, dynamic> json) {
    return HeatItem(
      id: json['id'] as String,
      name: json['name'] as String,
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      topResult: json['topResult'] as String? ?? '',
      type: json['type'] as String? ?? 'HEAT',
    );
  }
}

class HeatList {
  final String trackName;
  final List<HeatItem> heats;

  HeatList({
    required this.trackName,
    required this.heats,
  });

  factory HeatList.fromJson(Map<String, dynamic> json) {
    return HeatList(
      trackName: json['trackName'] as String,
      heats: (json['heats'] as List)
          .map((item) => HeatItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}