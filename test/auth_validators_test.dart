import 'package:flutter_test/flutter_test.dart';
import 'package:siyadi/features/auth/domain/auth_validators.dart';

void main() {
  group('auth validators', () {
    test('username rules', () {
      expect(validateUsername(null), isNotNull);
      expect(validateUsername('ab'), isNotNull);
      expect(validateUsername('valid_name'), isNull);
      expect(validateUsername('Bad Name'), isNotNull);
    });

    test('email rules', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('a@b.com'), isNull);
    });

    test('password rules', () {
      expect(validatePassword('123'), isNull); // existing login
      expect(validatePassword('123', isNew: true), isNotNull);
      expect(validatePassword('secret1', isNew: true), isNull);
    });
  });
}
