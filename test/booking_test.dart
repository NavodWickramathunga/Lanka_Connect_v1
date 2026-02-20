import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_connect/models/booking.dart';

void main() {
  group('Booking.fromMap', () {
    test('parses a complete map', () {
      final b = Booking.fromMap('b1', {
        'serviceId': 's1',
        'providerId': 'p1',
        'seekerId': 'u1',
        'status': 'accepted',
      });

      expect(b.id, 'b1');
      expect(b.serviceId, 's1');
      expect(b.providerId, 'p1');
      expect(b.seekerId, 'u1');
      expect(b.status, 'accepted');
    });

    test('fills defaults for missing fields', () {
      final b = Booking.fromMap('b2', {});

      expect(b.serviceId, '');
      expect(b.providerId, '');
      expect(b.seekerId, '');
      expect(b.status, 'pending');
    });
  });

  group('Booking.toMap', () {
    test('round-trips data', () {
      final b = Booking(
        id: 'b1',
        serviceId: 's1',
        providerId: 'p1',
        seekerId: 'u1',
        status: 'completed',
      );
      final map = b.toMap();
      expect(map['serviceId'], 's1');
      expect(map['providerId'], 'p1');
      expect(map['seekerId'], 'u1');
      expect(map['status'], 'completed');
      expect(map.containsKey('id'), isFalse);
    });
  });
}
