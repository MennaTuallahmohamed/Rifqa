import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../hajj/hajj_voice.dart';
import 'rawdah_art.dart';

/// فيديو تعليمي متحرك ومنطوق: يشرح كل ما في أدلة حجز الروضة مشهدًا بمشهد.
/// لا يحتاج ملف فيديو. (لاستعمال فيديو حقيقي لاحقًا يمكن إضافة video_player وتشغيله هنا.)

class _Scene {
  final String title, say;
  final List<String> bullets;
  const _Scene(this.title, this.say, this.bullets);
}

const _scenes = <_Scene>[
  _Scene(
    'حجز الروضة الشريفة بسهولة',
    'أهلًا بك. في هذا الشرح سنمشي معًا خطوة بخطوة حتى تحجز موعدك في الروضة الشريفة بإذن الله، فلا تقلق ولا تحمل همًّا. ابدأ بالصلاة على النبي صلى الله عليه وسلم.',
    ['خطوة بخطوة', 'بالصوت والصورة', 'ميسّر بإذن الله'],
  ),
  _Scene(
    '١. حساب نسك',
    'أولًا، حساب نسك. أول ما تستلم التأشيرة اعمل حسابًا على تطبيق نسك وخلّه جاهزًا. وإذا كان عندك حساب فابدأ متابعة الحجز فورًا بعد أن تحدد مواعيد سفرك ووجودك في المدينة المنورة.',
    ['استلمت التأشيرة؟ اعمل حساب نسك', 'خلّي الحساب جاهزًا', 'حدّد مواعيد سفرك ووجودك بالمدينة'],
  ),
  _Scene(
    '٢. لقيت الحجز مفتوح؟',
    'ثانيًا، إذا وجدت الحجز مفتوحًا فادخل واحجز فورًا، لأن المواعيد قد تنتهي بسرعة كبيرة. وتقدر تحاول من أي مكان، ما دامت المواعيد مفتوحة خلال فترة وجودك في المدينة.',
    ['ادخل واحجز فورًا ✅', 'المواعيد بتخلص بسرعة', 'تقدر تحاول من أي مكان'],
  ),
  _Scene(
    '٣. مواعيد المحاولة',
    'ثالثًا، مواعيد المحاولة. قبل موعد الزيارة بأسبوع ادخل الساعة خمسة وأربعين دقيقة عصرًا للرجال، أو الخامسة وأربع وأربعين دقيقة عصرًا للسيدات. وقبلها بيومين بنفس التوقيت. وقبلها بيوم ادخل الساعة العاشرة مساءً. وكل ذلك بتوقيت السعودية. وكن مستعدًا قبلها بدقائق.',
    ['قبل بأسبوع: رجال 5:40 م · سيدات 5:44 م', 'قبل بيومين: رجال 5:40 م · سيدات 5:44 م', 'قبل بيوم: 10:00 م'],
  ),
  _Scene(
    '٤. كل يوم 12 ظهرًا',
    'رابعًا، إذا لم تجد مواعيد فادخل كل يوم في تمام الثانية عشرة ظهرًا بتوقيت السعودية. ففيه تُفتح مواعيد جديدة للأيام التي كانت مغلقة.',
    ['كل يوم 12:00 ظهرًا', 'بتوقيت السعودية', 'مواعيد جديدة للأيام المقفلة'],
  ),
  _Scene(
    '٥. المسار الفوري',
    'خامسًا، المسار الفوري. هو لمن هو داخل المدينة المنورة، ويتيح حجز تصريح الصلاة في الروضة على مدار أربع وعشرين ساعة عبر تطبيق نسك. وليس له زر مستقل، وإنما تظهر مواعيده ضمن المواعيد المتاحة، وتميّزها بعلامة البرق.',
    ['لمن هو داخل المدينة المنورة', 'يعمل 24 ساعة عبر نسك', 'ابحث عن علامة ⚡ بجوار الموعد'],
  ),
  _Scene(
    '٦. كرّر ولا تيأس',
    'وهنا النقطة المهمة جدًا. المواعيد الجديدة لا تظهر تلقائيًا. فاختر اسم الشخص، ثم ادخل صفحة المواعيد المتاحة. إذا ظهر موعد مناسب فاحجزه فورًا. وإن لم يظهر فارجع واختر الاسم من جديد وكرّر. تظهر المواعيد غالبًا كل عشرين دقيقة، فقد يُطرح موعد جديد في أي لحظة.',
    ['اختر الاسم', 'ادخل صفحة المواعيد', 'ظهر موعد؟ احجز فورًا', 'ما ظهر؟ ارجع وكرّر 🔁'],
  ),
  _Scene(
    '٧. الموقع والشروط',
    'ولا تنس شرط الموقع. فعّل خدمة جي بي إس، واسمح لنسك باستخدام الموقع، وكن قريبًا من المسجد النبوي. والمواعيد التي تظهر في المسار الفوري تكون ليوم المحاولة فقط، وتقدر تحجز تصريحًا جديدًا كل أربع وعشرين ساعة متى توفرت المواعيد.',
    ['فعّل GPS واسمح لنسك بالموقع', 'كن قريبًا من المسجد النبوي', 'المواعيد لنفس اليوم فقط', 'تصريح جديد كل 24 ساعة'],
  ),
  _Scene(
    '٨. بعد الحجز',
    'بعد إتمام الحجز، راجع تفاصيله داخل تطبيق نسك. وتأكد من بوابة الدخول الموضحة في تصريحك، وراجع وقت ظهور رمز الكيو آر وتفعيله، فقد يختلف حسب النظام الحالي. وراجع شروط الأعمار المطبقة وقت زيارتك.',
    ['راجع التفاصيل داخل نسك', 'تأكد من بوابة الدخول', 'وقت ظهور QR Code قد يختلف', 'راجع شروط الأعمار'],
  ),
  _Scene(
    'يسّر الله لك',
    'يسّر الله لك ولنا زيارة نبيه، والصلاة في روضته الشريفة. وأكثر من الصلاة والسلام عليه. اللهم صلِّ وسلّم وبارك على نبينا محمد.',
    ['اللهم صلِّ وسلّم وبارك على نبينا محمد'],
  ),
];

