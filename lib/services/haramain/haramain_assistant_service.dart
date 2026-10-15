/// Deterministic contextual assistant for the Haramain map.
///
/// This is NOT an open AI chatbot and does not pretend to be one. It maps a
/// small, explicit set of intents to deterministic application actions, so the
/// same question always produces the same, verifiable behaviour.
///
/// The [HaramainAssistantBackend] seam is where a real AI service will be
/// plugged in later. When that happens the intent enum stays the contract, so
/// the UI and every action below keep working unchanged.
library;

import '../../models/haramain/haramain_map_demo_models.dart';
import '../../screens/haramain/haramain_live_models.dart';
import 'haramain_arabic_text.dart';

enum HmAssistantIntent {
  nearestToilet,
  nearestWater,
  nearestGate,
  nearestElevator,
  womenPrayer,
  medical,
  information,
  accessibleRoute,
  myGate,
  meetingPoint,
  myHotel,
  myLocation,
  lost,
  umrahContext,
  unknown,
}

/// A resolved assistant action the host screen must execute.
class HmAssistantPlan {
  const HmAssistantPlan({
    required this.intent,
    required this.utterance,
    this.category,
    this.enableWheelchairMode = false,
    this.speakReply = true,
  });

  final HmAssistantIntent intent;

  /// Arabic sentence spoken and shown to the pilgrim.
  final String utterance;

  /// Category to highlight/filter, when the intent maps to one.
  final HlCategory? category;

  /// True when the intent asks to turn wheelchair mode on.
  final bool enableWheelchairMode;

  final bool speakReply;
}

/// Replaceable backend. The local implementation is deterministic.
abstract class HaramainAssistantBackend {
  Future<HmAssistantPlan> resolve(String query);
}

/// Deterministic, offline, rule-based backend.
class LocalHaramainAssistantBackend implements HaramainAssistantBackend {
  const LocalHaramainAssistantBackend();

  static const _suggestions = <String>[
    'أين أقرب دورة مياه؟',
    'أين بابي؟',
    'أريد نقطة التجمع',
    'أنا تائه',
    'أحتاج طريق مناسب للكرسي المتحرك',
    'أين المياه؟',
    'أين أقرب مصعد؟',
    'أين مصلى النساء؟',
    'أين الإسعافات الأولية؟',
    'أين الفندق؟',
    'أين موقعي؟',
  ];

  List<String> get suggestions => _suggestions;

  @override
  Future<HmAssistantPlan> resolve(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      return const HmAssistantPlan(
        intent: HmAssistantIntent.unknown,
        utterance: 'اختر اقتراحًا أو اكتب طلبًا قصيرًا.',
        speakReply: false,
      );
    }

    bool has(List<String> parts) =>
        parts.any((p) => HmArabic.contains(q, p));

    // ── Safety-critical intents first ─────────────────────────────
    if (has(['تائه', 'ضايع', 'ضعت', 'تايه', 'lost', 'محتاج مساع'])) {
      return const HmAssistantPlan(
        intent: HmAssistantIntent.lost,
        utterance:
            'افتحت لك وضع «أنا تائه». فيه أزرار كبيرة لموقعك وبابك ونقطة '
            'التجمع والفندق، وبطاقة مساعدة يمكنك عرضها على من حولك.',
      );
    }

    if (has(['كرسي', 'wheelchair', 'ذوي الهمم', 'ذي الهمم', 'Accessible', 'مساعده'])) {
      return const HmAssistantPlan(
        intent: HmAssistantIntent.accessibleRoute,
        utterance:
            'فعلت وضع الكرسي المتحرك. سأعرض الخدمات الميسّرة الموثّقة فقط، '
            'ولن أقترح أي مسار غير موثّق أنه ميسّر.',
        enableWheelchairMode: true,
        category: HlCategory.accessibility,
      );
    }

