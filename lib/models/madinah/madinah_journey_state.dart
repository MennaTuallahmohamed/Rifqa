enum MadinahJourneyPhase {
  notStarted,
  exploringMadinah,
  prophetMosque,
  preparingForRawdah,
  waitingForRawdah,
  insideRawdah,
  afterRawdah,
  completed,
}

enum ProphetMosqueStage {
  notStarted,
  onTheWay,
  arrived,
  inside,
  completed,
}

enum RawdahJourneyStage {
  notStarted,
  appointment,
  sidqPause,
  prayerBag,
  prayerTrusts,
  peacefulWaiting,
  adab,
  quietMode,
  afterVisit,
  completed,
}

extension MadinahJourneyPhaseX on MadinahJourneyPhase {
  String get label {
    switch (this) {
      case MadinahJourneyPhase.notStarted:
        return 'لم تبدأ الرحلة';

      case MadinahJourneyPhase.exploringMadinah:
        return 'في حضرة المدينة';

      case MadinahJourneyPhase.prophetMosque:
        return 'المسجد النبوي';

      case MadinahJourneyPhase.preparingForRawdah:
        return 'الاستعداد للروضة';

      case MadinahJourneyPhase.waitingForRawdah:
        return 'انتظار بسكينة';

      case MadinahJourneyPhase.insideRawdah:
        return 'لحظة الروضة';

      case MadinahJourneyPhase.afterRawdah:
        return 'ثبّتي الأثر';

      case MadinahJourneyPhase.completed:
        return 'ذكريات المدينة';
    }
  }

  String get emoji {
    switch (this) {
      case MadinahJourneyPhase.notStarted:
        return '🤍';

      case MadinahJourneyPhase.exploringMadinah:
        return '🌙';

      case MadinahJourneyPhase.prophetMosque:
        return '🕌';

      case MadinahJourneyPhase.preparingForRawdah:
        return '🌿';

      case MadinahJourneyPhase.waitingForRawdah:
        return '🤍';

      case MadinahJourneyPhase.insideRawdah:
        return '🌿';

      case MadinahJourneyPhase.afterRawdah:
        return '✨';

      case MadinahJourneyPhase.completed:
        return '📖';
    }
  }
}

extension ProphetMosqueStageX on ProphetMosqueStage {
  String get label {
    switch (this) {
      case ProphetMosqueStage.notStarted:
        return 'لم أبدأ بعد';

      case ProphetMosqueStage.onTheWay:
        return 'في طريقي للمسجد';

      case ProphetMosqueStage.arrived:
        return 'وصلت إلى المسجد';

      case ProphetMosqueStage.inside:
        return 'داخل المسجد';

      case ProphetMosqueStage.completed:
        return 'انتهيت من زيارتي';
    }
  }
}

extension RawdahJourneyStageX on RawdahJourneyStage {
  String get label {
    switch (this) {
      case RawdahJourneyStage.notStarted:
        return 'لم أبدأ بعد';

      case RawdahJourneyStage.appointment:
        return 'الموعد';

      case RawdahJourneyStage.sidqPause:
        return 'وقفة صدق';

      case RawdahJourneyStage.prayerBag:
        return 'حقيبة دعائي';

      case RawdahJourneyStage.prayerTrusts:
        return 'أمانات الدعاء';

      case RawdahJourneyStage.peacefulWaiting:
        return 'انتظار بسكينة';

      case RawdahJourneyStage.adab:
        return 'آداب ورفق';

      case RawdahJourneyStage.quietMode:
        return 'لحظة الروضة';

      case RawdahJourneyStage.afterVisit:
        return 'ثبّتي الأثر';

      case RawdahJourneyStage.completed:
        return 'تمت الزيارة';
    }
  }
}

class MadinahJourneyState {
  final MadinahJourneyPhase phase;

  final ProphetMosqueStage mosqueStage;

  final RawdahJourneyStage rawdahStage;

  /// هل زارت المستخدمة المسجد النبوي؟
  final bool prophetMosqueVisited;

  /// هل أكملت زيارة الروضة؟
  final bool rawdahVisited;

  /// هل فتحت قسم حكايات النبي ﷺ؟
  final bool propheticStoriesStarted;

  /// عدد القصص التي قرأتها.
  final int propheticStoriesRead;

  /// IDs القصص التي قرأتها.
  final List<String> readStoryIds;

  /// المعاني التي اختارت الاحتفاظ بها
  /// بعد قراءة القصص.
  ///
  /// مثال:
  /// الرحمة
  /// الرفق
  /// التواضع
  final List<String> carriedValues;

  /// هل استخدمت مكتبة الصلاة والسلام؟
  final bool salawatStarted;

