import 'json_helpers.dart';

/// Модели live-тайминга (ответ `/api/live/current`).
/// Все времена — в миллисекундах.
class LiveSnapshot {
  final bool live;
  final String status; // LIVE | WAITING | FINISHED | IDLE
  final LiveHeat? heat;
  final int? lastUpdateAt;
  final int? ageMs;
  final int? startedAt;
  final int messages;
  final int staleTimeoutMs;

  /// Момент получения ответа — чтобы плавно «докручивать» секундомер.
  final DateTime fetchedAt;

  LiveSnapshot({
    required this.live,
    required this.status,
    this.heat,
    this.lastUpdateAt,
    this.ageMs,
    this.startedAt,
    this.messages = 0,
    this.staleTimeoutMs = 180000,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  factory LiveSnapshot.fromJson(Map<String, dynamic> json) {
    final heatJson = json['heat'];
    return LiveSnapshot(
      live: asBool(json['live']) ?? false,
      status: asString(json['status']) ?? 'IDLE',
      heat: heatJson is Map<String, dynamic> ? LiveHeat.fromJson(heatJson) : null,
      lastUpdateAt: asInt(json['lastUpdateAt']),
      ageMs: asInt(json['ageMs']),
      startedAt: asInt(json['startedAt']),
      messages: asInt(json['messages']) ?? 0,
      staleTimeoutMs: asInt(json['staleTimeoutMs']) ?? 180000,
    );
  }

  bool get hasHeat => heat != null;

  /// Сколько секунд прошло с последнего сообщения сайта (с учётом времени после ответа).
  int? get ageNowMs => ageNowMsAt(DateTime.now());

  int? ageNowMsAt(DateTime now) {
    if (ageMs == null) return null;
    final afterFetch = now.difference(fetchedAt).inMilliseconds;
    return ageMs! + (afterFetch < 0 ? 0 : afterFetch);
  }

  /// Текущее время live-заезда.
  ///
  /// `heat.elapsed` зафиксирован на моменте последнего сообщения сайта
  /// (`lastUpdateAt`), поэтому прибавляем возраст снимка `ageMs`, а не время
  /// с `fetchedAt`. Иначе на каждом опросе таймер откатывался бы назад.
  int elapsedNow(LiveHeat heat, {DateTime? now}) {
    if (!live) return heat.elapsed;
    final age = ageNowMsAt(now ?? DateTime.now());
    return age == null ? heat.elapsed : heat.elapsed + age;
  }
}

class LiveHeat {
  final String heatId;
  final String heatName;
  final String trackSlug;
  final int elapsed;
  final int mode;
  final List<int> pitlaneKarts;
  final int? pitstopTimeThreshold;
  final List<LiveDriver> drivers;

  LiveHeat({
    required this.heatId,
    required this.heatName,
    required this.trackSlug,
    required this.elapsed,
    required this.mode,
    required this.pitlaneKarts,
    this.pitstopTimeThreshold,
    required this.drivers,
  });

  factory LiveHeat.fromJson(Map<String, dynamic> json) {
    return LiveHeat(
      heatId: json['heatId']?.toString() ?? '',
      heatName: asString(json['heatName']) ?? '',
      trackSlug: asString(json['trackSlug']) ?? '',
      elapsed: asInt(json['elapsed']) ?? 0,
      mode: asInt(json['mode']) ?? 0,
      pitlaneKarts: (json['pitlaneKarts'] as List?)
              ?.map((e) => asInt(e))
              .whereType<int>()
              .toList() ??
          const [],
      pitstopTimeThreshold: asInt(json['pitstopTimeThreshold']),
      drivers: (json['drivers'] as List?)
              ?.map((d) => LiveDriver.fromJson(d as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// mode == 0 — гонка (сортировка по кругам), иначе — по лучшему кругу.
  bool get isRaceMode => mode == 0;

  bool get looksLikeRace {
    if (isRaceMode) return true;
    final name = heatName.toLowerCase();
    return name.contains('финал') || name.contains('гонк');
  }

  int get leaderLaps => drivers.isEmpty
      ? 0
      : drivers.map((d) => d.totalLaps).fold<int>(0, (a, b) => a > b ? a : b);

  /// Лучшее время круга во всей сессии.
  int? get sessionBestLap {
    final values = drivers
        .map((d) => d.bestLapTime)
        .whereType<int>()
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a < b ? a : b);
  }

  /// Лучшее время последнего круга среди пилотов (для дельты).
  int? get bestLastLap {
    final values = drivers
        .map((d) => d.lastLapTime)
        .whereType<int>()
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a < b ? a : b);
  }

  /// Позиции 1..N: сначала больше кругов, затем позиция с сервера.
  List<LiveDriver> get ranked {
    final list = [...drivers];
    list.sort((a, b) {
      if (a.totalLaps != b.totalLaps) return b.totalLaps.compareTo(a.totalLaps);
      if (a.position != b.position) return a.position.compareTo(b.position);
      final ab = a.bestLapTime ?? 1 << 30;
      final bb = b.bestLapTime ?? 1 << 30;
      return ab.compareTo(bb);
    });
    return list;
  }
}

class LiveDriver {
  final String driverId;
  final String driverName;
  final int? number;
  final int position;
  final int? bestTime;
  final LiveStint? stint;
  final List<LiveLap> laps;
  final int totalLaps;
  final int? lastLapNumber;
  final int? bestLapTime;
  final int? lastLapTime;
  final int? lastGapTime;

  LiveDriver({
    required this.driverId,
    required this.driverName,
    this.number,
    this.position = 0,
    this.bestTime,
    this.stint,
    this.laps = const [],
    this.totalLaps = 0,
    this.lastLapNumber,
    this.bestLapTime,
    this.lastLapTime,
    this.lastGapTime,
  });

  factory LiveDriver.fromJson(Map<String, dynamic> json) {
    return LiveDriver(
      driverId: json['driverId']?.toString() ?? '',
      driverName: asString(json['driverName']) ?? '—',
      number: asInt(json['number']),
      position: asInt(json['position']) ?? 0,
      bestTime: asInt(json['bestTime']),
      stint: json['stint'] is Map<String, dynamic>
          ? LiveStint.fromJson(json['stint'] as Map<String, dynamic>)
          : null,
      laps: (json['laps'] as List?)
              ?.map((l) => LiveLap.fromJson(l as Map<String, dynamic>))
              .toList() ??
          const [],
      totalLaps: asInt(json['totalLaps']) ??
          (json['laps'] as List?)?.length ??
          0,
      lastLapNumber: asInt(json['lastLapNumber']),
      bestLapTime: asInt(json['bestLapTime']),
      lastLapTime: asInt(json['lastLapTime']),
      lastGapTime: asInt(json['lastGapTime']),
    );
  }

  /// Круг, который пилот проехал последним (для истории кругов).
  LiveLap? get lastLap {
    if (laps.isEmpty) return null;
    final sorted = [...laps]..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));
    return sorted.last;
  }
}

class LiveStint {
  final int? kart;
  final int? number;
  final int? bestTime;
  final int? length;
  final int? avgTime;

  LiveStint({
    this.kart,
    this.number,
    this.bestTime,
    this.length,
    this.avgTime,
  });

  factory LiveStint.fromJson(Map<String, dynamic> json) {
    return LiveStint(
      kart: asInt(json['kart']),
      number: asInt(json['number']),
      bestTime: asInt(json['bestTime']),
      length: asInt(json['length']),
      avgTime: asInt(json['avgTime']),
    );
  }
}

class LiveLap {
  final int? stintNum;
  final int? number;
  final int? time;
  final int? gapTime;
  final int? kartNum;

  LiveLap({
    this.stintNum,
    this.number,
    this.time,
    this.gapTime,
    this.kartNum,
  });

  factory LiveLap.fromJson(Map<String, dynamic> json) {
    return LiveLap(
      stintNum: asInt(json['stintNum']),
      number: asInt(json['number']),
      time: asInt(json['time']),
      gapTime: asInt(json['gapTime']),
      kartNum: asInt(json['kartNum']),
    );
  }
}
