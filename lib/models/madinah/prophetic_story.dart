// ============================================================
// PROPHETIC STORY MODEL
// ============================================================
//
// هذا الـModel مخصص لقصص السيرة والمواقف النبوية داخل رِفقة.
//
// قاعدة أساسية:
//
// 1) narrativeText
//    صياغة رِفقة الوجدانية.
//
// 2) authenticText
//    النص المنقول من المصدر.
//
// 3) sourceReference
//    المرجع.
//
// 4) reviewStatus
//    لا يُعامل المحتوى كمحتوى معتمد قبل المراجعة.
//
// ============================================================

enum PropheticStoryCategory {
  mercy,
  kindness,
  humility,
  patience,
  loyalty,
  children,
  companions,
  worship,
  madinah,
  prophetMosque,
  general,
}

enum PropheticStoryContentType {
  hadith,
  seerahEvent,
  quran,
  historicalReport,
  editorialReflection,
}

enum PropheticStoryReviewStatus {
  draft,
  needsVerification,
  needsScholarlyReview,
  approved,
}

enum PropheticStorySceneType {
  opening,
  narrative,
  authenticText,
  reflection,
  takeaway,
}

extension PropheticStoryCategoryX on PropheticStoryCategory {
  String get label {
    switch (this) {
      case PropheticStoryCategory.mercy:
        return 'رحمته ﷺ';

      case PropheticStoryCategory.kindness:
        return 'رفقه ﷺ';

      case PropheticStoryCategory.humility:
        return 'تواضعه ﷺ';

      case PropheticStoryCategory.patience:
        return 'صبره ﷺ';

      case PropheticStoryCategory.loyalty:
        return 'وفاؤه ﷺ';

      case PropheticStoryCategory.children:
        return 'مع الأطفال';

      case PropheticStoryCategory.companions:
        return 'مع أصحابه';

      case PropheticStoryCategory.worship:
        return 'في عبادته';

      case PropheticStoryCategory.madinah:
        return 'في المدينة';

      case PropheticStoryCategory.prophetMosque:
        return 'في المسجد النبوي';

      case PropheticStoryCategory.general:
        return 'من سيرته ﷺ';
    }
  }

  String get emoji {
    switch (this) {
      case PropheticStoryCategory.mercy:
        return '🤍';

      case PropheticStoryCategory.kindness:
        return '🌿';

      case PropheticStoryCategory.humility:
        return '🕊️';

      case PropheticStoryCategory.patience:
        return '🌙';

      case PropheticStoryCategory.loyalty:
        return '💛';

      case PropheticStoryCategory.children:
        return '🤲';

      case PropheticStoryCategory.companions:
        return '🤝';

      case PropheticStoryCategory.worship:
        return '✨';

      case PropheticStoryCategory.madinah:
        return '🌴';

      case PropheticStoryCategory.prophetMosque:
        return '🕌';

      case PropheticStoryCategory.general:
        return 'ﷺ';
    }
  }
}

extension PropheticStoryContentTypeX on PropheticStoryContentType {
  String get label {
    switch (this) {
      case PropheticStoryContentType.hadith:
        return 'حديث';

      case PropheticStoryContentType.seerahEvent:
        return 'من السيرة';

      case PropheticStoryContentType.quran:
        return 'آية';

      case PropheticStoryContentType.historicalReport:
        return 'رواية تاريخية';

      case PropheticStoryContentType.editorialReflection:
        return 'وقفة وجدانية';
    }
  }
}

extension PropheticStoryReviewStatusX on PropheticStoryReviewStatus {
  String get label {
    switch (this) {
      case PropheticStoryReviewStatus.draft:
        return 'مسودة';

      case PropheticStoryReviewStatus.needsVerification:
        return 'يحتاج توثيق';

      case PropheticStoryReviewStatus.needsScholarlyReview:
        return 'بانتظار المراجعة';

      case PropheticStoryReviewStatus.approved:
        return 'مراجع ومعتمد';
    }
  }

  bool get canPublish {
    return this == PropheticStoryReviewStatus.approved;
  }
}

// ============================================================
// STORY SCENE
// ============================================================

class PropheticStoryScene {
  final String id;

  final PropheticStorySceneType type;

  /// عنوان صغير اختياري.
  ///
  /// مثال:
  /// "واسمعي ما حدث..."
  final String? title;

  /// النص المعروض في هذه المرحلة.
  final String text;

  /// هل الشاشة يفضل عرضها بهدوء شديد
  /// وبدون عناصر كثيرة؟
  final bool calm;

  /// مدة تقديرية للقراءة بالثواني.
  final int estimatedSeconds;

  const PropheticStoryScene({
    required this.id,
    required this.type,
    required this.text,
    this.title,
    this.calm = false,
    this.estimatedSeconds = 15,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'text': text,
      'calm': calm,
      'estimatedSeconds': estimatedSeconds,
    };
  }

