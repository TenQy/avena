String normalizeSearchText(String value) {
  final buffer = StringBuffer();
  final lowerValue = value.trim().toLowerCase();

  for (final rune in lowerValue.runes) {
    if (rune >= 0x0300 && rune <= 0x036f) {
      continue;
    }

    buffer.write(_searchRuneReplacements[rune] ?? String.fromCharCode(rune));
  }

  return buffer.toString();
}

const _searchRuneReplacements = <int, String>{
  0x00e0: 'a',
  0x00e1: 'a',
  0x00e2: 'a',
  0x00e3: 'a',
  0x00e4: 'a',
  0x00e5: 'a',
  0x00e7: 'c',
  0x00e8: 'e',
  0x00e9: 'e',
  0x00ea: 'e',
  0x00eb: 'e',
  0x00ec: 'i',
  0x00ed: 'i',
  0x00ee: 'i',
  0x00ef: 'i',
  0x00f1: 'n',
  0x00f2: 'o',
  0x00f3: 'o',
  0x00f4: 'o',
  0x00f5: 'o',
  0x00f6: 'o',
  0x00f9: 'u',
  0x00fa: 'u',
  0x00fb: 'u',
  0x00fc: 'u',
  0x00fd: 'y',
  0x00ff: 'y',
};
