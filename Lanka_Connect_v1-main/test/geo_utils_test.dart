import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_connect/utils/geo_utils.dart';

void main() {
  group('GeoUtils.extractPoint', () {
    test('parses numeric coordinates', () {
      final point = GeoUtils.extractPoint({
        'lat': 6.9271,
        'lng': 79.8612,
      });
      expect(point, isNotNull);
    });

    test('returns null for invalid coordinates', () {
      final point = GeoUtils.extractPoint({
        'lat': 200,
        'lng': 79.8612,
      });
      expect(point, isNull);
    });
  });

  group('GeoUtils.distanceKm', () {
    test('calculates positive distance', () {
      final distance = GeoUtils.distanceKm(
        fromLat: 6.9271,
        fromLng: 79.8612,
        toLat: 6.0535,
        toLng: 80.2210,
      );
      expect(distance, greaterThan(0));
    });
  });
}
