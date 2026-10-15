import 'dart:math' as math;
import 'package:flutter/material.dart';

/// مشاهد مرسومة ومتحركة لكل منسك من مناسك الحج (تعمل بلا أي ملفات صور).
/// إن وضعت صورة حقيقية في assets/hajj/step_N.jpg ستظهر بدلها تلقائيًا
/// إذا استعملت [HajjScene] مع [preferAsset] = true.
class HajjScene extends StatefulWidget {
  final int index; // 0..7
  final double height;
  final double radius;
  final bool preferAsset;
  final Widget? overlay;
  const HajjScene({
    super.key,
    required this.index,
    this.height = 160,
    this.radius = 20,
    this.preferAsset = true,
    this.overlay,
  });

  @override
  State<HajjScene> createState() => _HajjSceneState();
}

class _HajjSceneState extends State<HajjScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _painted() => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _ScenePainter(widget.index, _c.value),
          size: Size.infinite,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.preferAsset)
              Image.asset(
                'assets/hajj/step_${widget.index + 1}.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _painted(),
              )
            else
              _painted(),
            // تدرّج خفيف أسفل الصورة ليبرز النص
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x66000000)],
                ),
              ),
            ),
            if (widget.overlay != null) widget.overlay!,
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════ الرسم ═══════════════════════════

class _ScenePainter extends CustomPainter {
  final int i;
  final double t; // 0..1 متكرر
  _ScenePainter(this.i, this.t);

  static const _white = Color(0xFFF6F3EA);
  static const _gold = Color(0xFFD9B45A);

  double get _tw => t * math.pi * 2;

  @override
  void paint(Canvas c, Size s) {
    switch (i) {
      case 0:
        _mina(c, s, dawn: true);
        break;
      case 1:
        _arafat(c, s);
        break;
      case 2:
        _muzdalifah(c, s);
        break;
      case 3:
        _jamarat(c, s, three: false);
        break;
      case 4:
        _hady(c, s);
        break;
      case 5:
        _kaabaScene(c, s, sunset: false);
        break;
      case 6:
        _jamarat(c, s, three: true);
        break;
      default:
        _kaabaScene(c, s, sunset: true);
    }
  }

