import 'package:flutter/material.dart';
import 'cinematic_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
//  بيانات الروضة الشريفة لتطبيق رِفقة
//
//  مصادر البيانات (كلها قابلة للتغيير، والمرجع النهائي دائمًا نسك):
//   [A] إنفوجرافيك «صحبة ترانزيت» الثلاثة  → مصدر غير رسمي (مواعيد فتح الحجز + المسار الفوري)
//   [B] صفحة الخدمة في نسك nusuk.sa/service-details/152 → رسمي (خطوات الحجز)
//   [C] تصريحات الهيئة العامة للعناية بشؤون الحرمين ووزارة الحج والعمرة كما نقلتها
//       عكاظ وسبق وKSA Expats (2026) → أوقات الزيارة وشروط الدخول
//
//  آخر مراجعة لهذه البيانات: أكتوبر 2026.
// ════════════════════════════════════════════════════════════════════════════

// ───────────────────────────── أدوات الوقت ─────────────────────────────

/// السعودية = UTC+3 طوال السنة (بلا توقيت صيفي).
const Duration kSaudiOffset = Duration(hours: 3);

const List<String> kWeekdaysAr = [
  'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
];

String two(int v) => v.toString().padLeft(2, '0');

/// يعرض الساعة والدقيقة الموجودتين في [t] كما هما (12 ساعة، ص/م) دون أي تحويل.
String fmtClock(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final suffix = t.hour < 12 ? 'ص' : 'م';
  return '${two(h)}:${two(t.minute)} $suffix';
}

String fmtDateAr(DateTime d) =>
    '${kWeekdaysAr[d.weekday - 1]} ${d.day}/${d.month}/${d.year}';

String fmtCountdown(Duration d) {
  if (d.isNegative) return '00:00:00';
  final days = d.inDays;
  final h = d.inHours % 24;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (days > 0) return '$days يوم  ${two(h)}:${two(m)}:${two(s)}';
  return '${two(h)}:${two(m)}:${two(s)}';
}

// ─────────────────────── مواعيد فتح الحجز (من الإنفوجرافيك) ───────────────────────

class OpeningRule {
  const OpeningRule({
    required this.title,
    required this.hint,
    required this.daysBefore,
    required this.hour,
    required this.minuteMen,
    required this.minuteWomen,
    required this.icon,
  });

  final String title;
  final String hint;
  final int daysBefore;
  final int hour; // بتوقيت السعودية، 24 ساعة
  final int minuteMen;
  final int minuteWomen;
  final IconData icon;

  int minuteFor(bool women) => women ? minuteWomen : minuteMen;
}

/// [A] الإنفوجرافيك الأول: الرجال 3:30 عصرًا، السيدات 3:35 عصرًا (قبل أسبوع وقبل يومين)،
/// وقبل يوم الساعة 10 مساءً.
const List<OpeningRule> kOpeningRules = [
  OpeningRule(
    title: 'قبل الزيارة بأسبوع',
    hint: 'لو زيارتك يوم السبت، تابعي يوم السبت الذي قبله.',
    daysBefore: 7,
    hour: 15,
    minuteMen: 30,
    minuteWomen: 35,
    icon: Icons.calendar_view_week_rounded,
  ),
  OpeningRule(
    title: 'قبل الزيارة بيومين',
    hint: 'لو زيارتك يوم السبت، تابعي يوم الخميس.',
    daysBefore: 2,
    hour: 15,
    minuteMen: 30,
    minuteWomen: 35,
    icon: Icons.event_repeat_rounded,
  ),
  OpeningRule(
    title: 'قبل الزيارة بيوم',
    hint: 'تابعي مساء اليوم السابق؛ قد تظهر مواعيد جديدة لليوم التالي.',
    daysBefore: 1,
    hour: 22,
    minuteMen: 0,
    minuteWomen: 0,
    icon: Icons.nightlight_round,
  ),
];

/// كل يوم الساعة 12 ظهرًا (توقيت السعودية) تُفتح مواعيد جديدة للأيام التي كانت مقفلة.
const int kDailyRefreshHour = 12;

const String kScheduleCaveat =
    'هذه الأوقات من مصدر إرشادي غير رسمي (صحبة ترانزيت) وقد يغيّرها نسك في أي وقت. '
    'ادخلي قبل الموعد بدقائق، ولا تعتمدي على ساعة ثابتة.';

