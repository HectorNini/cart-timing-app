import 'dart:async';
import 'package:flutter/material.dart';
import '../models/heat_data.dart';
import '../models/heat_sort.dart';
import '../services/api_service.dart';
import '../theme/f1_theme.dart';

// Локальные ссылки на общую палитру
const Color _bg = F1.bg;
const Color _panel = F1.panel;
const Color _border = F1.border;
const Color _accent = F1.accent;
const Color _purple = F1.purple;
const Color _bestStint = F1.teal;
const Color _gold = F1.gold;

class HeatScreen extends StatefulWidget {
  final String heatId;
  final bool isRace;

  const HeatScreen({super.key, required this.heatId, this.isRace = false});

  @override
  State<HeatScreen> createState() => _HeatScreenState();
}

class _HeatScreenState extends State<HeatScreen> {
  final ApiService _apiService = ApiService();
  HeatData? _heatData;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _timer;
  late HeatSortMode _sortMode;
  late HeatGridMode _gridMode;

  @override
  void initState() {
    super.initState();
    // В гонках важен фактический порядок, в заездах — лучшее время.
    _sortMode = defaultHeatSortMode(isRace: widget.isRace);
    // В заездах позиция по кругам не вычисляется: показываем место по времени.
    _gridMode = widget.isRace ? HeatGridMode.position : HeatGridMode.lapTime;
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _apiService.getHeatData(widget.heatId);
      if (!mounted) return;
      setState(() {
        _heatData = data;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: Text(
            _heatData?.heatName ?? 'Загрузка...',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontSize: 16,
            ),
          ),
          backgroundColor: _panel,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _heatData == null) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: _accent),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              const Text(
                'Если заезд не синхронизирован — бэкенд подтянет его с сайта.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white38),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                ),
                onPressed: _fetchData,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (_heatData == null) {
      return const Center(
        child: Text('Нет данных', style: TextStyle(color: Colors.white70)),
      );
    }

    final heatData = _heatData!;
    if (heatData.drivers.isEmpty) {
      return const Center(
        child: Text('Нет гонщиков', style: TextStyle(color: Colors.white54)),
      );
    }

    return RefreshIndicator(
      color: _accent,
      backgroundColor: _panel,
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        children: [
          _buildHeader(heatData),
          const SizedBox(height: 10),
          _buildStandings(heatData),
          const SizedBox(height: 12),
          _buildGrid(heatData),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ---- Header with heat info ----
  Widget _buildHeader(HeatData heatData) {
    final maxLap = heatData.maxRaceLap;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isRace ? _gold : _accent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.isRace ? 'ГОНКА' : 'ЗАЕЗД',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heatData.heatName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (heatData.raceDate != null || heatData.raceTime != null)
                  Text(
                    '${heatData.raceDate ?? ''} ${heatData.raceTime ?? ''}'
                        .trim(),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$maxLap',
                style: const TextStyle(
                  color: _accent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'КРУГОВ',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Current standings (driver list) ----
  Widget _buildStandings(HeatData heatData) {
    final drivers = sortDrivers(heatData.drivers, _sortMode);

    int bestOverall = drivers
        .map((d) => d.bestLapMillis ?? 1 << 30)
        .fold(1 << 30, (a, b) => a < b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _sectionTitle('ПОЗИЦИИ', trailing: _sortToggle()),
          if (_sortMode == HeatSortMode.bestLap)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 7, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Порядок — по лучшему кругу. В бейдже — фактическое место.',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
            ),
          ...drivers.map((d) {
            final isBest =
                d.bestLapMillis != null && d.bestLapMillis == bestOverall;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _border, width: 0.6)),
              ),
              child: Row(
                children: [
                  _positionBadge(d.positionNumber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name ?? d.siteId ?? '-',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            if (d.kartNumber != null || d.stints.isNotEmpty)
                              _kartChip(_kartSequence(d)),
                            const SizedBox(width: 8),
                            Text(
                              '${d.totalLaps ?? 0} кр.',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatMillis(d.bestLapMillis),
                        style: TextStyle(
                          color: isBest ? _purple : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const Text(
                        'ЛУЧШИЙ',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---- Per-lap infographic grid ----
  Widget _buildGrid(HeatData heatData) {
    // Порядок строк не зависит от вкладок таблицы: он общий с блоком
    // «ПОЗИЦИИ» и меняется только его переключателем.
    final drivers = sortDrivers(heatData.drivers, _sortMode);
    final maxLap = heatData.maxRaceLap;
    if (maxLap == 0) {
      return const SizedBox.shrink();
    }

    // Матрица: строки = круг гонки, столбцы = гонщик.
    // Сопоставляем по columnIndex (индекс колонки в исходной таблице).
    final Map<int, Map<int, LapDetail>> grid = {};
    for (final row in heatData.laps) {
      final raceLap = int.tryParse(row.lapNumber);
      if (raceLap == null || row.details == null) continue;
      for (final det in row.details!) {
        final col = det.columnIndex;
        if (col == null) continue;
        grid.putIfAbsent(raceLap, () => {})[col] = det;
      }
    }

    // Места по времени внутри каждого круга: columnIndex -> позиция.
    final Map<int, Map<int, int>> timePositions = {
      for (final entry in grid.entries)
        entry.key: lapTimePositions(entry.value.values),
    };
    // Места по лучшему кругу нарастающим итогом: круг -> columnIndex -> место.
    final bestPositionsByLap = cumulativeBestLapPositions(
      grid,
      heatData.drivers,
    );

    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('ПОЗИЦИИ ПО КРУГАМ', trailing: _gridToggle()),
          if (_gridMode != HeatGridMode.position)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 7, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _gridMode == HeatGridMode.lapTime
                      ? 'В ячейках — место по времени этого круга.'
                      : 'В ячейках — место по лучшему кругу с учётом кругов до этого.',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // header row: lap numbers
                _gridHeaderRow(maxLap),
                // one row per driver
                ...List.generate(drivers.length, (dIdx) {
                  return _driverRow(
                    drivers[dIdx].columnIndex ?? dIdx,
                    drivers[dIdx],
                    maxLap,
                    grid,
                    timePositions,
                    bestPositionsByLap,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _gridLegend(),
        ],
      ),
    );
  }

  Widget _gridHeaderRow(int maxLap) {
    return Row(
      children: [
        Container(
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _border),
              right: BorderSide(color: _border),
            ),
          ),
          child: const Text(
            'ГОНЩИК',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...List.generate(maxLap, (i) {
          return Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Text(
              'К${i + 1}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _driverRow(
    int columnIndex,
    DriverInfo driver,
    int maxLap,
    Map<int, Map<int, LapDetail>> grid,
    Map<int, Map<int, int>> timePositions,
    Map<int, Map<int, int>> bestPositionsByLap,
  ) {
    return Row(
      children: [
        Container(
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _border, width: 0.6),
              right: BorderSide(color: _border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driver.name ?? driver.siteId ?? '-',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (driver.kartNumber != null || driver.stints.isNotEmpty)
                Text(
                  _driverKartLine(driver),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
            ],
          ),
        ),
        ...List.generate(maxLap, (lapIdx) {
          final raceLap = lapIdx + 1;
          final detail = grid[raceLap]?[columnIndex];
          // Первый круг на новом карте: стинт сменился относительно прошлого круга.
          final previousRow = raceLap > 1 ? grid[raceLap - 1] : null;
          final previousStint =
              previousRow != null ? previousRow[columnIndex]?.stintIndex : null;
          final stintStart =
              detail != null &&
              detail.stintIndex != null &&
              detail.stintIndex! > 1 &&
              previousStint != detail.stintIndex;
          final lapPositions = timePositions[raceLap];
          int? positionOverride;
          if (_gridMode == HeatGridMode.lapTime) {
            positionOverride = lapPositions?[columnIndex];
          } else if (_gridMode == HeatGridMode.bestLap) {
            positionOverride = bestPositionsByLap[raceLap]?[columnIndex];
          }
          return _gridCell(
            detail,
            stintStart: stintStart,
            positionOverride: positionOverride,
          );
        }),
      ],
    );
  }

  Widget _gridCell(
    LapDetail? detail, {
    bool stintStart = false,
    int? positionOverride,
  }) {
    if (detail == null || detail.lapTime == null) {
      return Container(
        width: 50,
        height: 46,
        decoration: BoxDecoration(
          border: Border(
            bottom: const BorderSide(color: _border, width: 0.6),
            left:
                stintStart
                    ? const BorderSide(color: _gold, width: 2)
                    : BorderSide.none,
          ),
        ),
        alignment: Alignment.center,
        child: const Text(
          '—',
          style: TextStyle(color: Colors.white12, fontSize: 12),
        ),
      );
    }

    final actualPos = (detail.racePosition ?? detail.position ?? '').replaceAll(
      'P',
      '',
    );
    final pos = positionOverride?.toString() ?? actualPos;
    final isOverallBest = detail.bestLapOverall == true;
    final isStintBest = detail.bestLapStint == true;
    final isBest = isOverallBest || isStintBest;

    Color bg = Colors.transparent;
    if (isOverallBest) {
      bg = _purple.withValues(alpha: 0.18);
    } else if (isStintBest) {
      bg = _bestStint.withValues(alpha: 0.15);
    }

    return Container(
      width: 50,
      height: 46,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: const BorderSide(color: _border, width: 0.6),
          left:
              stintStart
                  ? const BorderSide(color: _gold, width: 2)
                  : BorderSide.none,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (pos.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _posColor(int.tryParse(pos) ?? 99),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'P$pos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  _shortLapTime(detail.lapTime!),
                  style: TextStyle(
                    color:
                        isBest
                            ? (isOverallBest ? _purple : _bestStint)
                            : Colors.white70,
                    fontSize: 10,
                    fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          // Номер карта — в углу каждой ячейки, чтобы не занимать место у времени.
          if (detail.kartNumber != null)
            Positioned(
              top: 1,
              right: 3,
              child: Text(
                '${detail.kartNumber}',
                style: TextStyle(
                  color: stintStart ? _gold : Colors.white30,
                  fontSize: 8,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _gridLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          _legendDot(_purple, 'Лучший круг заезда'),
          _legendDot(_bestStint, 'Лучший круг стинта'),
          _legendDot(_gold, 'Первый круг на новом карте'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  Widget _sortToggle() {
    return _toggleGroup([
      // В заездах фактическую позицию не считаем — только время.
      if (widget.isRace)
        _toggleOption(
          label: 'ПОЗИЦИЯ',
          selected: _sortMode == HeatSortMode.position,
          onTap: () => setState(() => _sortMode = HeatSortMode.position),
        ),
      _toggleOption(
        label: 'ВРЕМЯ',
        selected: _sortMode == HeatSortMode.bestLap,
        onTap: () => setState(() => _sortMode = HeatSortMode.bestLap),
      ),
    ]);
  }

  Widget _gridToggle() {
    return _toggleGroup([
      // В заездах позиция по кругам не вычисляется: оставляем только время.
      if (widget.isRace)
        _toggleOption(
          label: 'ПОЗИЦИЯ',
          selected: _gridMode == HeatGridMode.position,
          onTap: () => setState(() => _gridMode = HeatGridMode.position),
        ),
      _toggleOption(
        label: 'КРУГ',
        selected: _gridMode == HeatGridMode.lapTime,
        onTap: () => setState(() => _gridMode = HeatGridMode.lapTime),
      ),
      _toggleOption(
        label: 'ЛУЧШЕЕ',
        selected: _gridMode == HeatGridMode.bestLap,
        onTap: () => setState(() => _gridMode = HeatGridMode.bestLap),
      ),
    ]);
  }

  Widget _toggleGroup(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _toggleOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, {Widget? trailing}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _positionBadge(int pos) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: _posColor(pos),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        pos > 0 ? '$pos' : '–',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _kartChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _border),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 10),
      ),
    );
  }

  /// «карт 9» для одного стинта или «9 → 101 → 6» при сменах карта.
  static String _kartSequence(DriverInfo driver) {
    final stints = driver.stints;
    if (stints.length > 1) {
      return stints.map((s) => s.kartNumber?.toString() ?? '?').join(' → ');
    }
    final kart =
        stints.isNotEmpty ? stints.first.kartNumber : driver.kartNumber;
    return kart != null ? 'карт $kart' : 'карт —';
  }

  /// Строка под именем в шапке строки таблицы.
  static String _driverKartLine(DriverInfo driver) {
    final count = driver.stints.length;
    final kart = count > 0 ? driver.stints.first.kartNumber : driver.kartNumber;
    if (kart == null) {
      return count > 1 ? '$count ${_pluralStints(count)}' : 'карт —';
    }
    if (count > 1) {
      return 'карт $kart · $count ${_pluralStints(count)}';
    }
    return 'карт $kart';
  }

  static String _pluralStints(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return 'стинт';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'стинта';
    }
    return 'стинтов';
  }

  static Color _posColor(int pos) => F1.positionColor(pos);

  static String _formatMillis(int? ms) => F1.formatMillis(ms);

  static String _shortLapTime(String t) {
    // 1:07.623 -> 7.623 ; 1:07.623 -> 07.623 (компактно)
    if (t.contains(':')) {
      final parts = t.split(':');
      if (parts.length == 2) {
        return '${parts[0]}:${parts[1]}';
      }
    }
    return t;
  }
}
