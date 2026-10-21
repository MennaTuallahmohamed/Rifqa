import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cinematic_theme.dart';
import '../../lost/widgets/rawdah_3d_widgets.dart';
import 'rawdah_data.dart';
import 'rifqa_audio.dart';

/// رِفقة · تدريب حجز الروضة الشريفة (الإصدار 5)
///
/// ما يفعله:
///  • معرض صور ثلاثي الأبعاد للروضة + صوت (مؤثرات، أجواء، تعليق صوتي عربي)
///  • عدّاد تنازلي لأوقات فتح الحجز (من إنفوجرافيك صحبة ترانزيت) بتوقيت السعودية وتوقيتك
///  • موبايل تدريبي مائل ثلاثي الأبعاد يحاكي خطوات نسك + حلقة المسار الفوري
///  • شروط الدخول وأوقات الزيارة والأسئلة الشائعة مع ذكر المصدر
///
/// ما لا يفعله (عمدًا): لا يحجز، لا يصدر تصريحًا، ولا يعرض مواعيد حقيقية.
/// المواعيد داخل التدريب وهمية وموسومة «تدريبي». الحجز الفعلي في نسك فقط.
class RawdahBookingSimulatorV5 extends StatefulWidget {
  const RawdahBookingSimulatorV5({
    super.key,
    this.initialWomen = true,
    this.onOpenFullGuide,
  });
  final bool initialWomen;
  final VoidCallback? onOpenFullGuide;

  @override
  State<RawdahBookingSimulatorV5> createState() => _RawdahBookingSimulatorV5State();
}

const Color _pageBg = Color(0xFFFCF8F1);
const Color _inkSoft = Color(0xFF55625A);
const List<String> _stepTitles = [
  'الصفحة الرئيسية',
  'اختيار الخدمة',
  'المرافقون',
  'التاريخ والوقت',
  'المراجعة والتعليمات',
  'انتهى التدريب',
];

class _RawdahBookingSimulatorV5State extends State<RawdahBookingSimulatorV5> {
  final RifqaAudio _audio = RifqaAudio.instance;
  final ValueNotifier<DateTime> _nowUtc = ValueNotifier<DateTime>(DateTime.now().toUtc());
  final ValueNotifier<int> _front = ValueNotifier<int>(0);
  late final Timer _clock;

  late bool _women;
  DateTime? _visitDay;

  // ── حالة التدريب ──
  int _step = 0;
  final Set<int> _companions = <int>{0};
  int _attempts = 0;
  bool _onSlotsPage = false;
  int? _pickedSlot;
  bool _agreed = false;
  bool _autoNarrate = false;
  late final List<String> _slots;
  late Set<int> _boltSlots;
  static const int _attemptsNeeded = 3;

  @override
  void initState() {
    super.initState();
    _women = widget.initialWomen;
    _slots = practiceSlots();
    _reshuffle();
    _audio.init();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      _nowUtc.value = DateTime.now().toUtc();
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    _nowUtc.dispose();
    _front.dispose();
    _audio.stopAll();
    super.dispose();
  }

  void _reshuffle() {
    final rnd = math.Random();
    final picked = <int>{};
    while (picked.length < 3) {
      picked.add(rnd.nextInt(_slots.length));
    }
    _boltSlots = picked;
  }

  // ════════════════════════ أدوات عامة ════════════════════════

