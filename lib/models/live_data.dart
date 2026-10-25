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
      live: json['live'] as bool? ?? false,
      status: json['status'] as String? ?? 'IDLE',
      heat: heatJson is Map<String, dynamic> ? LiveHeat.fromJson(heatJson) : null,
      lastUpdateAt: json['lastUpdateAt'] as int?,
      ageMs: json['ageMs'] as int?,
      startedAt: json['startedAt'] as int?,
      messages: json['messages'] as int? ?? 0,
      staleTimeoutMs: json['staleTimeoutMs'] as int? ?? 180000,
    );
  }

  bool get hasHeat => heat != null;

  /// Сколько секунд прошло с последнего сообщения сайта (с учётом времени после ответа).
  int? get ageNowMs {
    if (ageMs == null) return null;
    return ageMs! + DateTime.now().difference(fetchedAt).inMilliseconds;
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
      heatName: json['heatName'] as String? ?? '',
      trackSlug: json['trackSlug'] as String? ?? '',
      elapsed: json['elapsed'] as int? ?? 0,
      mode: json['mode'] as int? ?? 0,
      pitlaneKarts: (json['pitlaneKarts'] as List?)?.map((e) => e as int).toList() ?? const [],
      pitstopTimeThreshold: json['pitstopTimeThreshold'] as int?,
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
      driverName: json['driverName'] as String? ?? '—',
      number: json['number'] as int?,
      position: json['position'] as int? ?? 0,
      bestTime: json['bestTime'] as int?,
      stint: json['stint'] is Map<String, dynamic>
          ? LiveStint.fromJson(json['stint'] as Map<String, dynamic>)
          : null,
      laps: (json['laps'] as List?)
              ?.map((l) => LiveLap.fromJson(l as Map<String, dynamic>))
              .toList() ??
          const [],
      totalLaps: json['totalLaps'] as int? ??
          (json['laps'] as List?)?.length ??
          0,
      lastLapNumber: json['lastLapNumber'] as int?,
      bestLapTime: json['bestLapTime'] as int?,
      lastLapTime: json['lastLapTime'] as int?,
      lastGapTime: json['lastGapTime'] as int?,
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
      kart: json['kart'] as int?,
      number: json['number'] as int?,
      bestTime: json['bestTime'] as int?,
      length: json['length'] as int?,
      avgTime: json['avgTime'] as int?,
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
      stintNum: json['stintNum'] as int?,
      number: json['number'] as int?,
      time: json['time'] as int?,
      gapTime: json['gapTime'] as int?,
      kartNum: json['kartNum'] as int?,
    );
  }
}
