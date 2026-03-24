import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/phone_utils.dart';

void main() {
  group('PhoneNumber Normalization Tests', () {
    test('Should convert 0... format to +94...', () {
      expect(normalizePhoneNumber('0712345678'), '+94712345678');
      expect(normalizePhoneNumber('0771234567'), '+94771234567');
      expect(normalizePhoneNumber('0112345678'), '+94112345678');
    });

    test('Should keep +94 format as is', () {
      expect(normalizePhoneNumber('+94712345678'), '+94712345678');
    });

    test('Should trim whitespace', () {
      expect(normalizePhoneNumber(' 0712345678 '), '+94712345678');
      expect(normalizePhoneNumber(' +94712345678 '), '+94712345678');
    });

    test('Should return original if not matching 0... (10 digits) pattern', () {
      expect(normalizePhoneNumber('071234567'), '071234567'); // Too short
      expect(normalizePhoneNumber('07123456789'), '07123456789'); // Too long
      expect(normalizePhoneNumber('1712345678'), '1712345678'); // Not starting with 0
      expect(normalizePhoneNumber('abc'), 'abc');
    });
  });
}
