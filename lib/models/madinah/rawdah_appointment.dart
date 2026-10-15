enum RawdahAppointmentStatus {
  notSet,
  upcoming,
  today,
  completed,
  missed,
}

class RawdahAppointment {
  final DateTime dateTime;

  /// المستخدم هو الذي يؤكد أن لديه تصريحًا رسميًا.
  /// رِفقة لا تصدر التصريح ولا تتحقق منه.
  final bool hasOfficialPermit;

  /// هل أكدت المستخدمة أنها استعدت للزيارة؟
  final bool preparationCompleted;

  /// هل أكملت "وقفة صدق"؟
  final bool sidqPauseCompleted;

  /// هل جهزت حقيبة الدعاء؟
  final bool prayerBagPrepared;

  /// هل راجعت أمانات الدعاء؟
  final bool prayerTrustsReviewed;

  /// هل أكدت أنها وصلت إلى منطقة الانتظار؟
  final bool waitingStarted;

  /// هل دخلت وضع السكينة الخاص بالروضة؟
  final bool quietModeStarted;

  /// هل أكدت انتهاء الزيارة؟
  final bool visitCompleted;

  /// وقت انتهاء الزيارة، إن كانت قد انتهت.
  final DateTime? completedAt;

  const RawdahAppointment({
    required this.dateTime,
    this.hasOfficialPermit = false,
    this.preparationCompleted = false,
    this.sidqPauseCompleted = false,
    this.prayerBagPrepared = false,
    this.prayerTrustsReviewed = false,
    this.waitingStarted = false,
    this.quietModeStarted = false,
    this.visitCompleted = false,
    this.completedAt,
  });

  // ============================================================
  // STATUS
  // ============================================================

