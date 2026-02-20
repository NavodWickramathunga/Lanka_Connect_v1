import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_connect/models/user_profile.dart';

void main() {
  group('UserProfile.fromMap', () {
    test('parses a complete map', () {
      final up = UserProfile.fromMap('uid1', {
        'role': 'provider',
        'name': 'Alice',
        'contact': '+94771234567',
        'district': 'Colombo',
        'city': 'Dehiwala',
        'skills': ['plumbing', 'electrical'],
        'bio': 'Experienced handyman',
        'imageUrl': 'https://example.com/pic.png',
      });

      expect(up.uid, 'uid1');
      expect(up.role, 'provider');
      expect(up.name, 'Alice');
      expect(up.contact, '+94771234567');
      expect(up.district, 'Colombo');
      expect(up.city, 'Dehiwala');
      expect(up.skills, ['plumbing', 'electrical']);
      expect(up.bio, 'Experienced handyman');
      expect(up.imageUrl, 'https://example.com/pic.png');
    });

    test('fills defaults for missing fields', () {
      final up = UserProfile.fromMap('uid2', {});

      expect(up.role, '');
      expect(up.name, '');
      expect(up.contact, '');
      expect(up.skills, isEmpty);
      expect(up.bio, '');
      expect(up.imageUrl, '');
    });

    test('handles null skills as empty list', () {
      final up = UserProfile.fromMap('uid3', {'skills': null});
      expect(up.skills, isEmpty);
    });
  });

  group('UserProfile.toMap', () {
    test('round-trips data', () {
      final up = UserProfile(
        uid: 'uid1',
        role: 'seeker',
        name: 'Bob',
        contact: '+94770000000',
        district: 'Kandy',
        city: 'Peradeniya',
        skills: [],
        bio: '',
        imageUrl: '',
      );
      final map = up.toMap();
      expect(map['role'], 'seeker');
      expect(map['name'], 'Bob');
      expect(map['contact'], '+94770000000');
      expect(map['district'], 'Kandy');
      expect(map['city'], 'Peradeniya');
      expect(map['skills'], isEmpty);
      // uid is NOT in toMap
      expect(map.containsKey('uid'), isFalse);
    });
  });
}
