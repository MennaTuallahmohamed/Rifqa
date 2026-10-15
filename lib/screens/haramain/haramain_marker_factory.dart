import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// يرسم علامات الخريطة (دبوس بإيموجي، أو لافتة باب برقمه) كصور PNG
/// لأن ستايل الأقمار الصناعية لا يحتوي على خطوط (glyphs) لعرض نص مباشرة.
class HaramainMarkers {
  static const double scale = 2.0; // دقة الرسم
  static final _cache = <String, Uint8List>{};

  static String nameFor(String emoji, Color color, String? label, bool selected) =>
      'hm_${Object.hash(emoji, color.toARGB32(), label ?? '', selected)}';

  static Future<Uint8List> badge({
    required String emoji,
    required Color color,
    String? label,
    bool selected = false,
  }) async {
    final key = nameFor(emoji, color, label, selected);
    final hit = _cache[key];
    if (hit != null) return hit;

    final hasLabel = label != null && label.isNotEmpty;
    final w = hasLabel ? 56.0 : 46.0;
    final bodyH = hasLabel ? 62.0 : 46.0;
    const tail = 9.0, pad = 6.0;
    final totalW = w + pad * 2, totalH = bodyH + tail + pad * 2;
    final ring = selected ? const Color(0xFF1677FF) : color;

    final rec = ui.PictureRecorder();
    final c = Canvas(rec)..scale(scale);
    final rect = Rect.fromLTWH(pad, pad, w, bodyH);
    final rr = RRect.fromRectAndRadius(
        rect, Radius.circular(hasLabel ? 14 : w / 2));

    // ظل ناعم
    c.drawRRect(
      rr.shift(const Offset(0, 2)),
      Paint()
        ..color = const Color(0x44000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    final cx = totalW / 2;
    // ذيل الدبوس
    c.drawPath(
      Path()
        ..moveTo(cx - 7, pad + bodyH - 2)
        ..lineTo(cx, pad + bodyH + tail)
        ..lineTo(cx + 7, pad + bodyH - 2)
        ..close(),
      Paint()..color = ring,
    );
    c.drawRRect(rr, Paint()..color = Colors.white);
    // حلقة خارجية رفيعة تعطي إحساس العلامة النشطة
    if (selected) {
      c.drawRRect(
        rr.inflate(2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFF1677FF).withValues(alpha: 0.35),
      );
    }
    c.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 5 : 3.2
        ..color = ring,
    );
    _text(c, emoji, 22, Offset(cx, pad + (hasLabel ? 21 : bodyH / 2)));
    if (hasLabel) {
      _text(c, label, 17, Offset(cx, pad + 46), bold: true, color: color);
    }

    final img = await rec
        .endRecording()
        .toImage((totalW * scale).ceil(), (totalH * scale).ceil());
    final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    return _cache[key] = bytes;
  }

  static void _text(Canvas c, String s, double size, Offset center,
      {bool bold = false, Color color = Colors.black}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.w900 : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }
}
