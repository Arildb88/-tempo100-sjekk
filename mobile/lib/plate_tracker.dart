final _platePattern = RegExp(
  r'(^|[^A-Z])([A-Z]{2}|[A-Z]\s+[A-Z])[\s-]*(\d[\s-]*\d[\s-]*\d[\s-]*\d(?:[\s-]*\d)?)(?![\s-]*\d)',
);

class PlateTracker {
  String? _last;
  int _count = 0;

  String? add(String raw) {
    final candidates = _platePattern.allMatches(raw.toUpperCase())
        .map((match) {
          final letters = match.group(2)!.replaceAll(RegExp(r'\s+'), '');
          final digits = match.group(3)!.replaceAll(RegExp(r'[\s-]'), '');
          return '$letters$digits';
        })
        .toSet();
    if (candidates.length != 1) {
      reset();
      return null;
    }
    final candidate = candidates.single;
    _count = candidate == _last ? _count + 1 : 1;
    _last = candidate;
    return _count >= 2 ? candidate : null;
  }

  void reset() {
    _last = null;
    _count = 0;
  }
}
