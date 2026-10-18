import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../state/app_state.dart';
import 'umrah_data.dart';
import 'umrah_3d_materials.dart';
import 'rifqa_narration_player.dart';
import 'umrah_premium.dart';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  Ù…Ø­Ø±Ùƒ Ø«Ù„Ø§Ø«ÙŠ Ø§Ù„Ø£Ø¨Ø¹Ø§Ø¯ Ø¨Ø³ÙŠØ· (Ø¨Ø¯ÙˆÙ† Ø£ÙŠ Ù…Ù„ÙØ§Øª Ø®Ø§Ø±Ø¬ÙŠØ©)
//  Ø§Ù„Ù…Ø­Ø§ÙˆØ±: x Ø´Ø±Ù‚ØŒ y Ø£Ø¹Ù„Ù‰ØŒ z Ø¬Ù†ÙˆØ¨
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class V3 {
  final double x, y, z;
  const V3(this.x, this.y, this.z);
}

class P3 {
  final Offset o;
  final double depth, k;
  const P3(this.o, this.depth, this.k);
}

class Cam {
  double yaw, pitch, dist;
  V3 target;
  Cam({
    this.yaw = -2.4,
    this.pitch = .6,
    this.dist = 42,
    this.target = const V3(0, 3, 0),
  });

  V3 get pos {
    final z1 = -dist * math.cos(pitch);
    return V3(
      target.x + z1 * math.sin(yaw),
      target.y + dist * math.sin(pitch),
      target.z + z1 * math.cos(yaw),
    );
  }

  P3 project(V3 p, Size s) {
    final vx = p.x - target.x, vy = p.y - target.y, vz = p.z - target.z;
    final cy = math.cos(yaw), sy = math.sin(yaw);
    final x1 = vx * cy - vz * sy;
    final z1 = vx * sy + vz * cy;
    final cp = math.cos(pitch), sp = math.sin(pitch);
    final y2 = vy * cp + z1 * sp;
    final z2 = -vy * sp + z1 * cp;
    final depth = math.max(.5, z2 + dist);
    final k = s.width * 1.05 / depth;
    return P3(Offset(s.width / 2 - x1 * k, s.height * .375 - y2 * k), depth, k);
  }
}

const _L = V3(-.3, .8, .5);
double _dot(V3 a, V3 b) => a.x * b.x + a.y * b.y + a.z * b.z;

Color _shade(Color c, double f) => Color.fromARGB(
      255,
      (c.red * f).clamp(0, 255).round(),
      (c.green * f).clamp(0, 255).round(),
      (c.blue * f).clamp(0, 255).round(),
    );

Path _path(Cam cam, Size s, List<V3> pts) {
  final p = Path();
  for (int i = 0; i < pts.length; i++) {
    final o = cam.project(pts[i], s).o;
    i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
  }
  p.close();
  return p;
}

class _Item {
  final double depth;
  final VoidCallback draw;
  _Item(this.depth, this.draw);
}

class _F {
  final List<V3> pts;
  final V3 n;
  _F(this.pts, this.n);
}

/// Ù…Ø¬Ø³Ù… Ù…Ø³ØªØ·ÙŠÙ„ Ø¨ÙˆØ¬ÙˆÙ‡ Ù…Ø¸Ù„Ù„Ø© (ÙŠØ®ÙÙŠ Ø§Ù„ÙˆØ¬ÙˆÙ‡ Ø§Ù„Ø®Ù„ÙÙŠØ©)
void _drawBox(Canvas c, Cam cam, Size s, V3 a, V3 b, Color base) {
  final cp = cam.pos;
  final faces = <_F>[
    _F([
      V3(b.x, a.y, b.z),
      V3(b.x, a.y, a.z),
      V3(b.x, b.y, a.z),
      V3(b.x, b.y, b.z)
    ], const V3(1, 0, 0)),
    _F([
      V3(a.x, a.y, a.z),
      V3(a.x, a.y, b.z),
      V3(a.x, b.y, b.z),
      V3(a.x, b.y, a.z)
    ], const V3(-1, 0, 0)),
    _F([
      V3(a.x, a.y, b.z),
      V3(b.x, a.y, b.z),
      V3(b.x, b.y, b.z),
      V3(a.x, b.y, b.z)
    ], const V3(0, 0, 1)),
    _F([
      V3(b.x, a.y, a.z),
      V3(a.x, a.y, a.z),
      V3(a.x, b.y, a.z),
      V3(b.x, b.y, a.z)
    ], const V3(0, 0, -1)),
    _F([
      V3(a.x, b.y, a.z),
      V3(b.x, b.y, a.z),
      V3(b.x, b.y, b.z),
      V3(a.x, b.y, b.z)
    ], const V3(0, 1, 0)),
  ];
  for (final f in faces) {
    double cx = 0, cy = 0, cz = 0;
    for (final p in f.pts) {
      cx += p.x;
      cy += p.y;
      cz += p.z;
    }
    final n = f.pts.length;
    final ctr = V3(cx / n, cy / n, cz / n);
    if (_dot(f.n, V3(cp.x - ctr.x, cp.y - ctr.y, cp.z - ctr.z)) <= 0) continue;
    final lam = math.max(0.0, _dot(f.n, _L));
    final path = _path(cam, s, f.pts);
    c.drawPath(path, Paint()..color = _shade(base, .55 + .65 * lam));
    c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.black26);
  }
}

/// Ø´Ø±ÙŠØ· Ù…Ù„ÙˆÙ† Ø¹Ù„Ù‰ Ø¬Ø¯Ø§Ø± Ø±Ø£Ø³ÙŠ (Ù„Ù„Ø­Ø²Ø§Ù… Ø§Ù„Ø°Ù‡Ø¨ÙŠ ÙˆØ§Ù„Ø¨Ø§Ø¨)
void _wallQuad(Canvas c, Cam cam, Size s, V3 p0, V3 p1, double y0, double y1,
    V3 n, Color col) {
  final cp = cam.pos;
  final ctr = V3((p0.x + p1.x) / 2, (y0 + y1) / 2, (p0.z + p1.z) / 2);
  if (_dot(n, V3(cp.x - ctr.x, cp.y - ctr.y, cp.z - ctr.z)) <= 0) return;
  final pts = [
    V3(p0.x, y0, p0.z),
    V3(p1.x, y0, p1.z),
    V3(p1.x, y1, p1.z),
    V3(p0.x, y1, p0.z),
  ];
  final lam = math.max(0.0, _dot(n, _L));
  c.drawPath(_path(cam, s, pts), Paint()..color = _shade(col, .55 + .65 * lam));
}

void _tag(Canvas c, String t, Offset at,
    {Color bg = const Color(0xCC0F5E45),
    Color fg = Colors.white,
    double size = 11}) {
  final tp = TextPainter(
    text: TextSpan(
        text: t,
        style:
            TextStyle(color: fg, fontSize: size, fontWeight: FontWeight.w700)),
    textDirection: TextDirection.rtl,
  )..layout();
  c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: at, width: tp.width + 14, height: tp.height + 8),
          const Radius.circular(10)),
      Paint()..color = bg);
  tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
}

/// kind: 0 Ø±Ø¬Ù„ Ø¨Ø§Ù„Ø¥Ø­Ø±Ø§Ù…ØŒ 1 Ø§Ù…Ø±Ø£Ø©ØŒ 2 Ù…Ù„Ø§Ø¨Ø³ Ù…Ù„ÙˆÙ†Ø©
void _drawPilgrim(Canvas c, Cam cam, Size s, double x, double z, int kind,
    {bool me = false, double lift = 0, Color? tint}) {
  final foot = cam.project(V3(x, lift, z), s);
  final top = cam.project(V3(x, 1.45 + lift, z), s);
  final head = cam.project(V3(x, 1.68 + lift, z), s);
  final g = cam.project(V3(x, 0, z), s);
  final k = foot.k;

  c.drawOval(
      Rect.fromCenter(
          center: g.o,
          width: .95 * k,
          height: .95 * k * math.max(.22, math.sin(cam.pitch))),
      Paint()..color = Colors.black.withOpacity(.22));

  if (me) {
    final r = Rect.fromCenter(
        center: g.o,
        width: 2.1 * k,
        height: 2.1 * k * math.max(.22, math.sin(cam.pitch)));
    c.drawOval(r, Paint()..color = AppColors.gold.withOpacity(.25));
    c.drawOval(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = AppColors.gold);
  }

  final Color body = kind == 0
      ? Colors.white
      : (kind == 1
          ? const Color(0xFF23262C)
          : (tint ?? const Color(0xFF3B8FC4)));
  final w = math.max(2.5, .62 * k);
  if (kind == 0) {
    c.drawLine(
        foot.o,
        top.o,
        Paint()
          ..color = Colors.black26
          ..strokeWidth = w + 1.5
          ..strokeCap = StrokeCap.round);
  }
  c.drawLine(
      foot.o,
      top.o,
      Paint()
        ..color = body
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round);
  final hr = math.max(2.2, .2 * k);
  if (kind == 1) {
    c.drawCircle(head.o, hr, Paint()..color = body);
    c.drawCircle(head.o.translate(0, hr * .1), hr * .55,
        Paint()..color = const Color(0xFFD9A77A));
  } else {
    c.drawCircle(head.o, hr, Paint()..color = const Color(0xFFD9A77A));
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  Ø¹Ù†Ø§ØµØ± ÙˆØ§Ø¬Ù‡Ø© Ù…Ø´ØªØ±ÙƒØ© (Ø¯Ø§ÙƒÙ†Ø©)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

Widget _pill(String t, bool sel, VoidCallback on) => GestureDetector(
      onTap: on,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? AppColors.gold : Colors.white12,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(t,
            style: TextStyle(
                color: sel ? const Color(0xFF3B2A00) : Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700)),
      ),
    );

Widget _finishCard(
        String title, String msg, VoidCallback onClose, VoidCallback onAgain) =>
    Center(
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xF2081C17),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.gold, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ðŸ¤²', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.6)),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _pill('Ø¥Ø¹Ø§Ø¯Ø©', false, onAgain),
                const SizedBox(width: 10),
                _pill('Ø¥ØªÙ…Ø§Ù…', true, onClose),
              ],
            ),
          ],
        ),
      ),
    );

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  Ø§Ù„Ø·ÙˆØ§Ù Ø«Ù„Ø§Ø«ÙŠ Ø§Ù„Ø£Ø¨Ø¹Ø§Ø¯
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

