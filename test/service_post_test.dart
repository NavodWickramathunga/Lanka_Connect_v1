import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_connect/models/service_post.dart';

void main() {
  group('ServicePost.fromMap', () {
    test('parses a complete map', () {
      final sp = ServicePost.fromMap('s1', {
        'providerId': 'p1',
        'title': 'Plumbing',
        'category': 'Home',
        'price': 1500,
        'location': 'Colombo',
        'description': 'Fix taps',
        'status': 'approved',
      });

      expect(sp.id, 's1');
      expect(sp.providerId, 'p1');
      expect(sp.title, 'Plumbing');
      expect(sp.category, 'Home');
      expect(sp.price, 1500.0);
      expect(sp.location, 'Colombo');
      expect(sp.description, 'Fix taps');
      expect(sp.status, 'approved');
    });

    test('fills defaults for missing fields', () {
      final sp = ServicePost.fromMap('s2', {});

      expect(sp.providerId, '');
      expect(sp.title, '');
      expect(sp.category, '');
      expect(sp.price, 0.0);
      expect(sp.status, 'pending');
    });

    test('handles numeric price types', () {
      expect(ServicePost.fromMap('x', {'price': 99}).price, 99.0);
      expect(ServicePost.fromMap('x', {'price': 12.5}).price, 12.5);
    });
  });

  group('ServicePost.toMap', () {
    test('round-trips data', () {
      final sp = ServicePost(
        id: 's1',
        providerId: 'p1',
        title: 'Plumbing',
        category: 'Home',
        price: 2000,
        location: 'Kandy',
        description: 'desc',
        status: 'pending',
      );
      final map = sp.toMap();
      expect(map['providerId'], 'p1');
      expect(map['title'], 'Plumbing');
      expect(map['category'], 'Home');
      expect(map['price'], 2000);
      expect(map['location'], 'Kandy');
      expect(map['description'], 'desc');
      expect(map['status'], 'pending');
      // id is NOT included in toMap
      expect(map.containsKey('id'), isFalse);
    });
  });
}
