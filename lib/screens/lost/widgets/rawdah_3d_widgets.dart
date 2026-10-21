import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../madinah/immersive/cinematic_theme.dart';
import '../../madinah/immersive/rawdah_data.dart';

// ════════════════════════════════════════════════════════════════════════════
//  عناصر ثلاثية الأبعاد بدون أي مكتبة خارجية (Matrix4 + Perspective فقط)
//   • SafeAsset         : صورة من assets بخلفية بديلة لو الملف غير موجود
//   • Rawdah3DCarousel  : معرض دوّار أسطواني يُسحب بالإصبع ويدور وحده
//   • Tilt3D            : يميل أي عنصر (الموبايل) مع لمس الإصبع + لمعة + ظل متحرك
//   • PulseHighlight    : توهج نابض يوجّه المتدرّبة إلى مكان الضغط
//   • SparkleBurst      : انفجار نجوم ذهبية عند إتمام التدريب
// ════════════════════════════════════════════════════════════════════════════

class SafeAsset extends StatelessWidget {
  const SafeAsset(this.path,
      {super.key, this.fit = BoxFit.cover, this.alignment = Alignment.center});
  final String path;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Image.asset(
        path,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, __, ___) => const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B5A43), Color(0xFF023A2B)],
            ),
          ),
          child: Center(
            child: Icon(Icons.mosque_rounded, color: Color(0x66FFFFFF), size: 44),
          ),
        ),
      );
}

// ───────────────────────── معرض أسطواني ثلاثي الأبعاد ─────────────────────────

class Rawdah3DCarousel extends StatefulWidget {
  const Rawdah3DCarousel({
    super.key,
    required this.items,
    this.height = 270,
    this.onFrontChanged,
  });
  final List<GalleryItem> items;
  final double height;
  final ValueChanged<int>? onFrontChanged;

  @override
  State<Rawdah3DCarousel> createState() => _Rawdah3DCarouselState();
}

class _Rawdah3DCarouselState extends State<Rawdah3DCarousel>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _angle = 0;
  double _velocity = 0;
  bool _dragging = false;
  bool _reduceMotion = false;
  int _front = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _last = elapsed;
    if (!_dragging) {
      final auto = _reduceMotion ? 0.0 : 0.28;
      _angle += (auto + _velocity) * dt;
      _velocity *= math.pow(0.05, dt).toDouble();
    }
    final n = widget.items.length;
    var best = 0;
    var bestCos = -2.0;
    for (var i = 0; i < n; i++) {
      final c = math.cos(_angle + i * 2 * math.pi / n);
      if (c > bestCos) {
        bestCos = c;
        best = i;
      }
    }
    if (best != _front) {
      _front = best;
      widget.onFrontChanged?.call(best);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    if (n == 0) return SizedBox(height: widget.height);
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final cardW = math.min(w * 0.58, 280.0);
      final cardH = widget.height - 46;
      final radius = w * 0.30;
      // الأبعد أولًا ثم الأقرب فوقه
      final order = List<int>.generate(n, (i) => i)
        ..sort((a, b) => math
            .cos(_angle + a * 2 * math.pi / n)
            .compareTo(math.cos(_angle + b * 2 * math.pi / n)));
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _dragging = true;
          _velocity = 0;
        },
        onHorizontalDragUpdate: (d) => _angle += d.delta.dx * 0.009,
        onHorizontalDragEnd: (d) {
          _dragging = false;
          _velocity = (d.velocity.pixelsPerSecond.dx * 0.009).clamp(-4.0, 4.0).toDouble();
        },
        onHorizontalDragCancel: () => _dragging = false,
        child: SizedBox(
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ظل الأرضية
              Positioned(
                bottom: 4,
                child: Container(
                  width: cardW * 0.9,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: const [
                      BoxShadow(color: Color(0x66000000), blurRadius: 28, spreadRadius: 2),
                    ],
                  ),
                ),
              ),
              for (final i in order) _card(i, n, cardW, cardH, radius),
            ],
          ),
        ),
      );
    });
  }

  Widget _card(int i, int n, double cardW, double cardH, double radius) {
    final theta = _angle + i * 2 * math.pi / n;
    final s = math.sin(theta);
    final depth = (math.cos(theta) + 1) / 2; // 0 خلف … 1 أمام
    final scale = 0.66 + 0.34 * depth;
    final m = Matrix4.identity()
      ..setEntry(3, 2, 0.0014)
      ..rotateY(-s * 0.55)
      ..scale(scale, scale, 1.0);
    return Transform.translate(
      offset: Offset(s * radius * 1.15, -4 * depth),
      child: Transform(
        alignment: Alignment.center,
        transform: m,
        child: Opacity(
          opacity: 0.45 + 0.55 * depth,
          child: SizedBox(width: cardW, height: cardH, child: _face(widget.items[i], depth)),
        ),
      ),
    );
  }

  Widget _face(GalleryItem item, double depth) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: cinematicGold.withAlpha((90 + 120 * depth).round()),
            width: 1.6,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 26, offset: Offset(0, 16)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(fit: StackFit.expand, children: [
            SafeAsset(item.asset),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC021F17)],
                  stops: [0.45, 1],
                ),
              ),
            ),
            Positioned(
              right: 14,
              left: 14,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(item.caption,
                      style: const TextStyle(color: Color(0xFFEADFC2), fontSize: 11)),
                ],
              ),
            ),
          ]),
        ),
      );
}

