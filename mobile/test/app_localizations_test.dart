import 'package:flutter_test/flutter_test.dart';

import 'package:tempo100/app_localizations.dart';
import 'package:tempo100/plate_input.dart';

void main() {
  group('spoken registration number', () {
    test('joins spoken letters and digits', () {
      expect(normalizeSpokenPlate('A B 1 2 3 4'), 'AB1234');
      expect(isValidSpokenPlate(normalizeSpokenPlate('A B 1 2 3 4')), isTrue);
    });

    test('converts English and Norwegian digit words', () {
      expect(normalizeSpokenPlate('A B one two three four'), 'AB1234');
      expect(normalizeSpokenPlate('skilt A B en to tre fire'), 'AB1234');
    });

    test('rejects text that is not a plausible plate', () {
      expect(isValidSpokenPlate(normalizeSpokenPlate('hello there')), isFalse);
    });
  });

  test('English strings are translated and Norwegian stays unchanged', () {
    const norwegian = 'Les skilt med kamera';
    expect(translateForLanguage('en', norwegian), 'Scan plate with camera');
    expect(translateForLanguage('no', norwegian), norwegian);
  });
}
