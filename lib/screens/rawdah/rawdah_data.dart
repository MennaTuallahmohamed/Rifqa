import 'package:flutter/material.dart';

/// بيانات حجز الروضة الشريفة. المصدر: أدلة «صحبة ترانزيت» (دليل 2026 والمسار الفوري).
/// ⚠️ نظام الحجز في تطبيق «نسك» يتغير من وقت لآخر؛ هذه الأوقات إرشادية
/// وكل ما هنا لا يغني عن التعليمات الحالية داخل تطبيق نسك.

// ═══════════════════ التوقيت ═══════════════════
// توقيت السعودية = UTC+3 ثابتًا (بلا تغيير صيفي).
// نمثّل «الساعة الحائطية السعودية» بـ DateTime بعلامة UTC تتطابق حقوله مع الساعة هناك.

const _ksa = Duration(hours: 3);

DateTime saudiNow() => DateTime.now().toUtc().add(_ksa);

/// تاريخ فقط (حائطي سعودي)
DateTime saudiDay(DateTime d) => DateTime.utc(d.year, d.month, d.day);

String hm12(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour >= 12 ? 'م' : 'ص'}';
}

const _days = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
const _months = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
];

String dayName(DateTime d) => _days[d.weekday - 1];
String dateAr(DateTime d) => '${dayName(d)} ${d.day} ${_months[d.month - 1]}';

/// المتبقي حتى الساعة 12:00 ظهرًا القادمة بتوقيت السعودية
Duration untilNextNoon() {
  final n = saudiNow();
  var t = DateTime.utc(n.year, n.month, n.day, 12);
  if (!n.isBefore(t)) t = t.add(const Duration(days: 1));
  return t.difference(n);
}

String fmtDur(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  if (d.inDays >= 1) return '${d.inDays} يوم و ${h % 24} ساعة';
  return '${two(h)}:${two(m)}:${two(s)}';
}

// ═══════════════════ المحاولات ═══════════════════

class RAttempt {
  final String emoji, title, note;
  final DateTime wall; // الساعة الحائطية السعودية
  const RAttempt(this.emoji, this.title, this.note, this.wall);

  /// اللحظة الفعلية (UTC)
  DateTime get instant => wall.subtract(_ksa);
  DateTime get local => instant.toLocal();
  Duration get remaining => instant.difference(DateTime.now().toUtc());
}

/// يبني جدول محاولات الحجز ليوم زيارة معيّن (حسب الأدلة):
/// قبل بأسبوع 5:40 م رجال / 5:44 م سيدات، وقبل بيومين نفس الوقت، وقبل بيوم 10 م،
/// ويوميًا 12 ظهرًا لظهور مواعيد جديدة.
List<RAttempt> buildAttempts(DateTime visitDay, bool woman, {int maxNoon = 14}) {
  final d = saudiDay(visitDay);
  final mm = woman ? 44 : 40;
  final who = woman ? 'السيدات' : 'الرجال';
  final list = <RAttempt>[
    RAttempt('📅', 'قبل الزيارة بأسبوع', 'محاولة $who: ${dayName(d)} السابق عند 5:$mm م.',
        d.subtract(const Duration(days: 7)).add(Duration(hours: 17, minutes: mm))),
    RAttempt('🗓️', 'قبل الزيارة بيومين', 'محاولة $who عند 5:$mm م (${dayName(d.subtract(const Duration(days: 2)))}).',
        d.subtract(const Duration(days: 2)).add(Duration(hours: 17, minutes: mm))),
    RAttempt('🌙', 'قبل الزيارة بيوم', 'ادخل عند 10:00 م، وقد تظهر مواعيد جديدة لليوم التالي.',
        d.subtract(const Duration(days: 1)).add(const Duration(hours: 22))),
  ];
  // مواعيد 12 ظهرًا اليومية: من اليوم حتى يوم الزيارة
  final today = saudiDay(saudiNow());
  var cur = today;
  var n = 0;
  while (!cur.isAfter(d) && n < maxNoon) {
    list.add(RAttempt('🕛', 'ظهرًا: مواعيد جديدة',
        'تُفتح عند 12:00 ظهرًا بتوقيت السعودية للأيام التي كانت مغلقة (${dateAr(cur)}).',
        cur.add(const Duration(hours: 12))));
    cur = cur.add(const Duration(days: 1));
    n++;
  }
  final now = DateTime.now().toUtc();
  list.removeWhere((e) => !e.instant.isAfter(now));
  list.sort((a, b) => a.instant.compareTo(b.instant));
  return list;
}

