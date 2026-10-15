import 'dart:math' as math;
import 'package:maplibre_gl/maplibre_gl.dart';

class HmProj {
  final double dist, along;
  const HmProj(this.dist, this.along);
}

class HmGeo {
  static const _r = 6371000.0;
  static double _rad(double d) => d * math.pi / 180;
  static double _deg(double r) => r * 180 / math.pi;

  static double distance(LatLng a, LatLng b) {
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final s1 = math.sin(dLat / 2), s2 = math.sin(dLng / 2);
    final h = s1 * s1 +
        math.cos(_rad(a.latitude)) * math.cos(_rad(b.latitude)) * s2 * s2;
    return 2 * _r * math.asin(math.min(1.0, math.sqrt(h)));
  }

  /// الاتجاه من a إلى b بالدرجات (0 = شمال، 90 = شرق).
  static double bearing(LatLng a, LatLng b) {
    final p1 = _rad(a.latitude), p2 = _rad(b.latitude);
    final dl = _rad(b.longitude - a.longitude);
    final y = math.sin(dl) * math.cos(p2);
    final x = math.cos(p1) * math.sin(p2) -
        math.sin(p1) * math.cos(p2) * math.cos(dl);
    return (_deg(math.atan2(y, x)) + 360) % 360;
  }

  /// فرق الزاوية بإشارة: موجب = يمين، سالب = يسار. المدى (-180, 180].
  static double angleDiff(double from, double to) =>
      ((to - from + 540) % 360) - 180;

  static String cardinal(double b) {
    const n = [
      'شمالًا', 'شمال شرق', 'شرقًا', 'جنوب شرق',
      'جنوبًا', 'جنوب غرب', 'غربًا', 'شمال غرب'
    ];
    return n[(((b + 22.5) % 360) ~/ 45)];
  }

  static String meters(double m) =>
      m < 1000 ? '${m.round()} متر' : '${(m / 1000).toStringAsFixed(1)} كم';

  static List<double> cumulative(List<LatLng> p) {
    final c = <double>[0];
    for (var i = 1; i < p.length; i++) {
      c.add(c.last + distance(p[i - 1], p[i]));
    }
    return c;
  }

  /// أقرب نقطة على المسار: البعد عنه + المسافة المقطوعة عليه.
  static HmProj project(List<LatLng> pts, List<double> cum, LatLng p) {
    var best = double.infinity, along = 0.0;
    final kx = 111320.0 * math.cos(_rad(p.latitude)), ky = 110540.0;
    for (var i = 0; i < pts.length - 1; i++) {
      final ax = (pts[i].longitude - p.longitude) * kx;
      final ay = (pts[i].latitude - p.latitude) * ky;
      final bx = (pts[i + 1].longitude - p.longitude) * kx;
      final by = (pts[i + 1].latitude - p.latitude) * ky;
      final dx = bx - ax, dy = by - ay, l2 = dx * dx + dy * dy;
      final t = l2 == 0 ? 0.0 : ((-ax * dx - ay * dy) / l2).clamp(0.0, 1.0).toDouble();
      final px = ax + t * dx, py = ay + t * dy;
      final d = math.sqrt(px * px + py * py);
      if (d < best) {
        best = d;
        along = cum[i] + t * (cum[i + 1] - cum[i]);
      }
    }
    return HmProj(best, along);
  }
}
