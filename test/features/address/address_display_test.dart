import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_test/features/address/address_display.dart';

void main() {
  group('formatAddressForCell', () {
    test('short address is not changed', () {
      expect(
        formatAddressForCell('0x1234', 2.0),
        '0x1234',
      );
    });
    
    test('long address with 0x is formatted as 6 + 4 at scale 1.0', () {
      expect(
          formatAddressForCell(
              '0x1234567890abcdef1234567890abcdef12345678',
              1.0),
          '0x123456…5678'
      );
    });

    test('long address with 0x is formatted as 6 + 4 at scale 2.0', () {
      expect(
          formatAddressForCell(
              '0x1234567890abcdef1234567890abcdef12345678',
              2.0),
          '0x1234…5678'
      );
    });

    test('long address with 0x is formatted as 6 + 4 at scale 1.6', () {
      expect(
          formatAddressForCell(
              '0x1234567890abcdef1234567890abcdef12345678',
              1.6),
          '0x1234…5678'
      );
    });

    test('long address without 0x is also formatted', () {
      expect(
          formatAddressForCell(
              '1234567890abcdef',
              1.0),
          '123456…cdef'
      );
    });
    
    test('0x prefix is preserved', () {
      final result = formatAddressForCell('0xabcdef1234567890', 1.0);

      expect(result, startsWith('0x'));
      expect(result, '0xabcdef…7890');
    });
    
    test('address with exactly 12 main characters is not changed', () {
      expect(
          formatAddressForCell('0x123456789012', 2.0),
          '0x123456789012',
      );
    });
    
    test('scale below 1.6 still uses 6 + 4 format', () {
      expect(
          formatAddressForCell('1234567890abcdef', 1.59),
          '123456…cdef',
      );
    });
  });
}