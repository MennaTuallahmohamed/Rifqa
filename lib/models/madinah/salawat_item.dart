// ============================================================
// SALAWAT ITEM MODEL
// ============================================================
//
// يمثل صيغة واحدة داخل قسم الصلاة والسلام على النبي ﷺ.
//
// مهم:
// - لا نصف صيغة بأنها "مأثورة" إلا بعد التحقق من مصدرها.
// - النصوص غير المعتمدة لا تظهر في النسخة المنشورة كمحتوى موثق.
// - لا نستخدم عدد مرات الصلاة على النبي ﷺ كنقاط أو منافسة.
//
// ============================================================

enum SalawatType {
  authenticFormula,
  quranicCommand,
  generalFormula,
}

enum SalawatReviewStatus {
  draft,
  needsVerification,
  needsScholarlyReview,
  approved,
}

enum SalawatDisplayMode {
  normal,
  largeReader,
  calm,
}

extension SalawatTypeX on SalawatType {
  String get label {
    switch (this) {
      case SalawatType.authenticFormula:
        return 'صيغة مأثورة';

      case SalawatType.quranicCommand:
        return 'من القرآن';

      case SalawatType.generalFormula:
        return 'صيغة عامة';
    }
  }

  String get description {
    switch (this) {
      case SalawatType.authenticFormula:
        return 'صيغة منقولة من مصدر موثق بعد المراجعة.';

      case SalawatType.quranicCommand:
        return 'نص قرآني متعلق بالصلاة والسلام على النبي ﷺ.';

      case SalawatType.generalFormula:
        return 'صيغة عامة، ولا تُنسب إلى النبي ﷺ على أنها صيغة علّمها لأصحابه.';
    }
  }
}

extension SalawatReviewStatusX on SalawatReviewStatus {
  String get label {
    switch (this) {
      case SalawatReviewStatus.draft:
        return 'مسودة';

      case SalawatReviewStatus.needsVerification:
        return 'يحتاج توثيق';

      case SalawatReviewStatus.needsScholarlyReview:
        return 'بانتظار المراجعة';

      case SalawatReviewStatus.approved:
        return 'مراجع ومعتمد';
    }
  }

  bool get canPublish {
    return this == SalawatReviewStatus.approved;
  }
}

class SalawatItem {
  final String id;

  /// اسم مختصر للصيغة.
  ///
  /// مثال:
  /// الصلاة الإبراهيمية
  final String title;

  /// النص الكامل.
  final String text;

  /// وصف قصير يظهر قبل فتح الصيغة.
  final String subtitle;

  final SalawatType type;

  /// اسم المصدر عند وجود مصدر.
  ///
  /// مثال:
  /// صحيح البخاري
  final String? sourceName;

  /// المرجع التفصيلي بعد المراجعة.
  final String? sourceReference;

  /// رابط المصدر مستقبلًا.
  final String? sourceUrl;

  /// ملاحظة تحريرية عند الحاجة.
  ///
  /// مثال:
  /// هذه الملاحظة من رِفقة وليست جزءًا من الحديث.
  final String? editorialNote;

  /// شرح مبسط لمعنى الصيغة.
  ///
  /// يجب ألا يتحول إلى تفسير ديني غير مراجع.
  final String? meaning;

  /// هل يتوفر تسجيل صوتي؟
  final bool hasAudio;

  /// Asset أو URL للصوت مستقبلًا.
  final String? audioPath;

  /// ترتيب العنصر داخل المكتبة.
  final int priority;

  /// هل نعرض العنصر في الجزء المميز؟
  final bool featured;

  /// الوضع البصري المفضل.
  final SalawatDisplayMode preferredDisplayMode;

  /// حالة المراجعة.
  final SalawatReviewStatus reviewStatus;

  const SalawatItem({
    required this.id,
    required this.title,
    required this.text,
    required this.subtitle,
    required this.type,
    this.sourceName,
    this.sourceReference,
    this.sourceUrl,
    this.editorialNote,
    this.meaning,
    this.hasAudio = false,
    this.audioPath,
    this.priority = 0,
    this.featured = false,
    this.preferredDisplayMode = SalawatDisplayMode.largeReader,
    this.reviewStatus = SalawatReviewStatus.needsVerification,
  });

  // ============================================================
  // VERIFICATION
  // ============================================================

  bool get isApproved {
    return reviewStatus.canPublish;
  }

  bool get isAuthenticFormula {
    return type == SalawatType.authenticFormula;
  }

  bool get isQuranic {
    return type == SalawatType.quranicCommand;
  }

