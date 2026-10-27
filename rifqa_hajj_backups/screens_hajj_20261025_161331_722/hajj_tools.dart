import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../umrah/umrah_data.dart';
import '../umrah/umrah_tools.dart';
import 'hajj_data.dart';

// ═══════════════════════ أنواع النسك ═══════════════════════
class HajjTypesPage extends StatelessWidget {
  const HajjTypesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return UToolPage(
      title: 'أنواع النسك',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.softGold,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '💡 الأيسر والأكثر شيوعًا للقادمين من خارج مكة هو التمتع، وقد أمر به النبي ﷺ أصحابه الذين لم يسوقوا الهدي.',
              style: TextStyle(color: UC.ink, height: 1.6, fontSize: 14),
            ),
          ),
          const SizedBox(height: 14),
          for (final t in hajjTypes)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: UCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(t.emoji, style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(t.name,
                              style: const TextStyle(
                                  color: UC.ink,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: t.hady.contains('لا')
                                ? AppColors.softGreen
                                : AppColors.softRed,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(t.hady,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(t.who,
                        style: const TextStyle(color: UC.muted, height: 1.5)),
                    const SizedBox(height: 12),
                    for (int k = 0; k < t.order.length; k++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: UC.emerald),
                              ),
                              child: Text('${k + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(t.order[k],
                                  style: const TextStyle(
                                      color: UC.ink,
                                      height: 1.55,
                                      fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const Text(
              'اختيار النسك يكون قبل الإحرام، فاسأل أهل العلم أو مرشد حملتك.',
              textAlign: TextAlign.center,
              style: TextStyle(color: UC.muted, fontSize: 12)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ═══════════════════════ أيام الحج ═══════════════════════
class HajjCalendarPage extends StatelessWidget {
  const HajjCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return UToolPage(
      title: 'أيام الحج',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final d in hajjCalendar)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: UC.border),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 74,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF0A1F3D), Color(0xFF083D2D)],
                        ),
                        borderRadius: BorderRadiusDirectional.horizontal(
                            start: Radius.circular(21)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(d.num,
                              style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900)),
                          const Text('ذو الحجة',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.name,
                                style: const TextStyle(
                                    color: UC.ink,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 8),
                            for (final it in d.items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 6),
                                      child: Icon(Icons.circle,
                                          size: 6, color: AppColors.gold),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(it,
                                          style: const TextStyle(
                                              color: UC.ink,
                                              height: 1.5,
                                              fontSize: 13.5)),
                                    ),
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
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ═══════════════════════ الأسئلة الشائعة ═══════════════════════
class HajjFaqPage extends StatefulWidget {
  const HajjFaqPage({super.key});
  @override
  State<HajjFaqPage> createState() => _HajjFaqState();
}

class _HajjFaqState extends State<HajjFaqPage> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final items = hajjFaq
        .where((f) => q.isEmpty || f.q.contains(q) || f.a.contains(q))
        .toList();
    return UToolPage(
      title: 'أسئلة شائعة عن الحج',
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
              child: Text('لا توجد نتائج مطابقة.',
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
class HajjQuizPage extends StatefulWidget {
  const HajjQuizPage({super.key});
  @override
  State<HajjQuizPage> createState() => _HajjQuizState();
}

class _HajjQuizState extends State<HajjQuizPage> {
  int i = 0, score = 0;
  int? picked;
  bool finished = false;

  void _pick(int k) {
    if (picked != null) return;
    HapticFeedback.selectionClick();
    setState(() {
      picked = k;
      if (k == hajjQuiz[i].answer) score++;
    });
  }

  void _next() => setState(() {
        if (i < hajjQuiz.length - 1) {
          i++;
          picked = null;
        } else {
          finished = true;
        }
      });

  void _restart() => setState(() {
        i = 0;
        score = 0;
        picked = null;
        finished = false;
      });

  @override
  Widget build(BuildContext context) {
    return UToolPage(
        title: 'اختبر نفسك في الحج', body: finished ? _result() : _question());
  }

  Widget _result() {
    final total = hajjQuiz.length;
    final r = score / total;
    final msg = r >= .9
        ? 'ما شاء الله! أنت جاهز لأداء حجك بعلم وطمأنينة.'
        : r >= .6
            ? 'مستواك جيد. راجع الخطوات التي أخطأت فيها.'
            : 'لا بأس، ارجع لدليل الحج واقرأ الخطوات ثم أعد المحاولة.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: UCard(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(r >= .6 ? '🏅' : '📖', style: const TextStyle(fontSize: 52)),
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
    final q = hajjQuiz[i];
    final answered = picked != null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('السؤال ${i + 1} من ${hajjQuiz.length}',
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
            value: (i + (answered ? 1 : 0)) / hajjQuiz.length,
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
                borderRadius: BorderRadius.circular(16)),
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
            child:
                Text(i < hajjQuiz.length - 1 ? 'السؤال التالي' : 'عرض النتيجة'),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _option(UQuiz q, int k) {
    final answered = picked != null;
    final right = k == q.answer;
    final chosen = picked == k;
    Color bg = Colors.white;
    Color border = UC.border;
    IconData? icon;
    if (answered && right) {
      bg = AppColors.softGreen;
      border = AppColors.green;
      icon = Icons.check_circle_rounded;
    } else if (answered && chosen) {
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
                      color: UC.ink,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600)),
            ),
            if (icon != null)
              Icon(icon,
                  color: right ? AppColors.green : AppColors.red, size: 24),
          ],
        ),
      ),
    );
  }
}
