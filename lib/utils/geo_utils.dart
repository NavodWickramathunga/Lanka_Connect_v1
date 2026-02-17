import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

class GeoUtils {
  static double? parseCoordinate(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static LatLng? extractPoint(Map<String, dynamic> data) {
    final lat = parseCoordinate(data['lat']);
    final lng = parseCoordinate(data['lng']);
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  static double distanceKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(toLat - fromLat);
    final dLng = _toRadians(toLng - fromLng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(fromLat)) *
            math.cos(_toRadians(toLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static String formatKm(double value) {
    if (value < 1) return '${(value * 1000).round()} m';
    return '${value.toStringAsFixed(1)} km';
  }

  static double _toRadians(double degree) => degree * math.pi / 180.0;
}
