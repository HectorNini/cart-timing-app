import 'package:flutter/material.dart';

/// Единая палитра F1-стиля для всего приложения.
class F1 {
  F1._();

  static const Color bg = Color(0xFF0F0F0F);
  static const Color panel = Color(0xFF151515);
  static const Color panelAlt = Color(0xFF1B1B1B);
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFFE10600); // F1 red
  static const Color purple = Color(0xFFB026FF); // лучший круг заезда
  static const Color teal = Color(0xFF00D2BE); // лучший круг стинта
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  static Color positionColor(int pos) {
    switch (pos) {
      case 1:
        return gold;
      case 2:
        return silver;
      case 3:
        return bronze;
      default:
        return const Color(0xFF3A3A3A);
    }
  }

  static String formatMillis(int? ms) {
    if (ms == null) return '—';
    final minutes = ms ~/ 60000;
    final seconds = (ms % 60000) / 1000.0;
    if (minutes > 0) {
      return '$minutes:${seconds.toStringAsFixed(3).padLeft(6, '0')}';
    }
    return seconds.toStringAsFixed(3);
  }
}
