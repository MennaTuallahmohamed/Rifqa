import '../../models/haramain/haramain_map_demo_models.dart';
import '../../screens/haramain/haramain_live_models.dart';
import 'haramain_arabic_text.dart';

/// Deterministic, fully-local smart search for the Haramain map.
///
/// Ranking rules (no ML, no network, same input -> same output):
///  1. Exact normalized name match               -> strongest
///  2. Gate number match (typing "79" finds the gate numbered 79)
///  3. Category alias hit ("دورة مياه" -> toilets)
///  4. Name / subtitle / keyword token hit
///  5. Verified POIs are nudged above unverified exploration data
///
/// The service NEVER returns a route and never claims a POI is navigable.
/// Whether a result may be navigated is decided separately by
/// `HaramainNavSafety`, which requires an explicit VERIFIED_ROUTE.
class HaramainSearchService {
  static const Map<String, HlCategory> categoryAliases = {
    'باب': HlCategory.gate,
    'ابواب': HlCategory.gate,
    'بوابه': HlCategory.gate,
    'مدخل': HlCategory.gate,
    'مخرج': HlCategory.gate,
    'بوابي': HlCategory.gate,
    'دوره مياه': HlCategory.toilet,
    'حمام': HlCategory.toilet,
    'مرحاض': HlCategory.toilet,
    'موضع': HlCategory.wudu,
    'وضوء': HlCategory.wudu,
    'ماء': HlCategory.water,
    'مياه': HlCategory.water,
    'زمزم': HlCategory.water,
    'شرب': HlCategory.water,
    'مصعد': HlCategory.elevator,
    'مصاعد': HlCategory.elevator,
    'مصلي نساء': HlCategory.women,
    'نساء': HlCategory.women,
    'اسعاف': HlCategory.medical,
    'طبي': HlCategory.medical,
    'صحيه': HlCategory.medical,
    'استعلامات': HlCategory.info,
    'ارشاد': HlCategory.info,
    'معلومات': HlCategory.info,
    'كرسي متحرك': HlCategory.accessibility,
    'ذي الهمم': HlCategory.accessibility,
    'ذوي الهمم': HlCategory.accessibility,
    'مساعده': HlCategory.accessibility,
    'مصعد متحرك': HlCategory.escalator,
    'سلالم متحركه': HlCategory.escalator,
    'سلالم': HlCategory.stairs,
    'درجات': HlCategory.stairs,
    'طواف': HlCategory.ritual,
    'مطاف': HlCategory.ritual,
    'كعبه': HlCategory.ritual,
    'صفا': HlCategory.ritual,
    'مروه': HlCategory.ritual,
    'مسعي': HlCategory.ritual,
    'ساحه': HlCategory.courtyard,
    'بوصف': HlCategory.transport,
    'تاكسي': HlCategory.transport,
    'حافله': HlCategory.transport,
    'موقف': HlCategory.transport,
    'فندق': HlCategory.landmark,
    'روضه': HlCategory.landmark,
    'مسجد': HlCategory.landmark,
  };

  /// Aliases for non-Arabic keyboards.
  static const Map<String, HlCategory> latinAliases = {
    'toilet': HlCategory.toilet,
    'wc': HlCategory.toilet,
    'water': HlCategory.water,
    'zamzam': HlCategory.water,
    'gate': HlCategory.gate,
    'elevator': HlCategory.elevator,
    'lift': HlCategory.elevator,
    'prayer': HlCategory.women,
    'medical': HlCategory.medical,
    'info': HlCategory.info,
    'help': HlCategory.info,
    'accessible': HlCategory.accessibility,
    'wheelchair': HlCategory.accessibility,
    'steps': HlCategory.stairs,
    'escalator': HlCategory.escalator,
    'bus': HlCategory.transport,
    'taxi': HlCategory.transport,
  };

  static const int maxResults = 40;

  /// Categories that make sense as "quick services" chips, in display order.
  static const List<HlCategory> quickServiceOrder = [
    HlCategory.gate,
    HlCategory.toilet,
    HlCategory.water,
    HlCategory.accessibility,
    HlCategory.elevator,
    HlCategory.women,
    HlCategory.medical,
    HlCategory.info,
  ];

