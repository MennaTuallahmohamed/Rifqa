import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import 'umrah_data.dart';

/// هيكل مشترك لصفحات الأدوات
class UToolPage extends StatelessWidget {
  final String title;
  final Widget body;
  const UToolPage({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UC.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: body,
    );
  }
}

// ═══════════════════════ المواقيت ═══════════════════════
class MawaqitPage extends StatelessWidget {
  const MawaqitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return UToolPage(
      title: 'مواقيت الإحرام',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const UCard(
            padding: EdgeInsets.fromLTRB(8, 14, 8, 8),
            child: Column(
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: CustomPaint(painter: _MiqatPainter()),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'مخطط تقريبي لاتجاه كل ميقات بالنسبة إلى مكة المكرمة',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: UC.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final m in umrahMawaqit)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: UCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(colors: UC.emerald),
                      ),
                      child: const Icon(Icons.place_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.name,
                              style: const TextStyle(
                                  color: UC.ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5)),
                          const SizedBox(height: 4),
                          Text('لـ ${m.forWho}',
                              style: const TextStyle(
                                  color: UC.ink, fontSize: 13.5)),
                          const SizedBox(height: 2),
                          Text(m.place,
                              style: const TextStyle(
                                  color: UC.muted, fontSize: 12.5)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.softGold,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(m.dir,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          const _NoteBox('💡 من كان داخل المواقيت كأهل جدة فيُحرم من مكانه.'),
          const _NoteBox(
              '🕋 أهل مكة يُحرمون للعمرة من الحِل، كالتنعيم، ليجمعوا بين الحِل والحرم.'),
          const _NoteBox(
              '✈️ القادم بالطائرة يُحرم عند محاذاة الميقات؛ فيلبس ثياب الإحرام قبل الإقلاع وينوي عند تنبيه الطاقم.'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String text;
  const _NoteBox(this.text);
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.softGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text,
            style: const TextStyle(color: UC.ink, height: 1.6, fontSize: 14)),
      );
}

class _MiqatPainter extends CustomPainter {
  const _MiqatPainter();

  // الاسم، الاتجاه (درجات من الشمال)، نصف القطر، إزاحة النص
  static const _pts = <(String, double, double, Offset)>[
    ('ذو الحليفة', 350, 112, Offset(0, -16)),
    ('الجحفة', 325, 86, Offset(-30, -4)),
    ('قرن المنازل', 75, 100, Offset(0, 16)),
    ('ذات عرق', 45, 86, Offset(18, -16)),
    ('يلملم', 180, 108, Offset(0, 16)),
  ];

  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height / 2);

    // حلقات
    for (final r in [50.0, 90.0, 125.0]) {
      c.drawCircle(
          center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = UC.border);
    }

    // الشمال
    _label(c, 'شمال', Offset(center.dx, center.dy - 138), 11, UC.muted);
    c.drawLine(Offset(center.dx, center.dy - 128), Offset(center.dx, center.dy - 120),
        Paint()
          ..color = UC.muted
          ..strokeWidth = 2);

    // الكعبة
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 28, height: 28),
            const Radius.circular(3)),
        Paint()..color = const Color(0xFF111111));
    c.drawRect(
        Rect.fromCenter(center: center.translate(0, -5), width: 28, height: 4),
        Paint()..color = AppColors.gold);
    _label(c, 'مكة', center.translate(0, 26), 11, UC.ink);

    // المواقيت
    for (final p in _pts) {
      final rad = p.$2 * math.pi / 180;
      final pos = Offset(center.dx + p.$3 * math.sin(rad),
          center.dy - p.$3 * math.cos(rad));
      c.drawLine(
          center,
          pos,
          Paint()
            ..color = AppColors.green.withOpacity(.25)
            ..strokeWidth = 1.5);
      c.drawCircle(pos, 9, Paint()..color = Colors.white);
      c.drawCircle(pos, 6.5, Paint()..color = AppColors.green);
      _label(c, p.$1, pos + p.$4, 11.5, UC.ink);
    }
  }

  void _label(Canvas c, String t, Offset at, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: t,
          style: TextStyle(
              fontSize: size, color: color, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.rtl,
    )..layout();
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════ المحظورات ═══════════════════════
class IhramRulesPage extends StatefulWidget {
  const IhramRulesPage({super.key});
  @override
  State<IhramRulesPage> createState() => _IhramRulesPageState();
}

class _IhramRulesPageState extends State<IhramRulesPage> {
  int sel = 0;
  static const _labels = ['ممنوع', 'مباح', 'للمرأة'];

  @override
  Widget build(BuildContext context) {
    final list = sel == 0
        ? umrahForbidden
        : sel == 1
            ? umrahAllowed
            : umrahWomen;
    final tint = sel == 0
        ? AppColors.softRed
        : sel == 1
            ? AppColors.softGreen
            : const Color(0xFFF3EAF8);

    return UToolPage(
      title: 'محظورات الإحرام',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                for (int k = 0; k < 3; k++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => sel = k),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel == k ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_labels[k],
                            style: TextStyle(
                                color:
                                    sel == k ? AppColors.greenDark : UC.muted,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final r in list)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: UC.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(r.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title,
                            style: const TextStyle(
                                color: UC.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5)),
                        const SizedBox(height: 3),
                        Text(r.detail,
                            style: const TextStyle(
                                color: UC.muted, height: 1.5, fontSize: 13.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (sel == 0)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.softGold,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '⚖️ من فعل محظورًا فعليه فدية على التفصيل: صيام ثلاثة أيام، أو إطعام ستة مساكين، أو ذبح شاة. ويُعذر الناسي والجاهل في الإثم. اسأل أهل العلم عن حالتك.',
                style: TextStyle(color: UC.ink, height: 1.6, fontSize: 13.5),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ═══════════════════════ الأسئلة الشائعة ═══════════════════════
class FaqPage extends StatefulWidget {
  const FaqPage({super.key});
  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final items = umrahFaq
        .where((f) => q.isEmpty || f.q.contains(q) || f.a.contains(q))
        .toList();

    return UToolPage(
      title: 'أسئلة شائعة',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (v) => setState(() => q = v.trim()),
            decoration: InputDecoration(
              hintText: 'ابحث في الأسئلة',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: UC.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: UC.border),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Text('لا توجد نتائج مطابقة، جرّب كلمة أخرى.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: UC.muted)),
            ),
          for (final f in items)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: UC.border),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  iconColor: AppColors.greenDark,
                  title: Text(f.q,
                      style: const TextStyle(
                          color: UC.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  children: [
                    Text(f.a,
                        style: const TextStyle(
                            color: UC.ink, height: 1.7, fontSize: 14)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          const Text('للفتوى في حالتك الخاصة راجع أهل العلم.',
              textAlign: TextAlign.center,
              style: TextStyle(color: UC.muted, fontSize: 12)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ═══════════════════════ اختبر نفسك ═══════════════════════
class QuizPage extends StatefulWidget {
  const QuizPage({super.key});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int i = 0, score = 0;
  int? picked;
  bool finished = false;

  void _pick(int k) {
    if (picked != null) return;
    HapticFeedback.selectionClick();
    setState(() {
      picked = k;
      if (k == umrahQuiz[i].answer) score++;
    });
  }

  void _next() {
    setState(() {
      if (i < umrahQuiz.length - 1) {
        i++;
        picked = null;
      } else {
        finished = true;
      }
    });
  }

  void _restart() => setState(() {
        i = 0;
        score = 0;
        picked = null;
        finished = false;
      });

  @override
  Widget build(BuildContext context) {
    return UToolPage(
      title: 'اختبر نفسك',
      body: finished ? _result() : _question(),
    );
  }

  Widget _result() {
    final total = umrahQuiz.length;
    final ratio = score / total;
    final msg = ratio >= .9
        ? 'ما شاء الله! أنت جاهز لأداء عمرتك بعلم وطمأنينة.'
        : ratio >= .6
            ? 'مستواك جيد. راجع الخطوات التي أخطأت فيها وستكون جاهزًا.'
            : 'لا بأس، ارجع لدليل العمرة واقرأ الخطوات مرة أخرى ثم أعد المحاولة.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: UCard(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ratio >= .6 ? '🏅' : '📖',
                  style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 10),
              Text('$score / $total',
                  style: const TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold)),
              const SizedBox(height: 10),
              Text(msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: UC.ink, height: 1.7)),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _restart,
                child: const Text('أعد الاختبار'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _question() {
    final q = umrahQuiz[i];
    final answered = picked != null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('السؤال ${i + 1} من ${umrahQuiz.length}',
                style: const TextStyle(color: UC.muted, fontSize: 13)),
            const Spacer(),
            Text('النتيجة: $score',
                style: const TextStyle(
                    color: AppColors.greenDark, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (i + (answered ? 1 : 0)) / umrahQuiz.length,
            minHeight: 8,
            color: AppColors.gold,
            backgroundColor: UC.border,
          ),
        ),
        const SizedBox(height: 16),
        UCard(
          child: Text(q.q,
              style: const TextStyle(
                  color: UC.ink,
                  fontSize: 19,
                  height: 1.6,
                  fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 12),
        for (int k = 0; k < q.options.length; k++) _option(q, k),
        if (answered) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.softGold,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('💡 ${q.explain}',
                style: const TextStyle(color: UC.ink, height: 1.6)),
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _next,
            child: Text(i < umrahQuiz.length - 1 ? 'السؤال التالي' : 'عرض النتيجة'),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _option(UQuiz q, int k) {
    final answered = picked != null;
    final isRight = k == q.answer;
    final isPicked = picked == k;
    Color bg = Colors.white;
    Color border = UC.border;
    IconData? icon;
    if (answered && isRight) {
      bg = AppColors.softGreen;
      border = AppColors.green;
      icon = Icons.check_circle_rounded;
    } else if (answered && isPicked) {
      bg = AppColors.softRed;
      border = AppColors.red;
      icon = Icons.cancel_rounded;
    }
    return GestureDetector(
      onTap: () => _pick(k),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 1.6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(q.options[k],
                  style: const TextStyle(
                      color: UC.ink, fontSize: 15.5, fontWeight: FontWeight.w600)),
            ),
            if (icon != null)
              Icon(icon,
                  color: isRight ? AppColors.green : AppColors.red, size: 24),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════ حقيبة المعتمر ═══════════════════════
class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});
  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  final Set<String> _checked = {};

  int get _total =>
      umrahChecklist.values.fold<int>(0, (a, b) => a + b.length);

  @override
  Widget build(BuildContext context) {
    final done = _checked.length;
    return UToolPage(
      title: 'حقيبة المعتمر',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          UCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('جاهزيتك للسفر',
                        style: TextStyle(
                            color: UC.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    const Spacer(),
                    Text('$done / $_total',
                        style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w900,
                            fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _total == 0 ? 0 : done / _total,
                    minHeight: 9,
                    color: AppColors.gold,
                    backgroundColor: UC.border,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final e in umrahChecklist.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Text(e.key,
                  style: const TextStyle(
                      color: UC.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: UC.border),
              ),
              child: Column(
                children: [
                  for (final item in e.value)
                    CheckboxListTile(
                      value: _checked.contains(item),
                      activeColor: AppColors.green,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(item,
                          style: TextStyle(
                            color: _checked.contains(item) ? UC.muted : UC.ink,
                            decoration: _checked.contains(item)
                                ? TextDecoration.lineThrough
                                : null,
                            fontSize: 14.5,
                          )),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _checked.add(item);
                        } else {
                          _checked.remove(item);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}