/// تعارض بين صورتين من نفس المصدر، نعرضه بشفافية بدل إخفائه.
const String kScheduleConflictNote =
    'ملاحظة: الدليل الكامل 2026 من نفس المصدر يذكر 5:40 للرجال و5:44 للسيدات '
    'لنفس المحاولات، بدون توضيح صباحًا أو مساءً. اعتمدنا الأوقات الموضّحة بـ«عصرًا» '
    'وراجعي نسك للتأكد.';

class ScheduleEvent {
  const ScheduleEvent({
    required this.title,
    required this.hint,
    required this.openAtUtc,
    required this.icon,
    this.daily = false,
  });

  final String title;
  final String hint;
  final DateTime openAtUtc; // اللحظة الفعلية بتوقيت UTC
  final IconData icon;
  final bool daily;

  /// الوقت على الحائط في السعودية (كائن UTC يمثل الساعة المحلية السعودية).
  DateTime get saudiWall => openAtUtc.add(kSaudiOffset);

  /// الوقت على ساعة جهازك.
  DateTime get deviceLocal => openAtUtc.toLocal();
}

/// يبني جدول متابعة الحجز ليوم زيارة معيّن ([visitDay] تاريخ فقط، يُعامل تاريخًا سعوديًا).
List<ScheduleEvent> buildSchedule({
  required DateTime visitDay,
  required bool women,
}) {
  final base = DateTime.utc(visitDay.year, visitDay.month, visitDay.day);
  final events = <ScheduleEvent>[];
  for (final r in kOpeningRules) {
    final day = base.subtract(Duration(days: r.daysBefore));
    final wall = DateTime.utc(day.year, day.month, day.day, r.hour, r.minuteFor(women));
    events.add(ScheduleEvent(
      title: r.title,
      hint: r.hint,
      openAtUtc: wall.subtract(kSaudiOffset),
      icon: r.icon,
    ));
  }
  events.sort((a, b) => a.openAtUtc.compareTo(b.openAtUtc));
  return events;
}

/// أقرب موعد قادم لتحديث الساعة 12 ظهرًا بتوقيت السعودية.
ScheduleEvent nextDailyNoon(DateTime nowUtc) {
  final saudiNow = nowUtc.add(kSaudiOffset);
  var wall = DateTime.utc(saudiNow.year, saudiNow.month, saudiNow.day, kDailyRefreshHour);
  if (!wall.subtract(kSaudiOffset).isAfter(nowUtc)) {
    wall = wall.add(const Duration(days: 1));
  }
  return ScheduleEvent(
    title: 'تحديث المواعيد اليومي',
    hint: 'كل يوم تُفتح مواعيد جديدة للأيام التي كانت مقفلة.',
    openAtUtc: wall.subtract(kSaudiOffset),
    icon: Icons.wb_sunny_rounded,
    daily: true,
  );
}

// ─────────────────────────── المسار الفوري ───────────────────────────

/// [A] الإنفوجرافيك الثاني + [C] إعلان وزارة الحج: خدمة تتيح الحجز كل 20 دقيقة للقريبين من المسجد.
const List<InfoItem> kFawriFacts = [
  InfoItem(Icons.bolt_rounded, 'ما هو المسار الفوري؟',
      'حجز تصريح الصلاة في الروضة من تطبيق نسك لمن يكون داخل المدينة المنورة قرب المسجد النبوي، حسب المواعيد المتاحة.',
      source: 'صحبة ترانزيت + وزارة الحج والعمرة'),
  InfoItem(Icons.search_rounded, 'أين أجد مواعيده؟',
      'لا يوجد زر مستقل باسمه. تظهر مواعيده ضمن المواعيد المتاحة وتُميَّز بعلامة البرق ⚡.',
      source: 'صحبة ترانزيت'),
  InfoItem(Icons.schedule_rounded, 'متى تظهر؟',
      'تظهر المواعيد تباعًا خلال اليوم، وغالبًا عند بداية الساعة ونصفها وكل 20 دقيقة (…4:00 – 4:20 – 4:40).',
      source: 'صحبة ترانزيت'),
  InfoItem(Icons.refresh_rounded, 'مهم جدًا: المواعيد لا تظهر تلقائيًا',
      'كرّري الخطوات: اختاري اسم الشخص ← ادخلي صفحة المواعيد ← لو ظهر موعد مناسب احجزيه فورًا ← لو لم يظهر ارجعي واختاري الاسم من جديد. قد يُطرح موعد جديد في أي لحظة.',
      source: 'صحبة ترانزيت'),
  InfoItem(Icons.today_rounded, 'لنفس اليوم فقط',
      'مواعيد المسار الفوري تكون لنفس يوم الاستخدام، ولا يمكن من خلالها حجز يوم لاحق.',
      source: 'صحبة ترانزيت'),
  InfoItem(Icons.my_location_rounded, 'شرط الموقع',
      'يلزم التواجد قرب المسجد النبوي وتفعيل خدمة الموقع (GPS) على الهاتف والسماح لنسك باستخدامه.',
      source: 'صحبة ترانزيت + وزارة الحج والعمرة'),
];

