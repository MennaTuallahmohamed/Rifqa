import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../models/haramain/haramain_map_demo_models.dart' show HaramainSite;

/// مستوى توثيق البيانات. نفس نصوص HaramainVerifiedRepository في ملف JSON:
/// VERIFIED_POI / VERIFIED_ACCESS / VERIFIED_ROUTE، وأي شيء آخر = غير موثّق.
enum HlTrust { verifiedPoi, verifiedAccess, verifiedRoute, unverified }

HlTrust hlTrustFrom(String? v) => switch (v) {
      'VERIFIED_POI' => HlTrust.verifiedPoi,
      'VERIFIED_ACCESS' => HlTrust.verifiedAccess,
      'VERIFIED_ROUTE' => HlTrust.verifiedRoute,
      _ => HlTrust.unverified,
    };

enum HlCategory {
  gate,
  toilet,
  wudu,
  water,
  women,
  medical,
  info,
  accessibility,
  elevator,
  escalator,
  stairs,
  ritual,
  courtyard,
  landmark,
  transport,
}

extension HlCategoryX on HlCategory {
  String get label => switch (this) {
        HlCategory.gate => 'الأبواب',
        HlCategory.toilet => 'دورات المياه',
        HlCategory.wudu => 'الوضوء',
        HlCategory.water => 'ماء زمزم',
        HlCategory.women => 'مصليات النساء',
        HlCategory.medical => 'الإسعاف',
        HlCategory.info => 'الإرشاد',
        HlCategory.accessibility => 'ذوي الهمم',
        HlCategory.elevator => 'المصاعد',
        HlCategory.escalator => 'السلالم المتحركة',
        HlCategory.stairs => 'السلالم',
        HlCategory.ritual => 'المناسك',
        HlCategory.courtyard => 'الساحات',
        HlCategory.landmark => 'المعالم',
        HlCategory.transport => 'المواصلات',
      };

  String get emoji => switch (this) {
        HlCategory.gate => '🚪',
        HlCategory.toilet => '🚻',
        HlCategory.wudu => '💧',
        HlCategory.water => '🚰',
        HlCategory.women => '🧕',
        HlCategory.medical => '🚑',
        HlCategory.info => 'ℹ️',
        HlCategory.accessibility => '♿',
        HlCategory.elevator => '🛗',
        HlCategory.escalator => '↕️',
        HlCategory.stairs => '🪜',
        HlCategory.ritual => '🕋',
        HlCategory.courtyard => '☀️',
        HlCategory.landmark => '📍',
        HlCategory.transport => '🚌',
      };

  Color get color => switch (this) {
        HlCategory.gate => const Color(0xFF0A7A55),
        HlCategory.toilet => const Color(0xFF2F6FDE),
        HlCategory.wudu => const Color(0xFF1FA0C9),
        HlCategory.water => const Color(0xFF1FA0C9),
        HlCategory.women => const Color(0xFF8E5BB0),
        HlCategory.medical => const Color(0xFFD94F4F),
        HlCategory.info => const Color(0xFF5B6B7A),
        HlCategory.accessibility => const Color(0xFF3B5BDB),
        HlCategory.elevator => const Color(0xFF3B5BDB),
        HlCategory.escalator => const Color(0xFF3B5BDB),
        HlCategory.stairs => const Color(0xFF5B6B7A),
        HlCategory.ritual => const Color(0xFFC9992E),
        HlCategory.courtyard => const Color(0xFFE08A1E),
        HlCategory.landmark => const Color(0xFF075B4A),
        HlCategory.transport => const Color(0xFF5B6B7A),
      };

  IconData get icon => switch (this) {
        HlCategory.gate => Icons.door_front_door_outlined,
        HlCategory.toilet => Icons.wc_rounded,
        HlCategory.wudu => Icons.water_drop_outlined,
        HlCategory.water => Icons.local_drink_outlined,
        HlCategory.women => Icons.woman_rounded,
        HlCategory.medical => Icons.medical_services_outlined,
        HlCategory.info => Icons.info_outline_rounded,
        HlCategory.accessibility => Icons.accessible_rounded,
        HlCategory.elevator => Icons.elevator_outlined,
        HlCategory.escalator => Icons.stairs_outlined,
        HlCategory.stairs => Icons.stairs_rounded,
        HlCategory.ritual => Icons.mosque_outlined,
        HlCategory.courtyard => Icons.park_outlined,
        HlCategory.landmark => Icons.place_outlined,
        HlCategory.transport => Icons.directions_bus_outlined,
      };
}

class HlPoi {
  final String id, name, subtitle;
  final HaramainSite site;
  final HlCategory category;
  final LatLng position;
  final HlTrust trust;
  final String? gateNumber;
  final String? photo; // مسار صورة داخل assets (اختياري)
  final int floor;
  final bool wheelchair, womenOnly, isPin;
  final String? emojiOverride;
  final List<String> keywords;

  const HlPoi({
    required this.id,
    required this.name,
    required this.site,
    required this.category,
    required this.position,
    this.subtitle = '',
    this.trust = HlTrust.unverified,
    this.gateNumber,
    this.photo,
    this.floor = 0,
    this.wheelchair = false,
    this.womenOnly = false,
    this.isPin = false,
    this.emojiOverride,
    this.keywords = const [],
  });

  String get emoji => emojiOverride ?? category.emoji;

