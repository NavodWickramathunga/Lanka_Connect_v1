import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_connect/utils/validators.dart';

void main() {
  group('Validators.emailField', () {
    test('rejects empty email', () {
      expect(Validators.emailField(''), isNotNull);
    });

    test('accepts valid email', () {
      expect(Validators.emailField('user@example.com'), isNull);
    });
  });

  group('Validators.phoneField', () {
    test('accepts international format', () {
      expect(Validators.phoneField('+94771234567'), isNull);
    });

    test('rejects invalid phone', () {
      expect(Validators.phoneField('abc123'), isNotNull);
    });
  });

  group('Validators.passwordField', () {
    test('rejects short signup password', () {
      expect(
        Validators.passwordField('12345', isLogin: false),
        'Password must be at least 6 characters',
      );
    });

    test('accepts login password length as-is', () {
      expect(Validators.passwordField('123', isLogin: true), isNull);
    });
  });

  group('Validators.priceField', () {
    test('rejects zero price', () {
      expect(
        Validators.priceField('0', 'Price required'),
        'Price must be greater than 0',
      );
    });

    test('accepts positive price', () {
      expect(Validators.priceField('1500', 'Price required'), isNull);
    });
  });

  group('Validators.optionalLatitude', () {
    test('accepts empty latitude', () {
      expect(Validators.optionalLatitude(''), isNull);
    });

    test('rejects out-of-range latitude', () {
      expect(Validators.optionalLatitude('100'), isNotNull);
    });
  });

  group('Validators.optionalLongitude', () {
    test('accepts valid longitude', () {
      expect(Validators.optionalLongitude('79.8612'), isNull);
    });

    test('rejects out-of-range longitude', () {
      expect(Validators.optionalLongitude('-200'), isNotNull);
    });
  });
}