// ─────────────────────────── شروط الدخول ───────────────────────────

class InfoItem {
  const InfoItem(this.icon, this.title, this.body, {this.source = ''});
  final IconData icon;
  final String title;
  final String body;
  final String source;
}

/// [C] + [B]: ما تحتاجينه قبل الحجز وعند الحجز.
const List<InfoItem> kBookingConditions = [
  InfoItem(Icons.badge_outlined, 'تصريح رسمي مسبق من نسك',
      'لا يُسمح بدخول الروضة الشريفة إلا بتصريح صادر عبر تطبيق أو منصة نسك، وهو الطريقة المعتمدة الوحيدة. الخدمة مجانية.',
      source: 'الهيئة العامة للعناية بشؤون الحرمين · نسك'),
  InfoItem(Icons.rule_rounded, 'الموافقة على تعليمات الدخول',
      'قبل إصدار التصريح تظهر لك تعليمات دخول الروضة ويجب الموافقة عليها. اقرئيها كاملة ولا تضغطي موافقة بسرعة.',
      source: 'نسك · الرئاسة العامة لشؤون المسجد النبوي'),
  InfoItem(Icons.group_outlined, 'اختيار المرافقين',
      'أثناء الحجز تختارين المرافقين ثم التاريخ والوقت المتاح، وتراجعين ملخص الطلب قبل التأكيد.',
      source: 'نسك (الخدمة رقم 152)'),
  InfoItem(Icons.event_repeat_rounded, 'عدد مرات التصريح',
      'أعلنت وزارة الحج والعمرة أن التصريح المسبق متاح لكل شخص مرة كل 365 يومًا. للمسار الفوري قواعد مختلفة قد تسمح بتكرار الاستخدام، وهي تتغير، فتأكدي من نسك.',
      source: 'وزارة الحج والعمرة عبر الصحافة السعودية'),
  InfoItem(Icons.cancel_outlined, 'ألغي التصريح إن لم تستطيعي الحضور',
      'الهيئة تشدد على الإلغاء المبكر ليستفيد غيرك. عدم الإلغاء قد يمنع إصدار تصريح جديد لمدة سنة كاملة.',
      source: 'الرئاسة العامة لشؤون المسجد النبوي'),
  InfoItem(Icons.account_circle_outlined, 'جهّزي حسابك مبكرًا',
      'أول ما تستلمين التأشيرة أنشئي حسابك على نسك وأكملي بياناتك ليكون جاهزًا وقت فتح المواعيد.',
      source: 'صحبة ترانزيت'),
];