  String get title => (gateNumber == null || gateNumber!.isEmpty)
      ? name
      : '$name • $gateNumber';

  bool get verified => trust != HlTrust.unverified;

  bool matches(String q) {
    final v = q.trim().toLowerCase();
    if (v.isEmpty) return true;
    return name.toLowerCase().contains(v) ||
        subtitle.toLowerCase().contains(v) ||
        category.label.contains(v) ||
        (gateNumber ?? '').contains(v) ||
        keywords.any((k) => k.toLowerCase().contains(v));
  }

  factory HlPoi.fromJson(Map<String, dynamic> j) => HlPoi(
        id: j['id'] as String,
        name: j['name'] as String,
        subtitle: j['subtitle'] as String? ?? '',
        site: j['site'] == 'madinah' ? HaramainSite.madinah : HaramainSite.makkah,
        category: HlCategory.values.firstWhere(
          (e) => e.name == j['category'],
          orElse: () => HlCategory.landmark,
        ),
        position:
            LatLng((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble()),
        trust: hlTrustFrom(j['verificationStatus'] as String?),
        gateNumber: j['gateNumber']?.toString(),
        photo: j['photo'] as String?,
        floor: (j['floor'] as num?)?.toInt() ?? 0,
        wheelchair: j['wheelchair'] == true,
        womenOnly: j['womenOnly'] == true,
        keywords: ((j['keywords'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  factory HlPoi.fromPin(HlPin p) => HlPoi(
        id: p.id,
        name: p.label,
        subtitle: 'مكان حفظته أنت',
        site: p.site,
        category: HlCategory.landmark,
        position: p.position,
        isPin: true,
        emojiOverride: p.kind.emoji,
      );
}

enum HlTurn { start, straight, slightLeft, left, slightRight, right, uTurn, arrive }

extension HlTurnX on HlTurn {
  IconData get icon => switch (this) {
        HlTurn.start => Icons.navigation_rounded,
        HlTurn.straight => Icons.arrow_upward_rounded,
        HlTurn.slightLeft => Icons.turn_slight_left_rounded,
        HlTurn.left => Icons.turn_left_rounded,
        HlTurn.slightRight => Icons.turn_slight_right_rounded,
        HlTurn.right => Icons.turn_right_rounded,
        HlTurn.uTurn => Icons.u_turn_left_rounded,
        HlTurn.arrive => Icons.flag_rounded,
      };
}

class HlStep {
  final HlTurn turn;
  final String text;
  final int pointIndex; // مكان بداية المناورة داخل points
  final double meters; // طول المقطع بعد المناورة
  const HlStep(this.turn, this.text, this.pointIndex, this.meters);
}

class HlRoute {
  final List<LatLng> points;
  final List<double> cum; // المسافة التراكمية بالمتر
  final List<HlStep> steps;
  final HlPoi dest;
  final bool accessible;
  const HlRoute(this.points, this.cum, this.steps, this.dest,
      {this.accessible = false});

  double get meters => cum.last;
  int get minutes =>
      (meters / (accessible ? 50 : 60)).ceil().clamp(1, 999).toInt();
}

enum HlPinKind { myGate, hotel, bus, meeting, custom }

extension HlPinKindX on HlPinKind {
  String get label => switch (this) {
        HlPinKind.myGate => 'بابي',
        HlPinKind.hotel => 'فندقي',
        HlPinKind.bus => 'الباص',
        HlPinKind.meeting => 'نقطة التجمع',
        HlPinKind.custom => 'مكان محفوظ',
      };

  String get emoji => switch (this) {
        HlPinKind.myGate => '🚪',
        HlPinKind.hotel => '🏨',
        HlPinKind.bus => '🚌',
        HlPinKind.meeting => '👥',
        HlPinKind.custom => '📌',
      };

  IconData get icon => switch (this) {
        HlPinKind.myGate => Icons.door_sliding_outlined,
        HlPinKind.hotel => Icons.hotel_outlined,
        HlPinKind.bus => Icons.directions_bus_filled_outlined,
        HlPinKind.meeting => Icons.groups_outlined,
        HlPinKind.custom => Icons.push_pin_outlined,
      };
}

class HlPin {
  final String id, label;
  final HaramainSite site;
  final HlPinKind kind;
  final LatLng position;
  final DateTime createdAt;
  final String? poiId;
  const HlPin({
    required this.id,
    required this.label,
    required this.site,
    required this.kind,
    required this.position,
    required this.createdAt,
    this.poiId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'site': site.name,
        'kind': kind.name,
        'lat': position.latitude,
        'lng': position.longitude,
        'createdAt': createdAt.toIso8601String(),
        if (poiId != null) 'poiId': poiId,
      };

  factory HlPin.fromJson(Map<String, dynamic> j) => HlPin(
        id: j['id'] as String? ?? '',
        label: j['label'] as String? ?? '',
        site: HaramainSite.values.firstWhere((e) => e.name == j['site'],
            orElse: () => HaramainSite.makkah),
        kind: HlPinKind.values.firstWhere((e) => e.name == j['kind'],
            orElse: () => HlPinKind.custom),
        position: LatLng((j['lat'] as num?)?.toDouble() ?? 0,
            (j['lng'] as num?)?.toDouble() ?? 0),
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        poiId: j['poiId'] as String?,
      );
}
