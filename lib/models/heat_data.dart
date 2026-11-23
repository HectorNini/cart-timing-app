import 'json_helpers.dart';

class StintInfo {
  final int? number;
  final int? kartNumber;
  final int? lapFrom;
  final int? lapTo;
  final int? lapsCount;
  final int? bestLapMillis;
  final int? avgLapMillis;
  final int? devMillis;

  StintInfo({
    this.number,
    this.kartNumber,
    this.lapFrom,
    this.lapTo,
    this.lapsCount,
    this.bestLapMillis,
    this.avgLapMillis,
    this.devMillis,
  });

  factory StintInfo.fromJson(Map<String, dynamic> json) {
    return StintInfo(
      number: asInt(json['number']),
      kartNumber: asInt(json['kartNumber']),
      lapFrom: asInt(json['lapFrom']),
      lapTo: asInt(json['lapTo']),
      lapsCount: asInt(json['lapsCount']),
      bestLapMillis: asInt(json['bestLapMillis']),
      avgLapMillis: asInt(json['avgLapMillis']),
      devMillis: asInt(json['devMillis']),
    );
  }
}

class DriverInfo {
  final String? siteId;
  final String? name;
  final int? kartNumber;
  final int? startPosition;
  final String? bestTime;
  final String? avgTime;
  final String? devTime;
  final String? position;
  final int? bestLapMillis;
  final int? totalLaps;
  final int? columnIndex;
  final List<StintInfo> stints;

  DriverInfo({
    this.siteId,
    this.name,
    this.kartNumber,
    this.startPosition,
    this.bestTime,
    this.avgTime,
    this.devTime,
    this.position,
    this.bestLapMillis,
    this.totalLaps,
    this.columnIndex,
    this.stints = const [],
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      siteId: asString(json['siteId']),
      name: asString(json['name']),
      kartNumber: asInt(json['kartNumber']),
      startPosition: asInt(json['startPosition']),
      bestTime: asString(json['bestTime']),
      avgTime: asString(json['avgTime']),
      devTime: asString(json['devTime']),
      position: asString(json['position']),
      bestLapMillis: asInt(json['bestLapMillis']),
      totalLaps: asInt(json['totalLaps']),
      columnIndex: asInt(json['columnIndex']),
      stints: json['stints'] != null
          ? (json['stints'] as List)
              .map((s) => StintInfo.fromJson(s as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  int get positionNumber {
    if (position == null) return 0;
    return int.tryParse(position!.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }
}

class LapDetail {
  final String? lapTime;
  final int? lapTimeMillis;
  final String? position;
  final String? racePosition;
  final int? raceLapNumber;
  final int? stintIndex;
  final int? kartNumber;
  final int? columnIndex;
  final String? gapToLeader;
  final String? gapToPrevious;
  final bool? bestLapOverall;
  final bool? bestLapStint;

  LapDetail({
    this.lapTime,
    this.lapTimeMillis,
    this.position,
    this.racePosition,
    this.raceLapNumber,
    this.stintIndex,
    this.kartNumber,
    this.columnIndex,
    this.gapToLeader,
    this.gapToPrevious,
    this.bestLapOverall,
    this.bestLapStint,
  });

  factory LapDetail.fromJson(Map<String, dynamic> json) {
    return LapDetail(
      lapTime: asString(json['lapTime']),
      lapTimeMillis: asInt(json['lapTimeMillis']),
      position: asString(json['position']),
      racePosition: asString(json['racePosition']),
      raceLapNumber: asInt(json['raceLapNumber']),
      stintIndex: asInt(json['stintIndex']),
      kartNumber: asInt(json['kartNumber']),
      columnIndex: asInt(json['columnIndex']),
      gapToLeader: asString(json['gapToLeader']),
      gapToPrevious: asString(json['gapToPrevious']),
      bestLapOverall: asBool(json['bestLapOverall']),
      bestLapStint: asBool(json['bestLapStint']),
    );
  }
}

class LapRow {
  final String lapNumber;
  final List<String> results;
  final List<LapDetail>? details;

  LapRow({
    required this.lapNumber,
    required this.results,
    this.details,
  });

  factory LapRow.fromJson(Map<String, dynamic> json) {
    List<LapDetail>? detailsList;
    if (json['details'] != null) {
      detailsList = (json['details'] as List)
          .map((d) => LapDetail.fromJson(d as Map<String, dynamic>))
          .toList();
    }
    return LapRow(
      lapNumber: json['lapNumber']?.toString() ?? '',
      results: json['results'] != null
          ? List<String>.from(json['results'] as List)
          : <String>[],
      details: detailsList,
    );
  }
}

class HeatData {
  final String heatName;
  final List<DriverInfo> drivers;
  final List<LapRow> laps;
  final String? raceDate;
  final String? raceTime;

  HeatData({
    required this.heatName,
    required this.drivers,
    required this.laps,
    this.raceDate,
    this.raceTime,
  });

  factory HeatData.fromJson(Map<String, dynamic> json) {
    List<DriverInfo> driversList = [];
    if (json['drivers'] != null) {
      final driversJson = json['drivers'] as List;
      if (driversJson.isNotEmpty && driversJson.first is String) {
        // backward compatibility
        driversList =
            driversJson.map((d) => DriverInfo(name: d.toString())).toList();
      } else {
        driversList = driversJson
            .map((d) => DriverInfo.fromJson(d as Map<String, dynamic>))
            .toList();
      }
    }
    return HeatData(
      heatName: asString(json['heatName']) ?? '',
      drivers: driversList,
      laps: json['laps'] != null
          ? (json['laps'] as List)
              .map((lap) => LapRow.fromJson(lap as Map<String, dynamic>))
              .toList()
          : <LapRow>[],
      raceDate: json['raceDate']?.toString(),
      raceTime: json['raceTime']?.toString(),
    );
  }

  /// Максимальное число кругов в гонке.
  int get maxRaceLap => laps.isEmpty
      ? 0
      : laps
          .map((l) => int.tryParse(l.lapNumber) ?? 0)
          .fold<int>(0, (a, b) => a > b ? a : b);
}
