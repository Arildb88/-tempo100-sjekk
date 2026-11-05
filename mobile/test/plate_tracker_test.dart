import 'package:flutter_test/flutter_test.dart';
import 'package:tempo100/plate_tracker.dart';

void main() {
  test('requires two consecutive unambiguous camera readings', () {
    final tracker = PlateTracker();
    expect(tracker.add('AB 12345'), isNull);
    expect(tracker.add('AB 12345'), 'AB12345');
    tracker.reset();
    expect(tracker.add('AB12345 CD67890'), isNull);
    expect(tracker.add('AB12345'), isNull);
    expect(tracker.add('AB12346'), isNull);
    expect(tracker.add('AB12345'), isNull);
    expect(tracker.add('AB12345'), 'AB12345');
  });

  test('recognizes a four-digit plate written on one line', () {
    final tracker = PlateTracker();
    expect(tracker.add('AB 1234'), isNull);
    expect(tracker.add('AB 1234'), 'AB1234');
  });

  test('recognizes letters above digits on two lines', () {
    final tracker = PlateTracker();
    const stacked = 'AB\n1 2 3 4';
    expect(tracker.add(stacked), isNull);
    expect(tracker.add(stacked), 'AB1234');
  });

  test('recognizes letters and digits split into separate OCR tokens', () {
    final tracker = PlateTracker();
    const split = 'A B\n1\n2\n3\n4';
    expect(tracker.add(split), isNull);
    expect(tracker.add(split), 'AB1234');
  });

  test('rejects a six-digit number instead of truncating it', () {
    final tracker = PlateTracker();
    const tooManyDigits = 'AB\n1 2 3 4 5 6';
    expect(tracker.add(tooManyDigits), isNull);
    expect(tracker.add(tooManyDigits), isNull);
  });
}
