import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../../state/app_state.dart';
import 'umrah_data.dart';
import 'umrah_tools.dart';
import 'umrah_voice.dart';
import 'umrah_art.dart';
import 'umrah_3d.dart';

class _Tool {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final Widget page;
  const _Tool(this.label, this.icon, this.colors, this.page);
}

class UmrahScreen extends StatefulWidget {
  const UmrahScreen({super.key});
  @override
  State<UmrahScreen> createState() => _UmrahScreenState();
}

class _UmrahScreenState extends State<UmrahScreen> {
  int tab = 0;
  double duaScale = 1.0;
  bool _touring = false;

  @override
  void dispose() {
    UVoice.I.stop();
    super.dispose();
  }

  void _stopAudio() {
    _touring = false;
    UVoice.I.stop();
    if (mounted) setState(() {});
  }

  Future<void> _startTour() async {
    final st = AppScope.of(context);
    setState(() => _touring = true);
    for (int k = st.step; k < 7 && _touring; k++) {
      st.change(() => st.step = k);
      final ok = await UVoice.I.speak(stepNarration(umrahGuide[k], k));
      if (!ok || !_touring || !mounted) break;
      final ok2 =
          await UVoice.I.speak('الدعاء: ${umrahGuide[k].dua}', rate: .36);
      if (!ok2 || !_touring || !mounted) break;
    }
    if (mounted) setState(() => _touring = false);
  }

  int _lastStep = -1;

  static const _tools = <_Tool>[
    _Tool('طواف 3D', Icons.view_in_ar_rounded, UC.emerald, Tawaf3DPage()),
    _Tool('سعي 3D', Icons.directions_walk_rounded, UC.plum, Sai3DPage()),
    _Tool('المواقيت', Icons.explore_rounded, UC.sky, MawaqitPage()),
    _Tool('المحظورات', Icons.block_rounded, UC.rose, IhramRulesPage()),
    _Tool('أسئلة شائعة', Icons.help_rounded, UC.plum, FaqPage()),
    _Tool('اختبر نفسك', Icons.quiz_rounded, UC.gold, QuizPage()),
    _Tool('حقيبتك', Icons.luggage_rounded, UC.teal, ChecklistPage()),
  ];

