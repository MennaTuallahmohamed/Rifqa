import 'dart:math' as math;
import 'package:flutter/material.dart';

const _introGreen = Color(0xFF176B50);
const _introDarkGreen = Color(0xFF0C463A);
const _introGold = Color(0xFFDAB970);

/// 5.4-second cinematic splash, matching the existing FlowScreen timer.
/// The camera moves towards a still photo of the Kaaba; the Kaaba itself
/// does not unrealistically spin. Requires assets/images/rifqa_splash_kaaba.jpg.
class ImmersiveSplash extends StatefulWidget {
  const ImmersiveSplash({super.key});

  @override
  State<ImmersiveSplash> createState() => _ImmersiveSplashState();
}

class _ImmersiveSplashState extends State<ImmersiveSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5400),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _phase(double t, double start, double end) {
    return Curves.easeOutCubic.transform(
      ((t - start) / (end - start)).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: _introDarkGreen,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = reduceMotion ? 1.0 : _controller.value;
          final reveal = _phase(t, 0.03, 0.52);
          final words = _phase(t, 0.35, 0.70);
          final subtitle = _phase(t, 0.55, 0.82);
          return Stack(
            fit: StackFit.expand,
            children: [
              // The entire background drifts and zooms gently like a camera.
              Transform.translate(
                offset: Offset(0, 18 * (1 - reveal) - 13 * t),
                child: Transform.scale(
                  scale: 1.14 - 0.11 * reveal + 0.035 * t,
                  child: Image.asset(
                    'assets/images/rifqa_splash_kaaba.jpg',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.12),
                    errorBuilder: (_, __, ___) => const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFD7B873), _introDarkGreen],
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.mosque_rounded,
                            color: _introGold, size: 135),
                      ),
                    ),
                  ),
                ),
              ),
              // Light at the top, stronger emerald foundation for clear text.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.42, 0.70, 1.0],
                    colors: [
                      Color(0x300A392A),
                      Colors.transparent,
                      Color(0xA8083226),
                      Color(0xFA082B24),
                    ],
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _GoldenDustPainter(t),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 20, 26, 49),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Opacity(
                        opacity: words,
                        child: Transform.translate(
                          offset: Offset(0, 32 * (1 - words)),
                          child: const Column(
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  color: _introGold, size: 31),
                              SizedBox(height: 13),
                              Text(
                                'رِفقة',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 52,
                                  height: 1.12,
                                  fontWeight: FontWeight.w900,
                                  shadows: [Shadow(
                                    color: Color(0x77041F18),
                                    blurRadius: 20,
                                    offset: Offset(0, 4),
                                  )],
                                ),
                              ),
                              SizedBox(height: 10),
                              SizedBox(
                                width: 95,
                                child: Divider(color: _introGold, thickness: 1.2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Opacity(
                        opacity: subtitle,
                        child: const Column(
                          children: [
                            Text(
                              'رفيق المعتمر',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFF8E6BE),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'معك في كل خطوة... وطمأنينة في كل لحظة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xF0FFFFFF),
                                fontSize: 13,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 33),
                      Opacity(
                        opacity: _phase(t, 0.72, 0.96),
                        child: const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _introGold,
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
        },
      ),
    );
  }
}

class _GoldenDustPainter extends CustomPainter {
  const _GoldenDustPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 38; i++) {
      final x = ((i * 0.61803398875 + 0.13) % 1) * size.width;
      final initialY = ((i * 0.38196601125 + 0.22) % 1);
      final y = ((initialY - progress * (0.09 + (i % 4) * 0.017)) % 1) *
          size.height;
      final blink = 0.35 + 0.65 *
          (0.5 + 0.5 * math.sin(i * 2.4 + progress * math.pi * 7));
      final opacity = (0.12 + 0.50 * blink).clamp(0.0, 1.0);
      paint.color = _introGold.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), 0.8 + (i % 3) * 0.75, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GoldenDustPainter oldDelegate) =>
      oldDelegate.progress != progress;
}