  // ───── أدوات
  void _sky(Canvas c, Size s, Color a, Color b) {
    final r = Offset.zero & s;
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [a, b],
        ).createShader(r),
    );
  }

  void _stars(Canvas c, Size s, {int n = 46, double h = .6}) {
    final r = math.Random(11);
    for (int k = 0; k < n; k++) {
      final tw = .35 + .65 * (.5 + .5 * math.sin(_tw * 2 + k));
      c.drawCircle(
        Offset(r.nextDouble() * s.width, r.nextDouble() * s.height * h),
        r.nextDouble() * 1.3 + .4,
        Paint()..color = Colors.white.withOpacity(tw * .85),
      );
    }
  }

  void _glowSun(Canvas c, Offset p, double r, Color col) {
    c.drawCircle(
      p,
      r * 3,
      Paint()
        ..shader = RadialGradient(
          colors: [col.withOpacity(.45), col.withOpacity(0)],
        ).createShader(Rect.fromCircle(center: p, radius: r * 3)),
    );
    c.drawCircle(p, r, Paint()..color = col);
  }

  void _moon(Canvas c, Offset p, double r) {
    final a = Path()..addOval(Rect.fromCircle(center: p, radius: r));
    final b = Path()
      ..addOval(Rect.fromCircle(
          center: p.translate(r * .45, -r * .2), radius: r * .88));
    c.drawCircle(
      p,
      r * 2.2,
      Paint()
        ..shader = RadialGradient(
          colors: [_gold.withOpacity(.3), _gold.withOpacity(0)],
        ).createShader(Rect.fromCircle(center: p, radius: r * 2.2)),
    );
    c.drawPath(Path.combine(PathOperation.difference, a, b),
        Paint()..color = const Color(0xFFEFD58F));
  }

  void _ground(Canvas c, Size s, double y, Color a, Color b) {
    final r = Rect.fromLTWH(0, y, s.width, s.height - y);
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [a, b],
        ).createShader(r),
    );
  }

  void _hills(Canvas c, Size s, double base, Color col, double amp, int seed) {
    final p = Path()..moveTo(0, s.height);
    final r = math.Random(seed);
    final ph = r.nextDouble() * 6;
    for (double x = 0; x <= s.width; x += 6) {
      final y = base -
          amp * (.5 + .5 * math.sin(x / s.width * 5 + ph)) -
          amp * .4 * math.sin(x / s.width * 11 + ph * 2);
      p.lineTo(x, y);
    }
    p.lineTo(s.width, s.height);
    p.close();
    c.drawPath(p, Paint()..color = col);
  }

  void _tent(Canvas c, double x, double y, double w, Color col) {
    final h = w * .62;
    final body = Path()
      ..moveTo(x - w / 2, y)
      ..lineTo(x - w * .5, y - h * .45)
      ..lineTo(x, y - h)
      ..lineTo(x + w * .5, y - h * .45)
      ..lineTo(x + w / 2, y)
      ..close();
    c.drawPath(body, Paint()..color = col);
    c.drawPath(
      Path()
        ..moveTo(x, y - h)
        ..lineTo(x + w * .5, y - h * .45)
        ..lineTo(x + w / 2, y)
        ..lineTo(x, y)
        ..close(),
      Paint()..color = Colors.black.withOpacity(.12),
    );
    c.drawRect(
      Rect.fromCenter(
          center: Offset(x, y - h * .22), width: w * .16, height: h * .42),
      Paint()..color = const Color(0xFF2C3E50).withOpacity(.55),
    );
  }

  void _person(Canvas c, double x, double y, double h,
      {bool arms = false, Color robe = _white}) {
    final w = h * .34;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - w / 2, y - h * .72, w, h * .72),
        Radius.circular(w * .5),
      ),
      Paint()..color = robe,
    );
    c.drawCircle(Offset(x, y - h * .82), h * .13,
        Paint()..color = const Color(0xFFC98F65));
    if (arms) {
      final p = Paint()
        ..color = robe
        ..strokeWidth = h * .09
        ..strokeCap = StrokeCap.round;
      c.drawLine(Offset(x - w * .45, y - h * .55),
          Offset(x - w * .95, y - h * 1.0), p);
      c.drawLine(Offset(x + w * .45, y - h * .55),
          Offset(x + w * .95, y - h * 1.0), p);
    }
  }

  void _kaaba(Canvas c, Offset base, double w) {
    final h = w * 1.05;
    final front = Rect.fromLTWH(base.dx - w / 2, base.dy - h, w, h);
    c.drawRect(front, Paint()..color = const Color(0xFF15161A));
    c.drawRect(
      Rect.fromLTWH(front.left, front.top + h * .2, w, h * .1),
      Paint()..color = _gold,
    );
    // باب
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx - w * .12, base.dy - h * .52, w * .24, h * .42),
        const Radius.circular(3),
      ),
      Paint()..color = _gold.withOpacity(.9),
    );
    c.drawRect(
      Rect.fromLTWH(front.left, front.top, w, h * .035),
      Paint()..color = Colors.white10,
    );
  }

  // ───── 1) منى والتروية
  void _mina(Canvas c, Size s, {required bool dawn}) {
    _sky(c, s, const Color(0xFF1D3B63), const Color(0xFFFFB16B));
    _stars(c, s, n: 20, h: .3);
    _glowSun(c, Offset(s.width * .78, s.height * (.58 - .06 * math.sin(_tw))),
        18, const Color(0xFFFFE0A0));
    _hills(c, s, s.height * .62, const Color(0xFF6D5A52), 16, 2);
    _ground(
        c, s, s.height * .68, const Color(0xFFB79C79), const Color(0xFF8A7457));
    final r = math.Random(4);
    for (int row = 0; row < 3; row++) {
      final y = s.height * (.78 + row * .1);
      final w = 34 + row * 12.0;
      for (double x = -10 + row * 14; x < s.width + 20; x += w * 1.12) {
        _tent(c, x, y, w, row.isEven ? _white : const Color(0xFFEFE8D6));
      }
    }
    for (int k = 0; k < 7; k++) {
      final x = ((r.nextDouble() * s.width) + _tw * 6 * (k.isEven ? 1 : -1)) %
          s.width;
      _person(c, x, s.height * (.9 + (k % 3) * .02), 22);
    }
  }

  // ───── 2) عرفة
  void _arafat(Canvas c, Size s) {
    _sky(c, s, const Color(0xFF58B4EC), const Color(0xFFFFE9B8));
    _glowSun(c, Offset(s.width * .22, s.height * (.26 + .03 * math.sin(_tw))),
        16, const Color(0xFFFFE9A8));
    _hills(c, s, s.height * .62, const Color(0xFFA68B6A), 14, 7);
    // جبل الرحمة
    final m = Path()
      ..moveTo(s.width * .45, s.height * .72)
      ..quadraticBezierTo(
          s.width * .62, s.height * .28, s.width * .82, s.height * .72)
      ..close();
    c.drawPath(m, Paint()..color = const Color(0xFF8F7656));
    c.drawPath(
      Path()
        ..moveTo(s.width * .62, s.height * .38)
        ..quadraticBezierTo(
            s.width * .72, s.height * .5, s.width * .82, s.height * .72)
        ..lineTo(s.width * .62, s.height * .72)
        ..close(),
      Paint()..color = Colors.black.withOpacity(.14),
    );
    // النصب الأبيض
    c.drawRect(
      Rect.fromLTWH(s.width * .625, s.height * .33, 5, 20),
      Paint()..color = _white,
    );
    _ground(
        c, s, s.height * .72, const Color(0xFFCDB68F), const Color(0xFF9C8662));
    final r = math.Random(9);
    for (int k = 0; k < 16; k++) {
      final x = r.nextDouble() * s.width;
      final y = s.height * (.76 + r.nextDouble() * .2);
      _person(c, x, y, 18 + (y - s.height * .72) * .18,
          arms: (k + (t * 4).floor()) % 3 != 0);
    }
  }

  // ───── 3) مزدلفة
  void _muzdalifah(Canvas c, Size s) {
    _sky(c, s, const Color(0xFF050C1F), const Color(0xFF1A2E56));
    _stars(c, s, n: 80, h: .7);
    _moon(c, Offset(s.width * .2, s.height * .24), 15);
    _hills(c, s, s.height * .66, const Color(0xFF16213A), 12, 5);
    _ground(
        c, s, s.height * .7, const Color(0xFF2A2F3D), const Color(0xFF14171F));
    final r = math.Random(13);
    // حصى متناثرة
    for (int k = 0; k < 60; k++) {
      c.drawCircle(
        Offset(
            r.nextDouble() * s.width, s.height * (.72 + r.nextDouble() * .26)),
        1 + r.nextDouble() * 1.4,
        Paint()..color = const Color(0xFF8C8F99).withOpacity(.7),
      );
    }
    // حجاج نائمون ومصلّون
    for (int k = 0; k < 9; k++) {
      final x = (k + .5) * s.width / 9;
      final y = s.height * (.82 + (k % 3) * .06);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 30, height: 9),
          const Radius.circular(5),
        ),
        Paint()..color = _white.withOpacity(.85),
      );
      c.drawCircle(
          Offset(x - 17, y - 1), 4, Paint()..color = const Color(0xFFB9825C));
    }
  }

  // ───── 4 و 7) الجمرات
  void _jamarat(Canvas c, Size s, {required bool three}) {
    _sky(c, s, three ? const Color(0xFF3FA0E6) : const Color(0xFF2A74B8),
        const Color(0xFFFFEBC4));
    _glowSun(
        c, Offset(s.width * .84, s.height * .2), 14, const Color(0xFFFFE08A));
    _hills(c, s, s.height * .56, const Color(0xFFB7A184), 16, 3);
    _ground(
        c, s, s.height * .64, const Color(0xFFD7C8A8), const Color(0xFFA89572));
    final pillars = three ? 3 : 1;
    for (int k = 0; k < pillars; k++) {
      final cx = three ? s.width * (.25 + k * .25) : s.width * .5;
      final w = three ? 26.0 : 34.0;
      final h = s.height * (three ? .34 : .4);
      // الحوض
      c.drawOval(
        Rect.fromCenter(
            center: Offset(cx, s.height * .8), width: w * 3.6, height: w * 1.1),
        Paint()..color = const Color(0xFFE9E1CF),
      );
      c.drawOval(
        Rect.fromCenter(
            center: Offset(cx, s.height * .8), width: w * 3.2, height: w * .85),
        Paint()..color = const Color(0xFF9A8E75),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w / 2, s.height * .8 - h, w, h),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0xFFEDE6D6),
      );
      c.drawRect(
        Rect.fromLTWH(cx, s.height * .8 - h, w / 2, h),
        Paint()..color = Colors.black.withOpacity(.08),
      );
    }
    // حصيات تُرمى
    for (int k = 0; k < 7; k++) {
      final p = ((t * 2 + k / 7) % 1);
      final startX = s.width * (three ? .08 : .12);
      final endX = three ? s.width * (.25 + (k % 3) * .25) : s.width * .5;
      final x = startX + (endX - startX) * p;
      final y = s.height * .86 - math.sin(p * math.pi) * s.height * .45;
      c.drawCircle(Offset(x, y), 3, Paint()..color = const Color(0xFF5B5448));
    }
    for (int k = 0; k < 6; k++) {
      _person(
          c, s.width * (.05 + k * .035), s.height * (.9 + (k % 2) * .03), 24,
          arms: k == 0);
    }
  }

  // ───── 5) الهدي
  void _hady(Canvas c, Size s) {
    _sky(c, s, const Color(0xFF7BC4E8), const Color(0xFFFBE4B6));
    _glowSun(
        c, Offset(s.width * .8, s.height * .22), 15, const Color(0xFFFFD98A));
    _hills(c, s, s.height * .58, const Color(0xFF9BB07A), 14, 8);
    _ground(
        c, s, s.height * .64, const Color(0xFF8FB06A), const Color(0xFF5E8446));
    final bob = math.sin(_tw * 3) * 1.5;
    for (int k = 0; k < 3; k++) {
      final cx = s.width * (.25 + k * .24);
      final cy = s.height * (.78 + (k % 2) * .08) + (k.isEven ? bob : -bob);
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 56, height: 32),
          Paint()..color = const Color(0xFFF7F3EA));
      for (int b = 0; b < 4; b++) {
        c.drawCircle(Offset(cx - 18 + b * 12, cy - 8 + (b.isEven ? 0 : 3)), 10,
            Paint()..color = const Color(0xFFFFFFFF));
      }
      c.drawOval(
          Rect.fromCenter(
              center: Offset(cx + 30, cy - 4), width: 18, height: 18),
          Paint()..color = const Color(0xFF3B3B3B));
      for (final dx in [-16.0, -6.0, 8.0, 18.0]) {
        c.drawRect(Rect.fromLTWH(cx + dx, cy + 12, 3, 12),
            Paint()..color = const Color(0xFF3B3B3B));
      }
    }
    _moon(c, Offset(s.width * .12, s.height * .2), 8);
  }

  // ───── 6 و 8) الكعبة
  void _kaabaScene(Canvas c, Size s, {required bool sunset}) {
    if (sunset) {
      _sky(c, s, const Color(0xFF2E2A5A), const Color(0xFFFF8A4C));
      _stars(c, s, n: 24, h: .3);
      _glowSun(
          c, Offset(s.width * .2, s.height * .5), 20, const Color(0xFFFFC37A));
    } else {
      _sky(c, s, const Color(0xFF07122B), const Color(0xFF123A55));
      _stars(c, s, n: 60, h: .6);
      _moon(c, Offset(s.width * .84, s.height * .2), 11);
    }
    _ground(
        c, s, s.height * .74, const Color(0xFFE4DBC6), const Color(0xFFBDB191));
    // مآذن
    for (final x in [s.width * .08, s.width * .92]) {
      c.drawRect(Rect.fromLTWH(x - 5, s.height * .2, 10, s.height * .54),
          Paint()..color = const Color(0xFFD9D1BC));
      c.drawCircle(Offset(x, s.height * .2), 7, Paint()..color = _gold);
    }
    final base = Offset(s.width / 2, s.height * .72);
    _kaaba(c, base, math.min(s.width * .17, 64));
    // حلقة الطائفين
    final cx = s.width / 2, cy = s.height * .78;
    c.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy), width: s.width * .62, height: s.height * .2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white24,
    );
    const n = 26;
    for (int k = 0; k < n; k++) {
      final a = _tw + k * math.pi * 2 / n;
      final x = cx + math.cos(a) * s.width * .31;
      final y = cy + math.sin(a) * s.height * .1;
      final scale = .8 + .3 * (math.sin(a) * .5 + .5);
      _person(c, x, y + 8, 17 * scale);
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => old.t != t || old.i != i;
}