  /// Categories actually present in the loaded data, in quick-service order.
  static List<HlCategory> availableQuickServices(List<HlPoi> pois) {
    final present = pois.map((p) => p.category).toSet();
    return quickServiceOrder.where(present.contains).toList(growable: false);
  }

  static HlCategory? categoryForQuery(String query) {
    final raw = query.trim();
    if (raw.isEmpty) return null;

    final lower = raw.toLowerCase();
    for (final e in latinAliases.entries) {
      if (lower.contains(e.key)) return e.value;
    }
    for (final e in categoryAliases.entries) {
      if (HmArabic.matchesAllTokens(raw, e.key)) return e.value;
    }
    for (final c in HlCategory.values) {
      if (HmArabic.contains(c.label, raw)) return c;
    }
    return null;
  }

  /// Ranked search. An empty query returns a useful starter list.
  List<HlPoi> search(
    List<HlPoi> source,
    String query, {
    bool verifiedOnly = false,
    bool accessibleOnly = false,
  }) {
    final pool = source
        .where((p) => !verifiedOnly || p.verified)
        .where((p) => !accessibleOnly || p.wheelchair)
        .toList(growable: false);

    final q = query.trim();
    if (q.isEmpty) return _starters(pool);

    final cat = categoryForQuery(q);
    final scored = <(HlPoi, int)>[];
    for (final p in pool) {
      final score = _score(p, q, cat);
      if (score > 0) scored.add((p, score));
    }
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      if (byScore != 0) return byScore;
      return a.$1.title.compareTo(b.$1.title);
    });
    return [for (final s in scored.take(maxResults)) s.$1];
  }

  List<HlPoi> _starters(List<HlPoi> pool) {
    final starters = [...pool]
      ..sort((a, b) {
        final v = (b.verified ? 1 : 0).compareTo(a.verified ? 1 : 0);
        if (v != 0) return v;
        return a.title.compareTo(b.title);
      });
    return starters.take(20).toList(growable: false);
  }

  int _score(HlPoi p, String q, HlCategory? cat) {
    var score = 0;

    if (HmArabic.equals(p.name, q) || HmArabic.equals(p.title, q)) {
      score += 100;
    }
    if (HmArabic.contains(p.name, q) || HmArabic.contains(p.title, q)) {
      score += 40;
    }

    // Gate numbers: typing "79" or "باب 79" must find the numbered gate.
    final gate = p.gateNumber;
    if (gate != null && gate.isNotEmpty) {
      final digits = HmArabic.normalize(q).replaceAll(' ', '');
      if (digits.isNotEmpty && digits.length <= 4) {
        if (HmArabic.equals(gate, digits)) {
          score += 70;
        } else if (HmArabic.normalize(gate).contains(digits)) {
          score += 30;
        }
      }
    }

    if (cat != null && p.category == cat) score += 25;

    if (HmArabic.contains(p.subtitle, q)) score += 12;
    if (HmArabic.matchesAllTokens(p.name, q)) score += 10;
    for (final k in p.keywords) {
      if (HmArabic.contains(k, q)) {
        score += 14;
        break;
      }
    }
    if (HmArabic.contains(p.category.label, q)) score += 8;

    if (score == 0) return 0;
    if (p.verified) score += 2;
    return score;
  }

  /// Filter used by the on-map category chips.
  static List<HlPoi> filterByCategory(
    List<HlPoi> source,
    HlCategory? category, {
    bool accessibleOnly = false,
  }) {
    return source
        .where((p) => category == null || p.category == category)
        .where((p) => !accessibleOnly || p.wheelchair)
        .toList(growable: false);
  }
}

/// Arabic display names used across the Haramain entry points.
extension HaramainSearchSites on HaramainSite {
  String get arabicTitle => switch (this) {
        HaramainSite.makkah => 'المسجد الحرام — مكة المكرمة',
        HaramainSite.madinah => 'المسجد النبوي — المدينة المنورة',
      };

  String get shortArabic => switch (this) {
        HaramainSite.makkah => 'مكة المكرمة',
        HaramainSite.madinah => 'المدينة المنورة',
      };
}
