import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_connect/utils/user_roles.dart';

void main() {
  group('UserRoles.normalize', () {
    test('maps provider labels to provider', () {
      expect(UserRoles.normalize('provider'), UserRoles.provider);
      expect(UserRoles.normalize('Provider'), UserRoles.provider);
      expect(UserRoles.normalize('Service Provider'), UserRoles.provider);
    });

    test('maps admin to admin', () {
      expect(UserRoles.normalize('admin'), UserRoles.admin);
      expect(UserRoles.normalize('ADMIN'), UserRoles.admin);
    });

    test('defaults to seeker for unknown roles', () {
      expect(UserRoles.normalize('random-role'), UserRoles.seeker);
      expect(UserRoles.normalize(null), UserRoles.seeker);
    });
  });
}
