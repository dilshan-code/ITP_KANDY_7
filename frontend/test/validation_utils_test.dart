import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/validation_utils.dart';

void main() {
  group('ValidationUtils Tests', () {
    test('validateEmail - valid gmail', () {
      expect(ValidationUtils.validateEmail('test@gmail.com'), null);
      expect(ValidationUtils.validateEmail('TEST@GMAIL.COM'), null);
    });

    test('validateEmail - invalid email', () {
      expect(ValidationUtils.validateEmail('test@yahoo.com'), 'Email must end with @gmail.com');
      expect(ValidationUtils.validateEmail('test@hotmail.com'), 'Email must end with @gmail.com');
    });

    test('validateEmail - optional', () {
      expect(ValidationUtils.validateEmail(''), null);
      expect(ValidationUtils.validateEmail(null), null);
    });

    test('validatePhone - valid starts with 0', () {
      expect(ValidationUtils.validatePhone('0771234567'), null);
    });

    test('validatePhone - valid starts with +94', () {
      expect(ValidationUtils.validatePhone('+94771234567'), null);
    });

    test('validatePhone - invalid length', () {
      expect(ValidationUtils.validatePhone('077123456'), 'Phone number must have 9 digits after 0 (e.g. 0771234567)');
      expect(ValidationUtils.validatePhone('07712345678'), 'Phone number must have 9 digits after 0 (e.g. 0771234567)');
      expect(ValidationUtils.validatePhone('+9477123456'), 'Phone number must have 9 digits after +94 (e.g. +94771234567)');
    });

    test('validatePhone - required', () {
      expect(ValidationUtils.validatePhone(''), 'Phone number is required');
      expect(ValidationUtils.validatePhone(null), 'Phone number is required');
    });

    test('validatePassword - valid', () {
      expect(ValidationUtils.validatePassword('password123'), null);
    });

    test('validatePassword - invalid length', () {
      expect(ValidationUtils.validatePassword('pass'), 'Password must be at least 8 characters');
    });

    test('validateRequired - valid', () {
      expect(ValidationUtils.validateRequired('Store Name', 'Shop Name'), null);
    });

    test('validateRequired - invalid', () {
      expect(ValidationUtils.validateRequired('', 'Shop Name'), 'Shop Name is required');
    });
  });
}
