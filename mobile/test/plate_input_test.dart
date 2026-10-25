import 'package:flutter_test/flutter_test.dart';
import 'package:tempo100/plate_input.dart';

void main() {
  group('typed registration plate', () {
    test('normalizes spaces and lowercase letters', () {
      expect(normalizeTypedPlate('ab 1234'), 'AB1234');
    });

    test('accepts complete four or five digit plates', () {
      expect(isCompleteTypedPlate('AB 1234'), isTrue);
      expect(isCompleteTypedPlate('CD12345'), isTrue);
    });

    test('rejects incomplete and malformed plates', () {
      expect(isCompleteTypedPlate('AB 123'), isFalse);
      expect(isCompleteTypedPlate('A 12345'), isFalse);
      expect(isCompleteTypedPlate('AB123456'), isFalse);
    });
  });

  group('Tempo 100 voice command', () {
    test('extracts plate after Norwegian wake phrase', () {
      expect(parseTempo100SpokenPlate('Tempo 100, AB 1 2 3 4 5'), 'AB12345');
      expect(parseTempo100SpokenPlate('Tempo100, AB 12345'), 'AB12345');
      expect(parseTempo100SpokenPlate('Tempo hundre AB 1234'), 'AB1234');
    });

    test('supports English recognition of the wake phrase', () {
      expect(parseTempo100SpokenPlate('Tempo one hundred AB 12345'), 'AB12345');
    });

    test('rejects missing wake phrase or incomplete plate', () {
      expect(parseTempo100SpokenPlate('AB 12345'), isNull);
      expect(parseTempo100SpokenPlate('Tempo 100 AB 123'), isNull);
      expect(parseTempo100SpokenPlate('Tempo 100'), isNull);
    });
  });
}
