const Map<String, String> _spokenDigitWords = {
  'ZERO': '0', 'OH': '0', 'NULL': '0', 'NULLEN': '0',
  'ONE': '1', 'EN': '1', 'ETT': '1',
  'TWO': '2', 'TO': '2', 'THREE': '3', 'TRE': '3',
  'FOUR': '4', 'FIRE': '4', 'FIVE': '5', 'FEM': '5',
  'SIX': '6', 'SEKS': '6', 'SEVEN': '7', 'SJU': '7', 'SYV': '7',
  'EIGHT': '8', 'ATTE': '8', 'NINE': '9', 'NI': '9',
};

const Set<String> _spokenPlateFillers = {
  'SKILT', 'NUMMER', 'REGISTRERINGSNUMMER', 'REGISTRATION', 'PLATE',
  'TILHENGER', 'HENGER', 'REGNR',
};

String normalizeSpokenPlate(String words) {
  final tokens = words.toUpperCase()
      .replaceAll(RegExp(r'[^A-ZÆØÅ0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty && !_spokenPlateFillers.contains(word))
      .map((word) => _spokenDigitWords[word] ?? word);
  return tokens.join().replaceAll(RegExp(r'[^A-ZÆØÅ0-9]'), '');
}

bool isValidSpokenPlate(String plate) =>
    RegExp(r'^[A-ZÆØÅ0-9]{2,7}$').hasMatch(plate);

String normalizeTypedPlate(String value) =>
    value.toUpperCase().replaceAll(RegExp(r'\s+'), '');

bool isCompleteTypedPlate(String value) =>
    RegExp(r'^[A-Z]{2}\d{4,5}$').hasMatch(normalizeTypedPlate(value));

String? speechLocaleIdForLanguage(String language, Iterable<String> localeIds) {
  final wanted = language == 'en' ? 'en' : 'nb';
  for (final localeId in localeIds) {
    final normalized = localeId.replaceAll('_', '-').toLowerCase();
    if (wanted == 'en' && normalized.startsWith('en-')) return localeId;
    if (wanted == 'nb' &&
        (normalized.startsWith('nb-') || normalized.startsWith('no-'))) {
      return localeId;
    }
  }
  return null;
}

String? parseTempoSpokenPlate(String words) {
  final transcript = words.toUpperCase()
      .replaceAll(RegExp(r'[^A-ZÆØÅ0-9\s]'), ' ')
      .trim();
  if (!transcript.startsWith('TEMPO')) return null;

  var plateTranscript = transcript.substring('TEMPO'.length).trim();
  plateTranscript = plateTranscript.replaceFirst(
    RegExp(r'^(?:100|HUNDRE|HUNDRED|ETT\s+HUNDRE|ONE\s+HUNDRED)\b'),
    '',
  );
  final tokens = plateTranscript
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty && !_spokenPlateFillers.contains(word))
      .toList(growable: false);

  final candidates = <String>{};
  for (var i = 0; i < tokens.length; i++) {
    final token = tokens[i];

    // Handle recognizers that return a complete plate as one token.
    final compact = RegExp(r'^([A-Z]{2})(\d{4,})$').firstMatch(token);
    if (compact != null) {
      final candidate = compact.group(1)! + compact.group(2)!;
      if (isCompleteTypedPlate(candidate)) candidates.add(candidate);
      continue;
    }

    String? letters;
    var next = i + 1;
    if (RegExp(r'^[A-Z]{2}$').hasMatch(token)) {
      letters = token;
    } else if (RegExp(r'^[A-Z]$').hasMatch(token) &&
        next < tokens.length &&
        RegExp(r'^[A-Z]$').hasMatch(tokens[next])) {
      letters = token + tokens[next];
      next++;
    }
    if (letters == null) continue;

    final digits = StringBuffer();
    while (next < tokens.length) {
      final numberToken = tokens[next];
      if (RegExp(r'^\d+$').hasMatch(numberToken)) {
        digits.write(numberToken);
      } else if (_spokenDigitWords.containsKey(numberToken)) {
        digits.write(_spokenDigitWords[numberToken]);
      } else {
        break;
      }
      next++;
    }

    final candidate = letters + digits.toString();
    if (isCompleteTypedPlate(candidate)) candidates.add(candidate);
  }

  return candidates.length == 1 ? candidates.single : null;
}

@Deprecated('Use parseTempoSpokenPlate instead.')
String? parseTempo100SpokenPlate(String words) => parseTempoSpokenPlate(words);