  /// عدد الصيغ المختلفة التي حفظتها كمفضلة.
  ///
  /// هذا ليس عداد عبادة أو نظام نقاط.
  /// هو فقط لحفظ تفضيلات المحتوى.
  final List<String> favoriteSalawatIds;

  /// هل كتبت رسالة لنفسها؟
  final bool wroteLetterToSelf;

  /// هل كتبت ذكرى من المسجد؟
  final bool wroteMosqueMemory;

  /// هل كتبت ذكرى من الروضة؟
  final bool wroteRawdahMemory;

  /// هل فتحت صفحة الليلة الأخيرة؟
  final bool openedLastNight;

  /// بداية رحلة المدينة.
  final DateTime? startedAt;

  /// نهاية الرحلة إن اختارت إنهاءها.
  final DateTime? completedAt;

  const MadinahJourneyState({
    this.phase = MadinahJourneyPhase.notStarted,
    this.mosqueStage = ProphetMosqueStage.notStarted,
    this.rawdahStage = RawdahJourneyStage.notStarted,
    this.prophetMosqueVisited = false,
    this.rawdahVisited = false,
    this.propheticStoriesStarted = false,
    this.propheticStoriesRead = 0,
    this.readStoryIds = const [],
    this.carriedValues = const [],
    this.salawatStarted = false,
    this.favoriteSalawatIds = const [],
    this.wroteLetterToSelf = false,
    this.wroteMosqueMemory = false,
    this.wroteRawdahMemory = false,
    this.openedLastNight = false,
    this.startedAt,
    this.completedAt,
  });

  // ============================================================
  // DEFAULT STATE
  // ============================================================

  factory MadinahJourneyState.initial() {
    return const MadinahJourneyState();
  }

  // ============================================================
  // GENERAL HELPERS
  // ============================================================

  bool get hasStarted {
    return phase != MadinahJourneyPhase.notStarted;
  }

  bool get isCompleted {
    return phase == MadinahJourneyPhase.completed;
  }

  bool get hasVisitedAnySacredPlace {
    return prophetMosqueVisited || rawdahVisited;
  }

  bool get hasMemories {
    return wroteMosqueMemory ||
        wroteRawdahMemory ||
        wroteLetterToSelf ||
        carriedValues.isNotEmpty;
  }

  bool get hasStartedSpiritualContent {
    return propheticStoriesStarted || salawatStarted;
  }

  // ============================================================
  // STORY HELPERS
  // ============================================================

  bool hasReadStory(String storyId) {
    return readStoryIds.contains(storyId);
  }

  bool hasCarriedValue(String value) {
    return carriedValues.contains(value);
  }

  MadinahJourneyState markStoryRead({
    required String storyId,
  }) {
    if (readStoryIds.contains(storyId)) {
      return this;
    }

    final updatedIds = [
      ...readStoryIds,
      storyId,
    ];

    return copyWith(
      propheticStoriesStarted: true,
      propheticStoriesRead: updatedIds.length,
      readStoryIds: updatedIds,
    );
  }

  MadinahJourneyState addCarriedValue(
    String value,
  ) {
    final cleanValue = value.trim();

    if (cleanValue.isEmpty) {
      return this;
    }

    if (carriedValues.contains(cleanValue)) {
      return this;
    }

    return copyWith(
      carriedValues: [
        ...carriedValues,
        cleanValue,
      ],
    );
  }

  MadinahJourneyState removeCarriedValue(
    String value,
  ) {
    return copyWith(
      carriedValues: carriedValues.where((item) => item != value).toList(),
    );
  }

  // ============================================================
  // SALAWAT HELPERS
  // ============================================================

  bool isFavoriteSalawat(String id) {
    return favoriteSalawatIds.contains(id);
  }

  MadinahJourneyState toggleFavoriteSalawat(
    String id,
  ) {
    final updated = List<String>.from(
      favoriteSalawatIds,
    );

    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }

    return copyWith(
      salawatStarted: true,
      favoriteSalawatIds: updated,
    );
  }

  // ============================================================
  // JOURNEY HELPERS
  // ============================================================

  MadinahJourneyState startJourney() {
    if (hasStarted) {
      return this;
    }

    return copyWith(
      phase: MadinahJourneyPhase.exploringMadinah,
      startedAt: DateTime.now(),
    );
  }

  MadinahJourneyState enterProphetMosqueJourney() {
    return copyWith(
      phase: MadinahJourneyPhase.prophetMosque,
      mosqueStage: mosqueStage == ProphetMosqueStage.notStarted
          ? ProphetMosqueStage.onTheWay
          : mosqueStage,
      startedAt: startedAt ?? DateTime.now(),
    );
  }

  MadinahJourneyState updateMosqueStage(
    ProphetMosqueStage stage,
  ) {
    return copyWith(
      phase: MadinahJourneyPhase.prophetMosque,
      mosqueStage: stage,
      prophetMosqueVisited:
          stage == ProphetMosqueStage.completed ? true : prophetMosqueVisited,
    );
  }

  MadinahJourneyState enterRawdahJourney() {
    return copyWith(
      phase: MadinahJourneyPhase.preparingForRawdah,
      rawdahStage: rawdahStage == RawdahJourneyStage.notStarted
          ? RawdahJourneyStage.appointment
          : rawdahStage,
      startedAt: startedAt ?? DateTime.now(),
    );
  }

  MadinahJourneyState updateRawdahStage(
    RawdahJourneyStage stage,
  ) {
    MadinahJourneyPhase newPhase = MadinahJourneyPhase.preparingForRawdah;

    if (stage == RawdahJourneyStage.peacefulWaiting ||
        stage == RawdahJourneyStage.adab) {
      newPhase = MadinahJourneyPhase.waitingForRawdah;
    }

    if (stage == RawdahJourneyStage.quietMode) {
      newPhase = MadinahJourneyPhase.insideRawdah;
    }

    if (stage == RawdahJourneyStage.afterVisit) {
      newPhase = MadinahJourneyPhase.afterRawdah;
    }

    if (stage == RawdahJourneyStage.completed) {
      newPhase = MadinahJourneyPhase.afterRawdah;
    }

    return copyWith(
      phase: newPhase,
      rawdahStage: stage,
      rawdahVisited:
          stage == RawdahJourneyStage.completed ? true : rawdahVisited,
    );
  }

  MadinahJourneyState completeJourney() {
    return copyWith(
      phase: MadinahJourneyPhase.completed,
      completedAt: DateTime.now(),
    );
  }

  // ============================================================
  // CONTINUE JOURNEY
  // ============================================================

  String get continueTitle {
    if (!hasStarted) {
      return 'ابدئي رحلتك في المدينة';
    }

    if (phase == MadinahJourneyPhase.prophetMosque) {
      return mosqueStage.label;
    }

    if (phase == MadinahJourneyPhase.preparingForRawdah ||
        phase == MadinahJourneyPhase.waitingForRawdah ||
        phase == MadinahJourneyPhase.insideRawdah ||
        phase == MadinahJourneyPhase.afterRawdah) {
      return rawdahStage.label;
    }

    if (phase == MadinahJourneyPhase.completed) {
      return 'ذكريات المدينة';
    }

    return 'في حضرة المدينة';
  }

  String get continueSubtitle {
    switch (phase) {
      case MadinahJourneyPhase.notStarted:
        return 'المسجد النبوي، الروضة، وحكايات تبقى في القلب.';

      case MadinahJourneyPhase.exploringMadinah:
        return 'اختاري أين تحبين أن تكملي رحلتك.';

      case MadinahJourneyPhase.prophetMosque:
        return 'صحبتك الهادئة في المسجد النبوي.';

      case MadinahJourneyPhase.preparingForRawdah:
        return 'استعدي قبل الموعد حتى يكون وقتك هناك للحظة نفسها.';

      case MadinahJourneyPhase.waitingForRawdah:
        return 'انتظري بهدوء، بلا استعجال ولا تشتيت.';

      case MadinahJourneyPhase.insideRawdah:
        return 'رِفقة ستبتعد الآن... لتبقى اللحظة لكِ.';

      case MadinahJourneyPhase.afterRawdah:
        return 'احتفظي بما تريدين أن يبقى معك بعد الزيارة.';

      case MadinahJourneyPhase.completed:
        return 'عودي إلى الكلمات والمعاني التي أخذتها معك.';
    }
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  MadinahJourneyState copyWith({
    MadinahJourneyPhase? phase,
    ProphetMosqueStage? mosqueStage,
    RawdahJourneyStage? rawdahStage,
    bool? prophetMosqueVisited,
    bool? rawdahVisited,
    bool? propheticStoriesStarted,
    int? propheticStoriesRead,
    List<String>? readStoryIds,
    List<String>? carriedValues,
    bool? salawatStarted,
    List<String>? favoriteSalawatIds,
    bool? wroteLetterToSelf,
    bool? wroteMosqueMemory,
    bool? wroteRawdahMemory,
    bool? openedLastNight,
    DateTime? startedAt,
    DateTime? completedAt,
    bool clearStartedAt = false,
    bool clearCompletedAt = false,
  }) {
    return MadinahJourneyState(
      phase: phase ?? this.phase,
      mosqueStage: mosqueStage ?? this.mosqueStage,
      rawdahStage: rawdahStage ?? this.rawdahStage,
      prophetMosqueVisited: prophetMosqueVisited ?? this.prophetMosqueVisited,
      rawdahVisited: rawdahVisited ?? this.rawdahVisited,
      propheticStoriesStarted:
          propheticStoriesStarted ?? this.propheticStoriesStarted,
      propheticStoriesRead: propheticStoriesRead ?? this.propheticStoriesRead,
      readStoryIds: readStoryIds ?? this.readStoryIds,
      carriedValues: carriedValues ?? this.carriedValues,
      salawatStarted: salawatStarted ?? this.salawatStarted,
      favoriteSalawatIds: favoriteSalawatIds ?? this.favoriteSalawatIds,
      wroteLetterToSelf: wroteLetterToSelf ?? this.wroteLetterToSelf,
      wroteMosqueMemory: wroteMosqueMemory ?? this.wroteMosqueMemory,
      wroteRawdahMemory: wroteRawdahMemory ?? this.wroteRawdahMemory,
      openedLastNight: openedLastNight ?? this.openedLastNight,
      startedAt: clearStartedAt ? null : startedAt ?? this.startedAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    );
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'phase': phase.name,
      'mosqueStage': mosqueStage.name,
      'rawdahStage': rawdahStage.name,
      'prophetMosqueVisited': prophetMosqueVisited,
      'rawdahVisited': rawdahVisited,
      'propheticStoriesStarted': propheticStoriesStarted,
      'propheticStoriesRead': propheticStoriesRead,
      'readStoryIds': readStoryIds,
      'carriedValues': carriedValues,
      'salawatStarted': salawatStarted,
      'favoriteSalawatIds': favoriteSalawatIds,
      'wroteLetterToSelf': wroteLetterToSelf,
      'wroteMosqueMemory': wroteMosqueMemory,
      'wroteRawdahMemory': wroteRawdahMemory,
      'openedLastNight': openedLastNight,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory MadinahJourneyState.fromJson(
    Map<String, dynamic> json,
  ) {
    return MadinahJourneyState(
      phase: _phaseFromString(
        json['phase'] as String?,
      ),
      mosqueStage: _mosqueStageFromString(
        json['mosqueStage'] as String?,
      ),
      rawdahStage: _rawdahStageFromString(
        json['rawdahStage'] as String?,
      ),
      prophetMosqueVisited: json['prophetMosqueVisited'] as bool? ?? false,
      rawdahVisited: json['rawdahVisited'] as bool? ?? false,
      propheticStoriesStarted:
          json['propheticStoriesStarted'] as bool? ?? false,
      propheticStoriesRead: json['propheticStoriesRead'] as int? ?? 0,
      readStoryIds: _stringList(
        json['readStoryIds'],
      ),
      carriedValues: _stringList(
        json['carriedValues'],
      ),
      salawatStarted: json['salawatStarted'] as bool? ?? false,
      favoriteSalawatIds: _stringList(
        json['favoriteSalawatIds'],
      ),
      wroteLetterToSelf: json['wroteLetterToSelf'] as bool? ?? false,
      wroteMosqueMemory: json['wroteMosqueMemory'] as bool? ?? false,
      wroteRawdahMemory: json['wroteRawdahMemory'] as bool? ?? false,
      openedLastNight: json['openedLastNight'] as bool? ?? false,
      startedAt: _dateFromJson(
        json['startedAt'],
      ),
      completedAt: _dateFromJson(
        json['completedAt'],
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

  static DateTime? _dateFromJson(dynamic value) {
    if (value is! String) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static MadinahJourneyPhase _phaseFromString(
    String? value,
  ) {
    for (final item in MadinahJourneyPhase.values) {
      if (item.name == value) {
        return item;
      }
    }

    return MadinahJourneyPhase.notStarted;
  }

  static ProphetMosqueStage _mosqueStageFromString(
    String? value,
  ) {
    for (final item in ProphetMosqueStage.values) {
      if (item.name == value) {
        return item;
      }
    }

    return ProphetMosqueStage.notStarted;
  }

  static RawdahJourneyStage _rawdahStageFromString(
    String? value,
  ) {
    for (final item in RawdahJourneyStage.values) {
      if (item.name == value) {
        return item;
      }
    }

    return RawdahJourneyStage.notStarted;
  }

  @override
  String toString() {
    return 'MadinahJourneyState('
        'phase: ${phase.name}, '
        'mosque: ${mosqueStage.name}, '
        'rawdah: ${rawdahStage.name}, '
        'stories: $propheticStoriesRead'
        ')';
  }
}
