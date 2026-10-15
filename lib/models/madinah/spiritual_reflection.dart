enum SpiritualReflectionType {
  beforeMosque,
  insideMosque,
  beforeRawdah,
  afterRawdah,
  afterPropheticStory,
  lastNight,
  letterToSelf,
}

extension SpiritualReflectionTypeX on SpiritualReflectionType {
  String get label {
    switch (this) {
      case SpiritualReflectionType.beforeMosque:
        return 'قبل دخول المسجد';

      case SpiritualReflectionType.insideMosque:
        return 'في المسجد النبوي';

      case SpiritualReflectionType.beforeRawdah:
        return 'قبل الروضة';

      case SpiritualReflectionType.afterRawdah:
        return 'بعد الروضة';

      case SpiritualReflectionType.afterPropheticStory:
        return 'بعد الحكاية';

      case SpiritualReflectionType.lastNight:
        return 'ليلتي الأخيرة';

      case SpiritualReflectionType.letterToSelf:
        return 'رسالتي لنفسي';
    }
  }
}

class SpiritualReflection {
  final String id;

  final SpiritualReflectionType type;

  final String prompt;

  final String answer;

  final String? storyId;

  final String? carriedValue;

  final DateTime createdAt;

  final bool isPrivate;

  const SpiritualReflection({
    required this.id,
    required this.type,
    required this.prompt,
    required this.answer,
    this.storyId,
    this.carriedValue,
    required this.createdAt,
    this.isPrivate = true,
  });

  // ============================================================
  // HELPERS
  // ============================================================

  bool get hasAnswer {
    return answer.trim().isNotEmpty;
  }

  bool get isStoryReflection {
    return storyId != null && storyId!.trim().isNotEmpty;
  }

  bool get hasCarriedValue {
    return carriedValue != null && carriedValue!.trim().isNotEmpty;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  SpiritualReflection copyWith({
    String? id,
    SpiritualReflectionType? type,
    String? prompt,
    String? answer,
    String? storyId,
    String? carriedValue,
    DateTime? createdAt,
    bool? isPrivate,
  }) {
    return SpiritualReflection(
      id: id ?? this.id,
      type: type ?? this.type,
      prompt: prompt ?? this.prompt,
      answer: answer ?? this.answer,
      storyId: storyId ?? this.storyId,
      carriedValue: carriedValue ?? this.carriedValue,
      createdAt: createdAt ?? this.createdAt,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'prompt': prompt,
      'answer': answer,
      'storyId': storyId,
      'carriedValue': carriedValue,
      'createdAt': createdAt.toIso8601String(),
      'isPrivate': isPrivate,
    };
  }

  factory SpiritualReflection.fromJson(
    Map<String, dynamic> json,
  ) {
    return SpiritualReflection(
      id: json['id'] as String? ?? '',
      type: _typeFromString(
        json['type'] as String?,
      ),
      prompt: json['prompt'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      storyId: json['storyId'] as String?,
      carriedValue: json['carriedValue'] as String?,
      createdAt: DateTime.tryParse(
            json['createdAt'] as String? ?? '',
          ) ??
          DateTime.now(),
      isPrivate: json['isPrivate'] as bool? ?? true,
    );
  }

  // ============================================================
  // TYPE PARSER
  // ============================================================

  static SpiritualReflectionType _typeFromString(
    String? value,
  ) {
    for (final type in SpiritualReflectionType.values) {
      if (type.name == value) {
        return type;
      }
    }

    return SpiritualReflectionType.beforeMosque;
  }
}