const double kHw = 6.4, kHd = 5.5, kHijr = 4.5, kH = 13.0;

class _Seg {
  final double len;
  final Offset Function(double) at;
  _Seg(this.len, this.at);
}

/// Ù…Ø³Ø§Ø± Ø§Ù„Ø·ÙˆØ§Ù: Ù…Ø³ØªØ·ÙŠÙ„ Ø¨Ø²ÙˆØ§ÙŠØ§ Ù…Ø¯ÙˆÙ‘Ø±Ø© Ø­ÙˆÙ„ Ø§Ù„ÙƒØ¹Ø¨Ø© ÙˆØ§Ù„Ø­ÙØ¬Ø±ØŒ Ø¹ÙƒØ³ Ø¹Ù‚Ø§Ø±Ø¨ Ø§Ù„Ø³Ø§Ø¹Ø©
class Track {
  final List<_Seg> segs = [];
  final List<double> starts = [];
  double length = 0;

  Track(double m,
      {required double hw, required double hd, required double hijr}) {
    final a = hw + m, bt = hd + hijr + m, bb = hd + m;
    final rc = math.min(3.0, m);
    final q = rc * math.pi / 2;
    final c2 = Offset(a - rc, -bt + rc);
    final c4 = Offset(-a + rc, -bt + rc);
    final c6 = Offset(-a + rc, bb - rc);
    final c8 = Offset(a - rc, bb - rc);
    Offset arc(Offset c, double phi) =>
        c + Offset(rc * math.cos(phi), rc * math.sin(phi));
    void add(double len, Offset Function(double) f) {
      if (len < .001) return;
      starts.add(length);
      segs.add(_Seg(len, f));
      length += len;
    }

    add(hd + bt - rc, (u) => Offset(a, hd - u)); // Ø§Ù„Ø¬Ø¯Ø§Ø± Ø§Ù„Ø´Ø±Ù‚ÙŠ (Ø§Ù„Ø¨Ø§Ø¨)
    add(q, (u) => arc(c2, -u / rc)); // Ø§Ù„Ø±ÙƒÙ† Ø§Ù„Ø¹Ø±Ø§Ù‚ÙŠ
    add(2 * a - 2 * rc, (u) => Offset(a - rc - u, -bt)); // Ø¬Ù‡Ø© Ø§Ù„Ø­ÙØ¬Ø±
    add(q, (u) => arc(c4, -math.pi / 2 - u / rc)); // Ø§Ù„Ø±ÙƒÙ† Ø§Ù„Ø´Ø§Ù…ÙŠ
    add(bt + bb - 2 * rc, (u) => Offset(-a, -bt + rc + u)); // Ø§Ù„Ø¬Ø¯Ø§Ø± Ø§Ù„ØºØ±Ø¨ÙŠ
    add(q, (u) => arc(c6, -math.pi - u / rc)); // Ø§Ù„Ø±ÙƒÙ† Ø§Ù„ÙŠÙ…Ø§Ù†ÙŠ
    add(2 * a - 2 * rc, (u) => Offset(-a + rc + u, bb)); // Ø¨ÙŠÙ† Ø§Ù„ÙŠÙ…Ø§Ù†ÙŠ ÙˆØ§Ù„Ø­Ø¬Ø±
    add(q, (u) => arc(c8, -1.5 * math.pi - u / rc));
    add(bb - rc - hd, (u) => Offset(a, bb - rc - u));
  }

  Offset at(double s) {
    var d = s % length;
    if (d < 0) d += length;
    for (int i = 0; i < segs.length; i++) {
      if (d <= starts[i] + segs[i].len || i == segs.length - 1) {
        final u = math.max(0.0, math.min(segs[i].len, d - starts[i]));
        return segs[i].at(u);
      }
    }
    return Offset.zero;
  }

  double mid(int i, [double f = .5]) => starts[i] + segs[i].len * f;
  List<Offset> sample(int n) =>
      [for (int i = 0; i < n; i++) at(length * i / n)];
}

class _Mile {
  final double s;
  final String cap, say;
  final bool always;
  _Mile(this.s, this.cap, this.say, {this.always = false});
}

class _Npc {
  double s;
  final double v;
  final int lane, kind;
  final Color tint;
  _Npc(this.s, this.v, this.lane, this.kind, this.tint);
}

const _ordM = [
  'Ø§Ù„Ø£ÙˆÙ„',
  'Ø§Ù„Ø«Ø§Ù†ÙŠ',
  'Ø§Ù„Ø«Ø§Ù„Ø«',
  'Ø§Ù„Ø±Ø§Ø¨Ø¹',
  'Ø§Ù„Ø®Ø§Ù…Ø³',
  'Ø§Ù„Ø³Ø§Ø¯Ø³',
  'Ø§Ù„Ø³Ø§Ø¨Ø¹'
];

class Tawaf3DPage extends StatefulWidget {
  const Tawaf3DPage({super.key});
  @override
  State<Tawaf3DPage> createState() => _Tawaf3DPageState();
}