  @override
  Widget build(BuildContext c) {
    final st = AppScope.of(c);
    final i = st.step.clamp(0, 6).toInt();
    final s = umrahGuide[i];
    if (i != _lastStep) {
      tab = 0;
      _lastStep = i;
    }
    final doneCount = st.done.length;

    return Scaffold(
      backgroundColor: UC.ivory,
      body: Container(
        color: UC.ivory,
        child: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          _Header(done: doneCount),
          const SizedBox(height: 18),

          // أدواتك
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text('أدوات تساعدك',
                style: TextStyle(
                    color: UC.ink, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final t in _tools)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 10),
                    child: _ToolChip(
                      tool: t,
                      onTap: () => Navigator.push(
                          c, MaterialPageRoute(builder: (_) => t.page)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // مسار الرحلة
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text('مسار عمرتك',
                style: TextStyle(
                    color: UC.ink, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _PathRow(
              current: i,
              isDone: (k) => st.done.contains(k),
              onTap: (k) {
                _stopAudio();
                st.change(() => st.step = k);
              },
            ),
          ),
          const SizedBox(height: 14),

          // بطاقة الخطوة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: UCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: s.colors,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: s.colors.last.withOpacity(.35),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child:
                            Text(s.emoji, style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('الخطوة ${i + 1} من 7',
                                style: const TextStyle(
                                    color: UC.muted, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(s.title,
                                style: const TextStyle(
                                    color: UC.ink,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Badge(s.rank, _rankColor(s.rank)),
                      _Badge('⏱ ${s.duration}', AppColors.softGreen),
                    ],
                  ),
                  const SizedBox(height: 12),
                  UStepArt(index: i, colors: s.colors),
                  const SizedBox(height: 12),
                  Text(s.summary,
                      style: const TextStyle(
                          color: UC.muted, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 16),
                  _VoiceBar(
                    touring: _touring,
                    onExplain: () => UVoice.I.speak(stepNarration(s, i)),
                    onDua: () => UVoice.I.speak(s.dua, rate: .36),
                    onTour: _startTour,
                    onStop: _stopAudio,
                  ),
                  const SizedBox(height: 14),
                  _Tabs(sel: tab, on: (k) => setState(() => tab = k)),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey('$i-$tab'),
                      child: _tabBody(c, s),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (s.sim != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _Open3D(
                    label: s.sim == 'tawaf'
                        ? 'جرّب الطواف حول الكعبة بالـ3D'
                        : 'جرّب السعي بين الصفا والمروة بالـ3D',
                    page: s.sim == 'tawaf'
                        ? const Tawaf3DPage()
                        : const Sai3DPage(),
                  ),
                  const SizedBox(height: 12),
                  CounterCard(type: s.sim!),
                ],
              ),
            ),
          ],

          if (doneCount >= 7) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _Congrats(
                onReset: () => st.change(() {
                  st.done.clear();
                  st.step = 0;
                  st.tawaf = 0;
                  st.sai = 0;
                }),
              ),
            ),
          ],

          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (i > 0) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.greenDark,
                      side: const BorderSide(color: AppColors.green),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      _stopAudio();
                      st.change(() => st.step--);
                    },
                    child: const Text('السابقة'),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: PrimaryButton(
                    i < 6
                        ? 'تمّت هذه الخطوة ← التالية'
                        : 'أتممت العمرة، تقبّل الله',
                    onTap: () {
                      _stopAudio();
                      HapticFeedback.lightImpact();
                      st.change(() {
                        st.done.add(st.step);
                        if (st.step < 6) st.step++;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 14, 24, 28),
            child: Text(
              'محتوى إرشادي يعتمد على ما عليه جمهور أهل العلم، وللفتوى في حالتك الخاصة راجع أهل العلم.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: UC.muted, height: 1.5),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Color _rankColor(String r) {
    if (r == 'ركن') return AppColors.softGold;
    if (r == 'واجب') return AppColors.softRed;
    return AppColors.softGreen;
  }

  Widget _tabBody(BuildContext c, UStep s) {
    switch (tab) {
      case 1:
        return _duaBody(c, s);
      case 2:
        return _errorsBody(s);
      default:
        return _howBody(s);
    }
  }

  // ───────── الشرح ─────────
  Widget _howBody(UStep s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int k = 0; k < s.how.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: s.colors),
                  ),
                  child: Text('${k + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(s.how[k],
                        style: const TextStyle(
                            color: UC.ink, fontSize: 15, height: 1.6)),
                  ),
                ),
              ],
            ),
          ),
        InfoBox('💡 نصيحة', s.tip, AppColors.softGold),
        if (s.women != null)
          InfoBox('🌸 للمرأة', s.women!, const Color(0xFFF3EAF8)),
      ],
    );
  }

  // ───────── الدعاء ─────────
  Widget _duaBody(BuildContext c, UStep s) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [AppColors.greenDark, Color(0xFF083D2D)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child:
                    CustomPaint(painter: const UPatternPainter(opacity: .06)),
              ),
              Column(
                children: [
                  const Text('✦',
                      style: TextStyle(color: AppColors.gold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    s.dua,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20 * duaScale,
                      height: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              tooltip: 'تصغير الخط',
              onPressed: () =>
                  setState(() => duaScale = math.max(.85, duaScale - .15)),
              icon: const Icon(Icons.text_decrease_rounded),
              color: AppColors.greenDark,
            ),
            IconButton(
              tooltip: 'تكبير الخط',
              onPressed: () =>
                  setState(() => duaScale = math.min(1.6, duaScale + .15)),
              icon: const Icon(Icons.text_increase_rounded),
              color: AppColors.greenDark,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: s.dua));
                ScaffoldMessenger.of(c).showSnackBar(
                  const SnackBar(content: Text('تم نسخ الدعاء')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('نسخ'),
              style: TextButton.styleFrom(foregroundColor: AppColors.greenDark),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.softGold,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(s.duaNote,
              style: const TextStyle(color: UC.ink, fontSize: 13, height: 1.5)),
        ),
      ],
    );
  }

  // ───────── الأخطاء الشائعة ─────────
  Widget _errorsBody(UStep s) {
    return Column(
      children: [
        for (final e in s.errors)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: UC.border),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.softRed,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('❌ '),
                      Expanded(
                        child: Text(e.wrong,
                            style: const TextStyle(
                                color: UC.ink,
                                fontWeight: FontWeight.w700,
                                height: 1.5)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.softGreen,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✅ '),
                      Expanded(
                        child: Text(e.right,
                            style: const TextStyle(color: UC.ink, height: 1.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════ الهيدر ═══════════════════════
class _Header extends StatelessWidget {
  final int done;
  const _Header({required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.green, AppColors.greenDark, Color(0xFF083D2D)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: UPatternPainter()),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('دليل العمرة',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 27,
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text('سبع خطوات بين النية والتحلل',
                                  style: TextStyle(
                                      color: UC.goldLight.withOpacity(.95),
                                      fontSize: 13.5)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 66,
                          height: 66,
                          child: CustomPaint(
                            painter: _HeaderRing(done / 7),
                            child: Center(
                              child: Text('$done/7',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _HeroChip('ركن: الإحرام'),
                        _HeroChip('ركن: الطواف'),
                        _HeroChip('ركن: السعي'),
                        _HeroChip('واجب: الحلق أو التقصير'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String text;
  const _HeroChip(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withOpacity(.6)),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );
}

class _HeaderRing extends CustomPainter {
  final double value;
  _HeaderRing(this.value);
  @override
  void paint(Canvas canvas, Size size) {
    const w = 7.0;
    final r = (Offset.zero & size).deflate(w / 2);
    canvas.drawArc(
        r,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = Colors.white24);
    if (value > 0) {
      canvas.drawArc(
          r,
          -math.pi / 2,
          math.pi * 2 * value,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = w
            ..color = AppColors.gold);
    }
  }

  @override
  bool shouldRepaint(covariant _HeaderRing old) => old.value != value;
}

// ═══════════════════════ أدوات ═══════════════════════
class _ToolChip extends StatelessWidget {
  final _Tool tool;
  final VoidCallback onTap;
  const _ToolChip({required this.tool, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 88,
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: UC.border),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(colors: tool.colors),
                ),
                child: Icon(tool.icon, color: Colors.white, size: 23),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(tool.label,
                    style: const TextStyle(
                        color: UC.ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════ مسار الخطوات ═══════════════════════
class _PathRow extends StatelessWidget {
  final int current;
  final bool Function(int) isDone;
  final ValueChanged<int> onTap;
  const _PathRow(
      {required this.current, required this.isDone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const lineOn = AppColors.gold;
    final lineOff = UC.border;
    return Row(
      children: [
        for (int i = 0; i < 7; i++)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onTap(i),
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 3,
                                color: i == 0
                                    ? Colors.transparent
                                    : (isDone(i - 1) ? lineOn : lineOff),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 3,
                                color: i == 6
                                    ? Colors.transparent
                                    : (isDone(i) ? lineOn : lineOff),
                              ),
                            ),
                          ],
                        ),
                        _Node(index: i, current: i == current, done: isDone(i)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        umrahGuide[i].tabLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: i == current ? AppColors.greenDark : UC.muted,
                          fontWeight:
                              i == current ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  final int index;
  final bool current, done;
  const _Node({required this.index, required this.current, required this.done});

  @override
  Widget build(BuildContext context) {
    final size = current ? 38.0 : 32.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: current
            ? const LinearGradient(
                colors: [AppColors.green, AppColors.greenDark])
            : null,
        color: current ? null : (done ? AppColors.gold : Colors.white),
        border: Border.all(
          color: current ? AppColors.gold : (done ? AppColors.gold : UC.border),
          width: current ? 2.5 : 1.5,
        ),
        boxShadow: current
            ? [
                BoxShadow(
                  color: AppColors.green.withOpacity(.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: done && !current
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : Text('${index + 1}',
              style: TextStyle(
                color: current ? Colors.white : UC.muted,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              )),
    );
  }
}

// ═══════════════════════ مكونات صغيرة ═══════════════════════
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: const TextStyle(
                color: UC.ink, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class _Tabs extends StatelessWidget {
  final int sel;
  final ValueChanged<int> on;
  const _Tabs({required this.sel, required this.on});

  static const labels = ['الشرح', 'الدعاء', 'أخطاء شائعة'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (int k = 0; k < labels.length; k++)
            Expanded(
              child: GestureDetector(
                onTap: () => on(k),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel == k ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: sel == k
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(labels[k],
                      style: TextStyle(
                        color: sel == k ? AppColors.greenDark : UC.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      )),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Congrats extends StatelessWidget {
  final VoidCallback onReset;
  const _Congrats({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: UC.gold),
      ),
      child: Column(
        children: [
          const Text('🤲', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 6),
          const Text('تقبّل الله عمرتك',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
              'أتممت الخطوات السبع. نسأل الله أن يجعلها مبرورة وذنبك مغفورًا.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, height: 1.5)),
          TextButton(
            onPressed: onReset,
            child: const Text('ابدأ عمرة جديدة',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class InfoBox extends StatelessWidget {
  final String title, text;
  final Color color;
  final bool center;
  const InfoBox(this.title, this.text, this.color,
      {super.key, this.center = false});

  @override
  Widget build(BuildContext c) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment:
              center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(text,
                textAlign: center ? TextAlign.center : null,
                style: TextStyle(
                    fontSize: center ? 20 : 14.5,
                    height: center ? 1.8 : 1.5,
                    color: AppColors.ink)),
          ],
        ),
      );
}

// ═══════════════════════ عدّاد المحاكاة ═══════════════════════
class CounterCard extends StatelessWidget {
  final String type;
  const CounterCard({super.key, required this.type});

  String _hint(bool isT, int n) {
    if (isT) {
      if (n >= 7) return 'أتممت 7 أشواط 🎉 الآن صلِّ ركعتي الطواف';
      if (n < 3) {
        return 'الشوط ${n + 1}: للرجال رمل واضطباع، وللنساء مشي بسكينة';
      }
      return 'الشوط ${n + 1}: امشِ بهدوء وادعُ بما تحب';
    }
    if (n >= 7) return 'أتممت 7 أشواط 🎉 الآن احلق أو قصّر';
    final from = n.isEven ? 'الصفا' : 'المروة';
    final to = n.isEven ? 'المروة' : 'الصفا';
    return 'الشوط ${n + 1}: من $from إلى $to';
  }

  @override
  Widget build(BuildContext c) {
    final st = AppScope.of(c);
    final isT = type == 'tawaf';
    final int n = isT ? st.tawaf : st.sai;

    return UCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.touch_app_rounded,
                  color: Color(0xFF7A5B12), size: 20),
              const SizedBox(width: 6),
              Text(isT ? 'محاكاة الطواف' : 'محاكاة السعي',
                  style: const TextStyle(
                      color: Color(0xFF7A5B12), fontWeight: FontWeight.w800)),
            ],
          ),
          SizedBox(
            height: 210,
            width: double.infinity,
            child: CustomPaint(
              painter: isT ? TawafPainter(n) : SaiPainter(n),
            ),
          ),
          Text('$n / 7',
              style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int k = 0; k < 7; k++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: k < n ? AppColors.gold : UC.border,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_hint(isT, n),
              textAlign: TextAlign.center,
              style: const TextStyle(color: UC.ink, height: 1.5)),
          const SizedBox(height: 12),
          PrimaryButton(
            isT ? 'أتممت شوطًا' : 'وصلت الطرف الآخر',
            onTap: n >= 7
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    st.change(() {
                      if (isT) {
                        st.tawaf++;
                      } else {
                        st.sai++;
                      }
                    });
                  },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: n == 0
                    ? null
                    : () => st.change(() {
                          if (isT) {
                            st.tawaf--;
                          } else {
                            st.sai--;
                          }
                        }),
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text('تراجع'),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.greenDark),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => st.change(() {
                  if (isT) {
                    st.tawaf = 0;
                  } else {
                    st.sai = 0;
                  }
                }),
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('إعادة العدّاد'),
                style: TextButton.styleFrom(foregroundColor: UC.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _paintLabel(Canvas c, String t, Offset center,
    {double size = 11,
    Color color = UC.muted,
    FontWeight w = FontWeight.w700}) {
  final tp = TextPainter(
    text: TextSpan(
        text: t, style: TextStyle(fontSize: size, color: color, fontWeight: w)),
    textDirection: TextDirection.rtl,
  )..layout();
  tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
}

class TawafPainter extends CustomPainter {
  final int n;
  TawafPainter(this.n);

  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height / 2 + 6);
    const radius = 70.0;
    final frac = n.clamp(0, 7) / 7;

    // المسار
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = UC.border;
    c.drawCircle(center, radius, track);

    // التقدم (الطواف عكس عقارب الساعة والكعبة عن اليسار)
    if (frac > 0) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 12
        ..color = AppColors.gold;
      c.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2,
          -2 * math.pi * frac, false, p);
    }

    // الكعبة
    final kaaba = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 44, height: 44),
        const Radius.circular(3));
    c.drawRRect(kaaba, Paint()..color = const Color(0xFF111111));
    c.drawRect(
        Rect.fromCenter(center: center.translate(0, -8), width: 44, height: 5),
        Paint()..color = AppColors.gold);

    // خط البداية: الحجر الأسود
    final start = Offset(center.dx, center.dy - radius);
    c.drawLine(
        start.translate(0, -12),
        start.translate(0, 12),
        Paint()
          ..color = const Color(0xFF2E9D6F)
          ..strokeWidth = 3);
    _paintLabel(c, 'الحجر الأسود', start.translate(0, -22), size: 11);

    // الطائف
    final ang = -math.pi / 2 - 2 * math.pi * frac;
    final pos = Offset(
        center.dx + radius * math.cos(ang), center.dy + radius * math.sin(ang));
    c.drawCircle(pos, 11, Paint()..color = Colors.white);
    c.drawCircle(pos, 8, Paint()..color = AppColors.green);

    _paintLabel(c, 'الكعبة', center.translate(0, 38), size: 11);
  }

  @override
  bool shouldRepaint(covariant TawafPainter old) => old.n != n;
}

class SaiPainter extends CustomPainter {
  final int n;
  SaiPainter(this.n);

  @override
  void paint(Canvas c, Size s) {
    final y = s.height / 2 + 6;
    const pad = 34.0;

    // الطريق
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(pad, y - 6, s.width - pad * 2, 12),
            const Radius.circular(6)),
        Paint()..color = UC.border);

    // منطقة الهرولة بين العلمين الأخضرين
    final zone = Rect.fromLTWH(s.width * .38, y - 6, s.width * .24, 12);
    c.drawRect(zone, Paint()..color = const Color(0xFF2E9D6F));
    final post = Paint()
      ..color = const Color(0xFF2E9D6F)
      ..strokeWidth = 3;
    c.drawLine(Offset(zone.left, y - 18), Offset(zone.left, y + 18), post);
    c.drawLine(Offset(zone.right, y - 18), Offset(zone.right, y + 18), post);
    _paintLabel(c, 'العلمان الأخضران', Offset(s.width / 2, y + 32), size: 10.5);

    // الصفا والمروة
    for (final x in [pad, s.width - pad]) {
      final tri = Path()
        ..moveTo(x - 16, y - 8)
        ..lineTo(x, y - 34)
        ..lineTo(x + 16, y - 8)
        ..close();
      c.drawPath(tri, Paint()..color = const Color(0xFF8A7A5A));
    }
    _paintLabel(c, 'الصفا', Offset(pad, y - 48), size: 12, color: UC.ink);
    _paintLabel(c, 'المروة', Offset(s.width - pad, y - 48),
        size: 12, color: UC.ink);

    // الساعي
    final x = n.isEven ? pad : s.width - pad;
    final pos = Offset(x, y);
    c.drawCircle(pos, 13, Paint()..color = Colors.white);
    c.drawCircle(pos, 10, Paint()..color = AppColors.green);
  }

  @override
  bool shouldRepaint(covariant SaiPainter old) => old.n != n;
}

// ═══════════════════════ الصوت و 3D ═══════════════════════
class _VoiceBar extends StatelessWidget {
  final bool touring;
  final VoidCallback onExplain, onDua, onTour, onStop;
  const _VoiceBar({
    required this.touring,
    required this.onExplain,
    required this.onDua,
    required this.onTour,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: UVoice.I.speaking,
      builder: (context, sp, _) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.softGreen,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _VBtn(
                  icon: sp ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  label: sp ? 'إيقاف' : 'اسمع الشرح',
                  on: sp ? onStop : onExplain,
                  filled: true,
                ),
                const SizedBox(width: 8),
                _VBtn(
                    icon: Icons.front_hand_rounded, label: 'الدعاء', on: onDua),
                const SizedBox(width: 8),
                _VBtn(
                  icon: touring
                      ? Icons.stop_circle_rounded
                      : Icons.headphones_rounded,
                  label: touring ? 'إنهاء الجولة' : 'جولة صوتية',
                  on: touring ? onStop : onTour,
                ),
              ],
            ),
            ValueListenableBuilder<bool>(
              valueListenable: UVoice.I.arabicMissing,
              builder: (context, miss, _) => miss
                  ? const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                          'لم نجد صوتًا عربيًا في جهازك. ثبّت "Google Text-to-speech" وحمّل الصوت العربي من إعدادات الجهاز.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: UC.muted, fontSize: 11.5, height: 1.5)),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _VBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback on;
  final bool filled;
  const _VBtn(
      {required this.icon,
      required this.label,
      required this.on,
      this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: on,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: filled
                ? const LinearGradient(
                    colors: [AppColors.green, AppColors.greenDark])
                : null,
            color: filled ? null : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 22, color: filled ? Colors.white : AppColors.greenDark),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: filled ? Colors.white : UC.ink)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Open3D extends StatelessWidget {
  final String label;
  final Widget page;
  const _Open3D({required this.label, required this.page});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.green, Color(0xFF083D2D)],
          ),
          border: Border.all(color: AppColors.gold, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: AppColors.greenDark.withOpacity(.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.view_in_ar_rounded,
                color: AppColors.gold, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
