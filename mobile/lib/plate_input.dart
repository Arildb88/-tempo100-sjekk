String normalizeSpokenPlate(String words) {
  const digitWords = {
    'ZERO': '0', 'OH': '0', 'NULL': '0', 'NULLEN': '0',
    'ONE': '1', 'EN': '1', 'ETT': '1',
    'TWO': '2', 'TO': '2', 'THREE': '3', 'TRE': '3',
    'FOUR': '4', 'FIRE': '4', 'FIVE': '5', 'FEM': '5',
    'SIX': '6', 'SEKS': '6', 'SEVEN': '7', 'SJU': '7', 'SYV': '7',
    'EIGHT': '8', 'ATTE': '8', 'NINE': '9', 'NI': '9',
  };
  const commandWords = {
    'SKILT', 'NUMMER', 'REGISTRERINGSNUMMER', 'REGISTRATION', 'PLATE',
    'TILHENGER', 'HENGER', 'REGNR',
  };
  final tokens = words.toUpperCase()
      .replaceAll(RegExp(r'[^A-ZÆØÅ0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty && !commandWords.contains(word))
      .map((word) => digitWords[word] ?? word);
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
  final command = RegExp(r'^TEMPO(.*).firstMatch(transcript);
  if (command == null) return null;

  // Continue accepting the previous longer phrase during the transition.
  final plateWords = (command.group(1) ?? '').replaceFirst(
    RegExp(r'^\s*(?:100|HUNDRE|HUNDRED|ETT\s+HUNDRE|ONE\s+HUNDRED)\b'),
    '',
  );
  final plate = normalizeSpokenPlate(plateWords);
  return isCompleteTypedPlate(plate) ? plate : null;
}

@Deprecated('Use parseTempoSpokenPlate instead.')
String? parseTempo100SpokenPlate(String words) => parseTempoSpokenPlate(words);
).firstMatch(transcript);
  if (command == null) return null;

  // Continue accepting the previous longer phrase during the transition.
  final plateWords = (command.group(1) ?? '').replaceFirst(
    RegExp(r'^\s*(?:100|HUNDRE|HUNDRED|ETT\s+HUNDRE|ONE\s+HUNDRED)\b'),
    '',
  );
  final plate = normalizeSpokenPlate(plateWords);
  return isCompleteTypedPlate(plate) ? plate : null;
}

@Deprecated('Use parseTempoSpokenPlate instead.')
String? parseTempo100SpokenPlate(String words) => parseTempoSpokenPlate(words);