  bool get isGeneralFormula {
    return type == SalawatType.generalFormula;
  }

  bool get hasSource {
    return sourceName != null && sourceName!.trim().isNotEmpty;
  }

  bool get hasReference {
    return sourceReference != null && sourceReference!.trim().isNotEmpty;
  }

  bool get hasMeaning {
    return meaning != null && meaning!.trim().isNotEmpty;
  }

  // ============================================================
  // DISPLAY
  // ============================================================

  String get typeLabel {
    return type.label;
  }

  String get verificationLabel {
    if (!isApproved) {
      return reviewStatus.label;
    }

    if (hasSource) {
      return sourceName!;
    }

    return type.label;
  }

  String get sourceDisplay {
    if (!hasSource) {
      return '';
    }

    if (!hasReference) {
      return sourceName!;
    }

    return '$sourceName • $sourceReference';
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  SalawatItem copyWith({
    String? id,
    String? title,
    String? text,
    String? subtitle,
    SalawatType? type,
    String? sourceName,
    String? sourceReference,
    String? sourceUrl,
    String? editorialNote,
    String? meaning,
    bool? hasAudio,
    String? audioPath,
    int? priority,
    bool? featured,
    SalawatDisplayMode? preferredDisplayMode,
    SalawatReviewStatus? reviewStatus,
    bool clearSourceName = false,
    bool clearSourceReference = false,
    bool clearSourceUrl = false,
    bool clearEditorialNote = false,
    bool clearMeaning = false,
    bool clearAudioPath = false,
  }) {
    return SalawatItem(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      sourceName: clearSourceName ? null : sourceName ?? this.sourceName,
      sourceReference:
          clearSourceReference ? null : sourceReference ?? this.sourceReference,
      sourceUrl: clearSourceUrl ? null : sourceUrl ?? this.sourceUrl,
      editorialNote:
          clearEditorialNote ? null : editorialNote ?? this.editorialNote,
      meaning: clearMeaning ? null : meaning ?? this.meaning,
      hasAudio: hasAudio ?? this.hasAudio,
      audioPath: clearAudioPath ? null : audioPath ?? this.audioPath,
      priority: priority ?? this.priority,
      featured: featured ?? this.featured,
      preferredDisplayMode: preferredDisplayMode ?? this.preferredDisplayMode,
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
      'text': text,
      'subtitle': subtitle,
      'type': type.name,
      'sourceName': sourceName,
      'sourceReference': sourceReference,
      'sourceUrl': sourceUrl,
      'editorialNote': editorialNote,
      'meaning': meaning,
      'hasAudio': hasAudio,
      'audioPath': audioPath,
      'priority': priority,
      'featured': featured,
      'preferredDisplayMode': preferredDisplayMode.name,
      'reviewStatus': reviewStatus.name,
    };
  }

  factory SalawatItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return SalawatItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      text: json['text'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      type: _typeFromString(
        json['type'] as String?,
      ),
      sourceName: json['sourceName'] as String?,
      sourceReference: json['sourceReference'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      editorialNote: json['editorialNote'] as String?,
      meaning: json['meaning'] as String?,
      hasAudio: json['hasAudio'] as bool? ?? false,
      audioPath: json['audioPath'] as String?,
      priority: json['priority'] as int? ?? 0,
      featured: json['featured'] as bool? ?? false,
      preferredDisplayMode: _displayModeFromString(
        json['preferredDisplayMode'] as String?,
      ),
      reviewStatus: _reviewStatusFromString(
        json['reviewStatus'] as String?,
      ),
    );
  }

  // ============================================================
  // JSON HELPERS
  // ============================================================

  static SalawatType _typeFromString(
    String? value,
  ) {
    for (final item in SalawatType.values) {
      if (item.name == value) {
        return item;
      }
    }

    return SalawatType.generalFormula;
  }

  static SalawatDisplayMode _displayModeFromString(
    String? value,
  ) {
    for (final item in SalawatDisplayMode.values) {
      if (item.name == value) {
        return item;
      }
    }

    return SalawatDisplayMode.largeReader;
  }

  static SalawatReviewStatus _reviewStatusFromString(
    String? value,
  ) {
    for (final item in SalawatReviewStatus.values) {
      if (item.name == value) {
        return item;
      }
    }

    return SalawatReviewStatus.needsVerification;
  }

  @override
  String toString() {
    return 'SalawatItem('
        'id: $id, '
        'title: $title, '
        'type: ${type.name}, '
        'review: ${reviewStatus.name}'
        ')';
  }
}