  RawdahAppointmentStatus status({
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();

    if (visitCompleted) {
      return RawdahAppointmentStatus.completed;
    }

    final appointmentDay = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    final currentDay = DateTime(
      current.year,
      current.month,
      current.day,
    );

    if (appointmentDay == currentDay) {
      return RawdahAppointmentStatus.today;
    }

    if (dateTime.isAfter(current)) {
      return RawdahAppointmentStatus.upcoming;
    }

    return RawdahAppointmentStatus.missed;
  }

  // ============================================================
  // TIME HELPERS
  // ============================================================

  Duration timeRemaining({
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();

    if (dateTime.isBefore(current)) {
      return Duration.zero;
    }

    return dateTime.difference(current);
  }

  bool get isCompleted {
    return visitCompleted;
  }

  bool get hasStartedJourney {
    return sidqPauseCompleted ||
        prayerBagPrepared ||
        prayerTrustsReviewed ||
        waitingStarted ||
        quietModeStarted;
  }

  bool get isFullyPrepared {
    return hasOfficialPermit &&
        sidqPauseCompleted &&
        prayerBagPrepared &&
        prayerTrustsReviewed;
  }

  // ============================================================
  // JOURNEY PROGRESS
  // ============================================================

  int get completedPreparationSteps {
    var completed = 0;

    if (hasOfficialPermit) {
      completed++;
    }

    if (sidqPauseCompleted) {
      completed++;
    }

    if (prayerBagPrepared) {
      completed++;
    }

    if (prayerTrustsReviewed) {
      completed++;
    }

    return completed;
  }

  int get totalPreparationSteps {
    return 4;
  }

  double get preparationProgress {
    return completedPreparationSteps / totalPreparationSteps;
  }

  // ============================================================
  // NEXT STEP
  // ============================================================

  String get nextStepTitle {
    if (!hasOfficialPermit) {
      return 'راجعي تصريح الزيارة';
    }

    if (!sidqPauseCompleted) {
      return 'وقفة صدق';
    }

    if (!prayerBagPrepared) {
      return 'جهزي حقيبة دعائك';
    }

    if (!prayerTrustsReviewed) {
      return 'راجعي أمانات الدعاء';
    }

    if (!waitingStarted) {
      return 'استعدي للموعد';
    }

    if (!quietModeStarted) {
      return 'انتظار بسكينة';
    }

    if (!visitCompleted) {
      return 'عيشي اللحظة';
    }

    return 'ثبتي الأثر';
  }

  String get nextStepSubtitle {
    if (!hasOfficialPermit) {
      return 'التصريح يتم من خلال القناة الرسمية المعتمدة.';
    }

    if (!sidqPauseCompleted) {
      return 'دقائق هادئة للتوبة والنية والسكينة.';
    }

    if (!prayerBagPrepared) {
      return 'حتى لا تبحثي عما تريدين الدعاء به وقت الزيارة.';
    }

    if (!prayerTrustsReviewed) {
      return 'تذكري من حملوك أمانات دعائهم.';
    }

    if (!waitingStarted) {
      return 'راجعي استعدادك واتركي ما يشغلك.';
    }

    if (!quietModeStarted) {
      return 'اجعلي وقت الانتظار أكثر هدوءًا.';
    }

    if (!visitCompleted) {
      return 'رِفقة ستبتعد الآن... لتبقى اللحظة لكِ.';
    }

    return 'ماذا تريدين أن يبقى في قلبك بعد الزيارة؟';
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  RawdahAppointment copyWith({
    DateTime? dateTime,
    bool? hasOfficialPermit,
    bool? preparationCompleted,
    bool? sidqPauseCompleted,
    bool? prayerBagPrepared,
    bool? prayerTrustsReviewed,
    bool? waitingStarted,
    bool? quietModeStarted,
    bool? visitCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return RawdahAppointment(
      dateTime: dateTime ?? this.dateTime,
      hasOfficialPermit: hasOfficialPermit ?? this.hasOfficialPermit,
      preparationCompleted: preparationCompleted ?? this.preparationCompleted,
      sidqPauseCompleted: sidqPauseCompleted ?? this.sidqPauseCompleted,
      prayerBagPrepared: prayerBagPrepared ?? this.prayerBagPrepared,
      prayerTrustsReviewed: prayerTrustsReviewed ?? this.prayerTrustsReviewed,
      waitingStarted: waitingStarted ?? this.waitingStarted,
      quietModeStarted: quietModeStarted ?? this.quietModeStarted,
      visitCompleted: visitCompleted ?? this.visitCompleted,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    );
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'hasOfficialPermit': hasOfficialPermit,
      'preparationCompleted': preparationCompleted,
      'sidqPauseCompleted': sidqPauseCompleted,
      'prayerBagPrepared': prayerBagPrepared,
      'prayerTrustsReviewed': prayerTrustsReviewed,
      'waitingStarted': waitingStarted,
      'quietModeStarted': quietModeStarted,
      'visitCompleted': visitCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory RawdahAppointment.fromJson(
    Map<String, dynamic> json,
  ) {
    return RawdahAppointment(
      dateTime: DateTime.parse(
        json['dateTime'] as String,
      ),
      hasOfficialPermit: json['hasOfficialPermit'] as bool? ?? false,
      preparationCompleted: json['preparationCompleted'] as bool? ?? false,
      sidqPauseCompleted: json['sidqPauseCompleted'] as bool? ?? false,
      prayerBagPrepared: json['prayerBagPrepared'] as bool? ?? false,
      prayerTrustsReviewed: json['prayerTrustsReviewed'] as bool? ?? false,
      waitingStarted: json['waitingStarted'] as bool? ?? false,
      quietModeStarted: json['quietModeStarted'] as bool? ?? false,
      visitCompleted: json['visitCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(
              json['completedAt'] as String,
            ),
    );
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'RawdahAppointment('
        'dateTime: $dateTime, '
        'permit: $hasOfficialPermit, '
        'progress: $completedPreparationSteps/'
        '$totalPreparationSteps, '
        'completed: $visitCompleted'
        ')';
  }
}
