import 'dart:async';
import 'package:flutter/material.dart';
import '../models/heat_data.dart';
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

  @override
  void initState() {
    super.initState();
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
                fontWeight: FontWeight.w700, letterSpacing: 0.5, fontSize: 16),
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
                    '${heatData.raceDate ?? ''} ${heatData.raceTime ?? ''}'.trim(),
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
    final drivers = List<DriverInfo>.from(heatData.drivers)
      ..sort((a, b) => a.positionNumber.compareTo(b.positionNumber));

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
          _sectionTitle('ПОЗИЦИИ'),
          ...drivers.map((d) {
            final isBest = d.bestLapMillis != null && d.bestLapMillis == bestOverall;
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
                            if (d.kartNumber != null)
                              _kartChip(d.kartNumber!),
                            const SizedBox(width: 8),
                            Text(
                              '${d.totalLaps ?? 0} кр.',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11),
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
                            letterSpacing: 0.5),
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
    final drivers = List<DriverInfo>.from(heatData.drivers)
      ..sort((a, b) => a.positionNumber.compareTo(b.positionNumber));
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

    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('ПОЗИЦИИ ПО КРУГАМ'),
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
                      dIdx, drivers[dIdx].columnIndex ?? dIdx, drivers[dIdx],
                      maxLap, grid);
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
          width: 108,
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
                letterSpacing: 0.5),
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
                  fontWeight: FontWeight.w600),
            ),
          );
        }),
      ],
    );
  }

  Widget _driverRow(int displayIdx, int columnIndex, DriverInfo driver,
      int maxLap, Map<int, Map<int, LapDetail>> grid) {
    return Row(
      children: [
        Container(
          width: 108,
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
              if (driver.kartNumber != null)
                Text(
                  'карт ${driver.kartNumber}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
            ],
          ),
        ),
        ...List.generate(maxLap, (lapIdx) {
          final raceLap = lapIdx + 1;
          final detail = grid[raceLap]?[columnIndex];
          return _gridCell(detail);
        }),
      ],
    );
  }

  Widget _gridCell(LapDetail? detail) {
    if (detail == null || detail.lapTime == null) {
      return Container(
        width: 50,
        height: 46,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _border, width: 0.6)),
        ),
        alignment: Alignment.center,
        child: const Text('—',
            style: TextStyle(color: Colors.white12, fontSize: 12)),
      );
    }

    final pos = (detail.racePosition ?? detail.position ?? '')
        .replaceAll('P', '');
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
        border: const Border(bottom: BorderSide(color: _border, width: 0.6)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
          Text(
            _shortLapTime(detail.lapTime!),
            style: TextStyle(
              color: isBest ? (isOverallBest ? _purple : _bestStint) : Colors.white70,
              fontSize: 10,
              fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
              fontFeatures: const [FontFeature.tabularFigures()],
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
          _legendDot(const Color(0xFF4A4A4A), 'Смена карта'),
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
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
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

  Widget _kartChip(int kart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _border),
      ),
      child: Text(
        'карт $kart',
        style: const TextStyle(color: Colors.white70, fontSize: 10),
      ),
    );
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
