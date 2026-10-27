import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../umrah/umrah_data.dart';
import '../hajj_data.dart';
import '../hajj_voice.dart';
import 'hajj_photos.dart';
import 'hajj_scenes.dart';

/// غلاف سينمائي لكل منسك: صورة بملء العرض تتبدّل تلقائيًا كالقصص،
/// حركة تقريب، تأثير عمق مع السحب، وأزرار زجاجية للصوت.
class HajjCinematicHero extends StatefulWidget {
  final int index;
  final UStep step;
  final ScrollController scroll;
  final bool touring;
  final VoidCallback onTour, onStop;
  final double height;
  const HajjCinematicHero({
    super.key,
    required this.index,
    required this.step,
    required this.scroll,
    required this.touring,
    required this.onTour,
    required this.onStop,
    this.height = 430,
  });

  @override
  State<HajjCinematicHero> createState() => _HajjCinematicHeroState();
}

class _HajjCinematicHeroState extends State<HajjCinematicHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  int _p = 0;

  List<HajjPhoto> get _photos =>
      hajjStepPhotos[widget.index] ?? const <HajjPhoto>[];

  @override
  void initState() {
    super.initState();
    _t.addStatusListener((s) {
      if (s == AnimationStatus.completed && _photos.length > 1) {
        setState(() => _p = (_p + 1) % _photos.length);
        _t.forward(from: 0);
      }
    });
    _t.forward();
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  void _jump(int k) {
    setState(() => _p = k);
    _t.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final n = _photos.isEmpty ? 1 : _photos.length;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // الصورة مع تأثير العمق
            AnimatedBuilder(
              animation: widget.scroll,
              builder: (_, child) {
                final o = widget.scroll.hasClients ? widget.scroll.offset : 0.0;
                return Transform.translate(
                  offset: Offset(0, (o * .25).clamp(-40.0, 120.0).toDouble()),
                  child: Transform.scale(scale: 1.15, child: child),
                );
              },
              child: HajjScene(
                index: widget.index,
                photoIndex: _p,
                radius: 0,
                height: widget.height,
              ),
            ),
            // vignette
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.15,
                  colors: [Color(0x00000000), Color(0x55000000)],
                ),
              ),
            ),
            // تدرّج علوي وسفلي
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .22, .5, 1],
                  colors: [
                    Color(0xAA000000),
                    Color(0x00000000),
                    Color(0x22000000),
                    Color(0xF2051A14),
                  ],
                ),
              ),
            ),
            // مؤشر الصور (قصص)
            Positioned(
              top: 0,
              left: 16,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      for (int k = 0; k < n; k++)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _jump(k),
                            child: Container(
                              height: 18,
                              color: Colors.transparent,
                              alignment: Alignment.center,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: AnimatedBuilder(
                                  animation: _t,
                                  builder: (_, __) => LinearProgressIndicator(
                                    minHeight: 3,
                                    value: k < _p
                                        ? 1
                                        : (k == _p ? _t.value : 0),
                                    backgroundColor: Colors.white30,
                                    valueColor: const AlwaysStoppedAnimation(
                                        Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // المحتوى
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _glass(Text('📍 ${hajjStepSite[widget.index]}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700))),
                      const SizedBox(width: 8),
                      _glass(Text(hajjStepDay[widget.index],
                          style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'المنسك ${widget.index + 1} من 8',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    widget.step.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 14)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.step.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13.5, height: 1.5),
                  ),
                  if (_photos.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(_photos[_p].caption,
                        style: TextStyle(
                            color: AppColors.gold.withOpacity(.95),
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                  const SizedBox(height: 14),
                  _actions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    return ValueListenableBuilder<bool>(
      valueListenable: HajjSpeaker.I.busy,
      builder: (_, sp, __) => Row(
        children: [
          Expanded(
            flex: 5,
            child: _pill(
              icon: sp ? Icons.stop_rounded : Icons.play_arrow_rounded,
              label: sp ? 'إيقاف' : 'اسمع الشرح',
              gold: true,
              on: sp
                  ? widget.onStop
                  : () => HajjSpeaker.I.say(hajjStepNarration(widget.step, widget.index)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: _pill(
              icon: widget.touring
                  ? Icons.stop_circle_rounded
                  : Icons.headphones_rounded,
              label: widget.touring ? 'إنهاء الجولة' : 'جولة صوتية',
              on: widget.touring ? widget.onStop : widget.onTour,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(
      {required IconData icon,
      required String label,
      required VoidCallback on,
      bool gold = false}) {
    return GestureDetector(
      onTap: on,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              gradient: gold
                  ? const LinearGradient(
                      colors: [AppColors.gold, Color(0xFFB88A2E)])
                  : null,
              color: gold ? null : Colors.white.withOpacity(.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: gold ? Colors.transparent : Colors.white38),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 22,
                    color: gold ? const Color(0xFF3B2A00) : Colors.white),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        color: gold ? const Color(0xFF3B2A00) : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glass(Widget child) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.32),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: child,
          ),
        ),
      );
}

/// خطوة شرح مصوّرة: الصورة خلفية، والنص فوقها، برقم ذهبي.
/// تتنوّع زاوية القصّ من خطوة لأخرى فتبدو كل خطوة مشهدًا مختلفًا.
class HajjStoryStep extends StatelessWidget {
  final int step, k;
  final String text;
  const HajjStoryStep(
      {super.key, required this.step, required this.k, required this.text});

  static const _al = [
    Alignment(-.8, -.2),
    Alignment(.7, .1),
    Alignment(0, .6),
    Alignment(-.5, .3),
    Alignment(.9, -.4),
  ];

  @override
  Widget build(BuildContext context) {
    final asset = hajjPhotoAsset(step, k);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: const BoxConstraints(minHeight: 128),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.18),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: Transform.scale(
                scale: 1.5,
                alignment: _al[k % _al.length],
                child: asset == null
                    ? const ColoredBox(color: Color(0xFF083D2D))
                    : Image.asset(asset,
                        fit: BoxFit.cover,
                        alignment: _al[k % _al.length],
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Color(0xFF083D2D))),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0x66051A14), Color(0xEE051A14)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          colors: [AppColors.gold, Color(0xFFB88A2E)]),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.gold.withOpacity(.5),
                            blurRadius: 10)
                      ],
                    ),
                    child: Text('${k + 1}',
                        style: const TextStyle(
                            color: Color(0xFF3B2A00),
                            fontWeight: FontWeight.w900,
                            fontSize: 15)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(text,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            height: 1.7,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6)
                            ])),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
