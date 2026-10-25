import 'dart:async';

import 'package:flutter/material.dart';

import '../models/live_data.dart';
import '../services/live_service.dart';
import '../theme/f1_theme.dart';
import 'heat_screen.dart';

const Color _bg = F1.bg;
const Color _panel = F1.panel;
const Color _panelAlt = F1.panelAlt;
const Color _border = F1.border;
const Color _accent = F1.accent;
const Color _purple = F1.purple;
const Color _teal = F1.teal;
const Color _gold = F1.gold;

/// Экран гонки, которая идёт прямо сейчас.
class LiveScreen extends StatefulWidget {
  final LiveService liveService;

  const LiveScreen({super.key, required this.liveService});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Перерисовываем секундомер и «обновлено N с назад» каждую секунду.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    widget.liveService.start();
    widget.liveService.refresh();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text(
            'LIVE',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              fontSize: 15,
            ),
          ),
          backgroundColor: _panel,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () => widget.liveService.refresh(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Обновить',
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: widget.liveService,
          builder: (context, _) => _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final service = widget.liveService;
    final snapshot = service.snapshot;
    final heat = snapshot?.heat;

    if (snapshot == null && service.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    if (snapshot == null) {
      return _messageState(
        icon: Icons.wifi_off,
        title: 'Нет связи с live-таймингом',
        subtitle: service.error ?? 'Проверьте подключение к бэкенду.',
        onRetry: () => service.refresh(),
      );
    }

    if (heat == null || heat.drivers.isEmpty) {
      return _messageState(
        icon: Icons.sports_motorsports_outlined,
        title: 'Сейчас никто не едет',
        subtitle: 'Как только на трассе начнётся заезд, он появится здесь автоматически.',
        onRetry: () => service.refresh(),
      );
    }

    return RefreshIndicator(
      color: _accent,
      backgroundColor: _panel,
      onRefresh: () => service.refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 28),
        children: [
          _buildHeader(snapshot, heat),
          const SizedBox(height: 10),
          if (!snapshot.live) ...[
            _buildFinishedBanner(heat, snapshot.status),
            const SizedBox(height: 10),
          ],
          _buildStandings(heat),
          const SizedBox(height: 10),
          if (heat.pitlaneKarts.isNotEmpty) _buildPitlane(heat),
          const SizedBox(height: 8),
          _buildFooter(snapshot),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Шапка
  // ------------------------------------------------------------------

  Widget _buildHeader(LiveSnapshot snapshot, LiveHeat heat) {
    final isLive = snapshot.live;
    final isWaiting = snapshot.status == 'WAITING';
    final elapsed = _displayElapsed(snapshot, heat);
    final isRace = heat.looksLikeRace;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLive
              ? [_accent.withValues(alpha: 0.22), _panel]
              : (isWaiting
                  ? [const Color(0xFFFFB300).withValues(alpha: 0.12), _panel]
                  : [_panelAlt, _panel]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLive
              ? _accent.withValues(alpha: 0.6)
              : (isWaiting ? const Color(0xFFFFB300).withValues(alpha: 0.4) : _border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _livePill(snapshot.status),
              const SizedBox(width: 8),
              _typeBadge(isRace),
              const Spacer(),
              Text(
                _updatedLabel(snapshot),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            heat.heatName.isEmpty ? 'Заезд' : heat.heatName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatClock(elapsed),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'на трассе',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat('КРУГ', '${heat.leaderLaps}'),
              _statDivider(),
              _stat('ПИЛОТОВ', '${heat.drivers.length}'),
              _statDivider(),
              _stat('В ПИТЛЕЙНЕ', '${heat.pitlaneKarts.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _livePill(String status) {
    final isLive = status == 'LIVE';
    final isWaiting = status == 'WAITING';
    final color = isLive
        ? _accent
        : (isWaiting ? const Color(0xFFFFB300) : Colors.white24);
    final label = isLive
        ? 'LIVE'
        : (isWaiting ? 'ОЖИДАНИЕ' : 'ЗАВЕРШЕНО');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return Opacity(
                opacity: isLive ? (0.35 + 0.65 * _pulse.value) : 0.5,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(bool isRace) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: (isRace ? _gold : Colors.white).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: (isRace ? _gold : Colors.white24).withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        isRace ? 'ГОНКА' : 'ЗАЕЗД',
        style: TextStyle(
          color: isRace ? _gold : Colors.white70,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: _border,
    );
  }

  Widget _buildFinishedBanner(LiveHeat heat, String status) {
    final isWaiting = status == 'WAITING';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _panelAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWaiting ? const Color(0xFFFFB300).withValues(alpha: 0.3) : _border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isWaiting ? Icons.hourglass_empty : Icons.flag_outlined,
            color: isWaiting ? const Color(0xFFFFB300) : Colors.white54,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isWaiting
                  ? 'Проверяем, идёт ли сессия…'
                  : 'Сессия завершена. Итоговые позиции ниже.',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          if (!isWaiting && heat.heatId.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HeatScreen(heatId: heat.heatId, isRace: heat.looksLikeRace),
                  ),
                );
              },
              child: const Text(
                'К заезду',
                style: TextStyle(color: _accent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Таблица
  // ------------------------------------------------------------------

  Widget _buildStandings(LiveHeat heat) {
    final ranked = heat.ranked;
    final sessionBest = heat.sessionBestLap;
    final bestLastLap = heat.bestLastLap;

    return Column(
      children: [
        _tableHeader(),
        ...List.generate(ranked.length, (index) {
          return _driverRow(
            driver: ranked[index],
            position: index + 1,
            leaderLaps: heat.leaderLaps,
            sessionBest: sessionBest,
            bestLastLap: bestLastLap,
          );
        }),
      ],
    );
  }

  Widget _tableHeader() {
    const style = TextStyle(
      color: Colors.white38,
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      child: Row(
        children: const [
          SizedBox(width: 30, child: Text('P', style: style)),
          Expanded(child: Text('ПИЛОТ', style: style)),
          Text('КРУГ', style: style),
          SizedBox(width: 12),
          SizedBox(width: 62, child: Text('ВРЕМЯ', style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _driverRow({
    required LiveDriver driver,
    required int position,
    required int leaderLaps,
    required int? sessionBest,
    required int? bestLastLap,
  }) {
    final posColor = F1.positionColor(position);
    final isSessionBest = sessionBest != null && driver.bestLapTime == sessionBest;
    final lapsBehind = leaderLaps - driver.totalLaps;

    final sortedLaps = [...driver.laps]
      ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));
    final previousLap = sortedLaps.length >= 2
        ? sortedLaps[sortedLaps.length - 2].time
        : null;
    final lastLap = driver.lastLapTime;
    Color lapColor = Colors.white;
    if (lastLap != null && previousLap != null) {
      lapColor = lastLap < previousLap
          ? _teal
          : (lastLap > previousLap ? const Color(0xFFFF8A65) : Colors.white);
    }
    if (lastLap != null && bestLastLap != null && lastLap == bestLastLap) {
      lapColor = _purple;
    }

    return GestureDetector(
      onTap: () => _showDriverLaps(driver),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(8, 9, 10, 9),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: posColor, width: 3),
            top: const BorderSide(color: _border),
            right: const BorderSide(color: _border),
            bottom: const BorderSide(color: _border),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '$position',
                style: TextStyle(
                  color: posColor == const Color(0xFF3A3A3A) ? Colors.white70 : posColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          driver.driverName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSessionBest)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: _purple.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'ЛУЧШИЙ',
                            style: TextStyle(
                              color: _purple,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (driver.stint?.kart != null)
                        _miniChip('карт ${driver.stint!.kart}'),
                      if (driver.stint?.number != null) ...[
                        const SizedBox(width: 5),
                        _miniChip('стинт ${driver.stint!.number}'),
                      ],
                      if (driver.number != null) ...[
                        const SizedBox(width: 5),
                        _miniChip('#${driver.number}'),
                      ],
                      const Spacer(),
                      Text(
                        'луч ${F1.formatMillis(driver.bestLapTime)}',
                        style: TextStyle(
                          color: isSessionBest ? _purple : Colors.white38,
                          fontSize: 10.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 66,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    F1.formatMillis(lastLap),
                    style: TextStyle(
                      color: lapColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _gapLabel(driver, position, lapsBehind),
                    style: TextStyle(
                      color: position == 1 ? _gold : Colors.white38,
                      fontSize: 10.5,
                      fontWeight: position == 1 ? FontWeight.w700 : FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white54, fontSize: 9.5),
      ),
    );
  }

  String _gapLabel(LiveDriver driver, int position, int lapsBehind) {
    if (position == 1) return 'ЛИДЕР';
    if (lapsBehind > 0) return '+$lapsBehind кр.';
    final gap = driver.lastGapTime;
    if (gap == null) return '—';
    return '+${(gap / 1000).toStringAsFixed(1)}';
  }

  // ------------------------------------------------------------------
  // Питлейн и подвал
  // ------------------------------------------------------------------

  Widget _buildPitlane(LiveHeat heat) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: _panelAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.garage_outlined, color: Colors.white38, size: 16),
          const SizedBox(width: 8),
          const Text(
            'В питлейне:',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: heat.pitlaneKarts
                  .map((kart) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _accent.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '$kart',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(LiveSnapshot snapshot) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.liveService.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Нет связи с бэкендом, показаны последние данные.',
                style: TextStyle(color: _accent.withValues(alpha: 0.8), fontSize: 10.5),
              ),
            ),
          Text(
            'Источник: timing.batyrshin.name · сообщений: ${snapshot.messages}',
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // История кругов пилота
  // ------------------------------------------------------------------

  void _showDriverLaps(LiveDriver driver) {
    final laps = [...driver.laps]
      ..sort((a, b) => (b.number ?? 0).compareTo(a.number ?? 0));

    showModalBottomSheet(
      context: context,
      backgroundColor: _panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          driver.driverName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (driver.bestLapTime != null)
                        Text(
                          'луч ${F1.formatMillis(driver.bestLapTime)}',
                          style: const TextStyle(color: _purple, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                const Divider(color: _border, height: 1),
                Expanded(
                  child: laps.isEmpty
                      ? const Center(
                          child: Text('Кругов пока нет',
                              style: TextStyle(color: Colors.white38)),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: laps.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: _border, height: 1),
                          itemBuilder: (context, index) {
                            final lap = laps[index];
                            final isBest = lap.time != null && lap.time == driver.bestLapTime;
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: _panelAlt,
                                child: Text(
                                  '${lap.number ?? '?'}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                ),
                              ),
                              title: Text(
                                'Круг ${lap.number ?? '?'}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              subtitle: Text(
                                'стинт ${lap.stintNum ?? '—'}'
                                '${lap.kartNum != null ? ' · карт ${lap.kartNum}' : ''}',
                                style: const TextStyle(color: Colors.white30, fontSize: 10.5),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    F1.formatMillis(lap.time),
                                    style: TextStyle(
                                      color: isBest ? _purple : Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  if (lap.gapTime != null)
                                    Text(
                                      '+${(lap.gapTime! / 1000).toStringAsFixed(1)}',
                                      style: const TextStyle(
                                          color: Colors.white30, fontSize: 10),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // Вспомогательные
  // ------------------------------------------------------------------

  int _displayElapsed(LiveSnapshot snapshot, LiveHeat heat) {
    if (!snapshot.live) return heat.elapsed;
    final drift = DateTime.now().difference(snapshot.fetchedAt).inMilliseconds;
    return heat.elapsed + (drift < 0 ? 0 : drift);
  }

  String _updatedLabel(LiveSnapshot snapshot) {
    final age = snapshot.ageNowMs;
    switch (snapshot.status) {
      case 'LIVE':
        if (age == null) return '';
        final seconds = (age / 1000).round();
        if (seconds <= 2) return 'обновлено только что';
        return 'обновлено $seconds с назад';
      case 'WAITING':
        return 'проверяем данные…';
      case 'FINISHED':
        return 'сессия завершена';
      default:
        return '';
    }
  }

  static String _formatClock(int ms) {
    final totalSeconds = ms ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$mm:$ss';
    }
    return '$mm:$ss';
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 58, color: Colors.white24),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
              ),
              onPressed: onRetry,
              child: const Text('Обновить'),
            ),
          ],
        ),
      ),
    );
  }
}
