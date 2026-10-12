/// Extract using the original selection offsets, including repeated words.
String sentenceAt(String text, int start, int end) {
  if (start < 0 || end <= start || end > text.length) return '';
  final boundaries = RegExp(
    r'''[。！？!?]+[”’」』）)"']*|\.[”’」』）)"']*(?=\s|$)|\n+''',
  );
  final abbreviation = RegExp(
    r'\b(?:Mr|Mrs|Ms|Dr|Prof|Sr|Jr|St|vs|e\.g|i\.e|[A-Z])\.$',
    caseSensitive: false,
  );
  var sentenceStart = 0;
  for (final match in boundaries.allMatches(text)) {
    if (match.group(0) == '.' &&
        abbreviation
            .hasMatch(text.substring(sentenceStart, match.end).trim())) {
      continue;
    }
    if (match.end <= start) sentenceStart = match.end;
    if (match.end >= end) {
      return text
          .substring(sentenceStart, match.end)
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
  }
  return text.substring(sentenceStart).replaceAll(RegExp(r'\s+'), ' ').trim();
}