/// [C]: يوم الزيارة نفسه.
const List<InfoItem> kVisitDayConditions = [
  InfoItem(Icons.access_time_filled_rounded, 'الحضور قبل الموعد',
      'تطلب وزارة الحج والعمرة الحضور قبل الموعد بـ 30 دقيقة لانسياب التفويج. وتشير تعليمات أخرى إلى الوصول للبوابة قبل 15 دقيقة والتواجد داخل الحرم قبل 30 دقيقة.',
      source: 'وزارة الحج والعمرة · الرئاسة العامة'),
  InfoItem(Icons.qr_code_2_rounded, 'الباركود (QR) لمرة واحدة',
      'الباركود الخاص بموعدك يُستخدم مرة واحدة فقط، ويجب إبرازه عند البوابة وعند التفتيش، وبدونه لا يُسمح بالدخول.',
      source: 'الرئاسة العامة لشؤون المسجد النبوي'),
  InfoItem(Icons.door_front_door_outlined, 'بوابة الدخول',
      'الدخول من الساحات الجنوبية أمام باب مكة (رقم 37) وفق المسارات المعتمدة. تأكدي أيضًا من البوابة المكتوبة في تصريحك.',
      source: 'الهيئة العامة للعناية بشؤون الحرمين'),
  InfoItem(Icons.timer_outlined, 'مدة الصلاة',
      'تنص التعليمات على نحو 10 دقائق للصلاة لإتاحة الفرصة لغيرك، وتذكر بعض المصادر أن كل مجموعة تُمنح من 10 إلى 15 دقيقة.',
      source: 'الرئاسة العامة · KSA Expats'),
  InfoItem(Icons.record_voice_over_outlined, 'اتباع توجيهات العاملين',
      'التزمي بالسكينة وتعليمات المنظمين داخل الروضة، وأبقي تصريحك جاهزًا في هاتفك.',
      source: 'الهيئة العامة للعناية بشؤون الحرمين'),
  InfoItem(Icons.accessible_rounded, 'كبار السن',
      'يُسمح بدخول كبار السن بالعربة اليدوية ضمن الضوابط المحددة.',
      source: 'عكاظ نقلًا عن الهيئة'),
  InfoItem(Icons.rule_folder_outlined, 'شروط السن والحجز',
      'اطلعي على شروط الأعمار والحجز المطبقة وقت زيارتك لأنها قد تتغير.',
      source: 'صحبة ترانزيت'),
];

class HoursRow {
  const HoursRow(this.who, this.slots);
  final String who;
  final List<String> slots;
}

/// [C] الأوقات المعلنة (الأيام العادية). قد تتغير في رمضان والحج.
const List<HoursRow> kWeekdayHours = [
  HoursRow('السيدات', ['بعد الفجر حتى 11:00 ص', 'بعد العشاء حتى 2:00 ص']),
  HoursRow('الرجال', ['2:00 ص حتى صلاة الفجر', '11:20 ص حتى صلاة العشاء']),
];

/// [C] يوم الجمعة.
const List<HoursRow> kFridayHours = [
  HoursRow('السيدات', ['بعد الفجر حتى 9:00 ص', 'بعد العشاء حتى 2:00 ص']),
  HoursRow('الرجال', [
    '2:00 ص حتى صلاة الفجر',
    '9:20 ص حتى 11:20 ص',
    'بعد صلاة الجمعة حتى العشاء',
  ]),
];

const String kHoursCaveat =
    'الأوقات المعلنة في يناير–أبريل 2026، وتتغير في رمضان والحج. المرجع: نسك.';

// ─────────────────────────── أسئلة شائعة ───────────────────────────

class FaqItem {
  const FaqItem(this.q, this.a);
  final String q;
  final String a;
}

const List<FaqItem> kFaq = [
  FaqItem('هل أقدر أحجز قبل ما أوصل المدينة؟',
      'التصريح المسبق: نعم، لو المواعيد مفتوحة خلال فترة وجودك في المدينة يمكنك المحاولة من أي مكان وليس شرطًا أن تكوني داخل السعودية. المسار الفوري: لا، فهو لمن يتواجد قرب المسجد النبوي مع تفعيل الموقع.'),
  FaqItem('لقيت الحجز مفتوح، أعمل إيه؟',
      'ادخلي واحجزي فورًا. المواعيد قد تنتهي بسرعة كبيرة.'),
  FaqItem('ما لقيتش مواعيد؟',
      'جرّبي كل يوم الساعة 12 ظهرًا بتوقيت السعودية حيث تُفتح مواعيد جديدة للأيام التي كانت مقفلة. وتابعي أيضًا قبل الزيارة بأسبوع، وبيومين، وفي مساء اليوم السابق.'),
  FaqItem('هل ممكن أكرر الحجز؟',
      'وفق المصدر غير الرسمي يمكن استخدام المسار الفوري وحجز تصريح جديد كل 24 ساعة متى توفرت المواعيد وكنتِ مؤهلة. أما التصريح المسبق فمعلن مرة كل 365 يومًا لكل شخص. القواعد تتغير، فراجعي نسك.'),
  FaqItem('اتأخرت أو مش هقدر أحضر؟',
      'ألغي التصريح من نسك مبكرًا. عدم الإلغاء قد يمنع إصدار تصريح جديد لسنة كاملة.'),
  FaqItem('هل رِفقة بيحجز لي؟',
      'لا. رِفقة يشرح الخطوات ويدرّبك ويذكّرك بالمواعيد، أما كل الحجز الفعلي فيتم داخل نسك فقط.'),
];

