/// Arabic text normalization used by search and by the contextual assistant.
///
/// Arabic search in the real world rarely matches raw `contains` because the
/// pilgrim types without hamza/diacritics while the data is stored with them
/// (أ/إ/آ → ا), and sometimes with or without ta marbuta / alef variants.
///
/// This normalizer therefore:
///  - removes Arabic diacritics (tashkeel) and tatweel
///  - unifies alef variants (أ إ آ ٱ → ا)
///  - unifies yaa (ى → ي) and taa marbuta (ة → ه)
///  - converts Arabic-Indic digits to ASCII so "باب ٧٩" matches "باب 79"
///
/// It intentionally does NOT do stemming, and it does not guess meaning.
abstract final class HmArabic {
  static final RegExp _diacritics = RegExp(r'[ؐ-ًؚ-ٰٟۖ-ۭ]');
  static final RegExp _tatweel = RegExp(r'ـ');
  static final RegExp _arabicDigits = RegExp(r'[٠-٩۰-۹]');
  static final RegExp _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

  static const Map<String, String> _alef = {
    'أ': 'ا',
    'إ': 'ا',
    'آ': 'ا',
    'ٱ': 'ا',
    'ٲ': 'ا',
    'ٳ': 'ا',
  };
  static const Map<String, String> _yah = {'ى': 'ي', 'ی': 'ي'};
  static const Map<String, String> _taa = {'ة': 'ه', 'ۃ': 'ه'};

  static String normalize(String input) {
    if (input.isEmpty) return '';
    var s = input;
    s = s.replaceAll(_diacritics, '');
    s = s.replaceAll(_tatweel, '');
    s = s.toLowerCase();

    // Arabic-Indic / Extended Arabic-Indic digits -> ASCII.
    s = s.replaceAllMapped(_arabicDigits, (m) {
      final code = m[0]!.codeUnitAt(0);
      // ٠..٩ = 0x0660.. , ۰..۹ = 0x06F0..
      final base = code >= 0x06F0 ? 0x06F0 : 0x0660;
      return '${code - base}';
    });

    final out = StringBuffer();
    for (final ch in s.split('')) {
      out.write(_alef[ch] ?? _yah[ch] ?? _taa[ch] ?? ch);
    }
    return out.toString().replaceAll(_nonWord, ' ').trim();
  }

  /// Normalized substring test.
  static bool contains(String haystack, String needle) {
    final n = normalize(needle);
    if (n.isEmpty) return true;
    return normalize(haystack).contains(n);
  }

  /// Normalized equality test.
  static bool equals(String a, String b) {
    final x = normalize(a);
    final y = normalize(b);
    return x.isNotEmpty && x == y;
  }

  /// True when every token of [needle] appears somewhere in [haystack].
  ///
  /// "دوره مياه" must match "دورة المياه" even though the words differ.
  static bool matchesAllTokens(String haystack, String needle) {
    final tokens = normalize(needle)
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) return true;
    final hay = normalize(haystack);
    if (hay.isEmpty) return false;
    return tokens.every((t) => hay.contains(t) || _looseStem(hay, t));
  }

  /// Very small, conservative stemmer: allows a one-letter suffix mismatch
  /// (ماء/مياه, مصلى/مصليات). It never invents a word.
  static bool _looseStem(String hay, String token) {
    if (token.length < 4) return false;
    final stem = token.substring(0, token.length - 1);
    if (stem.length < 3) return false;
    return hay.contains(stem);
  }
}