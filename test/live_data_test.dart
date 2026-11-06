import 'package:cart_timing_app/models/live_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LiveHeat heat({int elapsed = 169000}) => LiveHeat(
        heatId: '1',
        heatName: 'Heat 1',
        trackSlug: 'narvskaya',
        elapsed: elapsed,
        mode: 1,
        pitlaneKarts: const [],
        drivers: const [],
      );

  group('LiveSnapshot.elapsedNow', () {
    test('continues from the last site update, not from fetch time', () {
      final snapshot = LiveSnapshot(
        live: true,
        status: 'LIVE',
        ageMs: 2000,
        lastUpdateAt: 1000000,
        heat: heat(),
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(1002000),
      );

      final now = DateTime.fromMillisecondsSinceEpoch(1003000);

      // 2 с от последнего сообщения + 1 с после получения ответа.
      expect(snapshot.elapsedNow(heat(), now: now), 172000);
    });

    test('uses ageMs instead of wall-clock difference with lastUpdateAt', () {
      final snapshot = LiveSnapshot(
        live: true,
        status: 'LIVE',
        ageMs: 5000,
        // Часы клиента и бэкенда могут не совпадать — lastUpdateAt не важен.
        lastUpdateAt: 999999999999,
        heat: heat(),
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(2000000),
      );

      final now = DateTime.fromMillisecondsSinceEpoch(2001000);

      expect(snapshot.elapsedNow(heat(), now: now), 175000);
    });

    test('finished snapshot keeps the stored elapsed', () {
      final snapshot = LiveSnapshot(
        live: false,
        status: 'FINISHED',
        ageMs: 30000,
        heat: heat(elapsed: 525891),
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(2000000),
      );

      expect(
        snapshot.elapsedNow(heat(elapsed: 525891),
            now: DateTime.fromMillisecondsSinceEpoch(2010000)),
        525891,
      );
    });
  });
}