// ───────────────────────── ميلان ثلاثي الأبعاد مع اللمس ─────────────────────────

/// يُميل [child] في الفضاء حسب مكان الإصبع. يستخدم Listener (وليس GestureDetector)
/// حتى لا يمنع تمرير الصفحة ولا ضغطات الأزرار داخل الموبايل.
class Tilt3D extends StatefulWidget {
  const Tilt3D({
    super.key,
    required this.child,
    this.borderRadius = 40,
    this.maxTilt = 0.30,
  });
  final Widget child;
  final double borderRadius;
  final double maxTilt;

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> with SingleTickerProviderStateMixin {
  late final AnimationController _idle;
  Offset _target = Offset.zero;
  bool _touching = false;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(vsync: this, duration: const Duration(seconds: 7))
      ..repeat();
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  void _update(PointerEvent e) {
    final size = context.size ?? const Size(300, 600);
    if (size.width <= 0 || size.height <= 0) return;
    final dx = (e.localPosition.dx / size.width * 2 - 1).clamp(-1.0, 1.0).toDouble();
    final dy = (e.localPosition.dy / size.height * 2 - 1).clamp(-1.0, 1.0).toDouble();
    setState(() {
      _touching = true;
      _target = Offset(dx, dy);
    });
  }

  void _release() => setState(() {
        _touching = false;
        _target = Offset.zero;
      });

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final radius = BorderRadius.circular(widget.borderRadius);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _update,
      onPointerMove: _update,
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(end: _target),
        duration: Duration(milliseconds: _touching ? 90 : 650),
        curve: _touching ? Curves.linear : Curves.easeOutBack,
        child: widget.child,
        builder: (context, tilt, child) => AnimatedBuilder(
          animation: _idle,
          child: child,
          builder: (context, child) {
            final sway = (_touching || reduce)
                ? Offset.zero
                : Offset(math.sin(_idle.value * 2 * math.pi) * 0.32,
                    math.cos(_idle.value * 2 * math.pi) * 0.18);
            final t = tilt + sway;
            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.0011)
              ..rotateX(-t.dy * widget.maxTilt)
              ..rotateY(t.dx * widget.maxTilt);
            final gx = t.dx.clamp(-1.0, 1.0).toDouble();
            final gy = t.dy.clamp(-1.0, 1.0).toDouble();
            return Transform(
              alignment: Alignment.center,
              transform: m,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x55000000),
                      blurRadius: 34,
                      offset: Offset(-t.dx * 22, 20 - t.dy * 10),
                    ),
                  ],
                ),
                child: Stack(children: [
                  child!,
                  // لمعة زجاجية تتحرك عكس الميلان
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          gradient: RadialGradient(
                            center: Alignment(-gx, -gy),
                            radius: 0.95,
                            colors: const [Color(0x2EFFFFFF), Color(0x00FFFFFF)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────── توهج نابض لمكان الضغط ─────────────────────────

class PulseHighlight extends StatefulWidget {
  const PulseHighlight({
    super.key,
    required this.child,
    this.active = true,
    this.radius = 14,
  });
  final Widget child;
  final bool active;
  final double radius;

  @override
  State<PulseHighlight> createState() => _PulseHighlightState();
}

class _PulseHighlightState extends State<PulseHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: [
            BoxShadow(
              color: cinematicGold.withAlpha((60 + 140 * _c.value).round()),
              blurRadius: 6 + 14 * _c.value,
              spreadRadius: 1 + 2 * _c.value,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ───────────────────────── نجوم ذهبية عند النجاح ─────────────────────────

class SparkleBurst extends StatefulWidget {
  const SparkleBurst({super.key});
  @override
  State<SparkleBurst> createState() => _SparkleBurstState();
}

class _Particle {
  _Particle(this.angle, this.speed, this.size, this.color);
  final double angle, speed, size;
  final Color color;
}

class _SparkleBurstState extends State<SparkleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(42);
    const palette = [cinematicGold, cinematicCream, Colors.white];
    _particles = List.generate(
      42,
      (_) => _Particle(
        rnd.nextDouble() * 2 * math.pi,
        70 + rnd.nextDouble() * 150,
        2 + rnd.nextDouble() * 4,
        palette[rnd.nextInt(palette.length)],
      ),
    );
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: SizedBox.expand(
          child: CustomPaint(painter: _SparklePainter(_c, _particles)),
        ),
      );
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.anim, this.particles) : super(repaint: anim);
  final Animation<double> anim;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(anim.value);
    final cx = size.width / 2;
    final cy = size.height * 0.38;
    for (final p in particles) {
      final x = cx + math.cos(p.angle) * p.speed * t;
      final y = cy + math.sin(p.angle) * p.speed * t + 110 * anim.value * anim.value;
      final alpha = ((1 - anim.value) * 255).clamp(0, 255).round();
      final paint = Paint()..color = p.color.withAlpha(alpha);
      canvas.drawCircle(Offset(x, y), p.size * (1 - anim.value * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => true;
}