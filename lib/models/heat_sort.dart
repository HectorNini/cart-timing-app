import 'heat_data.dart';

/// Порядок пилотов в протоколе заезда.
enum HeatSortMode {
  /// Фактическое место, которое отдаёт сайт тайминга.
  position,

  /// Лучший круг пилота: от быстрого к медленному.
  bestLap,
}

/// Что показывать в ячейках таблицы по кругам.
enum HeatGridMode {
  /// Фактическая позиция на трассе в этом круге.
  position,

  /// Место по времени прохождения этого круга.
  lapTime,

  /// Место по лучшему кругу пилота за весь заезд.
  bestLap,
}

/// Возвращает новый список, не меняя исходный порядок `drivers`.
List<DriverInfo> sortDrivers(List<DriverInfo> drivers, HeatSortMode mode) {
  final sorted = List<DriverInfo>.from(drivers);
  sorted.sort((a, b) {
    if (mode == HeatSortMode.bestLap) {
      final byTime = _compareBestLap(a.bestLapMillis, b.bestLapMillis);
      if (byTime != 0) return byTime;
    }

    final byPosition = _positionKey(a).compareTo(_positionKey(b));
    if (byPosition != 0) return byPosition;

    final byLaps = (b.totalLaps ?? 0).compareTo(a.totalLaps ?? 0);
    if (byLaps != 0) return byLaps;

    final byBest = _compareBestLap(a.bestLapMillis, b.bestLapMillis);
    if (byBest != 0) return byBest;

    return _columnKey(a).compareTo(_columnKey(b));
  });
  return sorted;
}

/// Позиции внутри одного круга по времени прохождения.
///
/// Возвращает `columnIndex -> место`, начиная с 1. Круги без времени
/// не участвуют в нумерации.
Map<int, int> lapTimePositions(Iterable<LapDetail> details) {
  final ranked =
      details
          .where((d) => d.columnIndex != null && d.lapTimeMillis != null)
          .toList()
        ..sort((a, b) {
          final byTime = a.lapTimeMillis!.compareTo(b.lapTimeMillis!);
          if (byTime != 0) return byTime;
          return a.columnIndex!.compareTo(b.columnIndex!);
        });

  final positions = <int, int>{};
  for (var i = 0; i < ranked.length; i++) {
    positions[ranked[i].columnIndex!] = i + 1;
  }
  return positions;
}

/// Места по лучшему кругу нарастающим итогом.
///
/// Для каждого круга берётся лучший круг каждого пилота только среди
/// пройденных кругов. Возвращает `круг -> (columnIndex -> место)`.
Map<int, Map<int, int>> cumulativeBestLapPositions(
  Map<int, Map<int, LapDetail>> grid,
  Iterable<DriverInfo> drivers,
) {
  final driverByColumn = <int, DriverInfo>{
    for (final driver in drivers)
      if (driver.columnIndex != null) driver.columnIndex!: driver,
  };
  final bestByColumn = <int, int>{};
  final result = <int, Map<int, int>>{};
  final laps = grid.keys.toList()..sort();

  for (final lap in laps) {
    final details = grid[lap];
    if (details == null) continue;

    for (final entry in details.entries) {
      final time = entry.value.lapTimeMillis;
      if (time == null) continue;
      final previous = bestByColumn[entry.key];
      if (previous == null || time < previous) {
        bestByColumn[entry.key] = time;
      }
    }

    final ranked =
        bestByColumn.entries.toList()..sort((a, b) {
          final byTime = a.value.compareTo(b.value);
          if (byTime != 0) return byTime;

          final byPosition = _driverPosition(
            driverByColumn[a.key],
          ).compareTo(_driverPosition(driverByColumn[b.key]));
          if (byPosition != 0) return byPosition;

          return a.key.compareTo(b.key);
        });

    final positions = <int, int>{};
    for (var i = 0; i < ranked.length; i++) {
      positions[ranked[i].key] = i + 1;
    }
    result[lap] = positions;
  }
  return result;
}

int _driverPosition(DriverInfo? driver) {
  return driver == null ? 1 << 30 : _positionKey(driver);
}

int _positionKey(DriverInfo driver) {
  final position = driver.positionNumber;
  return position > 0 ? position : 1 << 30;
}

int _columnKey(DriverInfo driver) => driver.columnIndex ?? 1 << 30;

/// `null` (круга ещё нет) всегда оказывается в конце.
int _compareBestLap(int? a, int? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}
