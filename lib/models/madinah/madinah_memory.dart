enum MadinahMemoryType {
  prophetMosque,
  rawdah,
  propheticStory,
  spiritualReflection,
  dua,
  letterToMyself,
  personalMoment,
}

extension MadinahMemoryTypeX on MadinahMemoryType {
  String get label {
    switch (this) {
      case MadinahMemoryType.prophetMosque:
        return 'المسجد النبوي';

      case MadinahMemoryType.rawdah:
        return 'الروضة الشريفة';

      case MadinahMemoryType.propheticStory:
        return 'من حكاياته ﷺ';

      case MadinahMemoryType.spiritualReflection:
        return 'وقفة مع القلب';

      case MadinahMemoryType.dua:
        return 'دعاء من قلبي';

      case MadinahMemoryType.letterToMyself:
        return 'رسالتي لنفسي';

      case MadinahMemoryType.personalMoment:
        return 'لحظة من المدينة';
    }
  }

  String get emoji {
    switch (this) {
      case MadinahMemoryType.prophetMosque:
        return '🕌';

      case MadinahMemoryType.rawdah:
        return '🌿';

      case MadinahMemoryType.propheticStory:
        return 'ﷺ';

      case MadinahMemoryType.spiritualReflection:
        return '🤍';

      case MadinahMemoryType.dua:
        return '🤲';

      case MadinahMemoryType.letterToMyself:
        return '💌';

      case MadinahMemoryType.personalMoment:
        return '✨';
    }
  }
}

class MadinahMemory {
  final String id;

  /// نوع الذكرى.
  final MadinahMemoryType type;

  /// عنوان اختياري يظهر في صفحة ذكريات المدينة.
  final String title;

  /// النص الذي كتبته المستخدمة.
  final String text;

  /// وقت إنشاء الذكرى.
  final DateTime createdAt;

  /// الذكريات خاصة افتراضيًا.
  final bool isPrivate;

  /// هل الذكرى مفضلة؟
  final bool isFavorite;

  /// اسم الشاشة أو الجزء الذي جاءت منه الذكرى.
  ///
  /// مثال:
  /// mosque_reflection
  /// rawdah_after
  /// prophetic_story
  final String? source;

  /// ID القصة إذا كانت الذكرى مرتبطة بقصة نبوية.
  final String? storyId;

  /// الخُلق أو المعنى الذي اختارته المستخدمة
  /// بعد قراءة قصة عن النبي ﷺ.
  ///
  /// مثال:
  /// الرحمة
  /// الرفق
  /// التواضع
  final String? learnedValue;

  /// يمكن استخدامها مستقبلًا عند مزامنة البيانات
  /// مع الـBackend.
  final bool isSynced;

  const MadinahMemory({
    required this.id,
    required this.type,
    required this.title,
    required this.text,
    required this.createdAt,
    this.isPrivate = true,
    this.isFavorite = false,
    this.source,
    this.storyId,
    this.learnedValue,
    this.isSynced = false,
  });

  // ============================================================
  // HELPERS
  // ============================================================

  bool get hasText {
    return text.trim().isNotEmpty;
  }

  bool get isFromPropheticStory {
    return type == MadinahMemoryType.propheticStory || storyId != null;
  }

  bool get hasLearnedValue {
    return learnedValue != null && learnedValue!.trim().isNotEmpty;
  }

  String get displayTitle {
    if (title.trim().isNotEmpty) {
      return title.trim();
    }

    return type.label;
  }

  String get displayEmoji {
    return type.emoji;
  }

  /// نص صغير يمكن استخدامه في Cards.
  String get preview {
    final value = text.trim();

    if (value.length <= 100) {
      return value;
    }

    return '${value.substring(0, 100)}...';
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  MadinahMemory copyWith({
    String? id,
    MadinahMemoryType? type,
    String? title,
    String? text,
    DateTime? createdAt,
    bool? isPrivate,
    bool? isFavorite,
    String? source,
    String? storyId,
    String? learnedValue,
    bool? isSynced,
    bool clearSource = false,
    bool clearStoryId = false,
    bool clearLearnedValue = false,
  }) {
    return MadinahMemory(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isPrivate: isPrivate ?? this.isPrivate,
      isFavorite: isFavorite ?? this.isFavorite,
      source: clearSource ? null : source ?? this.source,
      storyId: clearStoryId ? null : storyId ?? this.storyId,
      learnedValue:
          clearLearnedValue ? null : learnedValue ?? this.learnedValue,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'isPrivate': isPrivate,
      'isFavorite': isFavorite,
      'source': source,
      'storyId': storyId,
      'learnedValue': learnedValue,
      'isSynced': isSynced,
    };
  }

  factory MadinahMemory.fromJson(
    Map<String, dynamic> json,
  ) {
    return MadinahMemory(
      id: json['id'] as String,
      type: _memoryTypeFromString(
        json['type'] as String?,
      ),
      title: json['title'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(
            json['createdAt'] as String? ?? '',
          ) ??
          DateTime.now(),
      isPrivate: json['isPrivate'] as bool? ?? true,
      isFavorite: json['isFavorite'] as bool? ?? false,
      source: json['source'] as String?,
      storyId: json['storyId'] as String?,
      learnedValue: json['learnedValue'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }

  static MadinahMemoryType _memoryTypeFromString(
    String? value,
  ) {
    for (final type in MadinahMemoryType.values) {
      if (type.name == value) {
        return type;
      }
    }

    return MadinahMemoryType.personalMoment;
  }

  // ============================================================
  // FACTORY HELPERS
  // ============================================================

  /// ذكرى بعد زيارة المسجد النبوي.
  factory MadinahMemory.mosqueReflection({
    required String id,
    required String text,
  }) {
    return MadinahMemory(
      id: id,
      type: MadinahMemoryType.prophetMosque,
      title: 'كلمة من قلبي',
      text: text,
      createdAt: DateTime.now(),
      source: 'mosque_reflection',
    );
  }

  /// ذكرى بعد زيارة الروضة.
  factory MadinahMemory.rawdahReflection({
    required String id,
    required String text,
  }) {
    return MadinahMemory(
      id: id,
      type: MadinahMemoryType.rawdah,
      title: 'أثر من الروضة',
      text: text,
      createdAt: DateTime.now(),
      source: 'rawdah_after',
    );
  }

  /// ذكرى مرتبطة بقصة موثقة من السيرة.
  factory MadinahMemory.fromPropheticStory({
    required String id,
    required String storyId,
    required String storyTitle,
    required String reflection,
    String? learnedValue,
  }) {
    return MadinahMemory(
      id: id,
      type: MadinahMemoryType.propheticStory,
      title: storyTitle,
      text: reflection,
      createdAt: DateTime.now(),
      source: 'prophetic_story',
      storyId: storyId,
      learnedValue: learnedValue,
    );
  }

  /// رسالة خاصة للمستخدمة نفسها.
  factory MadinahMemory.letter({
    required String id,
    required String text,
  }) {
    return MadinahMemory(
      id: id,
      type: MadinahMemoryType.letterToMyself,
      title: 'إلى نفسي عندما أعود...',
      text: text,
      createdAt: DateTime.now(),
      source: 'letter_to_myself',
    );
  }

  @override
  String toString() {
    return 'MadinahMemory('
        'id: $id, '
        'type: ${type.name}, '
        'title: $displayTitle, '
        'private: $isPrivate'
        ')';
  }
}