// ============================================================
// Onboarding — cinematic emerald / gold / cream.
// All writing and buttons are real Flutter widgets, not baked into photos.
// ============================================================
class ImmersiveOnboarding extends StatefulWidget {
  const ImmersiveOnboarding({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<ImmersiveOnboarding> createState() => _ImmersiveOnboardingState();
}

class _Slide {
  const _Slide(this.image, this.title, this.detail, this.icon, this.items);
  final String image;
  final String title;
  final String detail;
  final IconData icon;
  final List<(IconData, String)> items;
}

class _ImmersiveOnboardingState extends State<ImmersiveOnboarding> {
  final PageController _pages = PageController();
  int _index = 0;
  bool _finished = false;

  static const _slides = <_Slide>[
    _Slide(
      'assets/images/rifqa_onboarding_1.jpg',
      'أهلًا بك في رِفقة',
      'رحلة روحانية أسهل وأهدأ، معك من أول خطوة حتى العودة.',
      Icons.mosque_rounded,
      [(Icons.auto_stories_rounded, 'مناسك العمرة'), (Icons.favorite_border_rounded, 'أدعية وأذكار')],
    ),
    _Slide(
      'assets/images/rifqa_onboarding_2.jpg',
      'دليلك في كل خطوة',
      'دليل واضح للمناسك، وخرائط للأماكن المهمة في الحرمين.',
      Icons.menu_book_rounded,
      [(Icons.map_rounded, 'الخرائط'), (Icons.menu_book_rounded, 'دليل العمرة')],
    ),
    _Slide(
      'assets/images/rifqa_onboarding_3.jpg',
      'لست وحدك',
      'رفقتك في كل خطوة.. من التخطيط حتى العودة.',
      Icons.favorite_rounded,
      [(Icons.groups_rounded, 'رفقتي'), (Icons.location_on_outlined, 'أنا تائه'), (Icons.chat_bubble_outline_rounded, 'اسأل رفقة')],
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _complete() {
    if (_finished) return;
    _finished = true;
    widget.onComplete();
  }

  void _next() {
    if (_index == _slides.length - 1) {
      _complete();
    } else {
      _pages.nextPage(duration: const Duration(milliseconds: 520), curve: Curves.easeInOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final compact = screenHeight < 710;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _introDarkGreen,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pages,
              itemCount: _slides.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) => _IntroPage(
                slide: _slides[index],
                compact: compact,
                animate: !reduceMotion,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 9, 20, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: _introGold, size: 21),
                        const SizedBox(width: 6),
                        const Text('رِفقة', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                        const Spacer(),
                        TextButton(
                          onPressed: _complete,
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFE8B5)),
                          child: const Text('تخطّي', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(23, 0, 23, compact ? 10 : 19),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_slides.length, (index) {
                            final selected = index == _index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: selected ? 26 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: selected ? _introGold : const Color(0xFF477E6A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          height: 53,
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _next,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF5E7C9),
                              foregroundColor: _introDarkGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: const BorderSide(color: _introGold, width: 1.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_index == _slides.length - 1 ? 'ابدئي رحلتك' : 'التالي',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                                const SizedBox(width: 9),
                                const Icon(Icons.arrow_back_rounded, size: 19),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.slide, required this.compact, required this.animate});
  final _Slide slide;
  final bool compact;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final height = constraints.maxHeight;
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(slide.image),
              tween: Tween(begin: animate ? 1.10 : 1.0, end: 1.0),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (context, zoom, child) => Transform.scale(scale: zoom, child: child),
              child: Image.asset(
                slide.image,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const DecoratedBox(
                  decoration: BoxDecoration(gradient: LinearGradient(
                    colors: [Color(0xFFC9A269), _introDarkGreen],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  )),
                  child: Center(child: Icon(Icons.mosque_rounded, color: _introGold, size: 100)),
                ),
              ),
            ),
          ),
          // Emerald gradient is opaque at the bottom, so Arabic stays readable.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.34, 0.55, 0.73, 0.91, 1.0],
                colors: [
                  Color(0x18031D17),
                  Color(0x00031D17),
                  Color(0x22072C22),
                  Color(0x88073C2D),
                  _introDarkGreen,
                  _introDarkGreen,
                ],
              )),
            ),
          ),
          Positioned(
            left: 20, right: 20,
            bottom: compact ? 131.0 : 150.0,
            child: TweenAnimationBuilder<double>(
              key: ValueKey('text-${slide.title}'),
              tween: Tween(begin: animate ? 0 : 1, end: 1),
              duration: const Duration(milliseconds: 680),
              curve: Curves.easeOut,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(offset: Offset(0, (1 - value) * 16), child: child),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(slide.icon, color: _introGold, size: compact ? 24 : 29),
                  SizedBox(height: compact ? 7 : 11),
                  Text(slide.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: const Color(0xFFFFE5AD),
                      fontSize: compact ? 26 : 30, height: 1.25,
                      fontWeight: FontWeight.w900)),
                  SizedBox(height: compact ? 6 : 10),
                  Text(slide.detail, textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, height: 1.65,
                      fontSize: compact ? 12.5 : 14)),
                  SizedBox(height: compact ? 15 : 21),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: slide.items.map((item) => Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: compact ? 38 : 44,
                            width: compact ? 38 : 44,
                            decoration: BoxDecoration(
                              color: const Color(0x264B9479),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0x99DAB970)),
                            ),
                            child: Icon(item.$1, color: _introGold, size: 22),
                          ),
                          const SizedBox(height: 7),
                          Text(item.$2, maxLines: 1, overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: compact ? 11 : 12,
                              fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}
