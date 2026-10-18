import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

// رِفقة - استشعار عظمة المكان
// 1) Three slow, photographic, perspective-animated scenes using existing photos.
// 2) An optional interactive, actual GLB 3D model (a conceptual architectural study).
// Neither screen depicts the Prophet ﷺ nor claims to be a live feed of the mosque.

const _night = Color(0xFF041B16);
const _green = Color(0xFF123D35);
const _gold = Color(0xFFC9A96E);
const _ivory = Color(0xFFFFF8E8);

class MosqueGrandeurExperience extends StatefulWidget {
  const MosqueGrandeurExperience({super.key});

  @override
  State<MosqueGrandeurExperience> createState() =>
      _MosqueGrandeurExperienceState();
}

class _GrandeurScene {
  const _GrandeurScene(this.image, this.title, this.description, this.smallLabel);

  final String image;
  final String title;
  final String description;
  final String smallLabel;
}

const _moments = <_GrandeurScene>[
  _GrandeurScene(
    'assets/images/madinah/gate_sultan_abdulmajeed.png',
    'لحظة عند الأبواب',
    'اقتربي بهدوء، واستحضري أنكِ في طريقك إلى مسجد رسول الله ﷺ.',
    'المشهد الأول • الوصول',
  ),
  _GrandeurScene(
    'assets/images/madinah/courtyard_day_umbrella.png',
    'في رحاب المسجد',
    'انظري إلى اتساع الصحن وروعة العمارة، وخذي لحظة من السكينة.',
    'المشهد الثاني • رحاب المسجد',
  ),
  _GrandeurScene(
    'assets/images/madinah/rawdah_grille.png',
    'استشعار عظمة المكان',
    'تأمّلي تفاصيل المكان، ثم اتركي الشاشة لتعيشي حضورك الحقيقي.',
    'المشهد الثالث • تفاصيل من الداخل',
  ),
];

class _MosqueGrandeurExperienceState extends State<MosqueGrandeurExperience>
    with TickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 15),
  )..repeat(reverse: true);

  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..forward();

  int _index = 0;
  bool _playing = true;
  bool _reduceMotion = false;
  double _touchTilt = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      if (reduce) {
        _ambient.stop();
        _reveal.value = 1;
      } else if (_playing) {
        _ambient.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    _reveal.dispose();
    super.dispose();
  }

  void _changeScene(int newIndex) {
    if (newIndex < 0 || newIndex >= _moments.length) return;
    setState(() {
      _index = newIndex;
      _touchTilt = 0;
    });
    if (!_reduceMotion) {
      _reveal.forward(from: 0);
    }
  }

  void _next() {
    if (_index == _moments.length - 1) {
      Navigator.of(context).maybePop();
    } else {
      _changeScene(_index + 1);
    }
  }

  void _toggleMotion() {
    if (_reduceMotion) return;
    setState(() => _playing = !_playing);
    if (_playing) {
      _ambient.repeat(reverse: true);
    } else {
      _ambient.stop();
    }
  }

  void _openModel() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _Architectural3DViewer(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scene = _moments[_index];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _night,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Photographic 2.5D - actual perspective matrix and interactive parallax.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                if (_reduceMotion) return;
                setState(() {
                  _touchTilt =
                      (_touchTilt + details.delta.dx / 1200).clamp(-0.07, 0.07).toDouble();
                });
              },
              onPanEnd: (_) => setState(() => _touchTilt = 0),
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: _reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 1100),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 1.055, end: 1)
                          .animate(animation),
                      child: child,
                    ),
                  ),
                  child: _AnimatedMosquePhoto(
                    key: ValueKey(scene.image),
                    asset: scene.image,
                    ambient: _ambient,
                    tilt: _touchTilt,
                    reduceMotion: _reduceMotion,
                  ),
                ),
              ),
            ),
            // Gentle legibility gradient, without painted light effects on sacred details.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xC9021712),
                      Color(0x12021712),
                      Color(0x44021712),
                      Color(0xF7041712),
                    ],
                    stops: [0, 0.3, 0.55, 1],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: CustomPaint(
                painter: const _SubtleArchitecturalFrame(),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _CircleButton(
                          icon: Icons.arrow_forward_ios_rounded,
                          onPressed: () => Navigator.of(context).maybePop(),
                          tooltip: 'العودة',
                        ),
                        const Expanded(
                          child: Text(
                            'استشعار عظمة المكان',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _ivory,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _CircleButton(
                          icon: _playing && !_reduceMotion
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          onPressed: _reduceMotion ? null : _toggleMotion,
                          tooltip: 'إيقاف أو تشغيل حركة المشهد',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '✦  في رحاب مسجد رسول الله ﷺ  ✦',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _gold,
                        letterSpacing: .3,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    FadeTransition(
                      opacity: _reveal,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, .12),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _reveal,
                          curve: Curves.easeOutCubic,
                        )),
                        child: _SceneCaption(scene: scene),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: List.generate(
                        _moments.length,
                        (i) => Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: i <= _index
                                  ? _gold
                                  : Colors.white.withValues(alpha: .25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _next,
                            icon: Icon(_index == _moments.length - 1
                                ? Icons.favorite_outline_rounded
                                : Icons.arrow_back_rounded),
                            label: Text(_index == _moments.length - 1
                                ? 'أعيش اللحظة الآن'
                                : 'المشهد التالي'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: _night,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.w800),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        _CircleButton(
                          icon: Icons.view_in_ar_rounded,
                          tooltip: 'افتحي النموذج المعماري ثلاثي الأبعاد',
                          onPressed: _openModel,
                          emphasized: true,
                        ),
                        if (_index > 0) ...[
                          const SizedBox(width: 7),
                          _CircleButton(
                            icon: Icons.arrow_forward_rounded,
                            tooltip: 'المشهد السابق',
                            onPressed: () => _changeScene(_index - 1),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'اسحبي الصورة برفق للإحساس بالعمق • اضغطي على المكعب لفتح 3D',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .69),
                        fontSize: 10.5,
                        height: 1.5,
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
  }
}

class _AnimatedMosquePhoto extends StatelessWidget {
  const _AnimatedMosquePhoto({
    super.key,
    required this.asset,
    required this.ambient,
    required this.tilt,
    required this.reduceMotion,
  });

  final String asset;
  final Animation<double> ambient;
  final double tilt;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, _) {
        final t = reduceMotion ? .5 : ambient.value;
        final eased = (1 - math.cos(math.pi * t)) / 2;
        final dx = (eased - .5) * 24;
        final dy = (eased - .5) * 14;
        final turn = tilt + (eased - .5) * .045;
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, .00052)
          ..rotateY(turn)
          ..rotateX((eased - .5) * .014)
          ..scale(1.13 + eased * .045);

        return Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Image.asset(
              asset,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) =>
                  const ColoredBox(color: _green),
            ),
          ),
        );
      },
    );
  }
}

