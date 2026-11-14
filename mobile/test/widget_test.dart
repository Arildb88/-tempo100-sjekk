import 'package:flutter_test/flutter_test.dart';
import 'package:tempo100/plate_input.dart';

void main() {
  test('normalizes and validates a typed Norwegian plate', () {
    expect(normalizeTypedPlate('ab 12345'), 'AB12345');
    expect(isCompleteTypedPlate('ab 12345'), isTrue);
    expect(isCompleteTypedPlate('AB123'), isFalse);
  });

  test('parses a spoken Tempo 100 plate', () {
    expect(parseTempoSpokenPlate('Tempo 100 AB 12345'), 'AB12345');
    expect(parseTempoSpokenPlate('AB 12345'), isNull);
  });
}
