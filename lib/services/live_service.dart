import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/live_data.dart';
import 'api_service.dart';

/// Опрашивает бэкенд и держит актуальное состояние live-тайминга.
///
/// Бэкенд сам постоянно подключён к WebSocket сайта, поэтому приложению
/// достаточно периодически забирать `/api/live/current`: пока гонка идёт —
/// чаще, когда тишина — реже.
///
/// Сервис живёт на уровне приложения. Два независимых переключателя:
/// * [setEnabled] — экраны выключают опрос, когда он им не нужен
///   (например, на экране конкретного заезда);
/// * [setAppActive] — цикл жизни приложения выключает опрос в фоне.
class LiveService extends ChangeNotifier {
  static const Duration liveInterval = Duration(seconds: 2);
  static const Duration idleInterval = Duration(seconds: 5);

  final ApiService _apiService;

  LiveService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  /// Общий клиент для всех экранов: один источник URL и удобная подмена в тестах.
  ApiService get apiService => _apiService;

  LiveSnapshot? _snapshot;
  bool _loading = false;
  String? _error;
  Timer? _timer;
  bool _disposed = false;
  bool _started = false;
  bool _enabled = true;
  bool _appActive = true;

  LiveSnapshot? get snapshot => _snapshot;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isLive => _snapshot?.live == true;
  LiveHeat? get heat => _snapshot?.heat;
  bool get enabled => _enabled;
  bool get appActive => _appActive;

  /// Включить опрос (используется при старте приложения).
  void start() {
    _enabled = true;
    _sync();
  }

  /// Выключить опрос по инициативе экрана.
  void stop() => setEnabled(false);

  void setEnabled(bool value) {
    _enabled = value;
    _sync();
  }

  void setAppActive(bool value) {
    _appActive = value;
    _sync();
  }

  void _sync() {
    if (_disposed) return;
    final shouldRun = _enabled && _appActive;
    if (shouldRun && !_started) {
      _started = true;
      unawaited(_tick());
    } else if (!shouldRun && _started) {
      _started = false;
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Принудительное обновление: работает и когда периодический опрос выключен.
  Future<void> refresh() async {
    await _fetch();
  }

  Future<void> _tick() async {
    if (_disposed || !_started) return;
    await _fetch();
    if (_disposed || !_started) return;
    _timer?.cancel();
    _timer = Timer(isLive ? liveInterval : idleInterval, _tick);
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
