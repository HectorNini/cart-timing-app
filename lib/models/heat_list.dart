import 'json_helpers.dart';

class HeatItem {
  final String id;
  final String name;
  final String date;
  final String time;
  final String topResult;
  final String type; // HEAT | RACE
  /// Есть ли подробные данные заезда в локальной БД backend'а.
  final bool synced;

  HeatItem({
    required this.id,
    required this.name,
    required this.date,
    required this.time,
    required this.topResult,
    this.type = 'HEAT',
    this.synced = true,
  });

  bool get isRace => type == 'RACE';

  factory HeatItem.fromJson(Map<String, dynamic> json) {
    return HeatItem(
      id: asString(json['id']) ?? '',
      name: asString(json['name']) ?? '',
      date: asString(json['date']) ?? '',
      time: asString(json['time']) ?? '',
      topResult: asString(json['topResult']) ?? '',
      type: asString(json['type']) ?? 'HEAT',
      synced: asBool(json['synced']) ?? true,
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
      trackName: asString(json['trackName']) ?? '',
      heats: (json['heats'] as List)
          .map((item) => HeatItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}