// ═══════════════════ مراحل «أنا فين؟» ═══════════════════

class RStage {
  final String id, emoji, title, summary;
  final List<String> steps;
  const RStage(this.id, this.emoji, this.title, this.summary, this.steps);
}

const rStages = <RStage>[
  RStage('novisa', '🛂', 'لسه ما استلمتش التأشيرة',
      'مفيش استعجال. جهّز نفسك للحظة استلام التأشيرة.', [
    'أول ما تستلم التأشيرة، اعمل حساب على تطبيق نسك.',
    'خلّي الحساب جاهز ومفعّل قبل ما تبدأ المواعيد.',
    'حدّد مواعيد سفرك ووجودك في المدينة المنورة.',
  ]),
  RStage('visa', '📄', 'استلمت التأشيرة ومعييش حساب',
      'أهم خطوة دلوقتي هي حساب نسك.', [
    'اعمل حساب على نسك فورًا وخليه جاهز.',
    'ابدأ متابعة مواعيد الروضة من بدري.',
    'لو لقيت الحجز مفتوح ادخل واحجز فورًا.',
  ]),
  RStage('account', '✅', 'عندي حساب نسك',
      'حدّدت مواعيد سفرك ووجودك بالمدينة؟ يبقى ابدأ المتابعة فورًا.', [
    'لو المواعيد مفتوحة خلال فترة وجودك في المدينة، حاول تحجز من أي مكان، ومش شرط تكون داخل السعودية.',
    'لقيت مواعيد؟ احجز فورًا لأنها بتخلص بسرعة جدًا.',
    'ملقتش؟ ادخل كل يوم 12 ظهرًا بتوقيت السعودية، ثم جرّب مواعيد: قبل الزيارة بأسبوع، وبيومين، وبيوم.',
  ]),
  RStage('medina', '🕌', 'أنا في المدينة دلوقتي',
      'تقدر تجرب «المسار الفوري» على مدار 24 ساعة.', [
    'فعّل GPS واسمح لنسك باستخدام الموقع، وكن قريبًا من المسجد النبوي.',
    'اختر الاسم ثم ادخل صفحة المواعيد، وابحث عن علامة ⚡.',
    'لو لقيت موعد مناسب احجزه فورًا، وإلا ارجع واختر الاسم من جديد وكرر.',
  ]),
];

// ═══════════════════ الأسئلة الشائعة ═══════════════════

class RFaq {
  final String q, a;
  const RFaq(this.q, this.a);
}

