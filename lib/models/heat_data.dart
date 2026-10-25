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
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      siteId: json['siteId'] as String?,
      name: json['name'] as String?,
      kartNumber: json['kartNumber'] as int?,
      startPosition: json['startPosition'] as int?,
      bestTime: json['bestTime'] as String?,
      avgTime: json['avgTime'] as String?,
      devTime: json['devTime'] as String?,
      position: json['position'] as String?,
      bestLapMillis: json['bestLapMillis'] as int?,
      totalLaps: json['totalLaps'] as int?,
      columnIndex: json['columnIndex'] as int?,
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
      lapTime: json['lapTime'] as String?,
      lapTimeMillis: json['lapTimeMillis'] as int?,
      position: json['position'] as String?,
      racePosition: json['racePosition'] as String?,
      raceLapNumber: json['raceLapNumber'] as int?,
      stintIndex: json['stintIndex'] as int?,
      kartNumber: json['kartNumber'] as int?,
      columnIndex: json['columnIndex'] as int?,
      gapToLeader: json['gapToLeader'] as String?,
      gapToPrevious: json['gapToPrevious'] as String?,
      bestLapOverall: json['bestLapOverall'] as bool?,
      bestLapStint: json['bestLapStint'] as bool?,
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
      heatName: json['heatName'] as String? ?? '',
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
