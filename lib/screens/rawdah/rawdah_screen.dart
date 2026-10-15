import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../hajj/hajj_duas.dart';
import '../hajj/hajj_duas_page.dart';
import '../hajj/hajj_voice.dart';
import '../umrah/umrah_data.dart';
import 'rawdah_art.dart';
import 'rawdah_data.dart';
import 'rawdah_duas.dart';
import 'rawdah_reminders.dart';
import 'rawdah_simulator.dart';
import 'rawdah_video.dart';

/// حجز الروضة الشريفة: شرح مرئي ومنطوق، محاكي 3D، جدول محاولات وتذكير، أسئلة، وأدعية.
class RawdahScreen extends StatefulWidget {
  const RawdahScreen({super.key});
  @override
  State<RawdahScreen> createState() => _RawdahScreenState();
}

class _RawdahScreenState extends State<RawdahScreen> with SingleTickerProviderStateMixin {
  final store = RawdahStore.I;
  final ValueNotifier<int> _tick = ValueNotifier<int>(0);
  Timer? _timer;
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  bool womanView = false; // عرض أوقات الجدول: رجال/سيدات

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick.value++);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _loop.dispose();
    _tick.dispose();
    HajjSpeaker.I.stop();
    super.dispose();
  }

  void _open(Widget p) {
    HajjSpeaker.I.stop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => p));
  }

  void _say(String t) => HajjSpeaker.I.say(t, rate: .5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) => ListView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: [
            _hero(),
            const SizedBox(height: 14),
            _clockCard(),
            const SizedBox(height: 14),
            _actions(),
            _section('أنا في أنهي مرحلة؟', '🧭'),
            _stages(),
            _section('مواعيد المحاولة', '⏰'),
            _timeTable(),
            _section('المسار الفوري (داخل المدينة)', '⚡'),
            _instant(),
            _section('أسئلة شائعة', '❓'),
            _faq(),
            _section('قبل ما تروح الروضة', '✅'),
            _checklist(),
            _section('صلِّ على النبي ﷺ وادعُ', '🌹'),
            _salawat(),
            _duasPreview(),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 36),
              child: Text(
                'هذا المحتوى إرشادي ومبني على أدلة «صحبة ترانزيت» (دليل 2026 والمسار الفوري). نظام الحجز في تطبيق نسك يتغير من وقت لآخر، فاعتمد دائمًا على التعليمات الحالية داخل نسك. التطبيق ليس تطبيقًا رسميًا لنسك ولا يحجز نيابة عنك.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: UC.muted, height: 1.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════ الهيدر ═══════════
  Widget _hero() => Container(
        height: 250,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A2540), Color(0xFF0F4D42)],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _loop,
                  builder: (_, __) => CustomPaint(painter: DomePainter(_loop.value)),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(.35), Colors.transparent, Colors.black.withOpacity(.55)],
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BackButton(color: Colors.white, onPressed: () => Navigator.pop(context)),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('حجز الروضة الشريفة',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 27,
                                    fontWeight: FontWeight.w900)),
                            SizedBox(height: 4),
                            Text('خطوة بخطوة… ومتشلش هم 🤍',
                                style: TextStyle(color: Color(0xFFFFE08A), fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // ═══════════ الساعة والعد التنازلي ═══════════
  Widget _clockCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ValueListenableBuilder<int>(
        valueListenable: _tick,
        builder: (_, __, ___) {
          final ksa = saudiNow();
          final loc = DateTime.now();
          String two(int v) => v.toString().padLeft(2, '0');
          final noon = untilNextNoon();
          final plan = store.plan;
          final next = plan.isEmpty ? null : plan.first;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF0A2540), Color(0xFF0F4D42)],
              ),
              border: Border.all(color: AppColors.gold.withOpacity(.6)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🇸🇦 الساعة في السعودية',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('${two(ksa.hour)}:${two(ksa.minute)}:${two(ksa.second)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  fontFeatures: [FontFeature.tabularFigures()])),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('📱 عندك',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('${two(loc.hour)}:${two(loc.minute)}',
                            style: const TextStyle(
                                color: Color(0xFFFFE08A),
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 22),
                _countRow('🕛 مواعيد جديدة (12 ظهرًا) بعد', fmtDur(noon)),
                if (next != null) ...[
                  const SizedBox(height: 8),
                  _countRow('⏳ محاولتك القادمة: ${next.title} بعد', fmtDur(next.remaining)),
                ],
                const SizedBox(height: 4),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _countRow(String l, String v) => Row(
        children: [
          Expanded(
              child: Text(l, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(.25), borderRadius: BorderRadius.circular(12)),
            child: Text(v,
                style: const TextStyle(
                    color: Color(0xFFFFE08A),
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ),
        ],
      );

  // ═══════════ الأزرار الرئيسية ═══════════
  Widget _actions() {
    Widget tile(String e, String t, String s, List<Color> c, VoidCallback on) => Expanded(
          child: GestureDetector(
            onTap: on,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                    begin: Alignment.topRight, end: Alignment.bottomLeft, colors: c),
                boxShadow: [
                  BoxShadow(
                      color: c.last.withOpacity(.3), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  Text(e, style: const TextStyle(fontSize: 30)),
                  const SizedBox(height: 6),
                  Text(t,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(s,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              tile('🎬', 'شاهد الشرح', 'فيديو بالصوت والصورة',
                  const [Color(0xFF0A2540), Color(0xFF1C5C7A)],
                  () => _open(const RawdahVideoPage())),
              tile('🧊', 'جرّب الحجز 3D', 'تدرّب بدون خوف',
                  const [Color(0xFF0F4D42), Color(0xFF2E8B6A)],
                  () => _open(const RawdahSimulatorPage())),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              tile('⏰', 'ذكّرني بالحجز', store.visitDay == null ? 'احسب مواعيدك' : 'جدولك جاهز ✓',
                  const [Color(0xFF8A5A10), Color(0xFFC9992E)],
                  () => _open(const RawdahPlannerPage())),
              tile('🤲', 'أدعية وصلوات', '${rawdahDuas.length} دعاءً بالصوت',
                  const [Color(0xFF6B3F73), Color(0xFF45254D)],
                  () => _open(const HajjDuasPage(
                        duas: rawdahDuas,
                        cats: rawdahDuaCats,
                        title: 'أدعية الروضة والصلاة على النبي ﷺ',
                      ))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String t, String e) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
        child: Row(
          children: [
            Text(e, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(t,
                style: const TextStyle(
                    color: UC.ink, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      );

  // ═══════════ المراحل ═══════════
  Widget _stages() {
    final cur = rStages.firstWhere((s) => s.id == store.stage, orElse: () => rStages[2]);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final s in rStages)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: () => store.setStage(s.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: s.id == cur.id ? AppColors.greenDark : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: s.id == cur.id ? AppColors.gold : UC.border),
                        ),
                        child: Text('${s.emoji} ${s.title}',
                            style: TextStyle(
                                color: s.id == cur.id ? Colors.white : UC.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Container(
              key: ValueKey(cur.id),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: UC.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(cur.summary,
                            style: const TextStyle(
                                color: AppColors.greenDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                height: 1.5)),
                      ),
                      IconButton(
                        onPressed: () => _say('${cur.summary} ${cur.steps.join('. ')}'),
                        icon: const Icon(Icons.volume_up_rounded, color: AppColors.greenDark),
                      ),
                    ],
                  ),
                  for (int k = 0; k < cur.steps.length; k++)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: AppColors.gold),
                            child: Text('${k + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, color: Color(0xFF3B2A00))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(cur.steps[k],
                                style: const TextStyle(color: UC.ink, height: 1.65, fontSize: 14.5)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════ جدول المواعيد ═══════════
  Widget _timeTable() {
    final t = womanView ? '5:44 م' : '5:40 م';
    final rows = <List<String>>[
      ['📅', 'قبل موعد الزيارة بأسبوع (7 أيام)', t],
      ['🗓️', 'قبل الموعد بيومين', t],
      ['🌙', 'قبل الموعد بيوم', '10:00 م'],
      ['🕛', 'كل يوم لو ملقتش مواعيد', '12:00 ظهرًا'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: UC.border)),
        child: Column(
          children: [
            Row(
              children: [
                for (final w in const [false, true])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => womanView = w),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: womanView == w ? AppColors.greenDark : AppColors.softGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(w ? '🧕 السيدات' : '🧔 الرجال',
                            style: TextStyle(
                                color: womanView == w ? Colors.white : UC.ink,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            for (final r in rows)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F0), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Text(r[0], style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(r[1],
                          style: const TextStyle(
                              color: UC.ink, fontWeight: FontWeight.w700, height: 1.4)),
                    ),
                    Text(r[2],
                        style: const TextStyle(
                            color: Color(0xFFE8730C), fontWeight: FontWeight.w900, fontSize: 15)),
                  ],
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.softGold, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                '💡 المهم: ادخل في الوقت المحدد بالضبط، وكن مستعدًا قبلها بدقائق. كل الأوقات بتوقيت السعودية.',
                style: TextStyle(color: UC.ink, height: 1.6, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _open(const RawdahPlannerPage()),
              icon: const Icon(Icons.event_available_rounded),
              label: const Text('احسب مواعيدي بالتاريخ وبتوقيتي'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════ المسار الفوري ═══════════
  Widget _instant() {
    const flow = [
      ['1', 'اختر الاسم', '👤'],
      ['2', 'ادخل صفحة المواعيد', '📋'],
      ['3', 'ظهر موعد ⚡؟ احجز فورًا', '✅'],
      ['4', 'ما ظهر؟ ارجع واختر الاسم', '🔁'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF0A2540), Color(0xFF0F4D42)]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'خدمة تتيح لزائر المدينة حجز تصريح الصلاة في الروضة كل 24 ساعة عبر نسك. لا يوجد زر باسمها، وتظهر مواعيدها بعلامة ⚡ بين المواعيد المتاحة، غالبًا كل 20 دقيقة.',
              style: TextStyle(color: Colors.white, height: 1.7),
            ),
            const SizedBox(height: 12),
            for (final f in flow)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.1),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.gold,
                        child: Text(f[0],
                            style: const TextStyle(
                                color: Color(0xFF3B2A00), fontWeight: FontWeight.w900))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(f[1],
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700))),
                    Text(f[2], style: const TextStyle(fontSize: 20)),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0x33FFD66B), borderRadius: BorderRadius.circular(12)),
              child: const Text(
                '⚠️ المواعيد الجديدة لا تظهر تلقائيًا، فكرّر الخطوات، وقد يُطرح موعد في أي لحظة. وهي لنفس اليوم فقط، ولمن هو بالمدينة قرب المسجد النبوي مع تفعيل GPS.',
                style: TextStyle(color: Colors.white, height: 1.6, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _open(const RawdahSimulatorPage()),
                icon: const Icon(Icons.view_in_ar_rounded, color: AppColors.gold),
                label: const Text('تدرّب عليها في المحاكي',
                    style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════ الأسئلة ═══════════
  Widget _faq() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            for (final f in rFaq)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: UC.border)),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                    childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    title: Text(f.q,
                        style: const TextStyle(
                            color: UC.ink, fontWeight: FontWeight.w800, fontSize: 14.5)),
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(f.a,
                            style: const TextStyle(color: UC.ink, height: 1.7, fontSize: 14)),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _say('${f.q}. ${f.a}'),
                          icon: const Icon(Icons.volume_up_rounded, size: 18),
                          label: const Text('اسمع الإجابة'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );

  // ═══════════ قائمة التحقق ═══════════
  Widget _checklist() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: UC.border)),
          child: Column(
            children: [
              for (int k = 0; k < rChecklist.length; k++)
                CheckboxListTile(
                  value: store.checked.contains(k),
                  onChanged: (_) {
                    HapticFeedback.selectionClick();
                    store.toggleCheck(k);
                  },
                  activeColor: AppColors.greenDark,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(rChecklist[k],
                      style: const TextStyle(color: UC.ink, fontSize: 14, height: 1.5)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: LinearProgressIndicator(
                  value: store.checked.length / rChecklist.length,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(6),
                  color: AppColors.gold,
                  backgroundColor: AppColors.softGold,
                ),
              ),
            ],
          ),
        ),
      );

  // ═══════════ الصلاة على النبي ﷺ ═══════════
  Widget _salawat() {
    const goal = 100;
    final n = store.salawat;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF0F5E45), Color(0xFF083D2D)]),
          border: Border.all(color: AppColors.gold.withOpacity(.7)),
        ),
        child: Column(
          children: [
            const Text('اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white, fontSize: 20, height: 1.9, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('من صلى عليه صلاة صلى الله عليه بها عشرًا (مسلم)',
                style: TextStyle(color: Color(0xFFFFE08A), fontSize: 12.5)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                store.addSalawat();
                if (store.salawat % 100 == 0) HapticFeedback.heavyImpact();
              },
              child: SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: CircularProgressIndicator(
                        value: (n % goal) / goal,
                        strokeWidth: 8,
                        color: AppColors.gold,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$n',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                        const Text('اضغط',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _say('اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ'),
                  icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
                  label: const Text('اسمعها', style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: store.resetSalawat,
                  child: const Text('تصفير', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _duasPreview() {
    final ids = ['r_salam_rasul', 'r_ease', 'r_ibrahimi'];
    final list = <HDua>[];
    for (final d in rawdahDuas) {
      if (ids.contains(d.id)) list.add(d);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          for (final d in list)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: UC.border)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.title,
                            style: const TextStyle(
                                color: AppColors.greenDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(d.ar,
                            style: const TextStyle(
                                color: UC.ink,
                                fontSize: 17,
                                height: 1.9,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => HajjSpeaker.I.say(d.ar, rate: d.rate),
                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.greenDark),
                  ),
                ],
              ),
            ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.greenDark,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => _open(const HajjDuasPage(
              duas: rawdahDuas,
              cats: rawdahDuaCats,
              title: 'أدعية الروضة والصلاة على النبي ﷺ',
            )),
            icon: const Icon(Icons.menu_book_rounded),
            label: Text('كل الأدعية والصلوات (${rawdahDuas.length})'),
          ),
        ],
      ),
    );
  }
}
