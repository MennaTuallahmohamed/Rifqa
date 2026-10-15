import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../hajj/hajj_voice.dart';
import 'rawdah_data.dart';

/// محاكي تدريبي ثلاثي الأبعاد لحجز الروضة (المسار الفوري).
/// ⚠️ هذا محاكي تعليمي مبسّط لتدريبك على الخطوات، وليس تطبيق نسك ولا يحجز فعليًا.
/// الشاشة مستوحاة من خطوات «المسار الفوري» في الدليل.

class RawdahSimulatorPage extends StatefulWidget {
  const RawdahSimulatorPage({super.key});
  @override
  State<RawdahSimulatorPage> createState() => _SimState();
}

class _SimState extends State<RawdahSimulatorPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  double rx = .0, ry = .0;
  int phase = 0; // 0 الاسم، 1 الموقع وفتح المواعيد، 2 المواعيد، 3 تم
  int person = -1;
  bool gps = false, near = false, voice = true;
  int attempts = 0;
  bool empty = false;
  int? picked;
  String warn = '';
  int _tries = 0; // لعدد مرات الرجوع (للعرض)

  static const persons = [
    ['أنا', false],
    ['زوجتي', true],
    ['والدتي', true],
    ['والدي', false],
  ];

  late List<bool> avail = List.filled(18, false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _coach());
  }

  @override
  void dispose() {
    HajjSpeaker.I.stop();
    _idle.dispose();
    super.dispose();
  }

  String get coachText {
    switch (phase) {
      case 0:
        return 'الخطوة 1: اختر اسم الشخص المراد الحجز له.';
      case 1:
        return 'الخطوة 2: فعّل GPS، وكن قريبًا من المسجد النبوي، ثم ادخل صفحة المواعيد المتاحة.';
      case 2:
        return empty
            ? 'مفيش مواعيد الآن، وده طبيعي! المواعيد الجديدة لا تظهر تلقائيًا. ارجع واختر الاسم من جديد وكرّر.'
            : 'ظهرت مواعيد! ابحث عن علامة ⚡ واختر موعدًا مناسبًا، ثم اضغط «تأكيد الموعد» فورًا.';
      default:
        return 'ما شاء الله! هكذا تتم الخطوات. في الواقع راجع التفاصيل داخل نسك وتأكد من بوابة الدخول.';
    }
  }

  void _coach() {
    if (voice) HajjSpeaker.I.say(coachText, rate: .5);
  }

  void _openSlots() {
    if (!gps || !near) {
      HapticFeedback.heavyImpact();
      setState(() => warn = 'فعّل GPS وكن قريبًا من المسجد النبوي أولًا.');
      return;
    }
    attempts++;
    final r = math.Random(attempts * 13 + 5);
    avail = List.filled(18, false);
    // المحاولة الأولى بلا مواعيد لتعلّم التكرار، ثم تظهر مواعيد
    if (attempts >= 2) {
      for (int k = 0; k < 5; k++) {
        avail[r.nextInt(18)] = true;
      }
    }
    empty = !avail.contains(true);
    picked = null;
    setState(() {
      warn = '';
      phase = 2;
    });
    _coach();
  }

  void _backToName() {
    _tries++;
    setState(() {
      phase = 0;
      person = -1;
      picked = null;
    });
    _coach();
  }

  void _confirm() {
    HapticFeedback.mediumImpact();
    setState(() => phase = 3);
    _coach();
  }

  void _reset() {
    HajjSpeaker.I.stop();
    setState(() {
      phase = 0;
      person = -1;
      gps = false;
      near = false;
      attempts = 0;
      empty = false;
      picked = null;
      warn = '';
      _tries = 0;
      rx = 0;
      ry = 0;
    });
    _coach();
  }

  @override
  Widget build(BuildContext context) {
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
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white)),
                    const Expanded(
                      child: Text('جرّب الحجز · محاكي 3D',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900)),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => voice = !voice);
                        voice ? _coach() : HajjSpeaker.I.stop();
                      },
                      icon: Icon(
                          voice ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          color: voice ? AppColors.gold : Colors.white54),
                    ),
                    IconButton(
                        onPressed: _reset,
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white)),
                  ],
                ),
              ),
              _steps(),
              _coachBubble(),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _threeD(),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text(
                  'اسحب الهاتف لتدويره 🔄 · محاكاة تعليمية لا تحجز فعليًا · تدرّبت $_tries مرة على الرجوع والتكرار',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 11.5, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _steps() {
    const labels = ['الاسم', 'الموقع', 'المواعيد', 'تم'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          for (int k = 0; k < 4; k++)
            Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: k <= phase ? AppColors.gold : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(labels[k],
                      style: TextStyle(
                          color: k == phase ? AppColors.gold : Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _coachBubble() => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Container(
          key: ValueKey('$phase$empty'),
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x33FFD66B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withOpacity(.6)),
          ),
          child: Row(
            children: [
              const Text('🧭', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(coachText,
                    style: const TextStyle(
                        color: Colors.white, height: 1.55, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );

  // ═══════════════ الهاتف ثلاثي الأبعاد ═══════════════
  Widget _threeD() {
    return GestureDetector(
      onPanUpdate: (d) => setState(() {
        ry = (ry + d.delta.dx * .01).clamp(-.55, .55).toDouble();
        rx = (rx - d.delta.dy * .01).clamp(-.35, .35).toDouble();
      }),
      onDoubleTap: () => setState(() {
        rx = 0;
        ry = 0;
      }),
      child: AnimatedBuilder(
        animation: _idle,
        builder: (_, child) {
          final w = math.sin(_idle.value * math.pi * 2) * .04;
          final m = Matrix4.identity()
            ..setEntry(3, 2, .0011)
            ..rotateX(rx + w)
            ..rotateY(ry + w * 1.4);
          return Transform(alignment: Alignment.center, transform: m, child: child);
        },
        child: SizedBox(
          width: 300,
          height: 590,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // سُمك الهاتف
              for (int z = 6; z >= 1; z--)
                Positioned.fill(
                  child: Transform(
                    transform: Matrix4.translationValues(0, 0, -z * 2.2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color.lerp(const Color(0xFF111418), const Color(0xFF2A2F37), z / 6),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C0E12),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 20)),
                    ],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Container(color: const Color(0xFFF2F6F8), child: _screen()),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 110,
                right: 110,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                      color: const Color(0xFF0C0E12), borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _screen() {
    return Column(
      children: [
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.close_rounded, size: 20, color: Colors.black54),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12)),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 15, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(person >= 0 ? persons[person][0] as String : 'أنت',
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 14),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    switch (phase) {
      case 0:
        return _pickPerson();
      case 1:
        return _gpsCard();
      case 2:
        return empty ? _emptyCard() : _slots();
      default:
        return _success();
    }
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Text(t,
            style: const TextStyle(
                color: Color(0xFF14283C), fontSize: 15, fontWeight: FontWeight.w900)),
      );

  Widget _pickPerson() => ListView(
        padding: EdgeInsets.zero,
        children: [
          _title('اختر الشخص المراد الحجز له'),
          for (int k = 0; k < persons.length; k++)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  person = k;
                  phase = 1;
                });
                _coach();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12)),
                child: Row(
                  children: [
                    Icon(persons[k][1] as bool ? Icons.woman_rounded : Icons.man_rounded,
                        color: const Color(0xFF1F6F8B)),
                    const SizedBox(width: 10),
                    Text(persons[k][0] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, color: Color(0xFF14283C))),
                    const Spacer(),
                    const Icon(Icons.chevron_left_rounded, color: Colors.black38),
                  ],
                ),
              ),
            ),
        ],
      );

  Widget _switchRow(String t, bool v, ValueChanged<bool> on) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: v ? const Color(0xFF39C48B) : Colors.black12)),
        child: Row(
          children: [
            Expanded(
                child: Text(t,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Color(0xFF14283C), fontSize: 13))),
            Switch(value: v, activeColor: const Color(0xFF1E8F6A), onChanged: on),
          ],
        ),
      );

  Widget _gpsCard() => ListView(
        padding: EdgeInsets.zero,
        children: [
          _title('تحقق من الموقع'),
          _switchRow('تفعيل خدمة الموقع GPS', gps, (v) => setState(() => gps = v)),
          _switchRow('أنا قريب من المسجد النبوي', near, (v) => setState(() => near = v)),
          if (warn.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(warn,
                  style: const TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 10),
          _btn('المواعيد المتاحة', _openSlots),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextButton(
              onPressed: _backToName,
              child: const Text('تغيير الشخص'),
            ),
          ),
        ],
      );

  Widget _btn(String t, VoidCallback on, {bool enabled = true}) => GestureDetector(
        onTap: enabled ? on : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? Colors.black : Colors.black26,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(t,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ),
      );

  Widget _emptyCard() => ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 40),
          const Center(child: Text('⌛', style: TextStyle(fontSize: 54))),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Text('لا توجد مواعيد متاحة الآن',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF14283C), fontWeight: FontWeight.w900, fontSize: 15)),
          ),
          const SizedBox(height: 24),
          _btn('رجوع واختيار الاسم من جديد', _backToName),
        ],
      );

  Widget _slots() {
    final day = dayName(saudiNow());
    final women = person >= 0 && (persons[person][1] as bool);
    return Column(
      children: [
        if (women)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('مواعيد مخصصة للنساء',
                  style: TextStyle(fontSize: 11, color: Colors.black54)),
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 18,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: 1.45, mainAxisSpacing: 6, crossAxisSpacing: 6),
            itemBuilder: (_, k) {
              final mins = 5 * 60 + k * 20;
              final label =
                  '${(mins ~/ 60).toString().padLeft(2, '0')}:${(mins % 60).toString().padLeft(2, '0')} ص';
              final ok = avail[k];
              final sel = picked == k;
              return GestureDetector(
                onTap: ok
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() => picked = k);
                      }
                    : null,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFFB7F0C6)
                        : (ok ? Colors.white : const Color(0xFFE8ECEF)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel ? const Color(0xFF39C48B) : Colors.black12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(ok ? '⚡' : '⌛', style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 3),
                      Text(label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: ok ? const Color(0xFF14283C) : Colors.black38)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (picked != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'موعدك: $day, ${(((5 * 60 + picked! * 20) ~/ 60)).toString().padLeft(2, '0')}:${((5 * 60 + picked! * 20) % 60).toString().padLeft(2, '0')} ص',
              style: const TextStyle(fontSize: 11.5, color: Colors.black54),
            ),
          ),
        const SizedBox(height: 6),
        _btn('← تأكيد الموعد', _confirm, enabled: picked != null),
        TextButton(onPressed: _backToName, child: const Text('رجوع وتحديث', style: TextStyle(fontSize: 12))),
      ],
    );
  }

  Widget _success() => ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 30),
          const Center(child: Text('✅', style: TextStyle(fontSize: 60))),
          const SizedBox(height: 8),
          const Text('تم تأكيد الموعد (تدريب)',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF14283C), fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 14),
          for (final t in const [
            'راجع التفاصيل داخل نسك',
            'تأكد من بوابة الدخول',
            'راجع وقت ظهور QR Code',
            'شروط الأعمار قد تتغير',
          ])
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF1E8F6A), size: 18),
                  const SizedBox(width: 8),
                  Text(t, style: const TextStyle(fontSize: 12.5, color: Color(0xFF14283C))),
                ],
              ),
            ),
          const SizedBox(height: 10),
          _btn('أعد التدريب', _reset),
        ],
      );
}
