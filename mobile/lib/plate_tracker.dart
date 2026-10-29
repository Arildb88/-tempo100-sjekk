final _platePattern = RegExp(
  r'(^|[^A-Z])([A-Z]{2}|[A-Z]\s+[A-Z])[\s-]*(\d[\s-]*\d[\s-]*\d[\s-]*\d(?:[\s-]*\d)?)(?![\s-]*\d)',
);

class PlateTracker {
  static const _confirmationWindow = Duration(seconds: 2);

  String? _last;
  DateTime? _lastSeen;
  int _count = 0;

  String? add(String raw, {DateTime? at}) {
    final now = at ?? DateTime.now();
    final candidates = _platePattern.allMatches(raw.toUpperCase())
        .map((match) {
          final letters = match.group(2)!.replaceAll(RegExp(r'\s+'), '');
          final digits = match.group(3)!.replaceAll(RegExp(r'[\s-]'), '');
          return '$letters$digits';
        })
        .toSet();

    if (candidates.length > 1) {
      reset();
      return null;
    }
    if (candidates.isEmpty) {
      _expireIfStale(now);
      return null;
    }

    final candidate = candidates.single;
    final previousSeen = _lastSeen;
    final withinWindow = previousSeen != null &&
        !now.isBefore(previousSeen) &&
        now.difference(previousSeen) <= _confirmationWindow;

    if (candidate == _last && withinWindow) {
      _count++;
    } else {
      _last = candidate;
      _count = 1;
    }
    _lastSeen = now;
    return _count >= 2 ? candidate : null;
  }

  void _expireIfStale(DateTime now) {
    final previousSeen = _lastSeen;
    if (previousSeen != null &&
        (now.isBefore(previousSeen) ||
            now.difference(previousSeen) > _confirmationWindow)) {
      reset();
    }
  }

  void reset() {
    _last = null;
    _lastSeen = null;
    _count = 0;
  }
}
