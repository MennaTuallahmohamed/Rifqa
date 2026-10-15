import 'package:flutter/material.dart';

enum HaramPoiCategory {
  landmark,
  gate,
  water,
  toilet,
  wudu,
  womenPrayer,
  medical,
  guidance,
  accessibility,
  elevator,
  escalator,
  stairs,
  courtyard,
  ritual,
  meetingPoint,
  transport,
  other,
}

extension HaramPoiCategoryX on HaramPoiCategory {
  String get label {
    switch (this) {
      case HaramPoiCategory.landmark:
        return 'معالم';
      case HaramPoiCategory.gate:
        return 'الأبواب';
      case HaramPoiCategory.water:
        return 'المياه';
      case HaramPoiCategory.toilet:
        return 'دورات المياه';
      case HaramPoiCategory.wudu:
        return 'الوضوء';
      case HaramPoiCategory.womenPrayer:
        return 'مصليات النساء';
      case HaramPoiCategory.medical:
        return 'الإسعاف';
      case HaramPoiCategory.guidance:
        return 'الإرشاد';
      case HaramPoiCategory.accessibility:
        return 'ذوي الهمم';
      case HaramPoiCategory.elevator:
        return 'المصاعد';
      case HaramPoiCategory.escalator:
        return 'السلالم المتحركة';
      case HaramPoiCategory.stairs:
        return 'السلالم';
      case HaramPoiCategory.courtyard:
        return 'الساحات';
      case HaramPoiCategory.ritual:
        return 'المناسك';
      case HaramPoiCategory.meetingPoint:
        return 'نقاط التجمع';
      case HaramPoiCategory.transport:
        return 'المواصلات';
      case HaramPoiCategory.other:
        return 'أخرى';
    }
  }

  String get emoji {
    switch (this) {
      case HaramPoiCategory.landmark:
        return '📍';
      case HaramPoiCategory.gate:
        return '🚪';
      case HaramPoiCategory.water:
        return '🚰';
      case HaramPoiCategory.toilet:
        return '🚻';
      case HaramPoiCategory.wudu:
        return '💧';
      case HaramPoiCategory.womenPrayer:
        return '🧕';
      case HaramPoiCategory.medical:
        return '🚑';
      case HaramPoiCategory.guidance:
        return 'ℹ️';
      case HaramPoiCategory.accessibility:
        return '♿';
      case HaramPoiCategory.elevator:
        return '🛗';
      case HaramPoiCategory.escalator:
        return '↗️';
      case HaramPoiCategory.stairs:
        return '🪜';
      case HaramPoiCategory.courtyard:
        return '☀️';
      case HaramPoiCategory.ritual:
        return '🕋';
      case HaramPoiCategory.meetingPoint:
        return '👥';
      case HaramPoiCategory.transport:
        return '🚌';
      case HaramPoiCategory.other:
        return '📌';
    }
  }
}

enum HaramDataAccuracy {
  verified,
  approximate,
  userDefined,
}

extension HaramDataAccuracyX on HaramDataAccuracy {
  String get label {
    switch (this) {
      case HaramDataAccuracy.verified:
        return 'موقع موثّق';
      case HaramDataAccuracy.approximate:
        return 'موقع تقريبي';
      case HaramDataAccuracy.userDefined:
        return 'حدده المستخدم';
    }
  }
}

class HaramPoi {
  final String id;
  final String haramId;

  final String name;
  final String description;

  final HaramPoiCategory category;
  final HaramDataAccuracy accuracy;

  /// إحداثيات داخل خريطة الحرم الداخلية.
  /// ليست GPS.
  final Offset position;

  final String? floorId;

  final bool wheelchairAccessible;
  final bool womenOnly;
  final bool currentlyAvailable;

  final List<String> searchKeywords;

  const HaramPoi({
    required this.id,
    required this.haramId,
    required this.name,
    required this.description,
    required this.category,
    required this.position,
    this.accuracy = HaramDataAccuracy.approximate,
    this.floorId,
    this.wheelchairAccessible = false,
    this.womenOnly = false,
    this.currentlyAvailable = true,
    this.searchKeywords = const [],
  });

  String get emoji => category.emoji;

  bool get isGate => category == HaramPoiCategory.gate;

  bool get isEmergency =>
      category == HaramPoiCategory.medical ||
      category == HaramPoiCategory.guidance;

  bool matches(String query) {
    final value = query.trim().toLowerCase();

    if (value.isEmpty) {
      return true;
    }

    if (name.toLowerCase().contains(value)) {
      return true;
    }

    if (description.toLowerCase().contains(value)) {
      return true;
    }

    if (category.label.toLowerCase().contains(value)) {
      return true;
    }

    return searchKeywords.any(
      (keyword) => keyword.toLowerCase().contains(value),
    );
  }
}