class _Tawaf3DPageState extends State<Tawaf3DPage>
    with SingleTickerProviderStateMixin {
  static const crowdCounts = [14, 46, 110];

  final cam = Cam();
  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  late final Track me;
  late final List<Track> lanes;
  late final List<Track> guides;
  late final List<_Mile> miles;
  final List<_Npc> npcs = [];

  double dist = 0, _prevLap = 0;
  bool started = false, playing = false, finished = false;
  bool male = true, labels = true;
  bool _controlsExpanded = false;
  Umrah3DMaterials? _materials;

  Future<void> _loadMaterials() async {
    try {
      final images = await Umrah3DMaterials.load();
      if (mounted) setState(() => _materials = images);
    } catch (_) {
      // Preserve procedural geometry when an asset is missing.
    }
  }

  double speed = 1.0;
  int crowd = 1;
  int camMode = 1; // cinematic orbit; 0 follow, 1 free, 2 overhead
  String caption = '';
  double _baseDist = 42;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
    me = Track(3.2, hw: kHw, hd: kHd, hijr: kHijr);
    lanes = [
      for (final m in [2.6, 3.8, 5.0, 6.2, 7.4, 8.6])
        Track(m, hw: kHw, hd: kHd, hijr: kHijr)
    ];
    guides = [
      for (final m in [3.2, 5.6, 8.0]) Track(m, hw: kHw, hd: kHd, hijr: kHijr)
    ];
    miles = [
      _Mile(me.mid(0, .55), 'Ø¨Ù…Ø­Ø§Ø°Ø§Ø© Ø¨Ø§Ø¨ Ø§Ù„ÙƒØ¹Ø¨Ø©. Ø§Ù„ÙƒØ¹Ø¨Ø© Ø¹Ù† ÙŠØ³Ø§Ø±Ùƒ Ø¯Ø§Ø¦Ù…Ù‹Ø§.',
          'Ø£Ù†Øª Ø§Ù„Ø¢Ù† Ø¨Ù…Ø­Ø§Ø°Ø§Ø© Ø¨Ø§Ø¨ Ø§Ù„ÙƒØ¹Ø¨Ø©. Ø§Ù„ÙƒØ¹Ø¨Ø© Ø¹Ù† ÙŠØ³Ø§Ø±Ùƒ.'),
      _Mile(me.mid(1), 'Ø§Ù„Ø±ÙƒÙ† Ø§Ù„Ø¹Ø±Ø§Ù‚ÙŠ. ÙˆØ§ØµÙ„ Ø§Ù„Ù…Ø´ÙŠ Ø¨Ù‡Ø¯ÙˆØ¡ ÙˆØ§Ø¯Ø¹Ù Ø¨Ù…Ø§ ØªØ­Ø¨.',
          'Ø§Ù„Ø±ÙƒÙ† Ø§Ù„Ø¹Ø±Ø§Ù‚ÙŠ. ÙˆØ§ØµÙ„ Ø§Ù„Ù…Ø´ÙŠ ÙˆØ§Ø¯Ø¹Ù Ø¨Ù…Ø§ ØªØ­Ø¨.'),
      _Mile(
          me.mid(2),
          'Ø¨Ø¬Ø§Ù†Ø¨ Ø§Ù„Ø­ÙØ¬Ø± (Ø­ÙØ¬Ø± Ø¥Ø³Ù…Ø§Ø¹ÙŠÙ„): Ø§Ø¨Ù‚ÙŽ Ø®Ø§Ø±Ø¬Ù‡ØŒ ÙÙ‡Ùˆ Ù…Ù† Ø§Ù„ÙƒØ¹Ø¨Ø©.',
          'Ø£Ù†Øª Ø¨Ø¬Ø§Ù†Ø¨ Ø§Ù„Ø­ÙØ¬Ø±. Ø§Ø¨Ù‚ Ø®Ø§Ø±Ø¬Ù‡ ÙˆÙ„Ø§ ØªØ¯Ø®Ù„ ÙÙŠÙ‡ØŒ ÙÙ‡Ùˆ Ù…Ù† Ø§Ù„ÙƒØ¹Ø¨Ø©.'),
      _Mile(me.mid(3), 'Ø§Ù„Ø±ÙƒÙ† Ø§Ù„Ø´Ø§Ù…ÙŠ.', 'Ø§Ù„Ø±ÙƒÙ† Ø§Ù„Ø´Ø§Ù…ÙŠ.'),
      _Mile(me.mid(4), 'Ø§Ù„Ø¬Ø¯Ø§Ø± Ø§Ù„ØºØ±Ø¨ÙŠ. Ø£ÙƒØ«Ø± Ù…Ù† Ø§Ù„Ø°ÙƒØ± ÙˆØ§Ù„Ø¯Ø¹Ø§Ø¡.',
          'Ø§Ù„Ø¬Ø¯Ø§Ø± Ø§Ù„ØºØ±Ø¨ÙŠ. Ø£ÙƒØ«Ø± Ù…Ù† Ø§Ù„Ø°ÙƒØ± ÙˆØ§Ù„Ø¯Ø¹Ø§Ø¡.'),
      _Mile(
          me.mid(5),
          'Ø§Ù„Ø±ÙƒÙ† Ø§Ù„ÙŠÙ…Ø§Ù†ÙŠ: Ø§Ù„Ù…Ø³Ù‡ Ø¨ÙŠØ¯Ùƒ Ø¥Ù† ØªÙŠØ³Ø± Ø¨Ù„Ø§ ØªÙ‚Ø¨ÙŠÙ„ØŒ ÙˆØ¥Ù„Ø§ ÙØ§Ù…Ø¶Ù.',
          'Ø§Ù„Ø±ÙƒÙ† Ø§Ù„ÙŠÙ…Ø§Ù†ÙŠ. Ø§Ù„Ù…Ø³Ù‡ Ø¨ÙŠØ¯Ùƒ Ø¥Ù† ØªÙŠØ³Ø± Ø¨Ù„Ø§ ØªÙ‚Ø¨ÙŠÙ„ØŒ ÙˆØ¥Ù† Ø¹Ø³Ø± ÙØ§Ù…Ø¶Ù Ø¯ÙˆÙ† Ø¥Ø´Ø§Ø±Ø©.'),
      _Mile(
          me.mid(6),
          'Ø¨ÙŠÙ† Ø§Ù„ÙŠÙ…Ø§Ù†ÙŠ ÙˆØ§Ù„Ø­Ø¬Ø± Ø§Ù„Ø£Ø³ÙˆØ¯: Ø±Ø¨Ù†Ø§ Ø¢ØªÙ†Ø§ ÙÙŠ Ø§Ù„Ø¯Ù†ÙŠØ§ Ø­Ø³Ù†Ø© ÙˆÙÙŠ Ø§Ù„Ø¢Ø®Ø±Ø© Ø­Ø³Ù†Ø© ÙˆÙ‚Ù†Ø§ Ø¹Ø°Ø§Ø¨ Ø§Ù„Ù†Ø§Ø±',
          'Ø±ÙŽØ¨ÙŽÙ‘Ù†ÙŽØ§ Ø¢ØªÙÙ†ÙŽØ§ ÙÙÙŠ Ø§Ù„Ø¯ÙÙ‘Ù†Ù’ÙŠÙŽØ§ Ø­ÙŽØ³ÙŽÙ†ÙŽØ©Ù‹ ÙˆÙŽÙÙÙŠ Ø§Ù„Ù’Ø¢Ø®ÙØ±ÙŽØ©Ù Ø­ÙŽØ³ÙŽÙ†ÙŽØ©Ù‹ ÙˆÙŽÙ‚ÙÙ†ÙŽØ§ Ø¹ÙŽØ°ÙŽØ§Ø¨ÙŽ Ø§Ù„Ù†ÙŽÙ‘Ø§Ø±Ù',
          always: true),
    ];
    final rnd = math.Random(7);
    const tints = [
      Color(0xFF3B8FC4),
      Color(0xFFD9675B),
      Color(0xFF8A5FB0),
      Color(0xFF2BA6A0)
    ];
    for (int i = 0; i < 110; i++) {
      final lane = rnd.nextInt(lanes.length);
      final r = rnd.nextDouble();
      npcs.add(_Npc(
        rnd.nextDouble() * lanes[lane].length,
        3.6 + rnd.nextDouble() * 1.6 - lane * .12,
        lane,
        r < .55 ? 0 : (r < .85 ? 1 : 2),
        tints[rnd.nextInt(4)],
      ));
    }
    caption = 'Ù‚Ù Ø¹Ù†Ø¯ Ø®Ø· Ø§Ù„Ø­Ø¬Ø± Ø§Ù„Ø£Ø³ÙˆØ¯ Ø§Ù„Ø£Ø®Ø¶Ø±ØŒ Ø«Ù… Ø§Ø¶ØºØ· â–¶ Ù„Ø¨Ø¯Ø¡ Ø§Ù„Ø·ÙˆØ§Ù.';
    _applyMode();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();

    super.dispose();
  }

  void _applyMode() {
    if (camMode == 0) {
      cam.pitch = .70;
      cam.dist = 34;
    } else if (camMode == 1) {
      cam
        ..pitch = .67
        ..dist = 54
        ..yaw = -2.25
        ..target = const V3(0, 3, 0);
    } else {
      cam
        ..pitch = 1.03
        ..yaw = -2.4
        ..dist = 57
        ..target = const V3(0, 3, 0);
    }
  }

  void _say(String t, {double rate = .42}) {
    /* No synthesized voice in 3D. Guidance remains visible as captions. */
  }

  void _tick(Duration t) {
    final dt = _last == Duration.zero ? 0.0 : (t - _last).inMicroseconds / 1e6;
    _last = t;
    final d = math.min(dt, .05);
    final len = me.length;
    for (final n in npcs) {
      n.s = (n.s + n.v * d) % lanes[n.lane].length;
    }
    if (playing && !finished) {
      final lap = (dist / len).floor();
      final raml = male && lap < 3;
      dist += 5.0 * speed * (raml ? 1.3 : 1.0) * d;
      if (dist >= 7 * len) {
        dist = 7 * len;
        _finish();
      } else {
        final cur = dist % len;
        final wrapped = cur < _prevLap;
        if (wrapped) _onLap((dist / len).floor());
        for (final m in miles) {
          final crossed = wrapped
              ? (m.s > _prevLap || m.s <= cur)
              : (m.s > _prevLap && m.s <= cur);
          if (crossed) _fire(m, (dist / len).floor());
        }
        _prevLap = cur;
      }
    }
    _updateCamera(d);
    _frame.value++;
  }

  void _updateCamera(double d) {
    if (camMode != 0) return;
    final p = me.at(dist);
    final h = me.at(dist + .9) - p;
    final ty = math.atan2(h.dx, h.dy);
    var diff = ty - cam.yaw;
    while (diff > math.pi) {
      diff -= 2 * math.pi;
    }
    while (diff < -math.pi) {
      diff += 2 * math.pi;
    }
    final a = 1 - math.exp(-d * 3.5);
    cam.yaw += diff * a;
    cam.target = V3(cam.target.x + (p.dx - cam.target.x) * a, 1.3,
        cam.target.z + (p.dy - cam.target.z) * a);
  }

  void _fire(_Mile m, int lap) {
    caption = m.cap;
    if (lap == 0 || m.always) _say(m.say);
    setState(() {});
  }

  void _onLap(int n) {
    final st = AppScope.of(context);
    st.change(() => st.tawaf = n);
    HapticFeedback.mediumImpact();
    caption =
        'ØªÙ…Ù‘ Ø§Ù„Ø´ÙˆØ· $n âœ“  Ø§Ù„Ø¢Ù† Ø§Ù„Ø´ÙˆØ· ${n + 1}: Ø£Ø´Ø± Ø¥Ù„Ù‰ Ø§Ù„Ø­Ø¬Ø± Ø§Ù„Ø£Ø³ÙˆØ¯ ÙˆÙƒØ¨Ù‘Ø±${male && n < 3 ? ' (Ø±Ù…Ù„ ÙˆØ§Ø¶Ø·Ø¨Ø§Ø¹)' : ''}';
    _say(
        'ØªÙ…Ù‘ Ø§Ù„Ø´ÙˆØ· ${_ordM[n - 1]}. Ø§Ù„Ø´ÙˆØ· ${_ordM[n]}: Ø£Ø´Ø± Ø¥Ù„Ù‰ Ø§Ù„Ø­Ø¬Ø± Ø§Ù„Ø£Ø³ÙˆØ¯ ÙˆÙƒØ¨Ù‘Ø±');
    setState(() {});
  }

  void _finish() {
    finished = true;
    playing = false;
    final st = AppScope.of(context);
    st.change(() => st.tawaf = 7);
    HapticFeedback.heavyImpact();
    caption = 'Ø£ØªÙ…Ù…Øª 7 Ø£Ø´ÙˆØ§Ø· ðŸŽ‰ Ø§Ù„Ø¢Ù† ØµÙ„ÙÙ‘ Ø±ÙƒØ¹ØªÙŠÙ† Ø®Ù„Ù Ø§Ù„Ù…Ù‚Ø§Ù….';
    _say(
        'ØªÙ‚Ø¨Ù‘Ù„ Ø§Ù„Ù„Ù‡ Ø·ÙˆØ§ÙÙƒ. Ø£ØªÙ…Ù…Øª Ø³Ø¨Ø¹Ø© Ø£Ø´ÙˆØ§Ø·. Ø§Ù„Ø¢Ù† ØµÙ„ÙÙ‘ Ø±ÙƒØ¹ØªÙŠÙ† Ø®Ù„Ù Ù…Ù‚Ø§Ù… Ø¥Ø¨Ø±Ø§Ù‡ÙŠÙ… Ø¥Ù† ØªÙŠØ³Ø±');
    setState(() {});
  }

  void _toggle() {
    if (finished) return;
    if (!started) {
      started = true;
      playing = true;
      caption =
          'Ø§Ù„Ø´ÙˆØ· Ø§Ù„Ø£ÙˆÙ„: Ø£Ø´Ø± Ø¥Ù„Ù‰ Ø§Ù„Ø­Ø¬Ø± Ø§Ù„Ø£Ø³ÙˆØ¯ ÙˆÙ‚Ù„: Ø¨Ø³Ù… Ø§Ù„Ù„Ù‡ØŒ Ø§Ù„Ù„Ù‡ Ø£ÙƒØ¨Ø±.${male ? ' (Ø±Ù…Ù„ ÙˆØ§Ø¶Ø·Ø¨Ø§Ø¹)' : ''}';
      _say(
          'Ø§Ø¨Ø¯Ø£ Ø§Ù„Ø·ÙˆØ§Ù Ù…Ù† Ø§Ù„Ø­Ø¬Ø± Ø§Ù„Ø£Ø³ÙˆØ¯ØŒ ÙˆØ§Ø¬Ø¹Ù„ Ø§Ù„ÙƒØ¹Ø¨Ø© Ø¹Ù† ÙŠØ³Ø§Ø±Ùƒ. Ø§Ù„Ø´ÙˆØ· Ø§Ù„Ø£ÙˆÙ„. Ø£Ø´Ø± Ø¥Ù„Ù‰ Ø§Ù„Ø­Ø¬Ø± Ø§Ù„Ø£Ø³ÙˆØ¯ ÙˆÙ‚Ù„: Ø¨Ø³Ù… Ø§Ù„Ù„Ù‡ØŒ Ø§Ù„Ù„Ù‡ Ø£ÙƒØ¨Ø±');
    } else {
      playing = !playing;
    }
    setState(() {});
  }

  void _restart() {
    final st = AppScope.of(context);
    st.change(() => st.tawaf = 0);
    dist = 0;
    _prevLap = 0;
    started = false;
    playing = false;
    finished = false;
    caption = 'Ù‚Ù Ø¹Ù†Ø¯ Ø®Ø· Ø§Ù„Ø­Ø¬Ø± Ø§Ù„Ø£Ø³ÙˆØ¯ Ø§Ù„Ø£Ø®Ø¶Ø±ØŒ Ø«Ù… Ø§Ø¶ØºØ· â–¶ Ù„Ø¨Ø¯Ø¡ Ø§Ù„Ø·ÙˆØ§Ù.';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lap = math.min((dist / me.length).floor(), 7);
    final shown = finished ? 7 : lap + 1;
    return _Rifqa3DStage(
      title: 'Ø§Ù„Ø·ÙˆØ§Ù Ø«Ù„Ø§Ø«ÙŠ Ø§Ù„Ø£Ø¨Ø¹Ø§Ø¯',
      subtitle: 'Ø¬ÙˆÙ„Ø© ØªÙØ§Ø¹Ù„ÙŠØ© Ø­ÙˆÙ„ Ø§Ù„ÙƒØ¹Ø¨Ø©',
      backgroundAsset: 'assets/umrah/tawaf_3d_atmosphere.jpg',
      step: shown,
      done: finished ? 7 : lap,
      caption: caption,
      isPlaying: playing,
      finished: finished,
      onStart: _toggle,
      onReset: _restart,
      onNarration: () => _showRecordedGuide(context, 3),
      onOverview: () => setState(() {
        camMode = 2;
        _applyMode();
      }),
      optionsExpanded: _controlsExpanded,
      onOptions: () => setState(() => _controlsExpanded = !_controlsExpanded),
      options: _sceneOptions(),
      completion: _finishCard(
        'ØªÙ‚Ø¨Ù‘Ù„ Ø§Ù„Ù„Ù‡ Ø·ÙˆØ§ÙÙƒ',
        'Ø£ØªÙ…Ù…Øª 7 Ø£Ø´ÙˆØ§Ø·. Ø§Ù„Ø®Ø·ÙˆØ© Ø§Ù„ØªØ§Ù„ÙŠØ©: Ø±ÙƒØ¹ØªØ§ Ø§Ù„Ø·ÙˆØ§Ù ÙˆØ´Ø±Ø¨ Ø²Ù…Ø²Ù….',
        () => Navigator.pop(context),
        _restart,
      ),
      scene: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (_) => _baseDist = cam.dist,
        onScaleUpdate: (d) {
          if (camMode != 0) {
            cam.yaw += d.focalPointDelta.dx * .008;
            cam.pitch = (cam.pitch + d.focalPointDelta.dy * .006)
                .clamp(.22, 1.3)
                .toDouble();
          }
          if (d.scale != 1) {
            cam.dist = (_baseDist / d.scale).clamp(23.0, 88.0).toDouble();
          }
        },
        child: CustomPaint(painter: _TawafPainter(this)),
      ),
    );
  }

  Widget _sceneOptions() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _sceneOption('0.6Ã—', speed == .6, () => setState(() => speed = .6)),
          _sceneOption('1Ã—', speed == 1, () => setState(() => speed = 1)),
          _sceneOption('1.8Ã—', speed == 1.8, () => setState(() => speed = 1.8)),
          _sceneOption(
              'Ø§ØªØ¨Ø¹Ù†ÙŠ',
              camMode == 0,
              () => setState(() {
                    camMode = 0;
                    _applyMode();
                  })),
          _sceneOption(
              'Ù…Ù†Ø¸ÙˆØ± Ø­Ø±',
              camMode == 1,
              () => setState(() {
                    camMode = 1;
                    _applyMode();
                  })),
          _sceneOption(
              'Ù…Ù† Ø£Ø¹Ù„Ù‰',
              camMode == 2,
              () => setState(() {
                    camMode = 2;
                    _applyMode();
                  })),
          _sceneOption('Ù‡Ø§Ø¯Ø¦', crowd == 0, () => setState(() => crowd = 0)),
          _sceneOption('Ù…ØªÙˆØ³Ø·', crowd == 1, () => setState(() => crowd = 1)),
          _sceneOption('Ù…Ø²Ø¯Ø­Ù…', crowd == 2, () => setState(() => crowd = 2)),
          _sceneOption('Ø±Ø¬Ù„', male, () => setState(() => male = true)),
          _sceneOption('Ø§Ù…Ø±Ø£Ø©', !male, () => setState(() => male = false)),
          _sceneOption(
              'Ø£Ø³Ù…Ø§Ø¡ Ø§Ù„Ù…ÙˆØ§Ù‚Ø¹', labels, () => setState(() => labels = !labels)),
        ],
      );
}

