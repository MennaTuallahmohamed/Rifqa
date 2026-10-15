import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'umrah_data.dart';

/// صورة الخطوة:
/// - إن وجدت صورة حقيقية في assets/umrah/step_1.jpg ... step_7.jpg تُعرض تلقائيًا
/// - وإلا يُرسم مشهد توضيحي بالكود
class UStepArt extends StatelessWidget {
  final int index;
  final List<Color> colors;
  const UStepArt({super.key, required this.index, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: Image.asset(
          'assets/umrah/step_${index + 1}.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: colors,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: UPatternPainter(opacity: .10)),
            CustomPaint(painter: _ArtPainter(index)),
          ],
        ),
      );
}

class _ArtPainter extends CustomPainter {
  final int i;
  _ArtPainter(this.i);

  static final _skin = Paint()..color = const Color(0xFFD9A77A);
  static final _white = Paint()..color = Colors.white;

  void _text(Canvas c, String t, Offset at,
      {double size = 14, Color color = Colors.white}) {
    final tp = TextPainter(
      text: TextSpan(
          text: t,
          style: TextStyle(
              fontSize: size, color: color, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.rtl,
    )..layout();
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final g = s.height - 16;
    final shadow = Paint()..color = Colors.black26;
    c.drawOval(
        Rect.fromCenter(
            center: Offset(cx, g + 4), width: s.width * .7, height: 14),
        shadow);

    switch (i) {
      case 0: // الإحرام
        final izar = Path()
          ..moveTo(cx - 24, g - 52)
          ..lineTo(cx + 24, g - 52)
          ..lineTo(cx + 30, g - 4)
          ..lineTo(cx - 30, g - 4)
          ..close();
        c.drawPath(izar, _white);
        c.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(cx + 2, g - 98, 24, 48),
                const Radius.circular(8)),
            _skin);
        final rida = Path()
          ..moveTo(cx - 28, g - 94)
          ..lineTo(cx + 4, g - 100)
          ..lineTo(cx + 22, g - 52)
          ..lineTo(cx - 28, g - 52)
          ..close();
        c.drawPath(rida, Paint()..color = const Color(0xFFF1F1F1));
        c.drawCircle(Offset(cx, g - 112), 14, _skin);
        c.drawRect(Rect.fromLTWH(cx - 22, g - 4, 16, 4),
            Paint()..color = const Color(0xFF4A3B2A));
        c.drawRect(Rect.fromLTWH(cx + 8, g - 4, 16, 4),
            Paint()..color = const Color(0xFF4A3B2A));
        _text(c, 'إزار ورداء أبيضان', Offset(cx + s.width * .28, g - 70),
            size: 12);
        break;

      case 1: // الميقات
        final board = RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx - 30, g - 70), width: 130, height: 50),
            const Radius.circular(10));
        c.drawRect(Rect.fromLTWH(cx - 92, g - 50, 6, 50),
            Paint()..color = Colors.white70);
        c.drawRect(Rect.fromLTWH(cx + 32, g - 50, 6, 50),
            Paint()..color = Colors.white70);
        c.drawRRect(board, Paint()..color = const Color(0xFF0B4A36));
        c.drawRRect(
            board,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = const Color(0xFFD9B45A));
        _text(c, 'الميقات', Offset(cx - 30, g - 70), size: 20);
        final bub = RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx + s.width * .26, 40), width: 130, height: 36),
            const Radius.circular(18));
        c.drawRRect(bub, _white);
        _text(c, 'لبيك اللهم عمرة', Offset(cx + s.width * .26, 40),
            size: 13, color: const Color(0xFF0B4A36));
        break;

      case 2: // الحرم
        final body = Paint()..color = Colors.white.withOpacity(.92);
        c.drawRect(Rect.fromLTWH(cx - 70, g - 56, 140, 56), body);
        final arch = Path()
          ..moveTo(cx - 20, g)
          ..lineTo(cx - 20, g - 28)
          ..arcToPoint(Offset(cx + 20, g - 28),
              radius: const Radius.circular(20))
          ..lineTo(cx + 20, g)
          ..close();
        c.drawPath(arch, Paint()..color = const Color(0xFF0B4A36));
        for (final dx in [-92.0, 92.0]) {
          c.drawRect(Rect.fromLTWH(cx + dx - 7, g - 100, 14, 100), body);
          final cap = Path()
            ..moveTo(cx + dx - 9, g - 100)
            ..lineTo(cx + dx, g - 122)
            ..lineTo(cx + dx + 9, g - 100)
            ..close();
          c.drawPath(cap, Paint()..color = const Color(0xFFD9B45A));
          c.drawCircle(Offset(cx + dx, g - 126), 3,
              Paint()..color = const Color(0xFFD9B45A));
        }
        c.drawArc(
            Rect.fromCenter(center: Offset(cx, g - 56), width: 70, height: 60),
            math.pi,
            math.pi,
            true,
            Paint()..color = const Color(0xFFD9B45A));
        break;

      case 3: // الكعبة والطواف
        final top = Path()
          ..moveTo(cx, g - 96)
          ..lineTo(cx + 36, g - 80)
          ..lineTo(cx, g - 64)
          ..lineTo(cx - 36, g - 80)
          ..close();
        final left = Path()
          ..moveTo(cx - 36, g - 80)
          ..lineTo(cx, g - 64)
          ..lineTo(cx, g - 16)
          ..lineTo(cx - 36, g - 32)
          ..close();
        final right = Path()
          ..moveTo(cx + 36, g - 80)
          ..lineTo(cx, g - 64)
          ..lineTo(cx, g - 16)
          ..lineTo(cx + 36, g - 32)
          ..close();
        c.drawPath(top, Paint()..color = const Color(0xFF2B2B2B));
        c.drawPath(left, Paint()..color = const Color(0xFF111111));
        c.drawPath(right, Paint()..color = const Color(0xFF1C1C1C));
        final band = Path()
          ..moveTo(cx, g - 54)
          ..lineTo(cx + 36, g - 70)
          ..lineTo(cx + 36, g - 62)
          ..lineTo(cx, g - 46)
          ..close();
        c.drawPath(band, Paint()..color = const Color(0xFFD9B45A));
        c.drawOval(
            Rect.fromCenter(center: Offset(cx, g - 28), width: 190, height: 56),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.white54);
        for (int k = 0; k < 8; k++) {
          final a = k * math.pi / 4 + .3;
          c.drawCircle(Offset(cx + 95 * math.cos(a), g - 28 + 28 * math.sin(a)),
              4, _white);
        }
        break;

      case 4: // المقام وزمزم
        final dome = Paint()..color = const Color(0xFFD9B45A);
        c.drawRect(Rect.fromLTWH(cx - 86, g - 50, 44, 50), dome);
        c.drawArc(Rect.fromLTWH(cx - 90, g - 74, 52, 48), math.pi, math.pi,
            true, dome);
        final cup = Path()
          ..moveTo(cx + 20, g - 70)
          ..lineTo(cx + 70, g - 70)
          ..lineTo(cx + 62, g - 8)
          ..lineTo(cx + 28, g - 8)
          ..close();
        c.drawPath(cup, Paint()..color = Colors.white.withOpacity(.85));
        c.drawRect(Rect.fromLTWH(cx + 25, g - 46, 40, 36),
            Paint()..color = const Color(0xFF6FC3E8));
        _text(c, 'زمزم', Offset(cx + 45, g - 90), size: 14);
        break;

      case 5: // السعي
        final hill = Paint()..color = const Color(0xFF8A7A5A);
        for (final x in [40.0, s.width - 40]) {
          final p = Path()
            ..moveTo(x - 36, g)
            ..lineTo(x, g - 64)
            ..lineTo(x + 36, g)
            ..close();
          c.drawPath(p, hill);
        }
        c.drawRect(Rect.fromLTWH(70, g - 6, s.width - 140, 6),
            Paint()..color = Colors.white30);
        c.drawRect(Rect.fromLTWH(cx - 34, g - 6, 68, 6),
            Paint()..color = const Color(0xFF2EE59D));
        for (int k = 0; k < 5; k++) {
          c.drawCircle(Offset(90 + k * (s.width - 180) / 4, g - 16), 6, _white);
        }
        _text(c, 'الصفا', Offset(40, g - 78), size: 12);
        _text(c, 'المروة', Offset(s.width - 40, g - 78), size: 12);
        break;

      default: // الحلق والتقصير
        final blade = Paint()
          ..color = Colors.white
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        final m = Offset(cx, g - 66);
        c.drawLine(m, m + const Offset(46, -50), blade);
        c.drawLine(m, m + const Offset(46, 50), blade);
        c.drawLine(m, m + const Offset(-26, 24), blade);
        c.drawLine(m, m + const Offset(-26, -24), blade);
        final ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = const Color(0xFFD9B45A);
        c.drawCircle(m + const Offset(-40, 36), 14, ring);
        c.drawCircle(m + const Offset(-40, -36), 14, ring);
        for (int k = 0; k < 4; k++) {
          c.drawLine(
              Offset(cx + 70 + k * 10, g - 20),
              Offset(cx + 76 + k * 10, g - 52),
              Paint()
                ..color = Colors.white54
                ..strokeWidth = 2);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _ArtPainter old) => old.i != i;
}
