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
  };
  final tokens = words.toUpperCase()
      .replaceAll(RegExp(r'[^A-ZÆØÅ0-9\\s]'), ' ')
      .split(RegExp(r'\\s+'))
      .where((word) => word.isNotEmpty && !commandWords.contains(word))
      .map((word) => digitWords[word] ?? word);
  return tokens.join().replaceAll(RegExp(r'[^A-ZÆØÅ0-9]'), '');
}

bool isValidSpokenPlate(String plate) =>
    RegExp(r'^[A-ZÆØÅ0-9]{2,7}$').hasMatch(plate);