class _TawafPainter extends CustomPainter {
  final _Tawaf3DPageState s;
  _TawafPainter(this.s) : super(repaint: s._frame);

  @override
  void paint(Canvas c, Size size) {
    final cam = s.cam;
    final rect = Offset.zero & size;
    // Photographic arcades/sky are in the underlying layered background.

    // Ø£Ø±Ø¶ÙŠØ© Ø§Ù„Ù…Ø·Ø§Ù
    c.drawPath(
        _path(cam, size, [
          for (int i = 0; i < 72; i++)
            V3(34 * math.cos(i * math.pi / 36), 0,
                34 * math.sin(i * math.pi / 36))
        ]),
        Paint()..color = const Color(0xFFEADFC9));

    if (this.s._materials != null) {
      final mat = this.s._materials!;
      final tileArea = _path(cam, size, [
        for (int i = 0; i < 72; i++)
          V3(34 * math.cos(i * math.pi / 36), .01,
              34 * math.sin(i * math.pi / 36))
      ]);
      c.save();
      c.clipPath(tileArea);
      Umrah3DMaterials.quad(
          c,
          [
            cam.project(const V3(-34, .01, -34), size).o,
            cam.project(const V3(34, .01, -34), size).o,
            cam.project(const V3(34, .01, 34), size).o,
            cam.project(const V3(-34, .01, 34), size).o,
          ],
          mat.marble,
          repeatX: 7,
          repeatY: 7,
          subdivisions: 12);
      c.restore();
    }

    // Ø®Ø·ÙˆØ· Ø§Ù„Ù…Ø³Ø§Ø±Ø§Øª
    final gp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0x44B8935A);
    for (final g in s.guides) {
      final pts = g.sample(120);
      final path = Path();
      for (int i = 0; i < pts.length; i++) {
        final o = cam.project(V3(pts[i].dx, .02, pts[i].dy), size).o;
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      path.close();
      c.drawPath(path, gp);
    }

    // Ø£Ø±Ø¶ÙŠØ© Ø§Ù„Ø­ÙØ¬Ø±
    c.drawPath(
        _path(cam, size, [
          for (int i = 0; i <= 24; i++)
            V3(kHijr * math.cos(i * math.pi / 24), .03,
                -kHd - kHijr * math.sin(i * math.pi / 24))
        ]),
        Paint()..color = const Color(0xFFD7C8A4));

    // Ø®Ø· Ø§Ù„Ø­Ø¬Ø± Ø§Ù„Ø£Ø³ÙˆØ¯ (Ø§Ù„Ø¶ÙˆØ¡ Ø§Ù„Ø£Ø®Ø¶Ø±)
    final a = cam.project(V3(kHw + .3, .05, kHd), size).o;
    final b = cam.project(V3(kHw + 12, .05, kHd), size).o;
    c.drawLine(
        a,
        b,
        Paint()
          ..color = const Color(0x552EE59D)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round);
    c.drawLine(
        a,
        b,
        Paint()
          ..color = const Color(0xFF2EE59D)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);

    final items = <_Item>[];

    // Ø§Ù„ÙƒØ¹Ø¨Ø© ÙˆØ§Ù„Ø­ÙØ¬Ø±
    items.add(_Item(cam.project(const V3(0, 6, 0), size).depth,
        () => _kaaba(c, cam, size)));

    // Ø£Ø¹Ù…Ø¯Ø© Ø§Ù„Ø­Ø±Ù…
    for (int i = 0; i < 28; i++) {
      final ang = i * 2 * math.pi / 28;
      final x = 37 * math.cos(ang), z = 37 * math.sin(ang);
      final pb = cam.project(V3(x, 0, z), size);
      items.add(_Item(pb.depth, () {
        final pt = cam.project(V3(x, 11, z), size);
        c.drawLine(
            pb.o,
            pt.o,
            Paint()
              ..color = const Color(0xFFD8CBB0)
              ..strokeWidth = math.max(2.0, 1.2 * pb.k)
              ..strokeCap = StrokeCap.round);
      }));
    }

    // Ù…Ù‚Ø§Ù… Ø¥Ø¨Ø±Ø§Ù‡ÙŠÙ…
    const mx = kHw + 10.5, mz = .5;
    items.add(_Item(cam.project(const V3(mx, 1, mz), size).depth, () {
      final base = cam.project(const V3(mx, 0, mz), size);
      final top = cam.project(const V3(mx, 2.4, mz), size);
      c.drawLine(
          base.o,
          top.o,
          Paint()
            ..color = const Color(0xFFD9B45A)
            ..strokeWidth = 1.5 * base.k
            ..strokeCap = StrokeCap.round);
      c.drawCircle(
          top.o, .9 * base.k, Paint()..color = const Color(0xFFE9CF8B));
    }));

    // Ø§Ù„Ø²Ø­Ø§Ù…
    final n = _Tawaf3DPageState.crowdCounts[s.crowd];
    for (int i = 0; i < n; i++) {
      final p = s.npcs[i];
      final pos = s.lanes[p.lane].at(p.s);
      final depth = cam.project(V3(pos.dx, 0, pos.dy), size).depth;
      items.add(_Item(depth, () {
        _drawPilgrim(c, cam, size, pos.dx, pos.dy, p.kind,
            tint: p.tint, lift: .06 * math.sin(p.s * 1.7).abs());
      }));
    }

    // Ø£Ù†Øª
    final mp = s.me.at(s.dist);
    final raml = s.male && (s.dist / s.me.length).floor() < 3;
    final lift =
        s.playing ? (raml ? .13 : .06) * math.sin(s.dist * 2.2).abs() : 0.0;
    items.add(_Item(cam.project(V3(mp.dx, 0, mp.dy), size).depth, () {
      _drawPilgrim(c, cam, size, mp.dx, mp.dy, s.male ? 0 : 1,
          me: true, lift: lift);
    }));

    items.sort((x, y) => y.depth.compareTo(x.depth));
    for (final it in items) {
      it.draw();
    }

    // Ø§Ù„Ø£Ø³Ù…Ø§Ø¡
    if (s.labels) {
      void lab(String t, V3 p) {
        final q = cam.project(p, size);
        if (q.depth > 1) _tag(c, t, q.o);
      }

      lab('Ø§Ù„Ø­Ø¬Ø± Ø§Ù„Ø£Ø³ÙˆØ¯', const V3(kHw, 3.2, kHd));
      lab('Ø¨Ø§Ø¨ Ø§Ù„ÙƒØ¹Ø¨Ø©', const V3(kHw, 7.2, .5));
      lab('Ø§Ù„Ø­ÙØ¬Ø±', const V3(0, 2.4, -kHd - kHijr));
      lab('Ø§Ù„Ø±ÙƒÙ† Ø§Ù„ÙŠÙ…Ø§Ù†ÙŠ', const V3(-kHw, 4.2, kHd));
      lab('Ø§Ù„Ø±ÙƒÙ† Ø§Ù„Ø¹Ø±Ø§Ù‚ÙŠ', const V3(kHw, 4.2, -kHd));
      lab('Ø§Ù„Ø±ÙƒÙ† Ø§Ù„Ø´Ø§Ù…ÙŠ', const V3(-kHw, 4.2, -kHd));
      lab('Ù…Ù‚Ø§Ù… Ø¥Ø¨Ø±Ø§Ù‡ÙŠÙ…', const V3(mx, 4.0, mz));
    }
    final meTop = cam.project(V3(mp.dx, 2.6, mp.dy), size);
    _tag(c, 'Ø£Ù†Øª', meTop.o,
        bg: AppColors.gold, fg: const Color(0xFF3B2A00), size: 12);

    // ØªØ¹ØªÙŠÙ… Ø§Ù„Ø£Ø·Ø±Ø§Ù
    c.drawRect(
        rect,
        Paint()
          ..shader = const RadialGradient(
            colors: [Colors.transparent, Color(0x30030E0C)],
            stops: [.62, 1],
          ).createShader(rect));
  }