    // ── Personal places ───────────────────────────────────────────
    if (has(['بابي', 'باب دخولي', 'رجعيني', 'my gate'])) {
      return const HmAssistantPlan(
        intent: HmAssistantIntent.myGate,
        utterance: 'أحاول عرض باب دخولك المحفوظ على الخريطة.',
      );
    }
    if (has(['تجمع', 'نقطة تجمع', 'رفاق', 'meeting'])) {
      return const HmAssistantPlan(
        intent: HmAssistantIntent.meetingPoint,
        utterance: 'أحاول عرض نقطة التجمع المحفوظة.',
      );
    }
    if (has(['فندق', 'hotel', 'الاقامة', 'إقامة'])) {
      return const HmAssistantPlan(
        intent: HmAssistantIntent.myHotel,
        utterance: 'أحاول عرض فندقك المحفوظ.',
      );
    }
    if (has(['موقعي', 'اين انا', 'where am i'])) {
      return const HmAssistantPlan(
        intent: HmAssistantIntent.myLocation,
        utterance: 'سأحدد موقعك على الخريطة.',
      );
    }

    // ── Service lookups ───────────────────────────────────────────
    if (has(['دوره مياه', 'دورات مياه', 'حمام', 'مرحاض', 'toilet', 'wc'])) {
      return const HmAssistantPlan(
        intent: HmAssistantIntent.nearestToilet,
        utterance: 'أبحث عن أقرب دورة مياه موثّقة في بيانات هذا الحرم.',
        category: HlCategory.toilet,
      );
    }
    if (has(['زمزم', 'ماء', 'مياه', 'water', 'zamzam', 'شرب'])) {
      return const HmAssistantPlan(
        intent: HmAssistantIntent.nearestWater,
        utterance: 'أبحث عن أقرب نقطة مياه أو زمزم.',
        category: HlCategory.water,
      );
    }
    if (has(['مصعد', 'مصاعد', 'elevator', 'lift'])) {
      return const HmAssistantPlan(
        intent: HmAssistantIntent.nearestElevator,
        utterance: 'أبحث عن أقرب مصعد.',
        category: HlCategory.elevator,
      );
    }
    if (has(['نساء', 'مصلي نساء', 'prayer'])) {
      return const HmAssistantPlan(
        intent: HmAssistantIntent.womenPrayer,
        utterance: 'أبحث عن مصليات النساء.',
        category: HlCategory.women,
      );
    }
    if (has(['اسعاف', 'طبي', 'صحيه', 'medical'])) {
      return const HmAssistantPlan(
        intent: HmAssistantIntent.medical,
        utterance: 'أبحث عن أقرب نقطة إسعافات أولية.',
        category: HlCategory.medical,
      );
    }
    if (has(['استعلامات', 'ارشاد', 'معلومات', 'info', 'help'])) {
      return const HmAssistantPlan(
        intent: HmAssistantIntent.information,
        utterance: 'أبحث عن مراكز الاستعلامات والإرشاد.',
        category: HlCategory.info,
      );
    }
    if (has(['باب', 'ابواب', 'بوابه', 'gate'])) {
      return const HmAssistantPlan(
        intent: HmAssistantIntent.nearestGate,
        utterance: 'أبحث عن الأبواب المعروفة.',
        category: HlCategory.gate,
      );
    }
    if (has(['عمرة', 'الصفا', 'المروه', 'مسعي', 'طواف'])) {
      return const HmAssistantPlan(
        intent: HmAssistantIntent.umrahContext,
        utterance:
            'افتحت لك سياق العمرة: الوصول والطواف والسعي والخدمات أثناء العمرة.',
      );
    }

    return const HmAssistantPlan(
      intent: HmAssistantIntent.unknown,
      utterance:
          'لم أفهم الطلب تمامًا. أستطيع المساعدة في: أقرب دورة مياه، بابي، '
          'نقطة التجمع، الفندق، أنا تائه، طريق مناسب للكرسي المتحرك، '
          'المياه، المصاعد، الإسعافات، وسياق العمرة.',
      speakReply: false,
    );
  }
}

/// Which site the assistant is answering for. Kept as a parameter so the same
/// backend serves Makkah and Madinah.
typedef AssistantSiteProvider = HaramainSite Function();