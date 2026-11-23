import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cart_timing_app/models/heat_data.dart';
import 'package:cart_timing_app/models/heat_list.dart';
import 'package:cart_timing_app/models/live_data.dart';
import 'package:cart_timing_app/screens/heat_list_screen.dart';
import 'package:cart_timing_app/screens/heat_screen.dart';
import 'package:cart_timing_app/screens/live_screen.dart';
import 'package:cart_timing_app/services/api_service.dart';
import 'package:cart_timing_app/services/live_service.dart';
import 'package:cart_timing_app/services/live_service_scope.dart';
import 'package:cart_timing_app/widgets/live_banner.dart';

class FakeApiService extends ApiService {
  LiveSnapshot? liveSnapshot;
  HeatData? heatData;
  HeatList? heatList;

  int liveCalls = 0;
  int heatCalls = 0;
  int listCalls = 0;

  @override
  Future<LiveSnapshot> getLiveCurrent() async {
    liveCalls++;
    return liveSnapshot ??
        LiveSnapshot(live: false, status: 'IDLE', messages: 1);
  }

  @override
  Future<HeatData> getHeatData(String heatId) async {
    heatCalls++;
    return heatData ??
        HeatData(heatName: 'Heat $heatId', drivers: const [], laps: const []);
  }

  @override
  Future<HeatList> getHeatList() async {
    listCalls++;
    return heatList ??
        HeatList(trackName: 'TEST TRACK', heats: const []);
  }
}

LiveSnapshot _liveSnapshot() {
  final heat = LiveHeat(
    heatId: '42',
    heatName: 'Финал',
    trackSlug: 'narvskaya',
    elapsed: 12_000,
    mode: 0,
    pitlaneKarts: const [],
    drivers: [
      LiveDriver(driverId: '1', driverName: 'Pilot', position: 1, totalLaps: 2),
    ],
  );
  return LiveSnapshot(
    live: true,
    status: 'LIVE',
    heat: heat,
    messages: 2,
    ageMs: 0,
  );
}

Widget _wrap(Widget child, LiveService service) {
  return LiveServiceScope(
    service: service,
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('LiveBanner появляется только при live и ведёт на LiveScreen',
      (tester) async {
    final api = FakeApiService();
    final service = LiveService(apiService: api)..setEnabled(false);
    addTearDown(() {
      service.setEnabled(false);
      service.dispose();
    });

    await tester.pumpWidget(_wrap(const Scaffold(body: LiveBanner()), service));
    await tester.pump();
    await tester.pump();
    expect(find.text('LIVE'), findsNothing);

    api.liveSnapshot = _liveSnapshot();
    await service.refresh();
    await tester.pump();
    expect(find.text('LIVE'), findsOneWidget);

    await tester.tap(find.text('LIVE'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(LiveScreen), findsOneWidget);
  });

  testWidgets('HeatScreen не опрашивает API после финиша заезда', (tester) async {
    final api = FakeApiService()
      ..heatData = HeatData(
        heatName: 'Heat 42',
        drivers: const [],
        laps: const [],
        status: HeatData.statusFinished,
      );
    final service = LiveService(apiService: api)..setEnabled(false);
    addTearDown(() {
      service.setEnabled(false);
      service.dispose();
    });

    await tester.pumpWidget(_wrap(const HeatScreen(heatId: '42'), service));
    await tester.pump();
    await tester.pump();
    expect(api.heatCalls, 1);

    await tester.pump(const Duration(seconds: 12));
    expect(api.heatCalls, 1);

    service.setEnabled(false);
    await tester.pump();
    await tester.pump();
  });

  testWidgets('HeatScreen продолжает опрос, пока заезд в процессе',
      (tester) async {
    final api = FakeApiService()
      ..heatData = HeatData(
        heatName: 'Heat 42',
        drivers: const [],
        laps: const [],
        status: HeatData.statusInProgress,
      );
    final service = LiveService(apiService: api)..setEnabled(false);
    addTearDown(() {
      service.setEnabled(false);
      service.dispose();
    });

    await tester.pumpWidget(_wrap(const HeatScreen(heatId: '42'), service));
    await tester.pump();
    await tester.pump();
    expect(api.heatCalls, 1);

    await tester.pump(const Duration(seconds: 12));
    expect(api.heatCalls, greaterThan(1));

    service.setEnabled(false);
    await tester.pump();
    await tester.pump();
  });

  testWidgets('LiveScreen показывает пилотов из live-снимка', (tester) async {
    // FINISHED-снимок с пилотами: гонка закончилась, но данные ещё есть.
    final finished = LiveSnapshot(
      live: false,
      status: 'FINISHED',
      heat: _liveSnapshot().heat,
      messages: 2,
    );
    final api = FakeApiService()..liveSnapshot = finished;
    final service = LiveService(apiService: api)..setEnabled(false);
    addTearDown(() {
      service.setEnabled(false);
      service.dispose();
    });

    await tester.pumpWidget(_wrap(const LiveScreen(), service));
    await tester.pump();
    await tester.pump();

    expect(find.text('Pilot'), findsOneWidget);
    expect(find.text('Финал'), findsOneWidget);
  });

  testWidgets('LiveService не опрашивает бэкенд, когда приложение в фоне',
      (tester) async {
    final api = FakeApiService();
    final service = LiveService(apiService: api);
    addTearDown(() {
      service.setEnabled(false);
      service.dispose();
    });

    service.start();
    await tester.pump();
    await tester.pump();
    expect(api.liveCalls, greaterThanOrEqualTo(1));

    service.setAppActive(false);
    final callsBeforePause = api.liveCalls;
    await tester.pump(const Duration(seconds: 12));
    expect(api.liveCalls, callsBeforePause);

    service.setAppActive(true);
    await tester.pump(const Duration(seconds: 12));
    expect(api.liveCalls, greaterThan(callsBeforePause));

    // Перед завершением теста снимаем периодический таймер.
    service.setEnabled(false);
    await tester.pump();
  });

  testWidgets('HeatListScreen берёт название трассы из API', (tester) async {
    final api = FakeApiService()
      ..heatList = HeatList(
        trackName: 'NARVA-TEST',
        heats: [
          HeatItem(
            id: '1',
            name: 'Heat 1',
            date: '21.11.2026',
            time: '12:00',
            topResult: '30.000',
          ),
        ],
      );
    final service = LiveService(apiService: api)..setEnabled(false);
    addTearDown(() {
      service.setEnabled(false);
      service.dispose();
    });

    await tester.pumpWidget(_wrap(const HeatListScreen(), service));
    await tester.pump();
    expect(find.text('NARVA-TEST'), findsOneWidget);
  });
}