  void _kaaba(Canvas c, Cam cam, Size sz) {
    final cp = cam.pos;

    void hijrWalls() {
      final segs = <_Item>[];
      for (int i = 0; i < 24; i++) {
        final a0 = i * math.pi / 24, a1 = (i + 1) * math.pi / 24;
        final p0 = V3(kHijr * math.cos(a0), 0, -kHd - kHijr * math.sin(a0));
        final p1 = V3(kHijr * math.cos(a1), 0, -kHd - kHijr * math.sin(a1));
        final d =
            cam.project(V3((p0.x + p1.x) / 2, .7, (p0.z + p1.z) / 2), sz).depth;
        segs.add(_Item(d, () {
          final pts = [
            V3(p0.x, 0, p0.z),
            V3(p1.x, 0, p1.z),
            V3(p1.x, 1.3, p1.z),
            V3(p0.x, 1.3, p0.z)
          ];
          final path = _path(cam, sz, pts);
          c.drawPath(path, Paint()..color = const Color(0xFFF2EBDD));
          c.drawPath(
              path,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1
                ..color = Colors.black26);
        }));
      }
      segs.sort((x, y) => y.depth.compareTo(x.depth));
      for (final it in segs) {
        it.draw();
      }
    }

    final northSide = cp.z < -kHd;
    if (!northSide) hijrWalls();

    _drawBox(c, cam, sz, const V3(-kHw, 0, -kHd), const V3(kHw, kH, kHd),
        const Color(0xFF2B2B2B));

    final textures = s._materials;
    if (textures != null) {
      void photoWall(List<V3> face, V3 normal, bool door) {
        final center = V3(
          (face[0].x + face[2].x) / 2,
          (face[0].y + face[2].y) / 2,
          (face[0].z + face[2].z) / 2,
        );
        if (_dot(normal,
                V3(cp.x - center.x, cp.y - center.y, cp.z - center.z)) <=
            0) return;
        Umrah3DMaterials.quad(
          c,
          [for (final p in face) cam.project(p, sz).o],
          door ? textures.front : textures.side,
          subdivisions: 12,
        );
      }

      // Clockwise textured surfaces from the source photograph; unlike a
      // pasted photo, their geometry responds to yaw, pitch and zoom.
      photoWall(const [
        V3(-kHw, kH, kHd + .01),
        V3(kHw, kH, kHd + .01),
        V3(kHw, 0, kHd + .01),
        V3(-kHw, 0, kHd + .01)
      ], const V3(0, 0, 1), false);
      photoWall(const [
        V3(kHw + .01, kH, kHd),
        V3(kHw + .01, kH, -kHd),
        V3(kHw + .01, 0, -kHd),
        V3(kHw + .01, 0, kHd)
      ], const V3(1, 0, 0), true);
      photoWall(const [
        V3(kHw, kH, -kHd - .01),
        V3(-kHw, kH, -kHd - .01),
        V3(-kHw, 0, -kHd - .01),
        V3(kHw, 0, -kHd - .01)
      ], const V3(0, 0, -1), false);
      photoWall(const [
        V3(-kHw - .01, kH, -kHd),
        V3(-kHw - .01, kH, kHd),
        V3(-kHw - .01, 0, kHd),
        V3(-kHw - .01, 0, -kHd)
      ], const V3(-1, 0, 0), true);
    }

    const gold = Color(0xFFD9B45A);
    _wallQuad(
        c,
        cam,
        sz,
        const V3(kHw + .02, 0, kHd),
        const V3(kHw + .02, 0, -kHd),
        kH * .72,
        kH * .80,
        const V3(1, 0, 0),
        gold);
    _wallQuad(
        c,
        cam,
        sz,
        const V3(kHw, 0, -kHd - .02),
        const V3(-kHw, 0, -kHd - .02),
        kH * .72,
        kH * .80,
        const V3(0, 0, -1),
        gold);
    _wallQuad(
        c,
        cam,
        sz,
        const V3(-kHw - .02, 0, -kHd),
        const V3(-kHw - .02, 0, kHd),
        kH * .72,
        kH * .80,
        const V3(-1, 0, 0),
        gold);
    _wallQuad(
        c,
        cam,
        sz,
        const V3(-kHw, 0, kHd + .02),
        const V3(kHw, 0, kHd + .02),
        kH * .72,
        kH * .80,
        const V3(0, 0, 1),
        gold);

    // Ø§Ù„Ø¨Ø§Ø¨
    _wallQuad(
        c,
        cam,
        sz,
        const V3(kHw + .04, 0, 1.7),
        const V3(kHw + .04, 0, -.7),
        2.0,
        5.8,
        const V3(1, 0, 0),
        const Color(0xFFE2BE6A));
    _wallQuad(
        c,
        cam,
        sz,
        const V3(kHw + .05, 0, 1.4),
        const V3(kHw + .05, 0, -.4),
        2.4,
        5.4,
        const V3(1, 0, 0),
        const Color(0xFFB88A2E));

    if (northSide) hijrWalls();

    // Ø§Ù„Ø­Ø¬Ø± Ø§Ù„Ø£Ø³ÙˆØ¯
    if (cp.x > kHw || cp.z > kHd) {
      final p = cam.project(const V3(kHw + .05, 1.5, kHd + .05), sz);
      c.drawCircle(p.o, .55 * p.k, Paint()..color = const Color(0xFFC9CED6));
      c.drawCircle(p.o, .38 * p.k, Paint()..color = const Color(0xFF2A2A2E));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  Ø§Ù„Ø³Ø¹ÙŠ Ø«Ù„Ø§Ø«ÙŠ Ø§Ù„Ø£Ø¨Ø¹Ø§Ø¯
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _SaiNpc {
  double x;
  final double z, v;
  final int dir, kind;
  final Color tint;
  _SaiNpc(this.x, this.z, this.v, this.dir, this.kind, this.tint);
}

class Sai3DPage extends StatefulWidget {
  const Sai3DPage({super.key});
  @override
  State<Sai3DPage> createState() => _Sai3DPageState();
}

class _Sai3DPageState extends State<Sai3DPage>
    with SingleTickerProviderStateMixin {
  static const safa = 32.0, marwa = -32.0, zoneHalf = 7.0;

  final cam =
      Cam(yaw: math.pi, pitch: .55, dist: 56, target: const V3(0, 2, 0));
  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final List<_SaiNpc> npcs = [];

  double x = safa, z = -2.4;
  int leg = 0; // Ø¹Ø¯Ø¯ Ø§Ù„Ø£Ø´ÙˆØ§Ø· Ø§Ù„Ù…ÙƒØªÙ…Ù„Ø©
  double pauseLeft = 0, pauseTotal = 6, _zFrom = -2.4, _zTo = -2.4;
  bool started = false, playing = false, finished = false;
  bool male = true, labels = true, _inZone = false;
  bool _controlsExpanded = false;
  Umrah3DMaterials? _materials;

  Future<void> _loadMaterials() async {
    try {
      final images = await Umrah3DMaterials.load();
      if (mounted) setState(() => _materials = images);
    } catch (_) {
      // Preserve procedural geometry when an asset is missing.
    }
  }

  double speed = 1.0;
  int camMode = 1; // cinematic orbit; 0 follow, 1 free, 2 overhead
  String caption = '';
  double _baseDist = 56;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
    final rnd = math.Random(11);
    const tints = [Color(0xFF3B8FC4), Color(0xFFD9675B), Color(0xFF8A5FB0)];
    for (int i = 0; i < 40; i++) {
      final dir = rnd.nextBool() ? 1 : -1;
      final r = rnd.nextDouble();
      npcs.add(_SaiNpc(
        -32 + rnd.nextDouble() * 64,
        (dir == 1 ? 3.0 : -3.0) +
            (rnd.nextDouble() - .5) * 2.4 +
            (dir == 1 ? 1.2 : -1.2),
        2.8 + rnd.nextDouble() * 1.8,
        dir,
        r < .55 ? 0 : (r < .85 ? 1 : 2),
        tints[rnd.nextInt(3)],
      ));
    }
    caption = 'Ø£Ù†Øª Ø¹Ù„Ù‰ Ø§Ù„ØµÙØ§. Ø§Ø¶ØºØ· â–¶ Ù„Ø¨Ø¯Ø¡ Ø§Ù„Ø³Ø¹ÙŠ Ù†Ø­Ùˆ Ø§Ù„Ù…Ø±ÙˆØ©.';
    _applyMode();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();

    super.dispose();
  }

  void _say(String t, {double rate = .42}) {
    /* No synthesized voice in 3D. Guidance remains visible as captions. */
  }

  void _tick(Duration t) {
    final dt = _last == Duration.zero ? 0.0 : (t - _last).inMicroseconds / 1e6;
    _last = t;
    final d = math.min(dt, .05);

    for (final n in npcs) {
      n.x += n.dir * n.v * d;
      if (n.x > 36) n.x = -36;
      if (n.x < -36) n.x = 36;
    }

    if (playing && !finished) {
      if (pauseLeft > 0) {
        pauseLeft -= d * speed;
        final tt = (1 - pauseLeft / pauseTotal).clamp(0.0, 1.0);
        z = _zFrom + (_zTo - _zFrom) * tt;
        if (pauseLeft <= 0) {
          pauseLeft = 0;
          z = _zTo;
          caption = leg.isEven
              ? 'Ø§Ù…Ø´Ù Ù…Ù† Ø§Ù„ØµÙØ§ Ø¥Ù„Ù‰ Ø§Ù„Ù…Ø±ÙˆØ©.'
              : 'Ø§Ù…Ø´Ù Ù…Ù† Ø§Ù„Ù…Ø±ÙˆØ© Ø¥Ù„Ù‰ Ø§Ù„ØµÙØ§.';
          setState(() {});
        }
      } else {
        final dirX = leg.isEven ? -1.0 : 1.0;
        final inZone = x.abs() < zoneHalf;
        if (inZone != _inZone) {
          _inZone = inZone;
          if (inZone) {
            caption = male
                ? 'Ø¨ÙŠÙ† Ø§Ù„Ø¹Ù„Ù…ÙŠÙ† Ø§Ù„Ø£Ø®Ø¶Ø±ÙŠÙ†: Ø£Ø³Ø±ÙØ¹ ÙÙŠ Ø§Ù„Ù…Ø´ÙŠ (Ù‡Ø±ÙˆÙ„Ø©).'
                : 'Ø¨ÙŠÙ† Ø§Ù„Ø¹Ù„Ù…ÙŠÙ† Ø§Ù„Ø£Ø®Ø¶Ø±ÙŠÙ†: Ø§Ù…Ø´Ù Ø¨Ø³ÙƒÙŠÙ†Ø©ØŒ ÙÙ„Ø§ Ù‡Ø±ÙˆÙ„Ø© Ø¹Ù„Ù‰ Ø§Ù„Ù…Ø±Ø£Ø©.';
            _say(caption);
          } else {
            caption = 'Ø¹ÙØ¯ Ø¥Ù„Ù‰ Ø§Ù„Ù…Ø´ÙŠ Ø§Ù„Ù…Ø¹ØªØ§Ø¯.';
          }
          setState(() {});
        }
        final v = 4.0 * speed * (male && inZone ? 2.1 : 1.0);
        x += dirX * v * d;
        final end = leg.isEven ? marwa : safa;
        if ((dirX < 0 && x <= end) || (dirX > 0 && x >= end)) {
          x = end;
          _arrive();
        }
      }
    }

    if (camMode == 0) {
      final dirX = leg.isEven ? -1.0 : 1.0;
      final ty = dirX > 0 ? math.pi / 2 : -math.pi / 2;
      var diff = ty - cam.yaw;
      while (diff > math.pi) {
        diff -= 2 * math.pi;
      }
      while (diff < -math.pi) {
        diff += 2 * math.pi;
      }
      final a = 1 - math.exp(-d * 3.5);
      cam.yaw += diff * a;
      cam.target = V3(cam.target.x + (x - cam.target.x) * a, 1.3,
          cam.target.z + (z - cam.target.z) * a);
    }
    _frame.value++;
  }

  void _arrive() {
    leg++;
    final st = AppScope.of(context);
    st.change(() => st.sai = leg);
    HapticFeedback.mediumImpact();
    if (leg >= 7) {
      finished = true;
      playing = false;
      caption = 'Ø£ØªÙ…Ù…Øª 7 Ø£Ø´ÙˆØ§Ø· ðŸŽ‰ Ø§Ù„Ø¢Ù† Ø§Ø­Ù„Ù‚ Ø£Ùˆ Ù‚ØµÙ‘Ø±.';
      _say(
          'ØªÙ‚Ø¨Ù‘Ù„ Ø§Ù„Ù„Ù‡ Ø³Ø¹ÙŠÙƒ. Ø£ØªÙ…Ù…Øª Ø³Ø¨Ø¹Ø© Ø£Ø´ÙˆØ§Ø· ÙˆØ£Ù†Øª Ø¹Ù„Ù‰ Ø§Ù„Ù…Ø±ÙˆØ©. Ø§Ù„Ø¢Ù† Ø§Ø­Ù„Ù‚ Ø£Ùˆ Ù‚ØµÙ‘Ø±');
      setState(() {});
      return;
    }
    final atMarwa = leg.isOdd;
    _zFrom = z;
    _zTo = leg.isEven ? -2.4 : 2.4;
    pauseTotal = 6;
    pauseLeft = pauseTotal;
    caption = atMarwa
        ? 'ÙˆØµÙ„Øª Ø§Ù„Ù…Ø±ÙˆØ© (Ø§Ù„Ø´ÙˆØ· $leg). Ø§Ø³ØªÙ‚Ø¨Ù„ Ø§Ù„ÙƒØ¹Ø¨Ø© ÙˆØ§ÙØ¹Ù„ ÙƒÙ…Ø§ ÙØ¹Ù„Øª Ø¹Ù„Ù‰ Ø§Ù„ØµÙØ§.'
        : 'Ø¹Ø¯Øª Ø¥Ù„Ù‰ Ø§Ù„ØµÙØ§ (Ø§Ù„Ø´ÙˆØ· $leg). Ø§Ø³ØªÙ‚Ø¨Ù„ Ø§Ù„ÙƒØ¹Ø¨Ø© ÙˆØ§Ø¯Ø¹Ù.';
    _say(atMarwa
        ? 'ÙˆØµÙ„Øª Ø§Ù„Ù…Ø±ÙˆØ©ØŒ ØªÙ…Ù‘ Ø§Ù„Ø´ÙˆØ· ${_ordM[leg - 1]}. Ø§Ø³ØªÙ‚Ø¨Ù„ Ø§Ù„ÙƒØ¹Ø¨Ø© ÙˆÙƒØ¨Ù‘Ø± ÙˆØ§Ø¯Ø¹Ù'
        : 'Ø¹Ø¯Øª Ø¥Ù„Ù‰ Ø§Ù„ØµÙØ§ØŒ ØªÙ…Ù‘ Ø§Ù„Ø´ÙˆØ· ${_ordM[leg - 1]}. Ø§Ø³ØªÙ‚Ø¨Ù„ Ø§Ù„ÙƒØ¹Ø¨Ø© ÙˆÙƒØ¨Ù‘Ø± ÙˆØ§Ø¯Ø¹Ù');
    setState(() {});
  }

  void _toggle() {
    if (finished) return;
    if (!started) {
      started = true;
      playing = true;
      pauseTotal = 8;
      pauseLeft = pauseTotal;
      _zFrom = z;
      _zTo = -2.4;
      caption =
          'Ø¹Ù„Ù‰ Ø§Ù„ØµÙØ§: Ø§Ù‚Ø±Ø£ Ø¥Ù† Ø§Ù„ØµÙØ§ ÙˆØ§Ù„Ù…Ø±ÙˆØ© Ù…Ù† Ø´Ø¹Ø§Ø¦Ø± Ø§Ù„Ù„Ù‡ØŒ Ø«Ù… Ø§Ø³ØªÙ‚Ø¨Ù„ Ø§Ù„ÙƒØ¹Ø¨Ø©ØŒ ÙˆÙƒØ¨Ù‘Ø± Ø«Ù„Ø§Ø«Ù‹Ø§ ÙˆÙ‚Ù„ Ø§Ù„Ø°ÙƒØ± ÙˆØ§Ø¯Ø¹Ù.';
      _say(
          'Ø£Ù†Øª Ø¹Ù„Ù‰ Ø§Ù„ØµÙØ§. Ø¥ÙÙ†ÙŽÙ‘ Ø§Ù„ØµÙŽÙ‘ÙÙŽØ§ ÙˆÙŽØ§Ù„Ù’Ù…ÙŽØ±Ù’ÙˆÙŽØ©ÙŽ Ù…ÙÙ†Ù’ Ø´ÙŽØ¹ÙŽØ§Ø¦ÙØ±Ù Ø§Ù„Ù„ÙŽÙ‘Ù‡ÙØŒ Ø£ÙŽØ¨Ù’Ø¯ÙŽØ£Ù Ø¨ÙÙ…ÙŽØ§ Ø¨ÙŽØ¯ÙŽØ£ÙŽ Ø§Ù„Ù„ÙŽÙ‘Ù‡Ù Ø¨ÙÙ‡Ù. Ø§Ø³ØªÙ‚Ø¨Ù„ Ø§Ù„ÙƒØ¹Ø¨Ø© ÙˆÙƒØ¨Ù‘Ø± Ø«Ù„Ø§Ø«Ù‹Ø§ Ø«Ù… Ù‚Ù„: ${umrahGuide[5].dua}',
          rate: .38);
    } else {
      playing = !playing;
    }
    setState(() {});
  }

  void _restart() {
    final st = AppScope.of(context);
    st.change(() => st.sai = 0);
    x = safa;
    z = -2.4;
    leg = 0;
    pauseLeft = 0;
    started = false;
    playing = false;
    finished = false;
    _inZone = false;
    caption = 'Ø£Ù†Øª Ø¹Ù„Ù‰ Ø§Ù„ØµÙØ§. Ø§Ø¶ØºØ· â–¶ Ù„Ø¨Ø¯Ø¡ Ø§Ù„Ø³Ø¹ÙŠ Ù†Ø­Ùˆ Ø§Ù„Ù…Ø±ÙˆØ©.';
    setState(() {});
  }

  void _applyMode() {
    if (camMode == 1) {
      cam
        ..yaw = 2.35
        ..pitch = .49
        ..dist = 55
        ..target = const V3(0, 2, 0);
    } else if (camMode == 2) {
      cam
        ..yaw = math.pi
        ..pitch = 1.08
        ..dist = 69
        ..target = const V3(0, 2, 0);
    } else {
      cam
        ..pitch = .70
        ..dist = 36;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = finished ? 7 : math.min(leg + 1, 7);
    return _Rifqa3DStage(
      title: 'Ø§Ù„Ø³Ø¹ÙŠ Ø«Ù„Ø§Ø«ÙŠ Ø§Ù„Ø£Ø¨Ø¹Ø§Ø¯',
      subtitle: 'Ø¨ÙŠÙ† Ø§Ù„ØµÙØ§ ÙˆØ§Ù„Ù…Ø±ÙˆØ©',
      backgroundAsset: 'assets/umrah/sai_3d_atmosphere.jpg',
      step: shown,
      done: finished ? 7 : leg,
      caption: caption,
      isPlaying: playing,
      finished: finished,
      onStart: _toggle,
      onReset: _restart,
      onNarration: () => _showRecordedGuide(context, 5),
      onOverview: () => setState(() {
        camMode = 2;
        _applyMode();
      }),
      optionsExpanded: _controlsExpanded,
      onOptions: () => setState(() => _controlsExpanded = !_controlsExpanded),
      options: _sceneOptions(),
      completion: _finishCard(
        'ØªÙ‚Ø¨Ù‘Ù„ Ø§Ù„Ù„Ù‡ Ø³Ø¹ÙŠÙƒ',
        'Ø£ØªÙ…Ù…Øª 7 Ø£Ø´ÙˆØ§Ø· Ø¹Ù„Ù‰ Ø§Ù„Ù…Ø±ÙˆØ©. Ø§Ù„Ø®Ø·ÙˆØ© Ø§Ù„Ø£Ø®ÙŠØ±Ø©: Ø§Ù„Ø­Ù„Ù‚ Ø£Ùˆ Ø§Ù„ØªÙ‚ØµÙŠØ±.',
        () => Navigator.pop(context),
        _restart,
      ),
      scene: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (_) => _baseDist = cam.dist,
        onScaleUpdate: (d) {
          if (camMode != 0) {
            cam.yaw += d.focalPointDelta.dx * .007;
            cam.pitch = (cam.pitch + d.focalPointDelta.dy * .006)
                .clamp(.20, 1.27)
                .toDouble();
          }
          if (d.scale != 1) {
            cam.dist = (_baseDist / d.scale).clamp(25.0, 100.0).toDouble();
          }
        },
        child: CustomPaint(painter: _SaiPainter(this)),
      ),
    );
  }

  Widget _sceneOptions() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _sceneOption('0.6Ã—', speed == .6, () => setState(() => speed = .6)),
          _sceneOption('1Ã—', speed == 1, () => setState(() => speed = 1)),
          _sceneOption('1.8Ã—', speed == 1.8, () => setState(() => speed = 1.8)),
          _sceneOption(
              'Ø§ØªØ¨Ø¹Ù†ÙŠ',
              camMode == 0,
              () => setState(() {
                    camMode = 0;
                    _applyMode();
                  })),
          _sceneOption(
              'Ù…Ù†Ø¸ÙˆØ± Ø­Ø±',
              camMode == 1,
              () => setState(() {
                    camMode = 1;
                    _applyMode();
                  })),
          _sceneOption(
              'Ù…Ù† Ø£Ø¹Ù„Ù‰',
              camMode == 2,
              () => setState(() {
                    camMode = 2;
                    _applyMode();
                  })),
          _sceneOption('Ø±Ø¬Ù„', male, () => setState(() => male = true)),
          _sceneOption('Ø§Ù…Ø±Ø£Ø©', !male, () => setState(() => male = false)),
          _sceneOption(
              'Ø£Ø³Ù…Ø§Ø¡ Ø§Ù„Ù…ÙˆØ§Ù‚Ø¹', labels, () => setState(() => labels = !labels)),
        ],
      );
}

