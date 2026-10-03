final _platePattern = RegExp(r'\b[A-Z]{2}\s?\d{4,5}\b');

class PlateTracker {
  String? _last;
  int _count = 0;

  String? add(String raw) {
    final candidates = _platePattern.allMatches(raw.toUpperCase())
        .map((m) => m.group(0)!.replaceAll(' ', ''))
        .toSet();
    if (candidates.length != 1) { reset(); return null; }
    final candidate = candidates.single;
    _count = candidate == _last ? _count + 1 : 1;
    _last = candidate;
    return _count >= 2 ? candidate : null;
  }

  void reset() { _last = null; _count = 0; }
}