  factory PropheticStoryScene.fromJson(
    Map<String, dynamic> json,
  ) {
    return PropheticStoryScene(
      id: json['id'] as String? ?? '',
      type: _sceneTypeFromString(
        json['type'] as String?,
      ),
      title: json['title'] as String?,
      text: json['text'] as String? ?? '',
      calm: json['calm'] as bool? ?? false,
      estimatedSeconds: json['estimatedSeconds'] as int? ?? 15,
    );
  }

  static PropheticStorySceneType _sceneTypeFromString(
    String? value,
  ) {
    for (final item in PropheticStorySceneType.values) {
      if (item.name == value) {
        return item;
      }
    }

    return PropheticStorySceneType.narrative;
  }
}

// ============================================================
// PROPHETIC STORY
// ============================================================

class PropheticStory {
  final String id;

  /// الاسم الظاهر في مكتبة القصص.
  ///
  /// مثال:
  /// "حين حنَّ الجذع إليه ﷺ"
  final String title;

  /// جملة قصيرة تظهر تحت العنوان.
  ///
  /// مثال:
  /// "حكاية شوقٍ رواها مسجد رسول الله ﷺ"
  final String subtitle;

  final PropheticStoryCategory category;

  final PropheticStoryContentType contentType;

  /// مقدمة وجدانية من كتابة رِفقة.
  ///
  /// هذا ليس حديثًا ولا نصًا منقولًا.
  final String narrativeText;

  /// النص الأصلي الموثق إن وجد.
  ///
  /// لا نضع هنا صياغة رِفقة.
  final String? authenticText;

  /// اسم المصدر.
  ///
  /// مثال:
  /// صحيح البخاري
  final String? sourceName;

  /// مرجع أكثر تحديدًا إن توفر.
  ///
  /// مثال:
  /// رقم الحديث / الكتاب / الباب.
  final String? sourceReference;

  /// رابط مرجعي يمكن استخدامه مستقبلًا.
  final String? sourceUrl;

  /// توضيح تحريري عند الحاجة.
  ///
  /// مثال:
  /// "النص أعلاه صياغة وجدانية من رِفقة،
  /// والحديث الموثق يظهر منفصلًا."
  final String? editorialNote;

  /// الشاشات التي تتكون منها Story Mode.
  final List<PropheticStoryScene> scenes;

  /// المعاني التي يمكن أن تختار المستخدمة
  /// الاحتفاظ بها بعد القصة.
  ///
  /// مثال:
  /// الرحمة - الرفق - الوفاء
  final List<String> suggestedValues;

  /// سؤال "وقفة مع القلب".
  final String reflectionQuestion;

  /// مدة القراءة التقريبية بالدقائق.
  final int readingMinutes;

  /// هل يوجد Audio Story؟
  final bool hasAudio;

  /// Asset أو URL للصوت مستقبلًا.
  final String? audioPath;

  /// هل القصة مرتبطة مباشرة بالمدينة؟
  final bool relatedToMadinah;

  /// هل القصة مرتبطة بالمسجد النبوي؟
  final bool relatedToProphetMosque;

  /// ترتيب القصة داخل الـFeatured Stories.
  final int priority;

  /// حالة المراجعة.
  final PropheticStoryReviewStatus reviewStatus;

