import 'dart:math' as math;
import 'package:flutter/material.dart';

/// القبة الخضراء والمآذن (رسم تجريدي)
class DomePainter extends CustomPainter {
  final double t; // 0..1
  const DomePainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final pulse = .5 + .5 * math.sin(t * math.pi * 2);
    // توهج
    c.drawCircle(
      Offset(w * .5, h * .5),
      h * .75,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFE08A).withOpacity(.20 + .10 * pulse),
          const Color(0x00FFE08A),
        ]).createShader(Rect.fromCircle(center: Offset(w * .5, h * .5), radius: h * .75)),
    );
    // مآذن
    for (final x in [w * .16, w * .84]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x - w * .018, h * .22, w * .036, h * .78), const Radius.circular(3)),
        Paint()..color = const Color(0xFFEADFC0),
      );
      c.drawRect(Rect.fromLTWH(x - w * .026, h * .36, w * .052, h * .035),
          Paint()..color = const Color(0xFFC9992E));
      final cap = Path()
        ..moveTo(x - w * .022, h * .22)
        ..lineTo(x, h * .08)
        ..lineTo(x + w * .022, h * .22)
        ..close();
      c.drawPath(cap, Paint()..color = const Color(0xFF2E7D5B));
      c.drawCircle(Offset(x, h * .075), w * .008, Paint()..color = const Color(0xFFFFD66B));
    }
    // المبنى
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .26, h * .62, w * .48, h * .38), const Radius.circular(6)),
      Paint()..color = const Color(0xFFEFE4C6),
    );
    for (int i = 0; i < 5; i++) {
      final x = w * (.30 + i * .1);
      c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, h * .75, w * .045, h * .2), Radius.circular(w * .02)),
        Paint()..color = const Color(0xFFD1BF92),
      );
    }
    // القبة
    final dome = Path()
      ..moveTo(w * .34, h * .62)
      ..cubicTo(w * .30, h * .26, w * .70, h * .26, w * .66, h * .62)
      ..close();
    c.drawPath(
      dome,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF39A26F), Color(0xFF1B6B49)],
        ).createShader(Rect.fromLTWH(w * .3, h * .26, w * .4, h * .36)),
    );
    c.drawRect(Rect.fromLTWH(w * .335, h * .60, w * .33, h * .03),
        Paint()..color = const Color(0xFFC9992E));
    c.drawRect(Rect.fromLTWH(w * .496, h * .17, w * .008, h * .1),
        Paint()..color = const Color(0xFFFFD66B));
    c.drawCircle(Offset(w * .5, h * .165), w * .014, Paint()..color = const Color(0xFFFFD66B));
  }

  @override
  bool shouldRepaint(covariant DomePainter old) => old.t != t;
}

/// ساعة تشير إلى 12:00 مع نبض
class ClockPainter extends CustomPainter {
  final double t; // 0..1 دورة
  const ClockPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    final r = math.min(s.width, s.height) / 2 - 6;
    final o = Offset(s.width / 2, s.height / 2);
    final pulse = .5 + .5 * math.sin(t * math.pi * 2);
    c.drawCircle(o, r + 4 + 4 * pulse, Paint()..color = const Color(0xFFFFB84D).withOpacity(.18));
    c.drawCircle(o, r, Paint()..color = Colors.white);
    c.drawCircle(
        o,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = const Color(0xFF0E3A5C));
    for (int i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final p1 = o + Offset(math.sin(a), -math.cos(a)) * (r - 6);
      final p2 = o + Offset(math.sin(a), -math.cos(a)) * (r - (i % 3 == 0 ? 18 : 12));
      c.drawLine(
          p1,
          p2,
          Paint()
            ..strokeWidth = i % 3 == 0 ? 3 : 1.6
            ..color = const Color(0xFF0E3A5C));
    }
    // عقرب الدقائق والساعات على 12 (يهتز بلطف)
    final wob = math.sin(t * math.pi * 2) * .03;
    final hand = Paint()
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF0E3A5C);
    c.drawLine(o, o + Offset(math.sin(wob), -math.cos(wob)) * (r * .72), hand..strokeWidth = 5);
    c.drawLine(o, o + Offset(math.sin(wob), -math.cos(wob)) * (r * .5), hand..strokeWidth = 7);
    c.drawCircle(o, 6, Paint()..color = const Color(0xFFE8730C));
  }

  @override
  bool shouldRepaint(covariant ClockPainter old) => old.t != t;
}

/// نبض موقع GPS حول نقطة
class PulsePainter extends CustomPainter {
  final double t;
  final Color color;
  const PulsePainter(this.t, {this.color = const Color(0xFF2F7DC1)});

  @override
  void paint(Canvas c, Size s) {
    final o = Offset(s.width / 2, s.height / 2);
    final m = math.min(s.width, s.height) / 2;
    for (int i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1;
      c.drawCircle(o, m * p, Paint()..color = color.withOpacity((1 - p) * .35));
    }
    c.drawCircle(o, 9, Paint()..color = Colors.white);
    c.drawCircle(o, 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant PulsePainter old) => old.t != t;
}
