import 'package:flutter_test/flutter_test.dart';
import 'package:tempo100/plate_tracker.dart';

void main() {
  test('requires three consecutive unambiguous camera readings', () {
    final tracker = PlateTracker();
    expect(tracker.add('AB 12345'), isNull);
    expect(tracker.add('AB 12345'), isNull);
    expect(tracker.add('AB 12345'), 'AB12345');
    tracker.reset();
    expect(tracker.add('AB12345 CD67890'), isNull);
    expect(tracker.add('AB12345'), isNull);
    expect(tracker.add('AB12346'), isNull);
    expect(tracker.add('AB12345'), isNull);
  });
}
