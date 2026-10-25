import 'dart:convert';
import 'package:cart_timing_app/models/heat_list.dart';
import 'package:http/http.dart' as http;
import '../models/heat_data.dart';

class ApiService {
  // Для веб-версии используем localhost, для эмулятора Android - 10.0.2.2
  static String get baseUrl {
    if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
      return 'http://localhost:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  Future<HeatData> getHeatData(String heatId) async {
    final url = Uri.parse('$baseUrl/heat/$heatId');
    
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return HeatData.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка подключения: $e');
    }
  }


  Future<HeatList> getHeatList() async {
    final url = Uri.parse('$baseUrl/heats');
    
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return HeatList.fromJson(jsonData);
      } else {
        throw Exception('Ошибка загрузки: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка подключения: $e');
    }
  }
}