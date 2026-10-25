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

  group('speech locale selection', () {
    test('uses the installed Norwegian locale', () {
      expect(speechLocaleIdForLanguage('no', ['en-US', 'nb_NO']), 'nb_NO');
    });

    test('uses the installed English locale', () {
      expect(speechLocaleIdForLanguage('en', ['nb-NO', 'en_GB']), 'en_GB');
    });

    test('reports when the selected language is not installed', () {
      expect(speechLocaleIdForLanguage('no', ['en-US']), isNull);
    });
  });

  group('Tempo voice command', () {
    test('extracts plate after the short Norwegian wake word', () {
      expect(parseTempoSpokenPlate('Tempo, AB 1 2 3 4 5'), 'AB12345');
      expect(parseTempoSpokenPlate('Tempo AB 12345'), 'AB12345');
      expect(parseTempoSpokenPlate('Tempo, AB 1234'), 'AB1234');
    });

    test('supports English recognition when English is selected in the app', () {
      expect(parseTempoSpokenPlate('Tempo, AB one two three four five'), 'AB12345');
    });

    test('rejects missing wake phrase or incomplete plate', () {
      expect(parseTempoSpokenPlate('AB 12345'), isNull);
      expect(parseTempoSpokenPlate('Tempo AB 123'), isNull);
      expect(parseTempoSpokenPlate('Tempo'), isNull);
    });
  });
}
