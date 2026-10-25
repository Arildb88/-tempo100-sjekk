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

String? parseTempo100SpokenPlate(String words) {
  final transcript = words.toUpperCase()
      .replaceAll(RegExp(r'[^A-ZÆØÅ0-9\s]'), ' ')
      .trim();
  final command = RegExp(
    r'^TEMPO\s*(?:100|HUNDRE|HUNDRED|ETT\s+HUNDRE|ONE\s+HUNDRED)\b(.*)$',
  ).firstMatch(transcript);
  if (command == null) return null;
  final plate = normalizeSpokenPlate(command.group(1) ?? '');
  return isCompleteTypedPlate(plate) ? plate : null;
}