class _SaiPainter extends CustomPainter {
  final _Sai3DPageState s;
  _SaiPainter(this.s) : super(repaint: s._frame);

  @override
  void paint(Canvas c, Size size) {
    final cam = s.cam;
    final rect = Offset.zero & size;
    // Mas'aa photo creates architectural depth beneath the animated 3D floor.

    // Ø§Ù„Ø£Ø±Ø¶ÙŠØ©
    c.drawPath(
        _path(cam, size,
            const [V3(-38, 0, -8), V3(38, 0, -8), V3(38, 0, 8), V3(-38, 0, 8)]),
        Paint()..color = const Color(0xFFEADFC9));
    if (this.s._materials != null) {
      Umrah3DMaterials.quad(
          c,
          [
            cam.project(const V3(-38, .01, -8), size).o,
            cam.project(const V3(38, .01, -8), size).o,
            cam.project(const V3(38, .01, 8), size).o,
            cam.project(const V3(-38, .01, 8), size).o,
          ],
          this.s._materials!.marble,
          repeatX: 8,
          repeatY: 2,
          subdivisions: 12);
    }

    // Ù…Ù†Ø·Ù‚Ø© Ø§Ù„Ù‡Ø±ÙˆÙ„Ø©
    c.drawPath(
        _path(cam, size, const [
          V3(-_Sai3DPageState.zoneHalf, .02, -8),
          V3(_Sai3DPageState.zoneHalf, .02, -8),
          V3(_Sai3DPageState.zoneHalf, .02, 8),
          V3(-_Sai3DPageState.zoneHalf, .02, 8)
        ]),
        Paint()..color = const Color(0x552EE59D));
    // Ø§Ù„ÙØ§ØµÙ„ Ø¨ÙŠÙ† Ø§Ù„Ø§ØªØ¬Ø§Ù‡ÙŠÙ†
    final d1 = cam.project(const V3(-36, .03, 0), size).o;
    final d2 = cam.project(const V3(36, .03, 0), size).o;
    c.drawLine(
        d1,
        d2,
        Paint()
          ..color = const Color(0x88B8935A)
          ..strokeWidth = 2);

    final items = <_Item>[];

    // Ø¬Ø¯Ø±Ø§Ù† Ø¬Ø§Ù†Ø¨ÙŠØ©
    for (final side in [-1.0, 1.0]) {
      for (int i = 0; i < 9; i++) {
        final x0 = -36.0 + i * 8;
        final a = V3(x0, 0, side > 0 ? 8 : 8.6 * side);
        final b = V3(x0 + 8, 1.4, side > 0 ? 8.6 : 8 * side);
        final mn = V3(math.min(a.x, b.x), 0, math.min(a.z, b.z));
        final mx = V3(math.max(a.x, b.x), 1.4, math.max(a.z, b.z));
        items.add(_Item(cam.project(V3(x0 + 4, .7, side * 8.3), size).depth,
            () => _drawBox(c, cam, size, mn, mx, const Color(0xFFD8CBB0))));
      }
    }

    // Ø§Ù„Ø¹Ù„Ù…Ø§Ù† Ø§Ù„Ø£Ø®Ø¶Ø±Ø§Ù†
    for (final px in [-_Sai3DPageState.zoneHalf, _Sai3DPageState.zoneHalf]) {
      for (final sz in [-8.3, 8.3]) {
        items.add(_Item(cam.project(V3(px, 2, sz), size).depth, () {
          _drawBox(c, cam, size, V3(px - .3, 0, sz - .3),
              V3(px + .3, 4.2, sz + .3), const Color(0xFF1FBF7A));
          final t = cam.project(V3(px, 4.4, sz), size);
          c.drawCircle(
              t.o,
              .8 * t.k,
              Paint()
                ..color = const Color(0x882EE59D)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        }));
      }
    }

    // Ø§Ù„ØµÙØ§ ÙˆØ§Ù„Ù…Ø±ÙˆØ©
    void hill(double sign) {
      items.add(_Item(cam.project(V3(sign * 36, 1, 0), size).depth, () {
        V3 mn(double x1, double x2, double y, double zz) =>
            V3(math.min(sign * x1, sign * x2), y, -zz);
        V3 mx(double x1, double x2, double y, double zz) =>
            V3(math.max(sign * x1, sign * x2), y, zz);
        const rock = Color(0xFF8A7B63);
        _drawBox(c, cam, size, mn(33.5, 41, 0, 6), mx(33.5, 41, 1.4, 6), rock);
        _drawBox(c, cam, size, mn(34.5, 39.5, 1.4, 4.5),
            mx(34.5, 39.5, 2.8, 4.5), rock);
        _drawBox(
            c, cam, size, mn(35.5, 38, 2.8, 3), mx(35.5, 38, 4.2, 3), rock);
        // Ù‚ÙˆØ³
        const gold = Color(0xFFD9B45A);
        _drawBox(c, cam, size, mn(32.4, 33.0, 0, 5.4), mx(32.4, 33.0, 6, -4.8),
            gold);
        _drawBox(c, cam, size, mn(32.4, 33.0, 0, -4.8), mx(32.4, 33.0, 6, 5.4),
            gold);
        _drawBox(
            c, cam, size, mn(32.4, 33.0, 6, 5.4), mx(32.4, 33.0, 7, 5.4), gold);
      }));
    }

    hill(1);
    hill(-1);

    // Ø§Ù„Ø²Ø­Ø§Ù…
    for (final n in s.npcs) {
      final depth = cam.project(V3(n.x, 0, n.z), size).depth;
      items.add(_Item(depth, () {
        final run = n.x.abs() < _Sai3DPageState.zoneHalf && n.kind == 0;
        _drawPilgrim(c, cam, size, n.x, n.z, n.kind,
            tint: n.tint, lift: (run ? .12 : .05) * math.sin(n.x * 1.9).abs());
      }));
    }

    // Ø£Ù†Øª
    final lift = s.playing && s.pauseLeft <= 0
        ? (s.male && s.x.abs() < _Sai3DPageState.zoneHalf ? .14 : .06) *
            math.sin(s.x * 2.4).abs()
        : 0.0;
    items.add(_Item(cam.project(V3(s.x, 0, s.z), size).depth, () {
      _drawPilgrim(c, cam, size, s.x, s.z, s.male ? 0 : 1,
          me: true, lift: lift);
    }));

    items.sort((a, b) => b.depth.compareTo(a.depth));
    for (final it in items) {
      it.draw();
    }

    if (s.labels) {
      void lab(String t, V3 p) {
        final q = cam.project(p, size);
        if (q.depth > 1) _tag(c, t, q.o);
      }

      lab('Ø§Ù„ØµÙØ§', const V3(_Sai3DPageState.safa + 4, 8.5, 0));
      lab('Ø§Ù„Ù…Ø±ÙˆØ©', const V3(_Sai3DPageState.marwa - 4, 8.5, 0));
      lab('Ø§Ù„Ø¹Ù„Ù…Ø§Ù† Ø§Ù„Ø£Ø®Ø¶Ø±Ø§Ù†', const V3(0, 5.6, -8.3));
    }
    final t = cam.project(V3(s.x, 2.6, s.z), size);
    _tag(c, 'Ø£Ù†Øª', t.o,
        bg: AppColors.gold, fg: const Color(0xFF3B2A00), size: 12);

    c.drawRect(
        rect,
        Paint()
          ..shader = const RadialGradient(
            colors: [Colors.transparent, Color(0x30030E0C)],
            stops: [.62, 1],
          ).createShader(rect));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// UI frame common to Tawaf and Sa'i. The motion and lap logic remain in the
/// original 3D states. Every control here is active, not a static mockup.
class _Rifqa3DStage extends StatelessWidget {
  const _Rifqa3DStage({
    required this.title,
    required this.subtitle,
    required this.backgroundAsset,
    required this.step,
    required this.done,
    required this.caption,
    required this.isPlaying,
    required this.finished,
    required this.onStart,
    required this.onReset,
    required this.onNarration,
    required this.onOverview,
    required this.onOptions,
    required this.optionsExpanded,
    required this.options,
    required this.completion,
    required this.scene,
  });
  final String title, subtitle, backgroundAsset, caption;
  final int step, done;
  final bool isPlaying, finished, optionsExpanded;
  final VoidCallback onStart, onReset, onNarration, onOverview, onOptions;
  final Widget options, completion, scene;
  static const green = Color(0xFF063D30);
  static const cream = Color(0xFFFCF8F0);
  static const gold = Color(0xFFD9B86C);
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: cream,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: cream,
        body: Stack(children: [
          Positioned.fill(
              child: Image.asset(backgroundAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFFC2B498)))),
          Positioned.fill(
              child: IgnorePointer(
                  child: DecoratedBox(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xAA031F1A), Color(0x10073E30), Color(0x220C4437)],
              stops: [0, .28, 1],
            )),
          ))),
          Positioned.fill(child: scene),
          SafeArea(
              child: Column(children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 4),
              child: Row(children: [
                Material(
                    color: const Color(0x770C3A30),
                    shape: const CircleBorder(),
                    child: const BackButton(color: Colors.white)),
                Expanded(
                    child: Column(children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFFF5E5C3), fontSize: 11.5)),
                ])),
                IconButton(
                    tooltip: 'Ø§Ø³ØªÙ…Ø¹ Ù„ØµÙˆØª Ø±ÙÙÙ‚Ø© Ø§Ù„Ù…Ø³Ø¬Ù‘Ù„',
                    onPressed: onNarration,
                    icon: const Icon(Icons.headphones_rounded,
                        color: gold, size: 29)),
              ]),
            ),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xDD07382F),
                      borderRadius: BorderRadius.circular(22),
                      border:
                          Border.all(color: const Color(0x88DEC587), width: 1)),
                  child: Row(children: [
                    Text('Ø§Ù„Ø´ÙˆØ· $step Ù…Ù† 7',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    for (var i = 0; i < 7; i++)
                      Padding(
                          padding: const EdgeInsetsDirectional.only(start: 5),
                          child: Icon(
                              i < done
                                  ? Icons.check_circle_rounded
                                  : Icons.circle,
                              size: i < done ? 14 : 12,
                              color:
                                  i < done ? gold : const Color(0xFF6F938A))),
                  ]),
                )),
            const Spacer(),
            Container(
              margin: const EdgeInsets.fromLTRB(11, 0, 11, 12),
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(29),
                border: Border.all(color: const Color(0xFFE5D3B5)),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0x44000000),
                      blurRadius: 28,
                      offset: const Offset(0, 9))
                ],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                        color: const Color(0xFFD4C4A7),
                        borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 11),
                Text(caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: green,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.2,
                        height: 1.5)),
                const SizedBox(height: 13),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RifqaSceneCircle(
                          icon: Icons.restart_alt_rounded,
                          label: 'Ø¥Ø¹Ø§Ø¯Ø©',
                          onTap: onReset),
                      Material(
                          color: green,
                          shape: const CircleBorder(),
                          child: SizedBox(
                              width: 67,
                              height: 67,
                              child: IconButton(
                                tooltip:
                                    isPlaying ? 'Ø¥ÙŠÙ‚Ø§Ù Ù…Ø¤Ù‚Øª' : 'Ø¨Ø¯Ø¡ Ø§Ù„Ù…Ø­Ø§ÙƒØ§Ø©',
                                onPressed: onStart,
                                icon: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: gold,
                                    size: 39),
                              ))),
                      _RifqaSceneCircle(
                          icon: Icons.layers_rounded,
                          label: 'Ù†Ø¸Ø±Ø© Ø¹Ù„ÙˆÙŠØ©',
                          onTap: onOverview),
                      _RifqaSceneCircle(
                          icon: optionsExpanded
                              ? Icons.expand_less_rounded
                              : Icons.tune_rounded,
                          label: 'Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª',
                          onTap: onOptions),
                    ]),
                const SizedBox(height: 8),
                Text('Ø§Ø³Ø­Ø¨ÙŠ Ù„ØªØºÙŠÙŠØ± Ø§Ù„Ø²Ø§ÙˆÙŠØ©  â€¢  Ù‚Ø±Ù‘Ø¨ÙŠ Ø¨Ø¥ØµØ¨Ø¹ÙŠÙ† Ù„Ù„ØªÙƒØ¨ÙŠØ±',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF78877D), fontSize: 10.5)),
                if (optionsExpanded) ...[
                  const SizedBox(height: 13),
                  const Divider(color: Color(0xFFEAE0CE), height: 1),
                  const SizedBox(height: 11),
                  options,
                ],
              ]),
            ),
          ])),
          if (finished)
            Positioned.fill(
                child: ColoredBox(
                    color: const Color(0x99000000), child: completion)),
        ]),
      ),
    );
  }
}