const rFaq = <RFaq>[
  RFaq('ما هو المسار الفوري؟',
      'خدمة تتيح لزائر المدينة المنورة حجز تصريح الصلاة في الروضة الشريفة على مدار 24 ساعة عبر تطبيق نسك، وفق المواعيد المتاحة.'),
  RFaq('كيف أجد مواعيد المسار الفوري؟',
      'لا يوجد زر مستقل باسم «المسار الفوري». تظهر مواعيده ضمن المواعيد المتاحة للحجز، ويمكن تمييزها بعلامة ⚡ بجوار الموعد.'),
  RFaq('متى تظهر مواعيد المسار الفوري؟',
      'تظهر المواعيد تباعًا خلال اليوم، وغالبًا عند بداية الساعة ونصفها وكل 20 دقيقة تقريبًا، مثل 4:00 ثم 4:20 ثم 4:40 ثم 5:00 وهكذا.'),
  RFaq('المواعيد الجديدة لا تظهر وحدها، فماذا أفعل؟',
      'كرّر الخطوات: اختر اسم الشخص، ثم ادخل صفحة المواعيد المتاحة. إن ظهر موعد مناسب فاحجزه فورًا. وإن لم يظهر فارجع واختر الاسم من جديد. استمر، فقد يُطرح موعد جديد في أي لحظة.'),
  RFaq('هل مواعيد المسار الفوري لنفس اليوم فقط؟',
      'نعم. المواعيد التي تظهر عبره تكون ليوم المحاولة فقط ولا تحجز بها يومًا لاحقًا. مثال: لو اليوم الخميس فالمتاح سيكون للخميس فقط.'),
  RFaq('هل أحجز بالمسار الفوري قبل وصولي للمدينة؟',
      'لا. المسار الفوري لمن هم داخل المدينة المنورة، ويشترط التواجد قرب المسجد النبوي وتفعيل GPS. أما الحجز المسبق (قبل الزيارة بأسبوع وغيره) فتقدر تحاول فيه من أي مكان.'),
  RFaq('هل يمكن تكرار الحجز؟',
      'نعم. يمكنك استخدام المسار الفوري وحجز تصريح جديد كل 24 ساعة متى توفرت المواعيد وكنت مؤهلًا للحجز.'),
  RFaq('لا أجد مواعيد أبدًا، ما الحل؟',
      'ادخل كل يوم 12 ظهرًا بتوقيت السعودية، ففيه تُفتح مواعيد جديدة للأيام التي كانت مغلقة. وجرّب أيضًا في أوقات مختلفة ولا تستنَّ لآخر لحظة.'),
  RFaq('هل أعتمد على ساعة ثابتة؟',
      'لا. نظام فتح الحجز قد يتغير من وقت لآخر حسب تحديثات نسك، فاعتبر الأوقات مرجعًا ثم تابع تطبيق نسك.'),
];

// ═══════════════════ قبل الذهاب ═══════════════════

const rChecklist = <String>[
  'تأكدت من بوابة الدخول الموضحة في تصريحي',
  'راجعت تفاصيل الحجز داخل تطبيق نسك بعد إتمامه',
  'عرفت وقت ظهور وتفعيل الـ QR Code حسب النظام الحالي (قد يختلف)',
  'راجعت شروط الأعمار والحجز المطبقة وقت زيارتي',
  'فعّلت GPS وسمحت لنسك باستخدام الموقع',
  'حسابي على نسك جاهز قبل موعد المحاولة بدقائق',
  'الهاتف مشحون والإنترنت جيد',
];

// ═══════════════════ المخزن ═══════════════════

class RawdahStore extends ChangeNotifier {
  RawdahStore._();
  static final RawdahStore I = RawdahStore._();

  DateTime? visitDay; // تاريخ فقط (سعودي)
  bool woman = false;
  bool remindersOn = false;
  String stage = 'account';
  final Set<int> checked = {};
  int salawat = 0;

  List<RAttempt> get plan =>
      visitDay == null ? const [] : buildAttempts(visitDay!, woman);

  void setPlan(DateTime d, bool w) {
    visitDay = saudiDay(d);
    woman = w;
    notifyListeners();
  }

  void setReminders(bool v) {
    remindersOn = v;
    notifyListeners();
  }

  void setStage(String s) {
    stage = s;
    notifyListeners();
  }

  void toggleCheck(int i) {
    checked.contains(i) ? checked.remove(i) : checked.add(i);
    notifyListeners();
  }

  void addSalawat([int n = 1]) {
    salawat += n;
    notifyListeners();
  }

  void resetSalawat() {
    salawat = 0;
    notifyListeners();
  }
}
