import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../umrah/umrah_3d.dart';
import '../../umrah/umrah_data.dart';
import '../../umrah/umrah_voice.dart';
import '../hajj_3d.dart';
import '../hajj_data.dart';
import '../hajj_duas.dart';
import '../hajj_duas_page.dart';
import '../hajj_guide.dart';
import '../hajj_voice.dart';
import 'hajj_cinematic.dart';
import 'hajj_photos.dart';
import 'hajj_scenes.dart';

class HajjStepCard extends StatefulWidget {
  final UStep step;
  final int index;
  final bool touring;
  final VoidCallback onTour, onStop;
  final VoidCallback? onGuideDone;
  final bool showBanner;
  const HajjStepCard({
    super.key,
    required this.step,
    required this.index,
    required this.touring,
    required this.onTour,
    required this.onStop,
    this.onGuideDone,
    this.showBanner = true,
  });

  @override
  State<HajjStepCard> createState() => _HajjStepCardState();
}

class _HajjStepCardState extends State<HajjStepCard> {
  int tab = 0;
  double scale = 1.0;

  Color _rankColor(String r) {
    if (r.startsWith('ركن')) return AppColors.softGold;
    if (r == 'واجب') return AppColors.softRed;
    return AppColors.softGreen;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.step;
    final i = widget.index;
    return UCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showBanner) ...[
            _Banner(index: i, step: s),
            const SizedBox(height: 14),
          ],
          Text(s.title,
              style: const TextStyle(
                  color: UC.ink, fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Badge(s.rank, _rankColor(s.rank)),
              _Badge('⏱ ${s.duration}', AppColors.softGreen),
            ],
          ),
          const SizedBox(height: 10),
          Text(s.summary,
              style:
                  const TextStyle(color: UC.muted, fontSize: 14, height: 1.5)),
          const SizedBox(height: 14),
          _voiceBar(s, i),
          const SizedBox(height: 12),
          _guideButton(s, i),
          const SizedBox(height: 12),
          _sim3D(s.sim, i),
          const SizedBox(height: 14),
          _tabs(),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey('$i-$tab'),
              child: tab == 0
                  ? _how(s)
                  : tab == 1
                      ? _dua(context, s)
                      : tab == 2
                          ? _errors(s)
                          : _photos(),
            ),
          ),
        ],
      ),
    );
  }

  // ───────── الصوت ─────────
  Widget _voiceBar(UStep s, int i) {
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
                  filled: true,
                  on: sp
                      ? widget.onStop
                      : () => UVoice.I.speak(hajjStepNarration(s, i)),
                ),
                const SizedBox(width: 8),
                _VBtn(
                  icon: Icons.front_hand_rounded,
                  label: 'الدعاء',
                  on: () => UVoice.I.speak(s.dua, rate: .36),
                ),
                const SizedBox(width: 8),
                _VBtn(
                  icon: widget.touring
                      ? Icons.stop_circle_rounded
                      : Icons.headphones_rounded,
                  label: widget.touring ? 'إنهاء الجولة' : 'جولة صوتية',
                  on: widget.touring ? widget.onStop : widget.onTour,
                ),
              ],
            ),
            ValueListenableBuilder<bool>(
              valueListenable: UVoice.I.arabicMissing,
              builder: (context, miss, _) => miss
                  ? const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                          'لم نجد صوتًا عربيًا في جهازك. ثبّت "Google Text-to-speech" وحمّل الصوت العربي.',
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

  // ───────── وضع المرشد ─────────
  Widget _guideButton(UStep s, int i) {
    return GestureDetector(
      onTap: () async {
        UVoice.I.stop();
        final ok = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => HajjGuidePage(index: i, step: s),
          ),
        );
        if (ok == true) widget.onGuideDone?.call();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [AppColors.gold, Color(0xFFB88A2E)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.route_rounded, color: Color(0xFF3B2A00), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('وضع المرشد: خطوة بخطوة',
                      style: TextStyle(
                          color: Color(0xFF3B2A00),
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900)),
                  Text('${s.how.length} خطوات بالصوت والصورة ودعاء كل خطوة',
                      style: const TextStyle(
                          color: Color(0xFF5A4100), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF3B2A00), size: 16),
          ],
        ),
      ),
    );
  }

  // ───────── أزرار الـ3D ─────────
  Widget _sim3D(String? sim, int i) {
    final items = <List<Object>>[];
    if (sim == 'arafat') {
      items.add(['عِش غروب عرفة بالـ3D', const HajjArafat3DPage()]);
    } else if (sim == 'jamarat') {
      items.add(['تدرّب على رمي الجمرات بالـ3D', const HajjJamarat3DPage()]);
    } else if (sim == 'tawaf') {
      items.add(['جرّب الطواف حول الكعبة بالـ3D', const Tawaf3DPage()]);
    }
    if (i == 2) {
      items.add(
          ['التقط سبع حصيات في مزدلفة بالـ3D', const HajjMuzdalifah3DPage()]);
    }
    items.add(['رحلة الحج كاملة بالـ3D', const HajjJourney3DPage()]);
    return Column(
      children: [
        for (int k = 0; k < items.length; k++)
          Padding(
            padding: EdgeInsets.only(top: k == 0 ? 0 : 8),
            child: _threeDTile(items[k][0] as String, items[k][1] as Widget,
                primary: k == 0 && (sim != null || i == 2)),
          ),
      ],
    );
  }

  Widget _threeDTile(String label, Widget page, {required bool primary}) {
    return GestureDetector(
      onTap: () {
        UVoice.I.stop();
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(primary ? 16 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0A1F3D), Color(0xFF083D2D)],
          ),
          border: Border.all(
              color: primary ? AppColors.gold : AppColors.gold.withOpacity(.4),
              width: primary ? 1.4 : 1),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: AppColors.greenDark.withOpacity(.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(Icons.view_in_ar_rounded,
                color: AppColors.gold, size: primary ? 30 : 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: primary ? 15 : 13.5,
                      fontWeight: FontWeight.w800)),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  // ───────── التبويبات ─────────
  Widget _tabs() {
    const labels = ['الشرح', 'الدعاء', 'أخطاء', '📸 صور'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (int k = 0; k < 4; k++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => tab = k),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tab == k ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(labels[k],
                      style: TextStyle(
                        color: tab == k ? AppColors.greenDark : UC.muted,
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

  Widget _how(UStep s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int k = 0; k < s.how.length; k++)
            HajjStoryStep(step: widget.index, k: k, text: s.how[k]),
          _info('💡 نصيحة', s.tip, AppColors.softGold),
          if (s.women != null)
            _info('🌸 للمرأة', s.women!, const Color(0xFFF3EAF8)),
        ],
      );

  Widget _info(String t, String x, Color c) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration:
            BoxDecoration(color: c, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(x,
                style: const TextStyle(
                    fontSize: 14.5, height: 1.5, color: UC.ink)),
          ],
        ),
      );

  Widget _dua(BuildContext c, UStep s) => Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF0A1F3D), Color(0xFF083D2D)],
              ),
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                    child: CustomPaint(painter: UPatternPainter(opacity: .06))),
                Column(
                  children: [
                    const Text('✦',
                        style: TextStyle(color: AppColors.gold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(s.dua,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20 * scale,
                          height: 2,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(
                    () => scale = (scale - .15).clamp(.85, 1.6).toDouble()),
                icon: const Icon(Icons.text_decrease_rounded),
                color: AppColors.greenDark,
              ),
              IconButton(
                onPressed: () => setState(
                    () => scale = (scale + .15).clamp(.85, 1.6).toDouble()),
                icon: const Icon(Icons.text_increase_rounded),
                color: AppColors.greenDark,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: s.dua));
                  ScaffoldMessenger.of(c).showSnackBar(
                      const SnackBar(content: Text('تم نسخ الدعاء')));
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('نسخ'),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.greenDark),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.softGold,
                borderRadius: BorderRadius.circular(14)),
            child: Text(s.duaNote,
                style:
                    const TextStyle(color: UC.ink, fontSize: 13, height: 1.5)),
          ),
          const SizedBox(height: 12),
          _moreDuas(c),
        ],
      );

  /// باقي أدعية هذا المنسك من المكتبة
  Widget _moreDuas(BuildContext c) {
    final ids = hajjStepDuaIds[widget.index] ?? const <String>[];
    final list = [
      for (final id in ids)
        if (hajjDuaById(id) != null) hajjDuaById(id)!
    ];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('أدعية وأذكار هذا المنسك',
                  style: TextStyle(
                      color: UC.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900)),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                c,
                MaterialPageRoute(builder: (_) => const HajjDuasPage()),
              ),
              child: const Text('كل الأدعية'),
            ),
          ],
        ),
        for (final d in list)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: UC.border),
            ),
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
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(d.ar,
                          style: TextStyle(
                              color: UC.ink,
                              fontSize: 16.5 * scale,
                              height: 1.9,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => HajjSpeaker.I.say(d.ar, rate: d.rate),
                  icon: const Icon(Icons.volume_up_rounded),
                  color: AppColors.greenDark,
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// تبويب الصور: معرض واقعي + ملاحظة
  Widget _photos() => Column(
        children: [
          HajjPhotoGallery(step: widget.index),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.softGold,
                borderRadius: BorderRadius.circular(14)),
            child: const Text(
              'اضغط على الصورة لتكبيرها، واسحب لرؤية باقي الصور.',
              style: TextStyle(color: UC.ink, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      );

  Widget _errors(UStep s) => Column(
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
                              style:
                                  const TextStyle(color: UC.ink, height: 1.5)),
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

/// بانر الموقع: مشهد متحرك مرسوم لكل منسك (أو صورة assets/hajj/step_N.jpg إن وُجدت)
class _Banner extends StatelessWidget {
  final int index;
  final UStep step;
  const _Banner({required this.index, required this.step});

  @override
  Widget build(BuildContext context) {
    return HajjScene(
      index: index,
      height: 170,
      radius: 20,
      overlay: Positioned(
        right: 14,
        left: 14,
        bottom: 12,
        child: Row(
          children: [
            Text(step.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('الخطوة ${index + 1} من 8',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11.5)),
                  Text(hajjStepSite[index],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 6)
                          ])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(hajjStepDay[index],
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

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
