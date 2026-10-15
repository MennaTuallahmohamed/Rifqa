import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../umrah/umrah_data.dart';
import 'hajj_3d.dart';
import 'hajj_data.dart';
import 'hajj_duas_page.dart';
import 'hajj_tools.dart';
import 'hajj_voice.dart';
import 'widgets/hajj_header.dart';
import 'widgets/hajj_progress.dart';
import 'widgets/hajj_step_card.dart';

/// شاشة الحج: رحلة من 8 مناسك بصوت وصورة و3D، وأدعية كاملة، ووضع مرشد.
class HajjScreen extends StatefulWidget {
  const HajjScreen({super.key});

  @override
  State<HajjScreen> createState() => _HajjScreenState();
}

class _HajjScreenState extends State<HajjScreen> {
  final HajjStore store = HajjStore.I;
  final ScrollController _scroll = ScrollController();
  final GlobalKey _cardKey = GlobalKey();
  bool _touring = false;

  @override
  void dispose() {
    _touring = false;
    HajjSpeaker.I.stop();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToCard() {
    final ctx = _cardKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: .02);
  }

  void _open(Widget page) {
    HajjSpeaker.I.stop();
    setState(() => _touring = false);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _startTour() async {
    setState(() => _touring = true);
    for (int i = store.step; i < hajjGuide.length; i++) {
      if (!_touring || !mounted) break;
      store.go(i);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCard());
      await HajjSpeaker.I.say(hajjStepNarration(hajjGuide[i], i));
      if (!_touring || !mounted) break;
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }
    if (mounted) setState(() => _touring = false);
  }

  void _stopTour() {
    setState(() => _touring = false);
    HajjSpeaker.I.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final i = store.step;
          final allDone = store.done.length == hajjGuide.length;
          return ListView(
            controller: _scroll,
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            children: [
              HajjHeader(
                done: store.done.length,
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              _tools(),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('مسار حجّك',
                    style: TextStyle(
                        color: UC.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: HajjProgress(
                  current: i,
                  isDone: (k) => store.done.contains(k),
                  onTap: (k) {
                    HajjSpeaker.I.stop();
                    setState(() => _touring = false);
                    store.go(k);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                key: _cardKey,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HajjStepCard(
                  key: ValueKey('hajj-step-$i'),
                  step: hajjGuide[i],
                  index: i,
                  touring: _touring,
                  onTour: _startTour,
                  onStop: _stopTour,
                  onGuideDone: () {
                    store.complete();
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _scrollToCard());
                  },
                ),
              ),
              if (allDone) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _congrats(),
                ),
              ],
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _nav(i),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 18, 24, 34),
                child: Text(
                  'هذا المحتوى إرشادي لتنظيم رحلة الحج ولا يُعد فتوى شخصية. الأحكام قد تختلف بحسب نوع النسك والحالة؛ ارجع إلى أهل العلم ومرشد حملتك عند الحاجة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: UC.muted, height: 1.6),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ───── شريط الأدوات
  Widget _tools() {
    final items = <_Tool>[
      _Tool('🤲', 'أدعية الحج', const [Color(0xFF0F5E45), Color(0xFF083D2D)],
          () => _open(const HajjDuasPage())),
      _Tool('🧊', 'رحلة 3D كاملة', const [Color(0xFF0A1F3D), Color(0xFF0F3B3A)],
          () => _open(const HajjJourney3DPage())),
      _Tool(
          '🌙',
          'التقط الحصى 3D',
          const [Color(0xFF1A2E56), Color(0xFF050C1F)],
          () => _open(const HajjMuzdalifah3DPage())),
      _Tool('🌟', 'أنواع النسك', const [Color(0xFF8A6A1E), Color(0xFFB88A2E)],
          () => _open(const HajjTypesPage())),
      _Tool('📅', 'أيام الحج', const [Color(0xFF3A5A8C), Color(0xFF1F3B63)],
          () => _open(const HajjCalendarPage())),
      _Tool('❓', 'أسئلة شائعة', const [Color(0xFF6B3F73), Color(0xFF45254D)],
          () => _open(const HajjFaqPage())),
      _Tool('🏅', 'اختبر نفسك', const [Color(0xFFB04A3B), Color(0xFF7D2D22)],
          () => _open(const HajjQuizPage())),
    ];
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, k) {
          final t = items[k];
          return GestureDetector(
            onTap: t.on,
            child: Container(
              width: 92,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: t.colors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: t.colors.last.withOpacity(.28),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(t.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ───── التنقل
  Widget _nav(int i) {
    final last = i == hajjGuide.length - 1;
    final done = store.done.contains(i);
    return Row(
      children: [
        if (i > 0) ...[
          OutlinedButton(
            onPressed: () {
              HajjSpeaker.I.stop();
              setState(() => _touring = false);
              store.go(i - 1);
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _scrollToCard());
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.greenDark,
              side: const BorderSide(color: AppColors.green),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('السابقة'),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: FilledButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              HajjSpeaker.I.stop();
              setState(() => _touring = false);
              if (last) {
                store.done.add(i);
                store.go(i);
              } else {
                store.complete();
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToCard());
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.greenDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              last
                  ? (done ? 'تقبّل الله حجّك ✓' : 'أتممت خطوات الرحلة')
                  : 'تمّت هذه الخطوة ← التالية',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _congrats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.gold, Color(0xFFB88A2E)],
        ),
      ),
      child: Column(
        children: [
          const Text('🤲', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 6),
          const Text('تقبّل الله حجّك',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          const Text(
            'أتممت مناسك الرحلة كلها. اللهم اجعله حجًّا مبرورًا وسعيًا مشكورًا وذنبًا مغفورًا.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, height: 1.6),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => HajjSpeaker.I.say(
                    'اللَّهُمَّ اجْعَلْهُ حَجًّا مَبْرُورًا، وَسَعْيًا مَشْكُورًا، وَذَنْبًا مَغْفُورًا',
                    rate: .38),
                icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
                label: const Text('اسمع الدعاء',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              TextButton(
                onPressed: () {
                  HajjSpeaker.I.stop();
                  store.reset();
                },
                child: const Text('إعادة الرحلة',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tool {
  final String emoji, label;
  final List<Color> colors;
  final VoidCallback on;
  const _Tool(this.emoji, this.label, this.colors, this.on);
}