class _SceneCaption extends StatelessWidget {
  const _SceneCaption({required this.scene});
  final _GrandeurScene scene;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(23, 20, 23, 23),
      decoration: BoxDecoration(
        color: _night.withValues(alpha: .86),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: _gold.withValues(alpha: .7), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .3),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(scene.smallLabel,
              style: const TextStyle(
                  color: _gold, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 10),
          Text(scene.title,
              style: const TextStyle(
                color: _ivory,
                fontWeight: FontWeight.w900,
                fontSize: 26,
                height: 1.3,
              )),
          const SizedBox(height: 11),
          Text(scene.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .88),
                fontSize: 14,
                height: 1.9,
              )),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.emphasized = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: emphasized ? _gold : _night.withValues(alpha: .8),
          foregroundColor: emphasized ? _night : _ivory,
          padding: const EdgeInsets.all(13),
          side: const BorderSide(color: _gold, width: 1),
        ),
        icon: Icon(icon, size: 21),
      );
}

class _SubtleArchitecturalFrame extends CustomPainter {
  const _SubtleArchitecturalFrame();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _gold.withValues(alpha: .30)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    const inset = 13.0;
    final left = inset, right = size.width - inset;
    final top = size.height * .19;
    final bottom = size.height * .70;
    final path = Path()
      ..moveTo(left, bottom)
      ..lineTo(left, top + 58)
      ..quadraticBezierTo(left, top + 15, left + 48, top)
      ..quadraticBezierTo(size.width / 2, top - 20, right - 48, top)
      ..quadraticBezierTo(right, top + 15, right, top + 58)
      ..lineTo(right, bottom);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SubtleArchitecturalFrame oldDelegate) => false;
}

class _Architectural3DViewer extends StatelessWidget {
  const _Architectural3DViewer();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _night,
        appBar: AppBar(
          backgroundColor: _night,
          foregroundColor: _ivory,
          title: const Text('المشهد المعماري ثلاثي الأبعاد'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: Text(
                  'تجوّلي بعينيكِ بين الأعمدة والأقواس',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ivory,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Expanded(
                child: ModelViewer(
                  src: 'assets/models/madinah/grandeur_mosque.glb',
                  alt: 'نموذج معماري فني ثلاثي الأبعاد لأعمدة وأقواس مستوحاة من العمارة الإسلامية',
                  ar: false,
                  autoRotate: true,
                  autoRotateDelay: 500,
                  cameraControls: true,
                  disableZoom: false,
                  backgroundColor: _night,
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  border: Border.all(color: _gold.withValues(alpha: .45)),
                  borderRadius: BorderRadius.circular(19),
                  color: _green,
                ),
                child: const Column(
                  children: [
                    Text(
                      'حرّكي إصبعك لتدوير النموذج، وبإصبعين للتقريب',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _ivory, height: 1.7),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'نموذج فني مستوحى من عناصر العمارة الإسلامية؛ ليس توثيقًا دقيقًا للمسجد النبوي أو الروضة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _gold, fontSize: 11, height: 1.55),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
