import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_connect/utils/location_lookup.dart';

void main() {
  group('LocationLookup.resolve', () {
    test('resolves known city first', () {
      final result = LocationLookup.resolve(
        city: 'Nugegoda',
        district: 'Colombo',
      );

      expect(result, isNotNull);
      expect(result!.sourceLabel, 'Approx. city');
      expect(result.isApproximate, true);
      expect(result.point.latitude, closeTo(6.8656, 0.001));
      expect(result.point.longitude, closeTo(79.8997, 0.001));
    });

    test('falls back to district when city is unknown', () {
      final result = LocationLookup.resolve(
        city: 'Unknown City',
        district: 'Gampaha',
      );

      expect(result, isNotNull);
      expect(result!.sourceLabel, 'Approx. district');
      expect(result.point.latitude, closeTo(7.0840, 0.001));
      expect(result.point.longitude, closeTo(80.0098, 0.001));
    });

    test('returns null when both city and district are unknown', () {
      final result = LocationLookup.resolve(
        city: 'City X',
        district: 'District Y',
      );

      expect(result, isNull);
    });

    test('normalizes spacing and case', () {
      final result = LocationLookup.resolve(
        city: '',
        district: '  NUWARA   ELIYA ',
      );

      expect(result, isNotNull);
      expect(result!.sourceLabel, 'Approx. district');
    });
  });
}
