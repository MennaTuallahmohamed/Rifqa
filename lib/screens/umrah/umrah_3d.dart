import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../state/app_state.dart';
import 'umrah_data.dart';
import 'umrah_voice.dart';

// ═══════════════════════════════════════════════════════════
//  محرك ثلاثي الأبعاد بسيط (بدون أي ملفات خارجية)
//  المحاور: x شرق، y أعلى، z جنوب
// ═══════════════════════════════════════════════════════════

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
    return P3(Offset(s.width / 2 - x1 * k, s.height * .46 - y2 * k), depth, k);
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

/// مجسم مستطيل بوجوه مظللة (يخفي الوجوه الخلفية)
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

/// شريط ملون على جدار رأسي (للحزام الذهبي والباب)
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

/// kind: 0 رجل بالإحرام، 1 امرأة، 2 ملابس ملونة
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

// ═══════════════════════════════════════════════════════════
//  عناصر واجهة مشتركة (داكنة)
// ═══════════════════════════════════════════════════════════

Widget _glass(
        {required Widget child,
        EdgeInsets padding = const EdgeInsets.all(12)}) =>
    Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xCC081C17),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: child,
    );

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

Widget _roundBtn(IconData i, VoidCallback on, {bool big = false}) =>
    GestureDetector(
      onTap: on,
      child: Container(
        width: big ? 54 : 44,
        height: big ? 54 : 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: big
              ? const LinearGradient(
                  colors: [AppColors.green, AppColors.greenDark])
              : null,
          color: big ? null : Colors.white12,
          border: big ? Border.all(color: AppColors.gold, width: 2) : null,
        ),
        child: Icon(i, color: Colors.white, size: big ? 30 : 22),
      ),
    );

Widget _dots(int done) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int k = 0; k < 7; k++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: k < done ? AppColors.gold : Colors.white24,
            ),
          ),
      ],
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
            const Text('🤲', style: TextStyle(fontSize: 44)),
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
                _pill('إعادة', false, onAgain),
                const SizedBox(width: 10),
                _pill('إتمام', true, onClose),
              ],
            ),
          ],
        ),
      ),
    );

// ═══════════════════════════════════════════════════════════
//  الطواف ثلاثي الأبعاد
// ═══════════════════════════════════════════════════════════

const double kHw = 6.4, kHd = 5.5, kHijr = 4.5, kH = 13.0;

class _Seg {
  final double len;
  final Offset Function(double) at;
  _Seg(this.len, this.at);
}

