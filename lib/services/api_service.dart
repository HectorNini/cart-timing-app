import 'dart:async';
import 'dart:convert';
import 'package:cart_timing_app/models/heat_list.dart';
import 'package:http/http.dart' as http;
import '../models/heat_data.dart';
import '../models/live_data.dart';

class ApiService {
  // Базовый URL: для эмулятора Android используем 10.0.2.2, для реального телефона
  // можно переопределить через --dart-define=API_BASE_URL=http://192.168.x.x:8080/api
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    final host = Uri.base.host;
    if (host == 'localhost' || host == '127.0.0.1') {
      return 'http://10.0.2.2:8080/api'; // Android emulator
    }
    // Для веб и прочих можно поменять под нужный IP
    return 'http://10.0.2.2:8080/api';
  }

  Future<HeatData> getHeatData(String heatId) async {
    final url = Uri.parse('$baseUrl/heat/$heatId');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return HeatData.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Превышено время ожидания. Попробуйте ещё раз.');
    } catch (e) {
      throw Exception('Ошибка подключения: $e');
    }
  }


  Future<HeatList> getHeatList() async {
    final url = Uri.parse('$baseUrl/heats');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return HeatList.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Превышено время ожидания. Попробуйте ещё раз.');
    } catch (e) {
      throw Exception('Ошибка подключения: $e');
    }
  }

  /// Текущая live-сессия: идёт ли гонка прямо сейчас и её последний снимок.
  Future<LiveSnapshot> getLiveCurrent() async {
    final url = Uri.parse('$baseUrl/live/current');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return LiveSnapshot.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки live: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Превышено время ожидания live-тайминга.');
    } catch (e) {
      throw Exception('Ошибка подключения: $e');
    }
  }
}