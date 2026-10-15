class AccessibilityProfile {
  final bool wheelchairMode;
  final bool largeText;
  final bool voiceGuidance;
  final bool highContrast;
  final bool reduceVisualComplexity;

  const AccessibilityProfile({
    this.wheelchairMode = false,
    this.largeText = false,
    this.voiceGuidance = true,
    this.highContrast = false,
    this.reduceVisualComplexity = false,
  });

  bool get hasCustomNeeds =>
      wheelchairMode || largeText || highContrast || reduceVisualComplexity;

  AccessibilityProfile copyWith({
    bool? wheelchairMode,
    bool? largeText,
    bool? voiceGuidance,
    bool? highContrast,
    bool? reduceVisualComplexity,
  }) {
    return AccessibilityProfile(
      wheelchairMode: wheelchairMode ?? this.wheelchairMode,
      largeText: largeText ?? this.largeText,
      voiceGuidance: voiceGuidance ?? this.voiceGuidance,
      highContrast: highContrast ?? this.highContrast,
      reduceVisualComplexity:
          reduceVisualComplexity ?? this.reduceVisualComplexity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wheelchairMode': wheelchairMode,
      'largeText': largeText,
      'voiceGuidance': voiceGuidance,
      'highContrast': highContrast,
      'reduceVisualComplexity': reduceVisualComplexity,
    };
  }

  factory AccessibilityProfile.fromJson(
    Map<String, dynamic> json,
  ) {
    return AccessibilityProfile(
      wheelchairMode: json['wheelchairMode'] as bool? ?? false,
      largeText: json['largeText'] as bool? ?? false,
      voiceGuidance: json['voiceGuidance'] as bool? ?? true,
      highContrast: json['highContrast'] as bool? ?? false,
      reduceVisualComplexity:
          json['reduceVisualComplexity'] as bool? ?? false,
    );
  }
}