/// مسار الطواف: مستطيل بزوايا مدوّرة حول الكعبة والحِجر، عكس عقارب الساعة
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

    add(hd + bt - rc, (u) => Offset(a, hd - u)); // الجدار الشرقي (الباب)
    add(q, (u) => arc(c2, -u / rc)); // الركن العراقي
    add(2 * a - 2 * rc, (u) => Offset(a - rc - u, -bt)); // جهة الحِجر
    add(q, (u) => arc(c4, -math.pi / 2 - u / rc)); // الركن الشامي
    add(bt + bb - 2 * rc, (u) => Offset(-a, -bt + rc + u)); // الجدار الغربي
    add(q, (u) => arc(c6, -math.pi - u / rc)); // الركن اليماني
    add(2 * a - 2 * rc, (u) => Offset(-a + rc + u, bb)); // بين اليماني والحجر
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
  'الأول',
  'الثاني',
  'الثالث',
  'الرابع',
  'الخامس',
  'السادس',
  'السابع'
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
  bool male = true, voice = true, labels = true;
  double speed = 1.0;
  int crowd = 1;
  int camMode = 0; // 0 تابعني، 1 حر، 2 من فوق
  String caption = '';
  double _baseDist = 42;

  @override
  void initState() {
    super.initState();
    me = Track(3.2, hw: kHw, hd: kHd, hijr: kHijr);
    lanes = [
      for (final m in [2.6, 3.8, 5.0, 6.2, 7.4, 8.6])
        Track(m, hw: kHw, hd: kHd, hijr: kHijr)
    ];
    guides = [
      for (final m in [3.2, 5.6, 8.0]) Track(m, hw: kHw, hd: kHd, hijr: kHijr)
    ];
    miles = [
      _Mile(me.mid(0, .55), 'بمحاذاة باب الكعبة. الكعبة عن يسارك دائمًا.',
          'أنت الآن بمحاذاة باب الكعبة. الكعبة عن يسارك.'),
      _Mile(me.mid(1), 'الركن العراقي. واصل المشي بهدوء وادعُ بما تحب.',
          'الركن العراقي. واصل المشي وادعُ بما تحب.'),
      _Mile(
          me.mid(2),
          'بجانب الحِجر (حِجر إسماعيل): ابقَ خارجه، فهو من الكعبة.',
          'أنت بجانب الحِجر. ابق خارجه ولا تدخل فيه، فهو من الكعبة.'),
      _Mile(me.mid(3), 'الركن الشامي.', 'الركن الشامي.'),
      _Mile(me.mid(4), 'الجدار الغربي. أكثر من الذكر والدعاء.',
          'الجدار الغربي. أكثر من الذكر والدعاء.'),
      _Mile(
          me.mid(5),
          'الركن اليماني: المسه بيدك إن تيسر بلا تقبيل، وإلا فامضِ.',
          'الركن اليماني. المسه بيدك إن تيسر بلا تقبيل، وإن عسر فامضِ دون إشارة.'),
      _Mile(
          me.mid(6),
          'بين اليماني والحجر الأسود: ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار',
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
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
    caption = 'قف عند خط الحجر الأسود الأخضر، ثم اضغط ▶ لبدء الطواف.';
    _applyMode();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    UVoice.I.stop();
    super.dispose();
  }

  void _applyMode() {
    if (camMode == 0) {
      cam.pitch = .34;
      cam.dist = 13;
    } else if (camMode == 1) {
      cam
        ..pitch = .6
        ..dist = 42
        ..yaw = -2.4
        ..target = const V3(0, 3, 0);
    } else {
      cam
        ..pitch = 1.2
        ..dist = 52
        ..target = const V3(0, 0, 0);
    }
  }

  void _say(String t, {double rate = .42}) {
    if (voice) UVoice.I.speak(t, rate: rate);
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
        'تمّ الشوط $n ✓  الآن الشوط ${n + 1}: أشر إلى الحجر الأسود وكبّر${male && n < 3 ? ' (رمل واضطباع)' : ''}';
    _say(
        'تمّ الشوط ${_ordM[n - 1]}. الشوط ${_ordM[n]}: أشر إلى الحجر الأسود وكبّر');
    setState(() {});
  }

  void _finish() {
    finished = true;
    playing = false;
    final st = AppScope.of(context);
    st.change(() => st.tawaf = 7);
    HapticFeedback.heavyImpact();
    caption = 'أتممت 7 أشواط 🎉 الآن صلِّ ركعتين خلف المقام.';
    _say(
        'تقبّل الله طوافك. أتممت سبعة أشواط. الآن صلِّ ركعتين خلف مقام إبراهيم إن تيسر');
    setState(() {});
  }

  void _toggle() {
    if (finished) return;
    if (!started) {
      started = true;
      playing = true;
      caption =
          'الشوط الأول: أشر إلى الحجر الأسود وقل: بسم الله، الله أكبر.${male ? ' (رمل واضطباع)' : ''}';
      _say(
          'ابدأ الطواف من الحجر الأسود، واجعل الكعبة عن يسارك. الشوط الأول. أشر إلى الحجر الأسود وقل: بسم الله، الله أكبر');
    } else {
      playing = !playing;
      if (!playing) UVoice.I.stop();
    }
    setState(() {});
  }

  void _restart() {
    UVoice.I.stop();
    final st = AppScope.of(context);
    st.change(() => st.tawaf = 0);
    dist = 0;
    _prevLap = 0;
    started = false;
    playing = false;
    finished = false;
    caption = 'قف عند خط الحجر الأسود الأخضر، ثم اضغط ▶ لبدء الطواف.';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lap = math.min((dist / me.length).floor(), 7);
    final shown = finished ? 7 : lap + 1;
    return Scaffold(
      backgroundColor: const Color(0xFF06141B),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: (_) => _baseDist = cam.dist,
              onScaleUpdate: (d) {
                if (camMode != 0) {
                  cam.yaw += d.focalPointDelta.dx * .008;
                  cam.pitch = (cam.pitch + d.focalPointDelta.dy * .006)
                      .clamp(.15, 1.45)
                      .toDouble();
                }
                if (d.scale != 1) {
                  cam.dist = (_baseDist / d.scale).clamp(10.0, 80.0).toDouble();
                }
              },
              child: CustomPaint(painter: _TawafPainter(this)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                  child: Row(
                    children: [
                      const BackButton(color: Colors.white),
                      const Expanded(
                        child: Text('الطواف ثلاثي الأبعاد',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => voice = !voice);
                          if (!voice) UVoice.I.stop();
                        },
                        icon: Icon(
                            voice
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            color: voice ? AppColors.gold : Colors.white54),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _glass(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Text('الشوط $shown من 7',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                        const Spacer(),
                        if (male && lap < 3 && !finished)
                          const Padding(
                            padding: EdgeInsetsDirectional.only(end: 10),
                            child: Text('رمل واضطباع',
                                style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                        _dots(finished ? 7 : lap),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _glass(
                        child: Row(
                          children: [
                            const Text('🎧', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(caption,
                                  maxLines: 3,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      height: 1.5,
                                      fontSize: 13.5)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _glass(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                _roundBtn(
                                    started && playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    _toggle,
                                    big: true),
                                const SizedBox(width: 8),
                                _roundBtn(Icons.restart_alt_rounded, _restart),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _pill('بطيء', speed == .6,
                                          () => setState(() => speed = .6)),
                                      _pill('عادي', speed == 1.0,
                                          () => setState(() => speed = 1.0)),
                                      _pill('سريع', speed == 1.8,
                                          () => setState(() => speed = 1.8)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _pill(
                                    'تابعني',
                                    camMode == 0,
                                    () => setState(() {
                                          camMode = 0;
                                          _applyMode();
                                        })),
                                _pill(
                                    'حر',
                                    camMode == 1,
                                    () => setState(() {
                                          camMode = 1;
                                          _applyMode();
                                        })),
                                _pill(
                                    'من فوق',
                                    camMode == 2,
                                    () => setState(() {
                                          camMode = 2;
                                          _applyMode();
                                        })),
                                _pill('زحام خفيف', crowd == 0,
                                    () => setState(() => crowd = 0)),
                                _pill('متوسط', crowd == 1,
                                    () => setState(() => crowd = 1)),
                                _pill('مزدحم', crowd == 2,
                                    () => setState(() => crowd = 2)),
                                _pill('رجل', male,
                                    () => setState(() => male = true)),
                                _pill('امرأة', !male,
                                    () => setState(() => male = false)),
                                _pill('الأسماء', labels,
                                    () => setState(() => labels = !labels)),
                              ],
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
          if (finished)
            _finishCard(
              'تقبّل الله طوافك',
              'أتممت 7 أشواط. الخطوة التالية: ركعتا الطواف وشرب زمزم.',
              () => Navigator.pop(context),
              _restart,
            ),
        ],
      ),
    );
  }
}

class _TawafPainter extends CustomPainter {
  final _Tawaf3DPageState s;
  _TawafPainter(this.s) : super(repaint: s._frame);

  @override
  void paint(Canvas c, Size size) {
    final cam = s.cam;
    final rect = Offset.zero & size;
    c.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF06141B), Color(0xFF124038)],
          ).createShader(rect));

    // أرضية المطاف
    c.drawPath(
        _path(cam, size, [
          for (int i = 0; i < 72; i++)
            V3(34 * math.cos(i * math.pi / 36), 0,
                34 * math.sin(i * math.pi / 36))
        ]),
        Paint()..color = const Color(0xFFEADFC9));

    // خطوط المسارات
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

    // أرضية الحِجر
    c.drawPath(
        _path(cam, size, [
          for (int i = 0; i <= 24; i++)
            V3(kHijr * math.cos(i * math.pi / 24), .03,
                -kHd - kHijr * math.sin(i * math.pi / 24))
        ]),
        Paint()..color = const Color(0xFFD7C8A4));

    // خط الحجر الأسود (الضوء الأخضر)
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

    // الكعبة والحِجر
    items.add(_Item(cam.project(const V3(0, 6, 0), size).depth,
        () => _kaaba(c, cam, size)));

    // أعمدة الحرم
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

    // مقام إبراهيم
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

    // الزحام
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

    // أنت
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

    // الأسماء
    if (s.labels) {
      void lab(String t, V3 p) {
        final q = cam.project(p, size);
        if (q.depth > 1) _tag(c, t, q.o);
      }

      lab('الحجر الأسود', const V3(kHw, 3.2, kHd));
      lab('باب الكعبة', const V3(kHw, 7.2, .5));
      lab('الحِجر', const V3(0, 2.4, -kHd - kHijr));
      lab('الركن اليماني', const V3(-kHw, 4.2, kHd));
      lab('الركن العراقي', const V3(kHw, 4.2, -kHd));
      lab('الركن الشامي', const V3(-kHw, 4.2, -kHd));
      lab('مقام إبراهيم', const V3(mx, 4.0, mz));
    }
    final meTop = cam.project(V3(mp.dx, 2.6, mp.dy), size);
    _tag(c, 'أنت', meTop.o,
        bg: AppColors.gold, fg: const Color(0xFF3B2A00), size: 12);

    // تعتيم الأطراف
    c.drawRect(
        rect,
        Paint()
          ..shader = const RadialGradient(
            colors: [Colors.transparent, Color(0x66000000)],
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

    // الباب
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

    // الحجر الأسود
    if (cp.x > kHw || cp.z > kHd) {
      final p = cam.project(const V3(kHw + .05, 1.5, kHd + .05), sz);
      c.drawCircle(p.o, .55 * p.k, Paint()..color = const Color(0xFFC9CED6));
      c.drawCircle(p.o, .38 * p.k, Paint()..color = const Color(0xFF2A2A2E));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════════════════════════════════════════
//  السعي ثلاثي الأبعاد
// ═══════════════════════════════════════════════════════════

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
  int leg = 0; // عدد الأشواط المكتملة
  double pauseLeft = 0, pauseTotal = 6, _zFrom = -2.4, _zTo = -2.4;
  bool started = false, playing = false, finished = false;
  bool male = true, voice = true, labels = true, _inZone = false;
  double speed = 1.0;
  int camMode = 1; // 0 تابعني، 1 حر، 2 من فوق
  String caption = '';
  double _baseDist = 56;

  @override
  void initState() {
    super.initState();
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
    caption = 'أنت على الصفا. اضغط ▶ لبدء السعي نحو المروة.';
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    UVoice.I.stop();
    super.dispose();
  }

  void _say(String t, {double rate = .42}) {
    if (voice) UVoice.I.speak(t, rate: rate);
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
              ? 'امشِ من الصفا إلى المروة.'
              : 'امشِ من المروة إلى الصفا.';
          setState(() {});
        }
      } else {
        final dirX = leg.isEven ? -1.0 : 1.0;
        final inZone = x.abs() < zoneHalf;
        if (inZone != _inZone) {
          _inZone = inZone;
          if (inZone) {
            caption = male
                ? 'بين العلمين الأخضرين: أسرِع في المشي (هرولة).'
                : 'بين العلمين الأخضرين: امشِ بسكينة، فلا هرولة على المرأة.';
            _say(caption);
          } else {
            caption = 'عُد إلى المشي المعتاد.';
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
      caption = 'أتممت 7 أشواط 🎉 الآن احلق أو قصّر.';
      _say(
          'تقبّل الله سعيك. أتممت سبعة أشواط وأنت على المروة. الآن احلق أو قصّر');
      setState(() {});
      return;
    }
    final atMarwa = leg.isOdd;
    _zFrom = z;
    _zTo = leg.isEven ? -2.4 : 2.4;
    pauseTotal = 6;
    pauseLeft = pauseTotal;
    caption = atMarwa
        ? 'وصلت المروة (الشوط $leg). استقبل الكعبة وافعل كما فعلت على الصفا.'
        : 'عدت إلى الصفا (الشوط $leg). استقبل الكعبة وادعُ.';
    _say(atMarwa
        ? 'وصلت المروة، تمّ الشوط ${_ordM[leg - 1]}. استقبل الكعبة وكبّر وادعُ'
        : 'عدت إلى الصفا، تمّ الشوط ${_ordM[leg - 1]}. استقبل الكعبة وكبّر وادعُ');
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
          'على الصفا: اقرأ إن الصفا والمروة من شعائر الله، ثم استقبل الكعبة، وكبّر ثلاثًا وقل الذكر وادعُ.';
      _say(
          'أنت على الصفا. إِنَّ الصَّفَا وَالْمَرْوَةَ مِنْ شَعَائِرِ اللَّهِ، أَبْدَأُ بِمَا بَدَأَ اللَّهُ بِهِ. استقبل الكعبة وكبّر ثلاثًا ثم قل: ${umrahGuide[5].dua}',
          rate: .38);
    } else {
      playing = !playing;
      if (!playing) UVoice.I.stop();
    }
    setState(() {});
  }

  void _restart() {
    UVoice.I.stop();
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
    caption = 'أنت على الصفا. اضغط ▶ لبدء السعي نحو المروة.';
    setState(() {});
  }

  void _applyMode() {
    if (camMode == 1) {
      cam
        ..yaw = math.pi
        ..pitch = .55
        ..dist = 56
        ..target = const V3(0, 2, 0);
    } else if (camMode == 2) {
      cam
        ..yaw = math.pi
        ..pitch = 1.3
        ..dist = 60
        ..target = const V3(0, 0, 0);
    } else {
      cam
        ..pitch = .34
        ..dist = 13;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = finished ? 7 : math.min(leg + 1, 7);
    return Scaffold(
      backgroundColor: const Color(0xFF06141B),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: (_) => _baseDist = cam.dist,
              onScaleUpdate: (d) {
                if (camMode != 0) {
                  cam.yaw += d.focalPointDelta.dx * .008;
                  cam.pitch = (cam.pitch + d.focalPointDelta.dy * .006)
                      .clamp(.15, 1.45)
                      .toDouble();
                }
                if (d.scale != 1) {
                  cam.dist = (_baseDist / d.scale).clamp(10.0, 90.0).toDouble();
                }
              },
              child: CustomPaint(painter: _SaiPainter(this)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                  child: Row(
                    children: [
                      const BackButton(color: Colors.white),
                      const Expanded(
                        child: Text('السعي ثلاثي الأبعاد',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => voice = !voice);
                          if (!voice) UVoice.I.stop();
                        },
                        icon: Icon(
                            voice
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            color: voice ? AppColors.gold : Colors.white54),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _glass(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Text('الشوط $shown من 7',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                        const Spacer(),
                        _dots(finished ? 7 : leg),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _glass(
                        child: Row(
                          children: [
                            const Text('🎧', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(caption,
                                  maxLines: 3,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      height: 1.5,
                                      fontSize: 13.5)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _glass(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                _roundBtn(
                                    started && playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    _toggle,
                                    big: true),
                                const SizedBox(width: 8),
                                _roundBtn(Icons.restart_alt_rounded, _restart),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _pill('بطيء', speed == .6,
                                          () => setState(() => speed = .6)),
                                      _pill('عادي', speed == 1.0,
                                          () => setState(() => speed = 1.0)),
                                      _pill('سريع', speed == 1.8,
                                          () => setState(() => speed = 1.8)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _pill(
                                    'تابعني',
                                    camMode == 0,
                                    () => setState(() {
                                          camMode = 0;
                                          _applyMode();
                                        })),
                                _pill(
                                    'حر',
                                    camMode == 1,
                                    () => setState(() {
                                          camMode = 1;
                                          _applyMode();
                                        })),
                                _pill(
                                    'من فوق',
                                    camMode == 2,
                                    () => setState(() {
                                          camMode = 2;
                                          _applyMode();
                                        })),
                                _pill('رجل', male,
                                    () => setState(() => male = true)),
                                _pill('امرأة', !male,
                                    () => setState(() => male = false)),
                                _pill('الأسماء', labels,
                                    () => setState(() => labels = !labels)),
                              ],
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
          if (finished)
            _finishCard(
              'تقبّل الله سعيك',
              'أتممت 7 أشواط على المروة. الخطوة الأخيرة: الحلق أو التقصير.',
              () => Navigator.pop(context),
              _restart,
            ),
        ],
      ),
    );
  }
}

class _SaiPainter extends CustomPainter {
  final _Sai3DPageState s;
  _SaiPainter(this.s) : super(repaint: s._frame);

  @override
  void paint(Canvas c, Size size) {
    final cam = s.cam;
    final rect = Offset.zero & size;
    c.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF06141B), Color(0xFF124038)],
          ).createShader(rect));

    // الأرضية
    c.drawPath(
        _path(cam, size,
            const [V3(-38, 0, -8), V3(38, 0, -8), V3(38, 0, 8), V3(-38, 0, 8)]),
        Paint()..color = const Color(0xFFEADFC9));
    // منطقة الهرولة
    c.drawPath(
        _path(cam, size, const [
          V3(-_Sai3DPageState.zoneHalf, .02, -8),
          V3(_Sai3DPageState.zoneHalf, .02, -8),
          V3(_Sai3DPageState.zoneHalf, .02, 8),
          V3(-_Sai3DPageState.zoneHalf, .02, 8)
        ]),
        Paint()..color = const Color(0x552EE59D));
    // الفاصل بين الاتجاهين
    final d1 = cam.project(const V3(-36, .03, 0), size).o;
    final d2 = cam.project(const V3(36, .03, 0), size).o;
    c.drawLine(
        d1,
        d2,
        Paint()
          ..color = const Color(0x88B8935A)
          ..strokeWidth = 2);

    final items = <_Item>[];

    // جدران جانبية
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

    // العلمان الأخضران
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

    // الصفا والمروة
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
        // قوس
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

    // الزحام
    for (final n in s.npcs) {
      final depth = cam.project(V3(n.x, 0, n.z), size).depth;
      items.add(_Item(depth, () {
        final run = n.x.abs() < _Sai3DPageState.zoneHalf && n.kind == 0;
        _drawPilgrim(c, cam, size, n.x, n.z, n.kind,
            tint: n.tint, lift: (run ? .12 : .05) * math.sin(n.x * 1.9).abs());
      }));
    }

    // أنت
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

      lab('الصفا', const V3(_Sai3DPageState.safa + 4, 8.5, 0));
      lab('المروة', const V3(_Sai3DPageState.marwa - 4, 8.5, 0));
      lab('العلمان الأخضران', const V3(0, 5.6, -8.3));
    }
    final t = cam.project(V3(s.x, 2.6, s.z), size);
    _tag(c, 'أنت', t.o,
        bg: AppColors.gold, fg: const Color(0xFF3B2A00), size: 12);

    c.drawRect(
        rect,
        Paint()
          ..shader = const RadialGradient(
            colors: [Colors.transparent, Color(0x66000000)],
            stops: [.62, 1],
          ).createShader(rect));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
