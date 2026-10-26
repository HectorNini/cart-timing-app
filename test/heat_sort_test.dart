import 'package:cart_timing_app/models/heat_data.dart';
import 'package:cart_timing_app/models/heat_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sortDrivers', () {
    test('position mode keeps the actual race position', () {
      final drivers = [
        DriverInfo(
          name: 'Sokolik',
          position: 'P3',
          bestLapMillis: 51491,
          totalLaps: 8,
          columnIndex: 2,
        ),
        DriverInfo(
          name: 'Vic',
          position: 'P4',
          bestLapMillis: 51880,
          totalLaps: 11,
          columnIndex: 3,
        ),
      ];

      final sorted = sortDrivers(drivers, HeatSortMode.position);

      expect(sorted.map((d) => d.name), ['Sokolik', 'Vic']);
    });

    test(
      'bestLap mode puts the faster lap first even with a lower position',
      () {
        final drivers = [
          DriverInfo(
            name: 'Position leader',
            position: 'P1',
            bestLapMillis: 52000,
            columnIndex: 0,
          ),
          DriverInfo(
            name: 'Faster lap',
            position: 'P5',
            bestLapMillis: 50000,
            columnIndex: 1,
          ),
        ];

        final sorted = sortDrivers(drivers, HeatSortMode.bestLap);

        expect(sorted.map((d) => d.name), ['Faster lap', 'Position leader']);
      },
    );

    test('bestLap mode places drivers without a lap time last', () {
      final drivers = [
        DriverInfo(name: 'No lap', position: 'P1', columnIndex: 0),
        DriverInfo(
          name: 'With lap',
          position: 'P2',
          bestLapMillis: 51000,
          columnIndex: 1,
        ),
      ];

      final sorted = sortDrivers(drivers, HeatSortMode.bestLap);

      expect(sorted.map((d) => d.name), ['With lap', 'No lap']);
    });

    test('bestLap mode uses position as a tie-breaker', () {
      final drivers = [
        DriverInfo(
          name: 'P2',
          position: 'P2',
          bestLapMillis: 51000,
          columnIndex: 0,
        ),
        DriverInfo(
          name: 'P1',
          position: 'P1',
          bestLapMillis: 51000,
          columnIndex: 1,
        ),
      ];

      final sorted = sortDrivers(drivers, HeatSortMode.bestLap);

      expect(sorted.map((d) => d.name), ['P1', 'P2']);
    });

    test('does not mutate the source list', () {
      final drivers = [
        DriverInfo(name: 'P2', position: 'P2', columnIndex: 0),
        DriverInfo(name: 'P1', position: 'P1', columnIndex: 1),
      ];

      sortDrivers(drivers, HeatSortMode.position);

      expect(drivers.map((d) => d.name), ['P2', 'P1']);
    });
  });
}
