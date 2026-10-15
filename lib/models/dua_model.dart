// نموذج الدعاء - Rifqa
// يتطلب Dart 3+ (switch expressions).

enum DuaCategory { umrah, hajj, tawaf, sai, arafah, travel, mosque, general }

/// نوع المصدر. أول ثلاثة = محتوى موثّق. الباقي لازم يظهر بوضوح إنه مش نص مأثور.
enum DuaSourceType {
  quran,
  hadith,
  mathur,
  generalPermissible,
  userCreated,
  aiAssisted
}

/// مرحلة المناسك. "الدعاء المناسب دلوقتي" (المرحلة 3) هيعتمد عليها.
/// جاهزة لاحقاً لإضافة الوقت/المكان من غير تغيير الموديل.
enum RitualStage {
  none,
  preTravel,
  ihram,
  enteringHaram,
  tawaf,
  afterTawaf,
  sai,
  arafah,
  muzdalifah,
  jamarat,
}

/// جاهز لربط الـBackend لاحقاً.
enum SyncStatus { localOnly, pending, synced }

extension DuaCategoryX on DuaCategory {
  String get label => switch (this) {
        DuaCategory.umrah => 'أدعية العمرة',
        DuaCategory.hajj => 'أدعية الحج',
        DuaCategory.tawaf => 'أدعية الطواف',
        DuaCategory.sai => 'أدعية السعي',
        DuaCategory.arafah => 'أدعية عرفة',
        DuaCategory.travel => 'أدعية السفر',
        DuaCategory.mosque => 'دخول المسجد والخروج',
        DuaCategory.general => 'أذكار وأدعية عامة',
      };

  String get emoji => switch (this) {
        DuaCategory.umrah => '🕋',
        DuaCategory.hajj => '🏔️',
        DuaCategory.tawaf => '🔄',
        DuaCategory.sai => '🚶',
        DuaCategory.arafah => '🤲',
        DuaCategory.travel => '✈️',
        DuaCategory.mosque => '🕌',
        DuaCategory.general => '📿',
      };
}

extension DuaSourceTypeX on DuaSourceType {
  String get label => switch (this) {
        DuaSourceType.quran => 'من القرآن',
        DuaSourceType.hadith => 'من السنة',
        DuaSourceType.mathur => 'مأثور',
        DuaSourceType.generalPermissible => 'دعاء عام جائز',
        DuaSourceType.userCreated => 'من أدعيتي',
        DuaSourceType.aiAssisted => 'صياغة مساعدة غير موثقة',
      };

  bool get isDocumented =>
      this == DuaSourceType.quran ||
      this == DuaSourceType.hadith ||
      this == DuaSourceType.mathur;

  /// تنبيه يظهر في التفاصيل لغير الموثّق.
  String? get disclaimer => switch (this) {
        DuaSourceType.generalPermissible =>
          'هذه صيغة عامة جائزة، وليست نصًا مأثورًا عن النبي ﷺ. للمسلم أن يدعو بما شاء من خير.',
        DuaSourceType.userCreated =>
          'هذا دعاء كتبتَه أنت، وليس من المحتوى الموثّق في التطبيق.',
        DuaSourceType.aiAssisted =>
          'صياغة مساعدة غير موثقة، ولا تُنسب لمصدر شرعي.',
        _ => null,
      };
}

T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

class Dua {
  const Dua({
    required this.id,
    required this.title,
    required this.arabicText,
    required this.category,
    required this.sourceType,
    required this.reference,
    this.stages = const [],
    this.transliteration,
    this.translations = const {},
    this.repeatCount = 1,
    this.grade,
    this.note,
    this.needsReview = false,
    this.isUserCreated = false,
    this.syncStatus = SyncStatus.localOnly,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String arabicText;
  final DuaCategory category;
  final DuaSourceType sourceType;

  /// المرجع (قرآن/كتاب حديث/…). بدون أرقام أحاديث غير مؤكدة.
  final String reference;

  /// مراحل المناسك المرتبطة. الدعاء قد يناسب أكثر من مرحلة.
  final List<RitualStage> stages;
  final String? transliteration;

  /// مفتاح اللغة -> المعنى. ('en' حالياً)
  final Map<String, String> translations;
  final int repeatCount;
  final String? grade;
  final String? note;

  /// علم داخلي للمراجعة الشرعية قبل الإطلاق (يظهر في Debug فقط).
  final bool needsReview;
  final bool isUserCreated;
  final SyncStatus syncStatus;
  final DateTime? updatedAt;

  RitualStage get ritualStage =>
      stages.isEmpty ? RitualStage.none : stages.first;

  String get copyText => '$arabicText\n\n— $title\n$reference\n(رفقة)';

  Dua copyWith({
    String? title,
    String? arabicText,
    DuaCategory? category,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
  }) =>
      Dua(
        id: id,
        title: title ?? this.title,
        arabicText: arabicText ?? this.arabicText,
        category: category ?? this.category,
        sourceType: sourceType,
        reference: reference,
        stages: stages,
        transliteration: transliteration,
        translations: translations,
        repeatCount: repeatCount,
        grade: grade,
        note: note,
        needsReview: needsReview,
        isUserCreated: isUserCreated,
        syncStatus: syncStatus ?? this.syncStatus,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'arabicText': arabicText,
        'category': category.name,
        'sourceType': sourceType.name,
        'reference': reference,
        'stages': stages.map((s) => s.name).toList(),
        'transliteration': transliteration,
        'translations': translations,
        'repeatCount': repeatCount,
        'grade': grade,
        'note': note,
        'isUserCreated': isUserCreated,
        'syncStatus': syncStatus.name,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Dua.fromJson(Map<String, dynamic> j) => Dua(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        arabicText: j['arabicText'] as String? ?? '',
        category: _byName(
            DuaCategory.values, j['category'] as String?, DuaCategory.general),
        sourceType: _byName(DuaSourceType.values, j['sourceType'] as String?,
            DuaSourceType.userCreated),
        reference: j['reference'] as String? ?? '',
        stages: ((j['stages'] as List?) ?? const [])
            .map((s) =>
                _byName(RitualStage.values, s as String?, RitualStage.none))
            .toList(),
        transliteration: j['transliteration'] as String?,
        translations:
            Map<String, String>.from((j['translations'] as Map?) ?? const {}),
        repeatCount: (j['repeatCount'] as int?) ?? 1,
        grade: j['grade'] as String?,
        note: j['note'] as String?,
        isUserCreated: (j['isUserCreated'] as bool?) ?? true,
        syncStatus: _byName(SyncStatus.values, j['syncStatus'] as String?,
            SyncStatus.localOnly),
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? ''),
      );
}