  BoxDecoration get _cardDeco => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEFE3C8)),
      );

  Future<void> _launch(String url) async {
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح الرابط، افتحي nusuk.sa من المتصفح.')),
      );
    }
  }

  void _snack(String msg) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  void _wrong(String msg) {
    _audio.play(Sfx.alert);
    _snack(msg);
  }

  Future<void> _chooseVisitDay() async {
    _audio.play(Sfx.tap);
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _visitDay ?? today.add(const Duration(days: 10)),
      firstDate: today,
      lastDate: DateTime(today.year + 2, 12, 31),
      helpText: 'يوم زيارة الروضة المتوقع (ليس حجزًا)',
      cancelText: 'إلغاء',
      confirmText: 'حفظ',
    );
    if (selected != null && mounted) {
      _audio.play(Sfx.success);
      setState(() => _visitDay = selected);
    }
  }

  // ════════════════════════ البناء الرئيسي ════════════════════════

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _hero()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _trainingBanner(),
                  const SizedBox(height: 14),
                  _clocks(),
                  const SizedBox(height: 14),
                  _plannerCard(),
                  const SizedBox(height: 24),
                  _sectionTitle('التدريب التفاعلي ثلاثي الأبعاد', Icons.view_in_ar_rounded),
                  _trainingSection(),
                  const SizedBox(height: 24),
                  _sectionTitle('المسار الفوري يوم الزيارة', Icons.bolt_rounded),
                  _infoCard(kFawriFacts),
                  const SizedBox(height: 24),
                  _sectionTitle('شروط الحجز', Icons.assignment_turned_in_outlined),
                  _infoCard(kBookingConditions),
                  const SizedBox(height: 24),
                  _sectionTitle('شروط الدخول ويوم الزيارة', Icons.door_front_door_outlined),
                  _infoCard(kVisitDayConditions),
                  const SizedBox(height: 24),
                  _sectionTitle('أوقات زيارة الروضة', Icons.schedule_rounded),
                  _hoursCard(),
                  const SizedBox(height: 24),
                  _sectionTitle('أسئلة شائعة', Icons.help_outline_rounded),
                  _faqCard(),
                  const SizedBox(height: 24),
                  _sourcesCard(),
                  const SizedBox(height: 18),
                  _bottomActions(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════ الواجهة العلوية ════════════════════════

  Widget _hero() => Stack(children: [
        Positioned.fill(
          child: ValueListenableBuilder<int>(
            valueListenable: _front,
            builder: (context, i, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              child: SizedBox.expand(
                key: ValueKey<int>(i),
                child: SafeAsset(kRawdahGallery[i % kRawdahGallery.length].asset),
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC012A20), Color(0xE6023A2B), _pageBg],
                stops: [0, 0.72, 1],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                _circleBtn(Icons.arrow_forward_ios_rounded, () => Navigator.pop(context),
                    'رجوع'),
                const Spacer(),
                const Text('رِفقة',
                    style: TextStyle(
                        color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const Spacer(),
                ValueListenableBuilder<bool>(
                  valueListenable: _audio.effectsOn,
                  builder: (context, on, _) => _circleBtn(
                    on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    () {
                      _audio.setEffects(!on);
                      if (!on) _audio.play(Sfx.tap);
                    },
                    on ? 'كتم المؤثرات' : 'تشغيل المؤثرات',
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: _audio.ambientOn,
                  builder: (context, on, _) => _circleBtn(
                    on ? Icons.music_note_rounded : Icons.music_off_rounded,
                    () => _audio.setAmbient(!on),
                    on ? 'إيقاف الأجواء' : 'تشغيل الأجواء الهادئة',
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerRight,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('حجز الروضة الشريفة',
                      style: TextStyle(
                          color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text('تدريب · مواعيد · شروط دخول، في مكان واحد',
                      style: TextStyle(color: Color(0xFFEADFC2), fontSize: 14, height: 1.5)),
                ]),
              ),
              const SizedBox(height: 8),
              Rawdah3DCarousel(
                items: kRawdahGallery,
                height: 270,
                onFrontChanged: (i) => _front.value = i,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 2, bottom: 8),
                child: Text('اسحبي الصور لتدويرها',
                    style: TextStyle(color: cinematicGreen, fontSize: 11)),
              ),
            ]),
          ),
        ),
      ]);

  Widget _circleBtn(IconData icon, VoidCallback onTap, String tip) => Material(
        color: const Color(0x33FFFFFF),
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: onTap,
          tooltip: tip,
        ),
      );

  Widget _trainingBanner() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0D0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, size: 21, color: cinematicGreen),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'هذا تدريب تعليمي داخل رِفقة وليس شاشة نسك الرسمية. المواعيد المعروضة داخل التدريب '
              'وهمية للتمرين فقط ولا يصدر عنها أي تصريح. الحجز الفعلي يتم في نسك فقط.',
              style: TextStyle(color: cinematicGreen, fontSize: 11.5, height: 1.6),
            ),
          ),
        ]),
      );

  Widget _clocks() => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ValueListenableBuilder<DateTime>(
            valueListenable: _nowUtc,
            builder: (context, now, _) {
              final saudi = now.add(kSaudiOffset);
              final local = now.toLocal();
              return Row(children: [
                Expanded(
                  child: _clockBlock('الوقت في السعودية', fmtClock(saudi),
                      fmtDateAr(saudi), Icons.mosque_rounded),
                ),
                Container(width: 1, height: 64, color: const Color(0xFFE8DCC6)),
                Expanded(
                  child: _clockBlock('عندك', fmtClock(local), fmtDateAr(local),
                      Icons.access_time_rounded),
                ),
              ]);
            },
          ),
        ),
      );

  Widget _clockBlock(String title, String value, String date, IconData icon) =>
      Column(children: [
        Icon(icon, color: const Color(0xFFC09348)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: cinematicGreen, fontSize: 12)),
        Text(value,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: cinematicGreen, fontSize: 20)),
        Text(date, style: const TextStyle(color: Color(0xFF848A81), fontSize: 10.5)),
      ]);

  Widget _sectionTitle(String text, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Icon(icon, color: const Color(0xFFC09348), size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: cinematicGreen, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ]),
      );

  // ════════════════════════ مخطط المواعيد ════════════════════════

  Widget _genderChip(String text, IconData icon, bool women) {
    final active = _women == women;
    return Material(
      color: active ? cinematicGreen : const Color(0xFFF8F6F0),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _audio.play(Sfx.tap);
          setState(() {
            _women = women;
            _pickedSlot = null;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: active ? Colors.white : const Color(0xFF879087), size: 20),
            const SizedBox(width: 8),
            Text(text,
                style: TextStyle(
                    color: active ? Colors.white : cinematicGreen,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }

  Widget _plannerCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.alarm_on_rounded, color: Color(0xFFC09348)),
            SizedBox(width: 8),
            Text('خطة متابعة فتح الحجز',
                style: TextStyle(
                    color: cinematicGreen, fontSize: 17, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 4),
          const Text(
            'اختاري نوع الزيارة ويوم الزيارة المتوقع، ونحسب لك أوقات المتابعة بتوقيت السعودية وتوقيت جهازك.',
            style: TextStyle(color: _inkSoft, fontSize: 12, height: 1.55),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _genderChip('السيدات', Icons.face_3_rounded, true)),
            const SizedBox(width: 8),
            Expanded(child: _genderChip('الرجال', Icons.person_rounded, false)),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _chooseVisitDay,
              icon: const Icon(Icons.edit_calendar_rounded),
              label: Text(_visitDay == null
                  ? 'حددي يوم زيارة الروضة'
                  : 'يوم الزيارة: ${fmtDateAr(_visitDay!)}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cinematicGreen,
                side: const BorderSide(color: cinematicGold),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<DateTime>(
            valueListenable: _nowUtc,
            builder: (context, now, _) => _plannerBody(now),
          ),
        ]),
      );

  Widget _plannerBody(DateTime now) {
    final visit = _visitDay;
    final events = <ScheduleEvent>[
      if (visit != null) ...buildSchedule(visitDay: visit, women: _women),
    ];
    final noon = nextDailyNoon(now);
    ScheduleEvent? next;
    for (final e in [...events, noon]) {
      if (e.openAtUtc.isAfter(now) &&
          (next == null || e.openAtUtc.isBefore(next.openAtUtc))) {
        next = e;
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (next != null) _nextBanner(next, now),
      const SizedBox(height: 10),
      for (final e in events) _eventRow(e, now, identical(e, next)),
      _eventRow(noon, now, identical(noon, next)),
      if (visit == null)
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 4),
          child: Text(
            'اختاري يوم الزيارة لتظهر لك مواعيد المتابعة قبلها بأسبوع وبيومين وبيوم.',
            style: TextStyle(color: _inkSoft, fontSize: 12, height: 1.5),
          ),
        ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '$kScheduleCaveat\n\n$kScheduleConflictNote',
          style: TextStyle(color: Color(0xFF7A6430), fontSize: 11, height: 1.6),
        ),
      ),
    ]);
  }

  Widget _nextBanner(ScheduleEvent e, DateTime now) {
    final left = e.openAtUtc.difference(now);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0B5A43), Color(0xFF023A2B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        const Text('أقرب موعد للمتابعة',
            style: TextStyle(color: Color(0xFFEADFC2), fontSize: 12)),
        const SizedBox(height: 2),
        Text(e.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(fmtCountdown(left),
              style: const TextStyle(
                  color: cinematicGold,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()])),
        ),
        const SizedBox(height: 6),
        Text(
          'السعودية ${fmtClock(e.saudiWall)}  ·  عندك ${fmtClock(e.deviceLocal)}',
          style: const TextStyle(color: Color(0xFFEEEADC), fontSize: 12),
        ),
      ]),
    );
  }

  Widget _eventRow(ScheduleEvent e, DateTime now, bool isNext) {
    final past = !e.openAtUtc.isAfter(now);
    final days = e.openAtUtc.difference(now).inDays;
    final when = e.daily
        ? 'كل يوم · السعودية ${fmtClock(e.saudiWall)} · عندك ${fmtClock(e.deviceLocal)}'
        : '${fmtDateAr(e.saudiWall)} · السعودية ${fmtClock(e.saudiWall)}\n'
            'عندك: ${fmtDateAr(e.deviceLocal)} ${fmtClock(e.deviceLocal)}';
    return Opacity(
      opacity: past ? 0.5 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isNext ? const Color(0xFFFFF4DA) : const Color(0xFFF8F5EE),
          borderRadius: BorderRadius.circular(16),
          border: isNext ? Border.all(color: cinematicGold, width: 1.4) : null,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(e.icon, color: cinematicGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.title,
                  style: const TextStyle(
                      color: cinematicGreen, fontWeight: FontWeight.w800, fontSize: 13.5)),
              const SizedBox(height: 3),
              Text(when,
                  style: const TextStyle(color: _inkSoft, fontSize: 11.5, height: 1.5)),
              const SizedBox(height: 2),
              Text(e.hint,
                  style: const TextStyle(color: Color(0xFF8A938C), fontSize: 11, height: 1.5)),
            ]),
          ),
          const SizedBox(width: 6),
          if (past)
            const Icon(Icons.check_circle_outline, color: Color(0xFF879087), size: 20)
          else if (!isNext)
            Text(days > 0 ? 'بعد $days يوم' : 'اليوم',
                style: const TextStyle(color: Color(0xFFA08A55), fontSize: 11)),
        ]),
      ),
    );
  }

  // ════════════════════════ التدريب: الموبايل ثلاثي الأبعاد ════════════════════════

  Widget _trainingSection() {
    final w = MediaQuery.sizeOf(context).width;
    final phoneW = (w - 64).clamp(260.0, 340.0).toDouble();
    return Column(children: [
      Center(
        child: Tilt3D(
          child: SizedBox(width: phoneW, height: 610, child: _phone()),
        ),
      ),
      const SizedBox(height: 6),
      const Text('المسي الموبايل وحرّكي إصبعك ليميل في الفضاء',
          style: TextStyle(color: Color(0xFF848A81), fontSize: 11)),
      const SizedBox(height: 14),
      Row(children: List.generate(_stepTitles.length, (i) {
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: i <= _step ? cinematicGold : const Color(0xFFDDDDD0),
            ),
          ),
        );
      })),
      const SizedBox(height: 8),
      Text('الخطوة ${_step + 1} من ${_stepTitles.length} · ${_stepTitles[_step]}',
          style: const TextStyle(
              fontSize: 13.5, color: cinematicGreen, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Row(children: [
        if (_step > 0)
          OutlinedButton.icon(
            onPressed: _back,
            icon: const Icon(Icons.chevron_right),
            label: const Text('السابق'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cinematicGreen,
              side: const BorderSide(color: cinematicGold),
            ),
          ),
        const Spacer(),
        TextButton.icon(
          onPressed: _restart,
          icon: const Icon(Icons.replay_rounded, color: cinematicGreen, size: 18),
          label: const Text('إعادة التدريب', style: TextStyle(color: cinematicGreen)),
        ),
      ]),
      SwitchListTile(
        value: _autoNarrate,
        onChanged: (v) {
          setState(() => _autoNarrate = v);
          if (v) _audio.narrate(kStepNarration[_step]);
          if (!v) _audio.stopNarration();
        },
        activeColor: cinematicGreen,
        contentPadding: EdgeInsets.zero,
        title: const Text('تعليق صوتي تلقائي لكل خطوة',
            style: TextStyle(color: cinematicGreen, fontSize: 13)),
        subtitle: const Text('يقرأ لك الشرح بصوت عربي أثناء التدريب',
            style: TextStyle(color: Color(0xFF848A81), fontSize: 11)),
      ),
    ]);
  }

  Widget _phone() => Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A14),
          borderRadius: BorderRadius.circular(44),
          border: Border.all(color: cinematicGold, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: ColoredBox(
            color: const Color(0xFF063C2D),
            child: Column(children: [
              _statusBar(),
              _appBar(),
              Expanded(
                child: Stack(children: [
                  // علامة مائية: تدريب
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Transform.rotate(
                          angle: -0.5,
                          child: const Text('تدريب',
                              style: TextStyle(
                                  fontSize: 96,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0x0DFFFFFF))),
                        ),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...previous, if (current != null) current],
                    ),
                    transitionBuilder: (child, anim) {
                      final rot = Tween<double>(begin: 0.5, end: 0).animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
                      return AnimatedBuilder(
                        animation: anim,
                        child: child,
                        builder: (context, c) => Opacity(
                          opacity: anim.value.clamp(0.0, 1.0).toDouble(),
                          child: Transform(
                            alignment: Alignment.centerRight,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0015)
                              ..rotateY(rot.value),
                            child: c,
                          ),
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<String>('$_step-$_onSlotsPage'),
                      child: _screen(),
                    ),
                  ),
                  if (_step == 5) const Positioned.fill(child: SparkleBurst()),
                ]),
              ),
            ]),
          ),
        ),
      );

  Widget _statusBar() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
        child: Row(children: [
          ValueListenableBuilder<DateTime>(
            valueListenable: _nowUtc,
            builder: (context, n, _) => Text(fmtClock(n.toLocal()),
                style: const TextStyle(
                    color: cinematicCream, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          Container(
            width: 70,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1A14),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const Spacer(),
          const Icon(Icons.signal_cellular_alt_rounded, size: 14, color: cinematicCream),
          const SizedBox(width: 4),
          const Icon(Icons.battery_full_rounded, size: 14, color: cinematicCream),
        ]),
      );

  Widget _appBar() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
        child: Row(children: [
          Text('${_step + 1}/${_stepTitles.length}',
              style: const TextStyle(color: cinematicGold, fontSize: 12)),
          const Spacer(),
          const Text('رِفقة • وضع التدريب',
              style: TextStyle(
                  color: cinematicCream, fontSize: 12, fontWeight: FontWeight.w800)),
          const Spacer(),
          ValueListenableBuilder<bool>(
            valueListenable: _audio.speaking,
            builder: (context, speaking, _) => InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => speaking
                  ? _audio.stopNarration()
                  : _audio.narrate(kStepNarration[_step]),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(children: [
                  Icon(
                    speaking ? Icons.stop_circle_rounded : Icons.record_voice_over_rounded,
                    color: cinematicGold,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(speaking ? 'إيقاف' : 'اسمعي الشرح',
                      style: const TextStyle(color: cinematicGold, fontSize: 10.5)),
                ]),
              ),
            ),
          ),
        ]),
      );

  // ── التنقل بين الخطوات ──

  void _goStep(int s) {
    _audio.stopNarration();
    _audio.play(s == 5 ? Sfx.success : Sfx.swipe);
    setState(() {
      if (s == 3 && _step < 3) {
        _attempts = 0;
        _onSlotsPage = false;
        _pickedSlot = null;
        _reshuffle();
      }
      _step = s;
    });
    if (_autoNarrate) _audio.narrate(kStepNarration[s]);
  }

  void _back() {
    _audio.stopNarration();
    _audio.play(Sfx.swipe);
    setState(() {
      if (_step == 3 && _onSlotsPage) {
        _onSlotsPage = false;
      } else if (_step == 4) {
        _step = 3;
        _onSlotsPage = true;
      } else if (_step > 0) {
        _step -= 1;
      }
    });
  }

  void _restart() {
    _audio.stopNarration();
    _audio.play(Sfx.tap);
    setState(() {
      _step = 0;
      _companions
        ..clear()
        ..add(0);
      _attempts = 0;
      _onSlotsPage = false;
      _pickedSlot = null;
      _agreed = false;
      _reshuffle();
    });
  }

  // ── محتوى كل شاشة ──

  Widget _screen() {
    switch (_step) {
      case 0:
        return _s0Home();
      case 1:
        return _s1Service();
      case 2:
        return _s2Companions();
      case 3:
        return _onSlotsPage ? _s3Slots() : _s3PickName();
      case 4:
        return _s4Review();
      default:
        return _s5Done();
    }
  }

  Widget _scroll(List<Widget> children) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );

  Widget _screenTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: cinematicCream, fontSize: 19, fontWeight: FontWeight.w900)),
      );

  Widget _hint(String text) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cinematicGold.withAlpha(38),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cinematicGold.withAlpha(90)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.lightbulb_outline_rounded, color: cinematicGold, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: cinematicCream, fontSize: 12, height: 1.55)),
          ),
        ]),
      );

  /// بلاطة شاشة نسك التجريبية. (الفراغ بين البلاطات عبر [_gap] حتى لا يتسع التوهج.)
  Widget _mockTile(IconData icon, String title, String subtitle, VoidCallback onTap) =>
      Material(
        color: const Color(0xFF14523F),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cinematicGold.withAlpha(60)),
            ),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cinematicGold.withAlpha(45),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: cinematicGold, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      style: const TextStyle(
                          color: cinematicCream,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(color: Color(0xFFC6C7B9), fontSize: 10.5)),
                ]),
              ),
              const Icon(Icons.chevron_left_rounded, color: cinematicGold),
            ]),
          ),
        ),
      );

  Widget _gap(Widget w) => Padding(padding: const EdgeInsets.only(bottom: 10), child: w);

  Widget _goldBtn(String label, IconData? icon, VoidCallback? onTap) => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: Icon(icon ?? Icons.check_rounded, size: 18),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          style: FilledButton.styleFrom(
            backgroundColor: cinematicGold,
            foregroundColor: cinematicDeep,
            disabledBackgroundColor: const Color(0xFF2E5E4D),
            disabledForegroundColor: const Color(0x99FFFFFF),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );

  // الخطوة 0: الصفحة الرئيسية
  Widget _s0Home() => _scroll([
        _screenTitle('الصفحة الرئيسية في نسك'),
        _hint('اضغطي على قسم «الروضة الشريفة» المضيء.'),
        _gap(_mockTile(Icons.flight_takeoff_rounded, 'رحلة العمرة', 'خدمات العمرة',
            () => _wrong('اضغطي على قسم الروضة الشريفة المضيء.'))),
        _gap(_mockTile(Icons.explore_outlined, 'اكتشف', 'المدن والأماكن',
            () => _wrong('اضغطي على قسم الروضة الشريفة المضيء.'))),
        _gap(PulseHighlight(
          radius: 16,
          child: _mockTile(Icons.mosque_rounded, 'الروضة الشريفة', 'تصاريح الصلاة في الروضة', () {
            _audio.play(Sfx.tap);
            _goStep(1);
          }),
        )),
      ]);

  // الخطوة 1: اختيار الخدمة
  Widget _s1Service() {
    final womenTile = _mockTile(Icons.face_3_rounded, 'تصريح الصلاة في الروضة', 'للسيدات', () {
      if (_women) {
        _audio.play(Sfx.tap);
        _goStep(2);
      } else {
        _wrong('هذه الخدمة للسيدات. اختاري خدمة الرجال المضيئة.');
      }
    });
    final menTile = _mockTile(Icons.person_rounded, 'تصريح الصلاة في الروضة', 'للرجال', () {
      if (!_women) {
        _audio.play(Sfx.tap);
        _goStep(2);
      } else {
        _wrong('هذه الخدمة للرجال. اختاري خدمة السيدات المضيئة.');
      }
    });
    return _scroll([
      _screenTitle('خدمة تصريح الصلاة في الروضة'),
      _hint('اختاري الخدمة المناسبة لك: ${_women ? 'للسيدات' : 'للرجال'}. '
          '(تغيير النوع من أعلى الصفحة).'),
      _gap(PulseHighlight(active: _women, radius: 16, child: womenTile)),
      _gap(PulseHighlight(active: !_women, radius: 16, child: menTile)),
    ]);
  }

  // الخطوة 2: المرافقون
  List<String> get _names => _women
      ? const ['أنتِ (الزائرة)', 'مرافقة ١', 'مرافقة ٢']
      : const ['أنت (الزائر)', 'مرافق ١', 'مرافق ٢'];

  Widget _s2Companions() => _scroll([
        _screenTitle('اختيار المرافقين'),
        _hint('اختاري من ستحجزين لهم (أسماء تجريبية)، ثم اضغطي «التالي».'),
        for (int i = 0; i < _names.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: const Color(0xFF14523F),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  _audio.play(Sfx.tap);
                  setState(() {
                    if (!_companions.add(i)) _companions.remove(i);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Icon(
                      _companions.contains(i)
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: cinematicGold,
                    ),
                    const SizedBox(width: 10),
                    Text(_names[i],
                        style: const TextStyle(color: cinematicCream, fontSize: 13.5)),
                  ]),
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        PulseHighlight(
          active: _companions.isNotEmpty,
          radius: 14,
          child: _goldBtn('التالي', Icons.arrow_back_rounded,
              _companions.isEmpty ? null : () => _goStep(3)),
        ),
      ]);

  // الخطوة 3 (أ): اختيار الاسم للدخول إلى صفحة المواعيد
  Widget _s3PickName() {
    final chosen = _companions.toList()..sort();
    return _scroll([
      _screenTitle('المسار الفوري · المحاولة ${_attempts + 1}'),
      _hint('اختاري اسم الشخص ثم ادخلي صفحة المواعيد. لو لم يظهر موعد، ارجعي واختاري الاسم '
          'من جديد. في التدريب يظهر الموعد بعد $_attemptsNeeded محاولات تقريبًا.'),
      for (int k = 0; k < chosen.length; k++)
        _gap(PulseHighlight(
          active: k == 0,
          radius: 16,
          child: _mockTile(Icons.account_circle_rounded, _names[chosen[k]],
              'اضغطي لعرض المواعيد المتاحة', _openSlots),
        )),
    ]);
  }

  void _openSlots() {
    setState(() {
      _attempts += 1;
      _onSlotsPage = true;
      _pickedSlot = null;
    });
    _audio.play(_attempts >= _attemptsNeeded ? Sfx.slot : Sfx.alert);
  }

  // الخطوة 3 (ب): صفحة المواعيد التدريبية
  bool get _slotsAvailable => _attempts >= _attemptsNeeded;

  Widget _s3Slots() => _scroll([
        _screenTitle('صفحة المواعيد (تدريبي)'),
        _hint(_slotsAvailable
            ? 'ظهر موعد بعلامة ⚡! اضغطي عليه فورًا ثم «تأكيد الموعد».'
            : 'لا توجد مواعيد الآن. هذا طبيعي في المسار الفوري: ارجعي وكرري المحاولة.'),
        Row(children: [
          Icon(_women ? Icons.face_3_rounded : Icons.person_rounded,
              color: cinematicGold, size: 16),
          const SizedBox(width: 6),
          Text(_women ? 'مواعيد مخصصة للنساء' : 'مواعيد مخصصة للرجال',
              style: const TextStyle(color: cinematicCream, fontSize: 11.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: cinematicGold,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('تدريبي',
                style: TextStyle(
                    color: cinematicDeep, fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ]),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: [for (int i = 0; i < _slots.length; i++) _slotCell(i)],
        ),
        const SizedBox(height: 10),
        if (_slotsAvailable)
          Text(
            _pickedSlot == null
                ? 'اختاري موعدًا يحمل علامة ⚡'
                : 'موعدك (تدريبي): ${_slots[_pickedSlot!]}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: cinematicCream, fontSize: 12),
          ),
        const SizedBox(height: 8),
        if (_slotsAvailable)
          PulseHighlight(
            active: _pickedSlot != null,
            radius: 14,
            child: _goldBtn('تأكيد الموعد', Icons.arrow_back_rounded,
                _pickedSlot == null ? null : () => _goStep(4)),
          )
        else
          PulseHighlight(
            radius: 14,
            child: _goldBtn('رجوع وإعادة المحاولة', Icons.refresh_rounded, () {
              _audio.play(Sfx.tap);
              setState(() => _onSlotsPage = false);
            }),
          ),
      ]);

  Widget _slotCell(int i) {
    final available = _slotsAvailable && _boltSlots.contains(i);
    final picked = _pickedSlot == i;
    final Color bg = picked
        ? const Color(0xFF3FBF7F)
        : available
            ? const Color(0xFF1E7A57)
            : const Color(0xFF0E4636);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (available) {
            _audio.play(Sfx.tap);
            setState(() => _pickedSlot = i);
          } else {
            _audio.play(Sfx.alert);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: available ? cinematicGold : cinematicGold.withAlpha(35),
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(
              available ? Icons.bolt_rounded : Icons.hourglass_empty_rounded,
              size: 13,
              color: available ? cinematicGold : const Color(0x80F7F0DC),
            ),
            const SizedBox(width: 4),
            Text(_slots[i],
                style: TextStyle(
                    color: available ? Colors.white : const Color(0x80F7F0DC),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }

  // الخطوة 4: المراجعة والموافقة على التعليمات
  Widget _s4Review() => _scroll([
        _screenTitle('مراجعة الطلب'),
        _summaryRow(Icons.mosque_outlined, 'الخدمة',
            'تصريح الصلاة في الروضة (${_women ? 'سيدات' : 'رجال'})'),
        _summaryRow(Icons.group_outlined, 'المرافقون', '${_companions.length}'),
        _summaryRow(Icons.event_available_outlined, 'الموعد',
            '${_slots[_pickedSlot ?? 0]} (تدريبي)'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1A14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('تعليمات دخول الروضة (ملخص)',
                style: TextStyle(
                    color: cinematicGold, fontSize: 12.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            for (final p in kAgreementPoints)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('• $p',
                    style: const TextStyle(color: cinematicCream, fontSize: 11.5, height: 1.5)),
              ),
            const SizedBox(height: 4),
            const Text('في نسك الحقيقي اقرئي التعليمات كاملة قبل الموافقة.',
                style: TextStyle(color: Color(0xFFC6C7B9), fontSize: 10.5)),
          ]),
        ),
        const SizedBox(height: 8),
        PulseHighlight(
          active: !_agreed,
          radius: 12,
          child: Material(
            color: const Color(0xFF14523F),
            borderRadius: BorderRadius.circular(12),
            child: CheckboxListTile(
              value: _agreed,
              onChanged: (v) {
                _audio.play(Sfx.tap);
                setState(() => _agreed = v ?? false);
              },
              checkColor: cinematicGreen,
              activeColor: cinematicGold,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: const Text('أوافق على تعليمات الدخول',
                  style: TextStyle(color: cinematicCream, fontSize: 12.5)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        PulseHighlight(
          active: _agreed,
          radius: 14,
          child: _goldBtn('إصدار التصريح (تدريب)', Icons.verified_rounded,
              _agreed ? () => _goStep(5) : null),
        ),
      ]);

  Widget _summaryRow(IconData icon, String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF14523F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cinematicGold.withAlpha(60)),
        ),
        child: Row(children: [
          Icon(icon, color: cinematicGold, size: 19),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Color(0xFFC6C7B9), fontSize: 11.5)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(color: cinematicCream, fontSize: 12, height: 1.4)),
          ),
        ]),
      );

  // الخطوة 5: النهاية
  Widget _s5Done() => _scroll([
        const SizedBox(height: 18),
        const Icon(Icons.verified_rounded, color: cinematicGold, size: 64),
        const SizedBox(height: 10),
        _screenTitle('أحسنتِ! أنهيتِ التدريب'),
        const Text(
          'هذا تدريب فقط: لم يصدر أي تصريح ولا يوجد أي حجز فعلي، والمواعيد التي رأيتها وهمية.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFE7E0CF), fontSize: 12, height: 1.6),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1A14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('الآن في نسك الحقيقي',
                style: TextStyle(
                    color: cinematicGold, fontSize: 12.5, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('• سجّلي الدخول وجهّزي بياناتك قبل وقت الفتح.',
                style: TextStyle(color: cinematicCream, fontSize: 11.5, height: 1.6)),
            Text('• كرري المحاولة بهدوء حتى يظهر موعد ⚡.',
                style: TextStyle(color: cinematicCream, fontSize: 11.5, height: 1.6)),
            Text('• بعد الإصدار احتفظي بالباركود وراجعي البوابة والوقت.',
                style: TextStyle(color: cinematicCream, fontSize: 11.5, height: 1.6)),
          ]),
        ),
        const SizedBox(height: 14),
        _goldBtn('افتحي نسك الرسمي', Icons.open_in_new_rounded, () => _launch(kNusukServiceUrl)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _restart,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('أعيدي التدريب'),
          style: OutlinedButton.styleFrom(
            foregroundColor: cinematicCream,
            side: BorderSide(color: cinematicGold.withAlpha(140)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ]);

  // ════════════════════════ المعلومات والشروط ════════════════════════

  Widget _infoCard(List<InfoItem> items) => Container(
        padding: const EdgeInsets.all(6),
        decoration: _cardDeco,
        child: Column(children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFEFE6D4)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0D0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(items[i].icon, color: cinematicGreen, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(items[i].title,
                        style: const TextStyle(
                            color: cinematicGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5)),
                    const SizedBox(height: 4),
                    Text(items[i].body,
                        style: const TextStyle(color: _inkSoft, fontSize: 12.5, height: 1.65)),
                    if (items[i].source.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('المصدر: ${items[i].source}',
                            style: const TextStyle(color: Color(0xFFA08A55), fontSize: 10.5)),
                      ),
                  ]),
                ),
              ]),
            ),
          ],
        ]),
      );

  Widget _hoursCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _hoursBlock('الأيام العادية', kWeekdayHours),
          const SizedBox(height: 14),
          _hoursBlock('يوم الجمعة', kFridayHours),
          const SizedBox(height: 6),
          const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.door_front_door_outlined, color: Color(0xFFC09348), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text('الدخول من الساحات الجنوبية أمام باب مكة (37).',
                  style: TextStyle(color: _inkSoft, fontSize: 12, height: 1.5)),
            ),
          ]),
          const SizedBox(height: 8),
          const Text(kHoursCaveat,
              style: TextStyle(color: Color(0xFF8A938C), fontSize: 11, height: 1.5)),
        ]),
      );

  Widget _hoursBlock(String title, List<HoursRow> rows) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: cinematicGreen, fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        for (final r in rows)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: r.who == 'السيدات' ? const Color(0xFFFFF1F6) : const Color(0xFFEFF5FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(r.who == 'السيدات' ? Icons.face_3_rounded : Icons.person_rounded,
                  color: cinematicGreen, size: 20),
              const SizedBox(width: 8),
              SizedBox(
                width: 56,
                child: Text(r.who,
                    style: const TextStyle(
                        color: cinematicGreen, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final s in r.slots)
                    Text('• $s',
                        style: const TextStyle(color: _inkSoft, fontSize: 12.5, height: 1.6)),
                ]),
              ),
            ]),
          ),
      ]);

  Widget _faqCard() => Container(
        decoration: _cardDeco,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Column(children: [
            for (int i = 0; i < kFaq.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: Color(0xFFEFE6D4)),
              ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                iconColor: cinematicGreen,
                collapsedIconColor: cinematicGreen,
                onExpansionChanged: (_) => _audio.play(Sfx.tap),
                title: Text(kFaq[i].q,
                    style: const TextStyle(
                        color: cinematicGreen, fontSize: 13.5, fontWeight: FontWeight.w800)),
                children: [
                  Text(kFaq[i].a,
                      style: const TextStyle(color: _inkSoft, fontSize: 12.5, height: 1.7)),
                ],
              ),
            ],
          ]),
        ),
      );

  Widget _sourcesCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EEE0),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('المصادر وآخر مراجعة',
              style: TextStyle(
                  color: cinematicGreen, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
            'آخر مراجعة للبيانات: أكتوبر 2026. مواعيد فتح الحجز والمسار الفوري مأخوذة من '
            'إنفوجرافيك «صحبة ترانزيت» وهو مصدر غير رسمي، وبقية الشروط من نسك والتصريحات '
            'المعلنة. الأنظمة تتغير، والمرجع النهائي نسك.',
            style: TextStyle(color: _inkSoft, fontSize: 11.5, height: 1.6),
          ),
          const SizedBox(height: 8),
          for (final s in kSources)
            InkWell(
              onTap: () => _launch(s.$2),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  const Icon(Icons.open_in_new_rounded, size: 15, color: Color(0xFFC09348)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.$1,
                        style: const TextStyle(
                            color: cinematicGreen,
                            fontSize: 12,
                            decoration: TextDecoration.underline)),
                  ),
                ]),
              ),
            ),
        ]),
      );

  Widget _bottomActions() => Column(children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              _audio.play(Sfx.tap);
              _launch(kNusukServiceUrl);
            },
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('الانتقال إلى نسك للحجز الرسمي',
                style: TextStyle(fontWeight: FontWeight.w800)),
            style: FilledButton.styleFrom(
              backgroundColor: cinematicGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _launch('tel:$kNusukPhone'),
            icon: const Icon(Icons.phone_in_talk_rounded),
            label: const Text('اتصلي بنسك: $kNusukPhone'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cinematicGreen,
              side: const BorderSide(color: cinematicGold),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (widget.onOpenFullGuide != null) ...[
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: widget.onOpenFullGuide,
            icon: const Icon(Icons.checklist_rtl, color: cinematicGreen),
            label: const Text('الدليل الكامل وقائمة الاستعداد',
                style: TextStyle(color: cinematicGreen)),
          ),
        ],
      ]);
}