import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_connect/models/review.dart';

void main() {
  group('Review.fromMap', () {
    test('parses a complete map', () {
      final r = Review.fromMap('r1', {
        'serviceId': 's1',
        'providerId': 'p1',
        'reviewerId': 'u1',
        'rating': 4,
        'comment': 'Great service',
      });

      expect(r.id, 'r1');
      expect(r.serviceId, 's1');
      expect(r.providerId, 'p1');
      expect(r.reviewerId, 'u1');
      expect(r.rating, 4);
      expect(r.comment, 'Great service');
    });

    test('fills defaults for missing fields', () {
      final r = Review.fromMap('r2', {});

      expect(r.serviceId, '');
      expect(r.providerId, '');
      expect(r.reviewerId, '');
      expect(r.rating, 0);
      expect(r.comment, '');
    });

    test('handles double rating by truncating to int', () {
      final r = Review.fromMap('r3', {'rating': 4.7});
      expect(r.rating, 4);
    });
  });

  group('Review.toMap', () {
    test('round-trips data', () {
      final r = Review(
        id: 'r1',
        serviceId: 's1',
        providerId: 'p1',
        reviewerId: 'u1',
        rating: 5,
        comment: 'Excellent',
      );
      final map = r.toMap();
      expect(map['serviceId'], 's1');
      expect(map['providerId'], 'p1');
      expect(map['reviewerId'], 'u1');
      expect(map['rating'], 5);
      expect(map['comment'], 'Excellent');
      expect(map.containsKey('id'), isFalse);
    });
  });
}
