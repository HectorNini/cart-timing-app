import 'package:cart_timing_app/models/json_helpers.dart';
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

  group('json helpers', () {
    test('asInt accepts numbers and numeric strings', () {
      expect(asInt(33), 33);
      expect(asInt('33'), 33);
      expect(asInt(' 42 '), 42);
      expect(asInt('n/a'), isNull);
      expect(asInt(null), isNull);
    });

    test('asBool accepts booleans and common string forms', () {
      expect(asBool(true), isTrue);
      expect(asBool('true'), isTrue);
      expect(asBool('1'), isTrue);
      expect(asBool('false'), isFalse);
      expect(asBool('0'), isFalse);
      expect(asBool('maybe'), isNull);
    });

    test('LiveSnapshot.fromJson survives string numbers', () {
      final snapshot = LiveSnapshot.fromJson({
        'live': 'true',
        'status': 'LIVE',
        'ageMs': '2500',
        'messages': '12',
        'heat': {
          'heatId': 133304,
          'elapsed': '91000',
          'mode': '0',
          'pitlaneKarts': ['9', 21, 'bad'],
          'drivers': [
            {'driverId': 7494, 'position': '2', 'totalLaps': '7'},
          ],
        },
      });

      expect(snapshot.live, isTrue);
      expect(snapshot.ageMs, 2500);
      expect(snapshot.messages, 12);
      expect(snapshot.heat!.heatId, '133304');
      expect(snapshot.heat!.elapsed, 91000);
      expect(snapshot.heat!.pitlaneKarts, [9, 21]);
      expect(snapshot.heat!.drivers.single.position, 2);
      expect(snapshot.heat!.drivers.single.totalLaps, 7);
    });
  });
}
