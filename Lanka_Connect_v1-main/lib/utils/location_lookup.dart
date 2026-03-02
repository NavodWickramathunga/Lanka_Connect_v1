import 'package:latlong2/latlong.dart';

class ResolvedLocation {
  const ResolvedLocation({
    required this.point,
    required this.sourceLabel,
    required this.isApproximate,
  });

  final LatLng point;
  final String sourceLabel;
  final bool isApproximate;
}

class LocationLookup {
  static const Map<String, LatLng> _cityPoints = {
    'colombo': LatLng(6.9271, 79.8612),
    'maharagama': LatLng(6.8470, 79.9265),
    'nugegoda': LatLng(6.8656, 79.8997),
    'dehiwala': LatLng(6.8513, 79.8657),
    'galle': LatLng(6.0535, 80.2210),
    'matara': LatLng(5.9549, 80.5550),
    'kandy': LatLng(7.2906, 80.6337),
    'kurunegala': LatLng(7.4863, 80.3647),
    'negombo': LatLng(7.2083, 79.8358),
    'jaffna': LatLng(9.6615, 80.0255),
    'anuradhapura': LatLng(8.3114, 80.4037),
    'trincomalee': LatLng(8.5874, 81.2152),
    'batticaloa': LatLng(7.7102, 81.6924),
    'badulla': LatLng(6.9934, 81.0550),
    'ratnapura': LatLng(6.6828, 80.3992),
    'kadawatha': LatLng(7.0017, 79.9490),
  };

  static const Map<String, LatLng> _districtPoints = {
    'colombo': LatLng(6.9271, 79.8612),
    'gampaha': LatLng(7.0840, 80.0098),
    'kalutara': LatLng(6.5854, 79.9607),
    'kandy': LatLng(7.2906, 80.6337),
    'matale': LatLng(7.4675, 80.6234),
    'nuwara eliya': LatLng(6.9497, 80.7891),
    'galle': LatLng(6.0535, 80.2210),
    'matara': LatLng(5.9549, 80.5550),
    'hambantota': LatLng(6.1241, 81.1185),
    'jaffna': LatLng(9.6615, 80.0255),
    'kilinochchi': LatLng(9.3803, 80.3760),
    'mannar': LatLng(8.9818, 79.9042),
    'vavuniya': LatLng(8.7514, 80.4971),
    'mullaitivu': LatLng(9.2673, 80.8128),
    'batticaloa': LatLng(7.7102, 81.6924),
    'ampara': LatLng(7.2975, 81.6820),
    'trincomalee': LatLng(8.5874, 81.2152),
    'kurunegala': LatLng(7.4863, 80.3647),
    'puttalam': LatLng(8.0362, 79.8283),
    'anuradhapura': LatLng(8.3114, 80.4037),
    'polonnaruwa': LatLng(7.9403, 81.0188),
    'badulla': LatLng(6.9934, 81.0550),
    'monaragala': LatLng(6.8721, 81.3507),
    'ratnapura': LatLng(6.6828, 80.3992),
    'kegalle': LatLng(7.2523, 80.3464),
  };

  static ResolvedLocation? resolve({dynamic city, dynamic district}) {
    final normalizedCity = _normalize(city);
    final normalizedDistrict = _normalize(district);

    final cityPoint = _cityPoints[normalizedCity];
    if (cityPoint != null) {
      return ResolvedLocation(
        point: cityPoint,
        sourceLabel: 'Approx. city',
        isApproximate: true,
      );
    }

    final districtPoint = _districtPoints[normalizedDistrict];
    if (districtPoint != null) {
      return ResolvedLocation(
        point: districtPoint,
        sourceLabel: 'Approx. district',
        isApproximate: true,
      );
    }

    return null;
  }

  static String _normalize(dynamic value) {
    final raw = (value ?? '').toString().trim().toLowerCase();
    return raw.replaceAll(RegExp(r'\s+'), ' ');
  }
}