class RawdahVideoPage extends StatefulWidget {
  const RawdahVideoPage({super.key});
  @override
  State<RawdahVideoPage> createState() => _RawdahVideoPageState();
}

class _RawdahVideoPageState extends State<RawdahVideoPage>
    with TickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  late final AnimationController _prog = AnimationController(vsync: this);
  int idx = 0, _tok = 0;
  bool playing = false, voice = true, ended = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    _tok++;
    HajjSpeaker.I.stop();
    _loop.dispose();
    _prog.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    final tok = ++_tok;
    if (ended) {
      idx = 0;
      ended = false;
    }
    setState(() => playing = true);
    while (mounted && tok == _tok) {
      final sc = _scenes[idx];
      final ms = (sc.say.length * 70).clamp(4500, 45000).toInt();
      _prog.duration = Duration(milliseconds: ms);
      _prog.forward(from: 0);
      if (voice) {
        await HajjSpeaker.I.say(sc.say, rate: .5);
        // حماية إن لم ينتظر المحرك انتهاء الكلام
        if (tok == _tok && _prog.value < .6) {
          await Future<void>.delayed(
              Duration(milliseconds: (ms * (1 - _prog.value) * .5).toInt()));
        }
      } else {
        await Future<void>.delayed(Duration(milliseconds: ms));
      }
      if (!mounted || tok != _tok) return;
      if (idx >= _scenes.length - 1) break;
      setState(() => idx++);
    }
    if (mounted && tok == _tok) {
      setState(() {
        playing = false;
        ended = true;
      });
    }
  }

  void _pause() {
    _tok++;
    HajjSpeaker.I.stop();
    _prog.stop();
    setState(() => playing = false);
  }

  void _jump(int i) {
    final was = playing;
    _tok++;
    HajjSpeaker.I.stop();
    _prog.stop();
    setState(() {
      idx = i.clamp(0, _scenes.length - 1).toInt();
      ended = false;
    });
    if (was) _play();
  }

  @override
  Widget build(BuildContext context) {
    final sc = _scenes[idx];
    return Scaffold(
      backgroundColor: const Color(0xFF07182A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A2540), Color(0xFF0B3B34), Color(0xFF07182A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _top(),
              _segments(),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Container(
                    key: ValueKey(idx),
                    height: 230,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.gold.withOpacity(.55)),
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFF10456A), Color(0xFF0D5B49)],
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _loop,
                      builder: (_, __) => _visual(idx, _loop.value),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  children: [
                    Text(sc.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: _prog,
                      builder: (_, __) {
                        final n = sc.bullets.length;
                        return Column(
                          children: [
                            for (int k = 0; k < n; k++)
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 350),
                                opacity: _prog.value >= (k / (n + 1)) * .9 || !playing ? 1 : 0,
                                child: AnimatedSlide(
                                  duration: const Duration(milliseconds: 350),
                                  offset: _prog.value >= (k / (n + 1)) * .9 || !playing
                                      ? Offset.zero
                                      : const Offset(.08, 0),
                                  child: Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(.08),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Text(sc.bullets[k],
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.5,
                                            height: 1.5,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(sc.say,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12.5, height: 1.7)),
                  ],
                ),
              ),
              _controls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _top() => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 6),
        child: Row(
          children: [
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white)),
            const Expanded(
              child: Text('شرح حجز الروضة · فيديو تعليمي',
                  style: TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            ),
            IconButton(
              tooltip: voice ? 'كتم الصوت' : 'تشغيل الصوت',
              onPressed: () {
                setState(() => voice = !voice);
                if (!voice) {
                  HajjSpeaker.I.stop();
                } else if (playing) {
                  _jump(idx);
                }
              },
              icon: Icon(voice ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: voice ? AppColors.gold : Colors.white54),
            ),
          ],
        ),
      );

  Widget _segments() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (int k = 0; k < _scenes.length; k++)
              Expanded(
                child: GestureDetector(
                  onTap: () => _jump(k),
                  child: Container(
                    height: 18,
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Container(
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                          color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                      child: k < idx
                          ? Container(
                              decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(4)))
                          : k == idx
                              ? AnimatedBuilder(
                                  animation: _prog,
                                  builder: (_, __) => FractionallySizedBox(
                                    alignment: AlignmentDirectional.centerStart,
                                    widthFactor: ended ? 1 : _prog.value.clamp(0, 1).toDouble(),
                                    child: Container(
                                        decoration: BoxDecoration(
                                            color: AppColors.gold,
                                            borderRadius: BorderRadius.circular(4))),
                                  ),
                                )
                              : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _controls() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _round(Icons.skip_next_rounded, () => _jump(idx + 1), enabled: idx < _scenes.length - 1),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: playing ? _pause : _play,
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppColors.gold, Color(0xFFB88A2E)]),
                ),
                child: Icon(
                  playing
                      ? Icons.pause_rounded
                      : (ended ? Icons.replay_rounded : Icons.play_arrow_rounded),
                  size: 38,
                  color: const Color(0xFF3B2A00),
                ),
              ),
            ),
            const SizedBox(width: 14),
            _round(Icons.skip_previous_rounded, () => _jump(idx - 1), enabled: idx > 0),
          ],
        ),
      );

  Widget _round(IconData i, VoidCallback on, {bool enabled = true}) => GestureDetector(
        onTap: enabled ? on : null,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(enabled ? .12 : .05),
          ),
          child: Icon(i, color: enabled ? Colors.white : Colors.white24, size: 28),
        ),
      );

  // ═══════════════ مشاهد الرسوم ═══════════════
  Widget _visual(int i, double t) {
    switch (i) {
      case 0:
        return Stack(children: [
          Positioned.fill(child: CustomPaint(painter: DomePainter(t))),
          const Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Text('﷽',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFFFE08A), fontSize: 26)),
          ),
        ]);
      case 1:
        return _iconRow(t, const ['🛂', '📱', '✅'], ['التأشيرة', 'حساب نسك', 'جاهز']);
      case 2:
        return _slotsMini(t, found: true);
      case 3:
        return _timeline(t);
      case 4:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
                width: 150, height: 150, child: CustomPaint(painter: ClockPainter(t))),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('12:00',
                    style: TextStyle(
                        color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                Text('ظهرًا · بتوقيت السعودية',
                    style: TextStyle(color: Color(0xFFFFE08A), fontSize: 13)),
              ],
            ),
          ],
        );
      case 5:
        return Stack(alignment: Alignment.center, children: [
          Positioned.fill(child: CustomPaint(painter: PulsePainter(t))),
          const Text('🕌', style: TextStyle(fontSize: 70)),
          Positioned(
              top: 18,
              right: 24,
              child: _chip('⚡ 24 ساعة', const Color(0xFFE8730C))),
        ]);
      case 6:
        return _loopCycle(t);
      case 7:
        return Stack(alignment: Alignment.center, children: [
          Positioned.fill(child: CustomPaint(painter: PulsePainter(t, color: const Color(0xFF39C48B)))),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white, size: 52),
              const SizedBox(height: 4),
              _chip('GPS مفعّل', const Color(0xFF1E8F6A)),
              const SizedBox(height: 6),
              const Text('قريب من المسجد النبوي',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ]);
      case 8:
        return Center(
          child: Container(
            width: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CustomPaint(painter: _QrPainter(t)),
                ),
                const SizedBox(height: 6),
                const Text('تصريح الروضة',
                    style: TextStyle(
                        color: Color(0xFF0E3A5C), fontWeight: FontWeight.w900, fontSize: 13)),
                const Text('تأكد من البوابة',
                    style: TextStyle(color: Colors.black54, fontSize: 11.5)),
              ],
            ),
          ),
        );
      default:
        return Stack(children: [
          Positioned.fill(child: CustomPaint(painter: DomePainter(t))),
          Positioned(
            top: 14,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: .75 + .25 * math.sin(t * math.pi * 2),
              child: const Text('🤲  اللهم صلِّ وسلّم وبارك على نبينا محمد',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFFFFE08A), fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ]);
    }
  }

  Widget _chip(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(14)),
        child: Text(t,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
      );

  Widget _iconRow(double t, List<String> e, List<String> l) {
    final step = (t * 3).floor() % 3;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int k = 0; k < e.length; k++) ...[
          AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: k == step ? 1.2 : .92,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e[k], style: const TextStyle(fontSize: 46)),
                const SizedBox(height: 6),
                Text(l[k],
                    style: TextStyle(
                        color: k == step ? const Color(0xFFFFE08A) : Colors.white70,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          if (k < e.length - 1)
            const Icon(Icons.arrow_back_rounded, color: Colors.white38),
        ],
      ],
    );
  }

  Widget _timeline(double t) {
    final rows = const [
      ['📅', 'قبل بأسبوع', '5:40 م / 5:44 م'],
      ['🗓️', 'قبل بيومين', '5:40 م / 5:44 م'],
      ['🌙', 'قبل بيوم', '10:00 م'],
    ];
    final cur = (t * 3).floor() % 3;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int k = 0; k < 3; k++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: k == cur ? const Color(0x33FFD66B) : Colors.white10,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: k == cur ? const Color(0xFFFFD66B) : Colors.white12),
              ),
              child: Row(
                children: [
                  Text(rows[k][0], style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(rows[k][1],
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                  Text(rows[k][2],
                      style: const TextStyle(
                          color: Color(0xFFFFE08A), fontWeight: FontWeight.w900)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _slotsMini(double t, {required bool found}) {
    final sel = (t * 6).floor() % 6;
    const times = ['05:00', '05:20', '05:40', '06:00', '06:20', '06:40'];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 2.3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (int k = 0; k < 6; k++)
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: k == sel ? const Color(0xFF39C48B) : Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${k == sel ? '⚡ ' : ''}${times[k]}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }

  Widget _loopCycle(double t) {
    const labels = ['اختر الاسم', 'صفحة المواعيد', 'موعد؟ احجز', 'لا؟ ارجع'];
    final cur = (t * 4).floor() % 4;
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          for (int k = 0; k < 4; k++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: k == cur ? const Color(0xFFFFD66B) : Colors.white12,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('${k + 1}  ${labels[k]}',
                  style: TextStyle(
                      color: k == cur ? const Color(0xFF3B2A00) : Colors.white,
                      fontWeight: FontWeight.w900)),
            ),
        ],
      ),
    );
  }
}

/// رمز QR تجريدي (للتوضيح فقط وليس رمزًا حقيقيًا)
class _QrPainter extends CustomPainter {
  final double t;
  const _QrPainter(this.t);
  @override
  void paint(Canvas c, Size s) {
    final r = math.Random(7);
    const n = 13;
    final cell = s.width / n;
    final p = Paint()..color = const Color(0xFF0E3A5C);
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        final corner = (x < 4 && y < 4) || (x > n - 5 && y < 4) || (x < 4 && y > n - 5);
        if (corner || r.nextBool()) {
          c.drawRect(Rect.fromLTWH(x * cell, y * cell, cell * .9, cell * .9), p);
        }
      }
    }
    final y = (t * s.height);
    c.drawRect(Rect.fromLTWH(0, y, s.width, 3), Paint()..color = const Color(0xAA39C48B));
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.t != t;
}