class _RifqaSceneCircle extends StatelessWidget {
  const _RifqaSceneCircle(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
            width: 66,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: const Color(0xFF0D5945), size: 26),
              const SizedBox(height: 5),
              Text(label,
                  style:
                      const TextStyle(color: Color(0xFF43574D), fontSize: 10.5),
                  maxLines: 1),
            ])),
      );
}

Widget _sceneOption(String label, bool chosen, VoidCallback tap) => Material(
    color: chosen ? const Color(0xFF0D5945) : const Color(0xFFF1EBDC),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: tap,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Text(label,
              style: TextStyle(
                  color: chosen ? Colors.white : const Color(0xFF244739),
                  fontSize: 12,
                  fontWeight: FontWeight.w700))),
    ));

Future<void> _showRecordedGuide(BuildContext context, int stepIndex) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFFFCF8F0),
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            16, 10, 16, MediaQuery.viewInsetsOf(sheetContext).bottom + 26),
        child: RifqaNarrationPlayer(
          stepIndex: stepIndex,
          onDua: () => showDialog<void>(
              context: sheetContext,
              builder: (dialogContext) => AlertDialog(
                    title: const Text('Ø¯Ø¹Ø§Ø¡ Ø§Ù„Ø®Ø·ÙˆØ©'),
                    content: SingleChildScrollView(
                        child: SelectableText(umrahGuide[stepIndex].dua,
                            textAlign: TextAlign.center,
                            style: const TextStyle(height: 1.9))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Ø¥ØºÙ„Ø§Ù‚'))
                    ],
                  )),
        ),
      ),
    ),
  );
}
