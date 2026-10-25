import 'package:flutter/material.dart';
import '../models/heat_list.dart';
import '../services/api_service.dart';
import '../theme/f1_theme.dart';
import 'heat_screen.dart';

class HeatListScreen extends StatefulWidget {
  const HeatListScreen({super.key});

  @override
  State<HeatListScreen> createState() => _HeatListScreenState();
}

class _HeatListScreenState extends State<HeatListScreen> {
  final ApiService _apiService = ApiService();
  HeatList? _heatList;
  bool _isLoading = true;
  String? _errorMessage;
  String _filter = 'ALL'; // ALL | HEAT | RACE

  @override
  void initState() {
    super.initState();
    _fetchHeatList();
  }

  Future<void> _fetchHeatList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getHeatList();
      if (!mounted) return;
      setState(() {
        _heatList = data;
        _isLoading = false;
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
    return Scaffold(
      backgroundColor: F1.bg,
      appBar: AppBar(
        title: const Text(
          'NARVSKAYA',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        backgroundColor: F1.panel,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fetchHeatList,
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _heatList == null) {
      return const Center(child: CircularProgressIndicator(color: F1.accent));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: F1.accent),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: F1.accent,
                  foregroundColor: Colors.white,
                ),
                onPressed: _fetchHeatList,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (_heatList == null || _heatList!.heats.isEmpty) {
      return const Center(
        child: Text('Нет доступных заездов',
            style: TextStyle(color: Colors.white70)),
      );
    }

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: RefreshIndicator(
            color: F1.accent,
            backgroundColor: F1.panel,
            onRefresh: _fetchHeatList,
            child: _buildList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final heats = _heatList!.heats;
    final heatCount = heats.where((h) => !h.isRace).length;
    final raceCount = heats.where((h) => h.isRace).length;

    return Container(
      color: F1.panel,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          _filterChip('ВСЕ', 'ALL', heats.length),
          const SizedBox(width: 8),
          _filterChip('ЗАЕЗДЫ', 'HEAT', heatCount),
          const SizedBox(width: 8),
          _filterChip('ГОНКИ', 'RACE', raceCount),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, int count) {
    final selected = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? F1.accent : F1.panelAlt,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: selected ? F1.accent : F1.border),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    final filtered = _heatList!.heats.where((h) {
      if (_filter == 'ALL') return true;
      return h.type == _filter;
    }).toList();

    if (filtered.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text('Пусто', style: TextStyle(color: Colors.white54)),
          ),
        ],
      );
    }

    // Группируем по дате (сохраняя исходный порядок).
    final List<Widget> children = [];
    String? currentDate;
    for (final heat in filtered) {
      if (heat.date != currentDate) {
        currentDate = heat.date;
        children.add(_dateHeader(heat.date));
      }
      children.add(_heatTile(heat));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
      children: children,
    );
  }

  Widget _dateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(
        _formatDate(date),
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _heatTile(HeatItem heat) {
    final isRace = heat.isRace;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HeatScreen(heatId: heat.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: F1.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: F1.border),
        ),
        child: Row(
          children: [
            // Иконка типа
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isRace
                    ? F1.gold.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isRace ? F1.gold : F1.border,
                ),
              ),
              child: Icon(
                isRace ? Icons.emoji_events : Icons.timer_outlined,
                color: isRace ? F1.gold : Colors.white70,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heat.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _typeBadge(isRace),
                      const SizedBox(width: 8),
                      Text(
                        heat.time,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(bool isRace) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isRace
            ? F1.gold.withValues(alpha: 0.2)
            : F1.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        isRace ? 'ГОНКА' : 'ЗАЕЗД',
        style: TextStyle(
          color: isRace ? F1.gold : F1.accent,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static String _formatDate(String iso) {
    if (iso.length < 10) return iso;
    return '${iso.substring(8, 10)}.${iso.substring(5, 7)}.${iso.substring(0, 4)}';
  }
}
