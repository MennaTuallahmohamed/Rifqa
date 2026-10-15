import '../haramain_live_models.dart';

enum HaramainAssistantIntent {
  nearestToilet,
  nearestWater,
  nearestGate,
  myGate,
  meetingPoint,
  lost,
  wheelchair,
  womenPrayer,
  medical,
  unknown,
}

class HaramainAssistant {
  HaramainAssistantIntent parse(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return HaramainAssistantIntent.unknown;
    bool has(List<String> parts) => parts.any(q.contains);

    if (has(['تائه', 'ضعت', 'ضايع', 'أنا تائه'])) {
      return HaramainAssistantIntent.lost;
    }
    if (has(['كرسي', 'wheelchair', 'ميسّر', 'ميسر', 'إعاقة', 'اعاقة'])) {
      return HaramainAssistantIntent.wheelchair;
    }
    if (has(['بابي', 'باب دخولي', 'رجعيني'])) {
      return HaramainAssistantIntent.myGate;
    }
    if (has(['تجمع', 'نقطة التجمع', 'رفاقي'])) {
      return HaramainAssistantIntent.meetingPoint;
    }
    if (has(['دورة', 'حمام', 'تواليت'])) {
      return HaramainAssistantIntent.nearestToilet;
    }
    if (has(['زمزم', 'مياه', 'ماء'])) {
      return HaramainAssistantIntent.nearestWater;
    }
    if (has(['نساء', 'مصلى نساء', 'حريم'])) {
      return HaramainAssistantIntent.womenPrayer;
    }
    if (has(['إسعاف', 'اسعاف', 'طبي'])) {
      return HaramainAssistantIntent.medical;
    }
    if (has(['باب', 'مدخل'])) {
      return HaramainAssistantIntent.nearestGate;
    }
    return HaramainAssistantIntent.unknown;
  }

  HlCategory? categoryFor(HaramainAssistantIntent intent) => switch (intent) {
        HaramainAssistantIntent.nearestToilet => HlCategory.toilet,
        HaramainAssistantIntent.nearestWater => HlCategory.water,
        HaramainAssistantIntent.nearestGate => HlCategory.gate,
        HaramainAssistantIntent.womenPrayer => HlCategory.women,
        HaramainAssistantIntent.medical => HlCategory.medical,
        HaramainAssistantIntent.wheelchair => HlCategory.accessibility,
        _ => null,
      };

  String replyFor(HaramainAssistantIntent intent) => switch (intent) {
        HaramainAssistantIntent.lost =>
          'وضعتُك في وضع «أنا تائه». اختر أقرب إجراء بسيط.',
        HaramainAssistantIntent.myGate => 'أعرض باب دخولك المحفوظ إن وُجد.',
        HaramainAssistantIntent.meetingPoint =>
          'أعرض نقطة التجمع المحفوظة إن وُجدت.',
        HaramainAssistantIntent.wheelchair =>
          'أفعّل وضع الكرسي المتحرك وأعرض الخدمات الموثّقة فقط.',
        HaramainAssistantIntent.nearestToilet =>
          'أبحث عن دورات المياه المعروفة على الخريطة.',
        HaramainAssistantIntent.nearestWater =>
          'أبحث عن نقاط المياه / زمزم المعروفة.',
        HaramainAssistantIntent.nearestGate => 'أبحث عن الأبواب المعروفة.',
        HaramainAssistantIntent.womenPrayer => 'أبحث عن مصليات النساء.',
        HaramainAssistantIntent.medical => 'أبحث عن نقاط الإسعاف المعروفة.',
        HaramainAssistantIntent.unknown =>
          'يمكنني المساعدة في: أقرب دورة مياه، بابي، نقطة التجمع، أنا تائه، كرسي متحرك، المياه.',
      };
}
