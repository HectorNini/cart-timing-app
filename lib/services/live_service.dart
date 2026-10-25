import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/live_data.dart';
import 'api_service.dart';

/// Опрашивает бэкенд и держит актуальное состояние live-тайминга.
///
/// Бэкенд сам постоянно подключён к WebSocket сайта, поэтому приложению
/// достаточно периодически забирать `/api/live/current`: пока гонка идёт —
/// чаще, когда тишина — реже.
class LiveService extends ChangeNotifier {
  static const Duration _liveInterval = Duration(seconds: 2);
  static const Duration _idleInterval = Duration(seconds: 5);

  final ApiService _apiService;

  LiveService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  LiveSnapshot? _snapshot;
  bool _loading = false;
  String? _error;
  Timer? _timer;
  bool _disposed = false;
  bool _started = false;

  LiveSnapshot? get snapshot => _snapshot;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isLive => _snapshot?.live == true;
  LiveHeat? get heat => _snapshot?.heat;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _tick();
  }

  void stop() {
    _started = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    await _fetch();
  }

  Future<void> _tick() async {
    if (_disposed || !_started) return;
    await _fetch();
    if (_disposed || !_started) return;
    _timer?.cancel();
    _timer = Timer(isLive ? _liveInterval : _idleInterval, _tick);
  }

  Future<void> _fetch() async {
    if (_disposed) return;
    _loading = true;
    try {
      final data = await _apiService.getLiveCurrent();
      if (_disposed) return;
      _snapshot = data;
      _error = null;
      notifyListeners();
    } catch (e) {
      if (_disposed) return;
      // Ошибку сети не раздуваем: показываем последнее известное состояние.
      _error = e.toString();
      notifyListeners();
    } finally {
      if (!_disposed) _loading = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _started = false;
    _timer?.cancel();
    super.dispose();
  }
}