// ─────────────────────────── التدريب التفاعلي ───────────────────────────

/// نقاط تظهر في شاشة مراجعة التعليمات داخل التدريب.
const List<String> kAgreementPoints = [
  'مدة الصلاة نحو 10 دقائق.',
  'الحضور قبل الموعد بـ 30 دقيقة.',
  'الباركود يُستخدم مرة واحدة ويُعرض عند البوابة.',
  'ألغي التصريح مبكرًا إن لم تستطيعي الحضور.',
];

/// نص التعليق الصوتي لكل شاشة تدريب (يُقرأ بصوت عربي عبر flutter_tts).
const List<String> kStepNarration = [
  'الخطوة الأولى. افتحي تطبيق نسك، وفي الصفحة الرئيسية اضغطي على قسم الروضة الشريفة.',
  'الخطوة الثانية. اختاري خدمة تصريح الصلاة في الروضة المناسبة لك، سيدات أو رجال.',
  'الخطوة الثالثة. اختاري المرافقين الذين ستحجزين لهم، ثم اضغطي التالي.',
  'الخطوة الرابعة، وهي الأهم. في المسار الفوري اختاري الاسم، وادخلي صفحة المواعيد. لو لم تجدي موعدًا ارجعي واختاري الاسم من جديد، وكرري حتى يظهر موعد بعلامة البرق، ثم احجزيه فورًا.',
  'الخطوة الخامسة. راجعي ملخص الطلب، واقرئي تعليمات دخول الروضة، ووافقي عليها، ثم أصدري التصريح.',
  'أحسنتِ. هذا كان تدريبًا فقط ولم يُصدر أي تصريح. افتحي نسك الرسمي الآن وطبّقي الخطوات، وبإذن الله تكون زيارتك مباركة.',
];

/// أوقات المواعيد التدريبية: 05:00 ص … 10:40 ص كل 20 دقيقة (مثل الإنفوجرافيك).
List<String> practiceSlots() => [
      for (int m = 5 * 60; m <= 10 * 60 + 40; m += 20)
        '${two(m ~/ 60)}:${two(m % 60)} ص',
    ];

// ─────────────────────────── معرض الصور ───────────────────────────

class GalleryItem {
  const GalleryItem(this.asset, this.title, this.caption);
  final String asset;
  final String title;
  final String caption;
}

/// الصور الموجودة فعلًا في مشروعك. لإضافة صور جديدة: ضعيها داخل
/// assets/scenes/ (نفس مجلد cinematicAssets/scenes) وأضيفي سطرًا هنا.
const List<GalleryItem> kRawdahGallery = [
  GalleryItem('$cinematicAssets/scenes/rawdah_grille.jpg',
      'الروضة الشريفة', 'بين بيت النبي ﷺ ومنبره'),
  GalleryItem('$cinematicAssets/scenes/courtyard_day_umbrella.jpg',
      'ساحات المسجد النبوي', 'مظلات الساحات نهارًا'),
  GalleryItem('$cinematicAssets/scenes/exterior_sunset_wide.jpg',
      'المسجد النبوي', 'وقت الغروب'),
];

// ─────────────────────────── المصادر ───────────────────────────

const List<(String, String)> kSources = [
  ('نسك: تصريح زيارة الروضة الشريفة (رسمي)', 'https://www.nusuk.sa/service-details/152'),
  ('عكاظ: مواعيد زيارة الروضة للرجال والنساء', 'https://www.okaz.com.sa/local/saudi-arabia/2225232'),
  ('سبق: دعوة وزارة الحج والعمرة لجدولة الزيارة', 'https://sabq.org/article/1M75CT4'),
  ('KSA Expats: تعليمات دخول الروضة', 'https://ksaexpats.com/new-guidelines-al-rawdah-al-sharifah-visits/'),
];

const String kNusukServiceUrl = 'https://www.nusuk.sa/service-details/152';
const String kNusukPhone = '920002814';