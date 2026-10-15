enum ZiyaratCity {
  makkah,
  madinah,
}

enum ZiyaratCategory {
  mosque,
  landmark,
  mountain,
  well,
  historical,
  hajjSite,
  other,
}

enum ZiyaratVerificationStatus {
  verified,
  needsReview,
}

enum ZiyaratEvidenceType {
  quran,
  hadith,
  history,
  guidance,
  other,
}

class ZiyaratEvidence {
  const ZiyaratEvidence({
    required this.text,
    required this.source,
    this.type = ZiyaratEvidenceType.other,
    this.reference,
    this.authenticity,
    this.note,
  });

  /// نص الآية أو الحديث أو المعلومة التاريخية.
  final String text;

  /// اسم المصدر، مثل:
  /// صحيح البخاري - صحيح مسلم - القرآن الكريم.
  final String source;

  /// نوع الدليل.
  final ZiyaratEvidenceType type;

  /// رقم الحديث أو السورة/الآية أو المرجع.
  final String? reference;

  /// درجة الحديث عند الحاجة.
  final String? authenticity;

  /// ملاحظة تحريرية أو توضيحية.
  final String? note;
}

class ZiyaratVisitorGuidance {
  const ZiyaratVisitorGuidance({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

class ZiyaratPlace {
  const ZiyaratPlace({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    required this.shortDescription,
    required this.story,
    required this.significance,
    required this.visitorGuidance,
    required this.warnings,
    required this.evidence,
    required this.verificationStatus,
    this.icon = '📍',
    this.heroImage,
    this.latitude,
    this.longitude,
    this.accessibilityInfo,
    this.estimatedVisitMinutes,
    this.audioAsset,
  });

  final String id;

  final String name;

  final ZiyaratCity city;

  final ZiyaratCategory category;

  /// وصف مختصر يظهر في بطاقة المزار.
  final String shortDescription;

  /// قصة المكان أو الحدث التاريخي المرتبط به.
  final String story;

  /// أهمية المكان.
  ///
  /// وجود المكان في التطبيق لا يعني بالضرورة
  /// وجود فضل شرعي مخصوص لزيارته.
  final String significance;

  /// ما الذي يمكن للزائر فعله؟
  final List<ZiyaratVisitorGuidance> visitorGuidance;

  /// تنبيهات وآداب مرتبطة بالزيارة.
  final List<String> warnings;

  /// القرآن أو الحديث أو المراجع التاريخية.
  final List<ZiyaratEvidence> evidence;

  /// حالة مراجعة المحتوى.
  final ZiyaratVerificationStatus verificationStatus;

  /// رمز بصري مؤقت للمكان.
  final String icon;

  /// صورة حقيقية للمكان عند توفر Asset مناسب.
  final String? heroImage;

  /// لا نضع إحداثيات تقريبية.
  ///
  /// تظل null حتى يتم اعتماد إحداثيات موثوقة.
  final double? latitude;
  final double? longitude;

  /// معلومات الوصول عند توفر معلومات موثوقة.
  final String? accessibilityInfo;

  /// مدة تقديرية للزيارة عند توفرها.
  final int? estimatedVisitMinutes;

  /// ملف صوتي محلي مستقبلاً.
  final String? audioAsset;

  bool get hasVerifiedCoordinates {
    return latitude != null && longitude != null;
  }

  bool get needsReview {
    return verificationStatus ==
        ZiyaratVerificationStatus.needsReview;
  }

  String get cityName {
    switch (city) {
      case ZiyaratCity.makkah:
        return 'مكة المكرمة';

      case ZiyaratCity.madinah:
        return 'المدينة المنورة';
    }
  }

  String get categoryName {
    switch (category) {
      case ZiyaratCategory.mosque:
        return 'مسجد';

      case ZiyaratCategory.landmark:
        return 'معلم إسلامي';

      case ZiyaratCategory.mountain:
        return 'معلم تاريخي';

      case ZiyaratCategory.well:
        return 'بئر تاريخي';

      case ZiyaratCategory.historical:
        return 'موقع تاريخي';

      case ZiyaratCategory.hajjSite:
        return 'من مشاعر الحج';

      case ZiyaratCategory.other:
        return 'مزار';
    }
  }
}