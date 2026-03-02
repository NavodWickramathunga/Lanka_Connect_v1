import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_connect/utils/display_name_utils.dart';

void main() {
  group('DisplayNameUtils.userDisplayName', () {
    test('uses profile name when present', () {
      final value = DisplayNameUtils.userDisplayName(
        uid: 'abc123xyz789',
        name: 'Navod Wickramathunga',
        email: 'navod@example.com',
      );
      expect(value, 'Navod Wickramathunga');
    });

    test('falls back to email local part when name empty', () {
      final value = DisplayNameUtils.userDisplayName(
        uid: 'abc123xyz789',
        name: '',
        email: 'navod.wickramathunga@example.com',
      );
      expect(value, 'Navod Wickramathunga');
    });

    test('falls back to short user id when name and email are empty', () {
      final value = DisplayNameUtils.userDisplayName(
        uid: '3ruHNxtU4pVlvS0TneJT5YJxkUF2',
        name: '',
        email: '',
      );
      expect(value, 'User 3ruHNxtU');
    });
  });

  group('DisplayNameUtils.locationLabel', () {
    test('formats city and district when both exist', () {
      final value = DisplayNameUtils.locationLabel(
        city: 'Maharagama',
        district: 'Colombo',
      );
      expect(value, 'Maharagama, Colombo');
    });

    test('returns fallback when location is missing', () {
      final value = DisplayNameUtils.locationLabel(city: '', district: '');
      expect(value, 'Location not set');
    });
  });
}