  const PropheticStory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.contentType,
    required this.narrativeText,
    required this.scenes,
    required this.suggestedValues,
    required this.reflectionQuestion,
    this.authenticText,
    this.sourceName,
    this.sourceReference,
    this.sourceUrl,
    this.editorialNote,
    this.readingMinutes = 2,
    this.hasAudio = false,
    this.audioPath,
    this.relatedToMadinah = false,
    this.relatedToProphetMosque = false,
    this.priority = 0,
    this.reviewStatus = PropheticStoryReviewStatus.needsVerification,
  });

  // ============================================================
  // VERIFICATION
  // ============================================================

  bool get isApproved {
    return reviewStatus.canPublish;
  }

  bool get hasSource {
    return sourceName != null && sourceName!.trim().isNotEmpty;
  }

  bool get hasAuthenticText {
    return authenticText != null && authenticText!.trim().isNotEmpty;
  }

  bool get hasSourceReference {
    return sourceReference != null && sourceReference!.trim().isNotEmpty;
  }

  bool get isFullyReferenced {
    return hasSource && hasAuthenticText && hasSourceReference;
  }

  // ============================================================
  // DISPLAY
  // ============================================================

  String get categoryLabel {
    return category.label;
  }

  String get categoryEmoji {
    return category.emoji;
  }

  String get sourceBadge {
    if (!isApproved) {
      return reviewStatus.label;
    }

    if (hasSource) {
      return sourceName!;
    }

    return contentType.label;
  }

  String get readingTimeLabel {
    if (readingMinutes <= 1) {
      return 'دقيقة واحدة';
    }

    if (readingMinutes == 2) {
      return 'دقيقتان';
    }

    if (readingMinutes <= 10) {
      return '$readingMinutes دقائق';
    }

    return '$readingMinutes دقيقة';
  }

  // ============================================================
  // STORY MODE
  // ============================================================

  int get sceneCount {
    return scenes.length;
  }

  bool get hasStoryMode {
    return scenes.isNotEmpty;
  }

  PropheticStoryScene? sceneAt(int index) {
    if (index < 0 || index >= scenes.length) {
      return null;
    }

    return scenes[index];
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  PropheticStory copyWith({
    String? id,
    String? title,
    String? subtitle,
    PropheticStoryCategory? category,
    PropheticStoryContentType? contentType,
    String? narrativeText,
    String? authenticText,
    String? sourceName,
    String? sourceReference,
    String? sourceUrl,
    String? editorialNote,
    List<PropheticStoryScene>? scenes,
    List<String>? suggestedValues,
    String? reflectionQuestion,
    int? readingMinutes,
    bool? hasAudio,
    String? audioPath,
    bool? relatedToMadinah,
    bool? relatedToProphetMosque,
    int? priority,
    PropheticStoryReviewStatus? reviewStatus,
  }) {
    return PropheticStory(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      contentType: contentType ?? this.contentType,
      narrativeText: narrativeText ?? this.narrativeText,
      authenticText: authenticText ?? this.authenticText,
      sourceName: sourceName ?? this.sourceName,
      sourceReference: sourceReference ?? this.sourceReference,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      editorialNote: editorialNote ?? this.editorialNote,
      scenes: scenes ?? this.scenes,
      suggestedValues: suggestedValues ?? this.suggestedValues,
      reflectionQuestion: reflectionQuestion ?? this.reflectionQuestion,
      readingMinutes: readingMinutes ?? this.readingMinutes,
      hasAudio: hasAudio ?? this.hasAudio,
      audioPath: audioPath ?? this.audioPath,
      relatedToMadinah: relatedToMadinah ?? this.relatedToMadinah,
      relatedToProphetMosque:
          relatedToProphetMosque ?? this.relatedToProphetMosque,
      priority: priority ?? this.priority,
      reviewStatus: reviewStatus ?? this.reviewStatus,
    );
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'category': category.name,
      'contentType': contentType.name,
      'narrativeText': narrativeText,
      'authenticText': authenticText,
      'sourceName': sourceName,
      'sourceReference': sourceReference,
      'sourceUrl': sourceUrl,
      'editorialNote': editorialNote,
      'scenes': scenes.map((scene) => scene.toJson()).toList(),
      'suggestedValues': suggestedValues,
      'reflectionQuestion': reflectionQuestion,
      'readingMinutes': readingMinutes,
      'hasAudio': hasAudio,
      'audioPath': audioPath,
      'relatedToMadinah': relatedToMadinah,
      'relatedToProphetMosque': relatedToProphetMosque,
      'priority': priority,
      'reviewStatus': reviewStatus.name,
    };
  }

  factory PropheticStory.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawScenes = json['scenes'];

    return PropheticStory(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      category: _categoryFromString(
        json['category'] as String?,
      ),
      contentType: _contentTypeFromString(
        json['contentType'] as String?,
      ),
      narrativeText: json['narrativeText'] as String? ?? '',
      authenticText: json['authenticText'] as String?,
      sourceName: json['sourceName'] as String?,
      sourceReference: json['sourceReference'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      editorialNote: json['editorialNote'] as String?,
      scenes: rawScenes is List
          ? rawScenes
              .whereType<Map>()
              .map(
                (item) => PropheticStoryScene.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : [],
      suggestedValues: _stringList(
        json['suggestedValues'],
      ),
      reflectionQuestion: json['reflectionQuestion'] as String? ??
          'ما المعنى الذي تريدين أن يبقى معك؟',
      readingMinutes: json['readingMinutes'] as int? ?? 2,
      hasAudio: json['hasAudio'] as bool? ?? false,
      audioPath: json['audioPath'] as String?,
      relatedToMadinah: json['relatedToMadinah'] as bool? ?? false,
      relatedToProphetMosque: json['relatedToProphetMosque'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
      reviewStatus: _reviewStatusFromString(
        json['reviewStatus'] as String?,
      ),
    );
  }

  // ============================================================
  // JSON HELPERS
  // ============================================================

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value.whereType<String>().toList();
  }

  static PropheticStoryCategory _categoryFromString(
    String? value,
  ) {
    for (final item in PropheticStoryCategory.values) {
      if (item.name == value) {
        return item;
      }
    }

    return PropheticStoryCategory.general;
  }

  static PropheticStoryContentType _contentTypeFromString(
    String? value,
  ) {
    for (final item in PropheticStoryContentType.values) {
      if (item.name == value) {
        return item;
      }
    }

    return PropheticStoryContentType.seerahEvent;
  }

  static PropheticStoryReviewStatus _reviewStatusFromString(
    String? value,
  ) {
    for (final item in PropheticStoryReviewStatus.values) {
      if (item.name == value) {
        return item;
      }
    }

    return PropheticStoryReviewStatus.needsVerification;
  }

  @override
  String toString() {
    return 'PropheticStory('
        'id: $id, '
        'title: $title, '
        'category: ${category.name}, '
        'review: ${reviewStatus.name}'
        ')';
  }
}
