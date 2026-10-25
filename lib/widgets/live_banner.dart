import 'dart:async';

import 'package:flutter/material.dart';

import '../models/live_data.dart';
import '../services/live_service.dart';
import '../theme/f1_theme.dart';
import '../screens/live_screen.dart';

/// Баннер «сейчас идёт гонка» на экране списка.
/// Скрыт, когда live-сессии нет.
class LiveBanner extends StatefulWidget {
  final LiveService liveService;

  const LiveBanner({super.key, required this.liveService});

  @override
  State<LiveBanner> createState() => _LiveBannerState();
}

class _LiveBannerState extends State<LiveBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.liveService,
      builder: (context, _) {
        final snapshot = widget.liveService.snapshot;
        final heat = snapshot?.heat;
        if (snapshot == null || !snapshot.live || heat == null) {
          return const SizedBox.shrink();
        }
        return _buildBanner(snapshot, heat);
      },
    );
  }

  Widget _buildBanner(LiveSnapshot snapshot, LiveHeat heat) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveScreen(liveService: widget.liveService),
              ),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [F1.accent.withValues(alpha: 0.35), F1.panel],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: F1.accent.withValues(alpha: 0.7)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      return Opacity(
                        opacity: 0.35 + 0.65 * _pulse.value,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: F1.accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: F1.accent, blurRadius: 8),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: F1.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          heat.heatName.isEmpty ? 'Заезд' : heat.heatName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${heat.drivers.length} пилотов · круг ${heat.leaderLaps}'
                          '${heat.pitlaneKarts.isNotEmpty ? ' · питлейн ${heat.pitlaneKarts.length}' : ''}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatClock(_elapsed(snapshot, heat)),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.white38),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _elapsed(LiveSnapshot snapshot, LiveHeat heat) {
    if (!snapshot.live) return heat.elapsed;
    final drift = DateTime.now().difference(snapshot.fetchedAt).inMilliseconds;
    return heat.elapsed + (drift < 0 ? 0 : drift);
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
}
