import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../umrah/umrah_voice.dart';
import 'hajj_data.dart';

// ═══════════════════════════════════════════════════════════
//  Hajj standalone 3D engine
//  This file intentionally does NOT depend on umrah_3d.dart.
// ═══════════════════════════════════════════════════════════

class V3 {
  final double x;
  final double y;
  final double z;

  const V3(this.x, this.y, this.z);

  V3 operator +(V3 other) => V3(x + other.x, y + other.y, z + other.z);
  V3 operator -(V3 other) => V3(x - other.x, y - other.y, z - other.z);
  V3 operator *(double value) => V3(x * value, y * value, z * value);
}

class P3 {
  final Offset o;
  final double depth;
  final double k;

  const P3(this.o, this.depth, this.k);
}

class Cam {
  double yaw;
  double pitch;
  double dist;
  V3 target;

  Cam({
    required this.yaw,
    required this.pitch,
    required this.dist,
    required this.target,
  });

  P3 project(V3 p, Size size) {
    final dx = p.x - target.x;
    final dy = p.y - target.y;
    final dz = p.z - target.z;

    final cy = math.cos(yaw);
    final sy = math.sin(yaw);

    final x1 = dx * cy - dz * sy;
    final z1 = dx * sy + dz * cy;

    final cp = math.cos(pitch);
    final sp = math.sin(pitch);

    final y2 = dy * cp - z1 * sp;
    final z2 = dy * sp + z1 * cp;

    final depth = dist - z2;
    final safeDepth = math.max(1.0, depth);
    final focal = math.min(size.width, size.height) * 1.05;
    final k = focal / safeDepth;

    return P3(
      Offset(
        size.width / 2 + x1 * k,
        size.height / 2 - y2 * k,
      ),
      depth,
      k,
    );
  }
}

class Item3D {
  final double depth;
  final VoidCallback draw;

  const Item3D(this.depth, this.draw);
}

Path path3D(Cam cam, Size size, List<V3> points) {
  final path = Path();
  if (points.isEmpty) return path;

  final first = cam.project(points.first, size).o;
  path.moveTo(first.dx, first.dy);

  for (int i = 1; i < points.length; i++) {
    final p = cam.project(points[i], size).o;
    path.lineTo(p.dx, p.dy);
  }

  path.close();
  return path;
}

Color _shade3D(Color color, double factor) {
  final f = factor.clamp(0.0, 1.5).toDouble();

  int channel(int value) => (value * f).round().clamp(0, 255).toInt();

  return Color.fromARGB(
    color.alpha,
    channel(color.red),
    channel(color.green),
    channel(color.blue),
  );
}

void drawBox3D(
  Canvas canvas,
  Cam cam,
  Size size,
  V3 min,
  V3 max,
  Color color,
) {
  final v = <V3>[
    V3(min.x, min.y, min.z),
    V3(max.x, min.y, min.z),
    V3(max.x, min.y, max.z),
    V3(min.x, min.y, max.z),
    V3(min.x, max.y, min.z),
    V3(max.x, max.y, min.z),
    V3(max.x, max.y, max.z),
    V3(min.x, max.y, max.z),
  ];

  const faces = <List<int>>[
    [0, 1, 5, 4],
    [1, 2, 6, 5],
    [2, 3, 7, 6],
    [3, 0, 4, 7],
    [4, 5, 6, 7],
  ];

  final visible = <MapEntry<double, List<int>>>[];

  for (final face in faces) {
    double d = 0;
    for (final index in face) {
      d += cam.project(v[index], size).depth;
    }
    visible.add(MapEntry(d / face.length, face));
  }

  visible.sort((a, b) => b.key.compareTo(a.key));

  for (int i = 0; i < visible.length; i++) {
    final face = visible[i].value;
    final points = [for (final index in face) v[index]];

    canvas.drawPath(
      path3D(cam, size, points),
      Paint()
        ..color = _shade3D(color, 0.78 + i * 0.055)
        ..style = PaintingStyle.fill,
    );
  }
}

void drawPilgrim3D(
  Canvas canvas,
  Cam cam,
  Size size,
  double x,
  double z,
  int variant, {
  double lift = 0,
}) {
  final feet = cam.project(V3(x, lift, z), size);
  if (feet.depth <= 1) return;

  final bodyTop = cam.project(V3(x, 1.55 + lift, z), size);
  final head = cam.project(V3(x, 1.92 + lift, z), size);

  final bodyColor =
      variant == 0 ? const Color(0xFFF6F3EA) : const Color(0xFFE8E3D8);

  canvas.drawLine(
    feet.o,
    bodyTop.o,
    Paint()
      ..color = bodyColor
      ..strokeWidth = math.max(2.0, .42 * feet.k)
      ..strokeCap = StrokeCap.round,
  );

  canvas.drawCircle(
    head.o,
    math.max(1.8, .16 * head.k),
    Paint()..color = const Color(0xFFC98F65),
  );
}

Widget glass3D({
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.all(12),
}) {
  return Container(
    padding: padding,
    decoration: BoxDecoration(
      color: const Color(0xCC071322),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(.16)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.22),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

Widget roundBtn3D(
  IconData icon,
  VoidCallback onTap, {
  bool big = false,
}) {
  final size = big ? 54.0 : 44.0;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.green,
          border: Border.all(color: AppColors.gold.withOpacity(.75)),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: big ? 29 : 23,
        ),
      ),
    ),
  );
}

Widget pill3D(
  String text,
  bool selected,
  VoidCallback onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.gold : const Color(0xAA0B1B2A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? AppColors.gold : Colors.white24,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? const Color(0xFF3B2A00) : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

Widget dots3D(int count) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      7,
      (i) => Container(
        width: 9,
        height: 9,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i < count ? AppColors.gold : Colors.white24,
          border: Border.all(color: Colors.white30),
        ),
      ),
    ),
  );
}

void tag3D(
  Canvas canvas,
  String text,
  Offset center, {
  Color bg = const Color(0xCC0F5E45),
  Color fg = Colors.white,
  double size = 12,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: fg,
        fontSize: size,
        fontWeight: FontWeight.w800,
      ),
    ),
    textDirection: TextDirection.rtl,
  )..layout();

  final rect = Rect.fromCenter(
    center: center,
    width: painter.width + 18,
    height: painter.height + 10,
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(10)),
    Paint()..color = bg,
  );

  painter.paint(
    canvas,
    Offset(
      center.dx - painter.width / 2,
      center.dy - painter.height / 2,
    ),
  );
}

Widget finishCard3D(
  String title,
  String text,
  VoidCallback finish,
  VoidCallback replay,
) {
  return Positioned.fill(
    child: Container(
      color: Colors.black54,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: glass3D(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.gold,
              size: 54,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: replay,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('إعادة'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: finish,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('تم'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// محوّل الصوت: يربط مجسّمات الـ3D بمحرك النطق الحقيقي (UVoice).
/// كل ما تنطقه الرحلة ثلاثية الأبعاد يخرج بصوت عربي حقيقي.
class HajjVoice {
  HajjVoice._();

  static final HajjVoice I = HajjVoice._();

  Future<void> speak(String text, {double rate = .5}) async {
    try {
      await UVoice.I.speak(text, rate: rate);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await UVoice.I.stop();
    } catch (_) {}
  }
}

// ═══════════════════════════════════════════════════════════

//  أدوات مشتركة: سماء متغيرة (نهار/غروب/ليل) + تلال
// ═══════════════════════════════════════════════════════════

Color _mix(Color a, Color b, double t) =>
    Color.lerp(a, b, t.clamp(0.0, 1.0).toDouble())!;

final List<Offset> _stars = () {
  final r = math.Random(5);
  return [
    for (int i = 0; i < 70; i++) Offset(r.nextDouble(), r.nextDouble() * .55)
  ];
}();

/// e = ارتفاع الشمس من -1 إلى 1، sunX موضعها الأفقي (0..1)
void _sky(Canvas c, Size s, double e, double sunX) {
  const n1 = Color(0xFF040A18), n2 = Color(0xFF0B1D3A);
  const d1 = Color(0xFF2E2A5A), d2 = Color(0xFFFF8A4C);
  const a1 = Color(0xFF58B4EC), a2 = Color(0xFFD6EEFA);
  final top = e >= 0 ? _mix(d1, a1, e / .45) : _mix(d1, n1, -e / .3);
  final bot = e >= 0 ? _mix(d2, a2, e / .45) : _mix(d2, n2, -e / .3);
  final r = Offset.zero & s;
  c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bot],
        ).createShader(r));
  if (e < .05) {
    final a = ((.05 - e) * 4).clamp(0.0, 1.0).toDouble();
    for (final st in _stars) {
      c.drawCircle(Offset(st.dx * s.width, st.dy * s.height), 1.2,
          Paint()..color = Colors.white.withOpacity(a * .9));
    }
  }
  if (e > -.12) {
    final sy = s.height * (.48 - .36 * e);
    final sx = s.width * sunX;
    final rect = Rect.fromCircle(center: Offset(sx, sy), radius: 74);
    c.drawCircle(
        Offset(sx, sy),
        74,
        Paint()
          ..shader = const RadialGradient(
                  colors: [Color(0x99FFD27A), Color(0x00FFD27A)])
              .createShader(rect));
    c.drawCircle(Offset(sx, sy), 20, Paint()..color = const Color(0xFFFFE3A3));
  } else {
    c.drawCircle(Offset(s.width * .78, s.height * .14), 16,
        Paint()..color = const Color(0xFFF4F1DE));
  }
}

void _hill(Canvas c, Cam cam, Size sz, double x, double z, double k) {
  drawBox3D(c, cam, sz, V3(x - 9 * k, 0, z - 7 * k),
      V3(x + 9 * k, 2.2 * k, z + 7 * k), const Color(0xFF8E7A5A));
  drawBox3D(c, cam, sz, V3(x - 6.5 * k, 2.2 * k, z - 5 * k),
      V3(x + 6.5 * k, 4.4 * k, z + 5 * k), const Color(0xFF9C8765));
  drawBox3D(c, cam, sz, V3(x - 3.8 * k, 4.4 * k, z - 3 * k),
      V3(x + 3.8 * k, 6.4 * k, z + 3 * k), const Color(0xFFAB9672));
}

Widget _topBar(
        BuildContext context, String title, bool voice, VoidCallback toggle) =>
    Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
      child: Row(
        children: [
          const BackButton(color: Colors.white),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
          ),
          IconButton(
            onPressed: toggle,
            icon: Icon(
                voice ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: voice ? AppColors.gold : Colors.white54),
          ),
        ],
      ),
    );

// ═══════════════════════════════════════════════════════════
//  1) خريطة الرحلة ثلاثية الأبعاد مع ساعة الحج (نهار وليل)
// ═══════════════════════════════════════════════════════════

class _Site {
  final String name;
  final double x, z;
  const _Site(this.name, this.x, this.z);
}

const _sites = [
  _Site('مكة المكرمة', -46, 12),
  _Site('منى', -18, 4),
  _Site('مزدلفة', 8, 14),
  _Site('عرفة', 38, -6),
];

class HajjJourney3DPage extends StatefulWidget {
  const HajjJourney3DPage({super.key});
  @override
  State<HajjJourney3DPage> createState() => _JourneyState();
}

class _JourneyState extends State<HajjJourney3DPage>
    with SingleTickerProviderStateMixin {
  static const total = 112.0;
  final cam =
      Cam(yaw: math.pi, pitch: .8, dist: 105, target: const V3(-4, 0, 4));
  V3 focus = const V3(-4, 0, 4);
  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double h = 0, rate = 3, _base = 105;
  bool playing = false, voice = true;
  int _spoken = -1;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    HajjVoice.I.stop();
    super.dispose();
  }

  int get evIndex {
    int k = 0;
    for (int i = 0; i < hajjTimeline.length; i++) {
      if (hajjTimeline[i].h <= h) k = i;
    }
    return k;
  }

  double get tod => (6 + h) % 24;
  double get elev => math.sin(2 * math.pi * (tod - 6) / 24);
  int get day => 8 + ((h + 6) / 24).floor();

  String get dayName {
    switch (day) {
      case 8:
        return 'يوم التروية';
      case 9:
        return 'يوم عرفة';
      case 10:
        return 'يوم النحر';
      case 11:
        return 'أول أيام التشريق';
      default:
        return 'ثاني أيام التشريق';
    }
  }

  String get clock {
    final t = tod;
    final hh = t.floor(), mm = ((t - hh) * 60).floor();
    final ap = hh >= 12 ? 'م' : 'ص';
    final h12 = hh % 12 == 0 ? 12 : hh % 12;
    return '$h12:${mm.toString().padLeft(2, '0')} $ap';
  }

  /// موضع المعتمِر على الخريطة
  Offset pos() {
    final ev = hajjTimeline;
    final i = evIndex;
    final a = _sites[ev[i].site];
    if (i == ev.length - 1) return Offset(a.x, a.z);
    final b = _sites[ev[i + 1].site];
    final ts = math.max(ev[i].h, ev[i + 1].h - 2.5);
    final u = ((h - ts) / (ev[i + 1].h - ts)).clamp(0.0, 1.0).toDouble();
    final t = u * u * (3 - 2 * u);
    return Offset(a.x + (b.x - a.x) * t, a.z + (b.z - a.z) * t);
  }

  void _tick(Duration t) {
    final dt = _last == Duration.zero ? 0.0 : (t - _last).inMicroseconds / 1e6;
    _last = t;
    final d = math.min(dt, .05);
    if (playing) {
      h += rate * d;
      if (h >= total) {
        h = total;
        playing = false;
        setState(() {});
      }
    }
    final k = evIndex;
    if (k != _spoken) {
      _spoken = k;
      if (voice && playing) HajjVoice.I.speak(hajjTimeline[k].say);
      setState(() {});
    }
    final a = 1 - math.exp(-d * 4);
    cam.target = V3(cam.target.x + (focus.x - cam.target.x) * a, 0,
        cam.target.z + (focus.z - cam.target.z) * a);
    _frame.value++;
  }

  @override
  Widget build(BuildContext context) {
    final ev = hajjTimeline[evIndex];
    return Scaffold(
      backgroundColor: const Color(0xFF040A18),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: (_) => _base = cam.dist,
              onScaleUpdate: (d) {
                cam.yaw += d.focalPointDelta.dx * .008;
                cam.pitch = (cam.pitch + d.focalPointDelta.dy * .006)
                    .clamp(.3, 1.45)
                    .toDouble();
                if (d.scale != 1) {
                  cam.dist = (_base / d.scale).clamp(35.0, 150.0).toDouble();
                }
              },
              child: CustomPaint(painter: _JourneyPainter(this)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(context, 'رحلة الحج ثلاثية الأبعاد', voice, () {
                  setState(() => voice = !voice);
                  if (!voice) HajjVoice.I.stop();
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: glass3D(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Text('$day ذو الحجة',
                            style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 18,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(width: 10),
                        Text(dayName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Icon(
                            elev > 0
                                ? Icons.wb_sunny_rounded
                                : Icons.nightlight_round,
                            color: elev > 0 ? AppColors.gold : Colors.white70,
                            size: 20),
                        const SizedBox(width: 6),
                        Text(clock,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: glass3D(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ev.title,
                            style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 15,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(ev.text,
                            maxLines: 3,
                            style: const TextStyle(
                                color: Colors.white,
                                height: 1.5,
                                fontSize: 13.5)),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.gold,
                            thumbColor: AppColors.gold,
                            inactiveTrackColor: Colors.white24,
                            overlayColor: Colors.white12,
                          ),
                          child: Slider(
                            value: h,
                            min: 0,
                            max: total,
                            onChanged: (v) => setState(() => h = v),
                          ),
                        ),
                        Row(
                          children: [
                            roundBtn3D(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded, () {
                              if (h >= total) h = 0;
                              setState(() => playing = !playing);
                              if (!playing) HajjVoice.I.stop();
                            }, big: true),
                            const SizedBox(width: 10),
                            roundBtn3D(Icons.record_voice_over_rounded,
                                () => HajjVoice.I.speak(ev.say)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  pill3D('بطيء', rate == 1.5,
                                      () => setState(() => rate = 1.5)),
                                  pill3D('عادي', rate == 3,
                                      () => setState(() => rate = 3)),
                                  pill3D('سريع', rate == 6,
                                      () => setState(() => rate = 6)),
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
                            for (final s in _sites)
                              pill3D(s.name, false, () {
                                setState(() => focus = V3(s.x, 0, s.z));
                              }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyPainter extends CustomPainter {
  final _JourneyState s;
  _JourneyPainter(this.s) : super(repaint: s._frame);

  @override
  void paint(Canvas c, Size size) {
    final cam = s.cam;
    final e = s.elev;
    final tod = s.tod;
    final sunX = (tod >= 6 && tod <= 18) ? .12 + .76 * (tod - 6) / 12 : .5;
    _sky(c, size, e, sunX);

    // الأرض
    c.drawPath(
        path3D(cam, size, const [
          V3(-120, 0, -70),
          V3(120, 0, -70),
          V3(120, 0, 70),
          V3(-120, 0, 70)
        ]),
        Paint()..color = const Color(0xFFCDB68C));

    // الطريق بين المحطات (مكة ← منى ← مزدلفة ← عرفة)
    final order = [0, 1, 2, 3];
    for (int i = 0; i < order.length - 1; i++) {
      final a =
          cam.project(V3(_sites[order[i]].x, .05, _sites[order[i]].z), size).o;
      final b = cam
          .project(
              V3(_sites[order[i + 1]].x, .05, _sites[order[i + 1]].z), size)
          .o;
      c.drawLine(
          a,
          b,
          Paint()
            ..color = const Color(0x55FFFFFF)
            ..strokeWidth = 10
            ..strokeCap = StrokeCap.round);
      c.drawLine(
          a,
          b,
          Paint()
            ..color = const Color(0xFFD9B45A)
            ..strokeWidth = 2);
    }

    final items = <Item3D>[];

    // تلال محيطة
    for (final p in const [
      [-30.0, -30.0, 1.4],
      [10.0, -34.0, 1.8],
      [-60.0, -20.0, 1.3],
      [60.0, -30.0, 1.6],
      [-10.0, 40.0, 1.5],
      [40.0, 38.0, 1.4],
      [-70.0, 40.0, 1.6],
    ]) {
      items.add(Item3D(cam.project(V3(p[0], 2, p[1]), size).depth,
          () => _hill(c, cam, size, p[0], p[1], p[2])));
    }

    // مكة: الكعبة والمآذن
    const m = _Site('', -46, 12);
    items.add(Item3D(cam.project(const V3(-46, 2, 12), size).depth, () {
      c.drawPath(
          path3D(cam, size, [
            for (int i = 0; i < 28; i++)
              V3(m.x + 8 * math.cos(i * math.pi / 14), .03,
                  m.z + 8 * math.sin(i * math.pi / 14))
          ]),
          Paint()..color = const Color(0xFFEADFC9));
      drawBox3D(c, cam, size, V3(m.x - 1.7, 0, m.z - 1.5),
          V3(m.x + 1.7, 3.5, m.z + 1.5), const Color(0xFF2B2B2B));
      drawBox3D(c, cam, size, V3(m.x - 1.72, 2.5, m.z - 1.52),
          V3(m.x + 1.72, 2.9, m.z + 1.52), const Color(0xFFD9B45A));
      for (final dx in [-7.0, 7.0]) {
        for (final dz in [-7.0, 7.0]) {
          drawBox3D(c, cam, size, V3(m.x + dx - .4, 0, m.z + dz - .4),
              V3(m.x + dx + .4, 9, m.z + dz + .4), const Color(0xFFF2EBDD));
        }
      }
    }));

    // منى: خيام وجمرات
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 4; j++) {
        final tx = -26.0 + i * 3.4, tz = -3.0 + j * 3.4;
        items.add(Item3D(cam.project(V3(tx, .5, tz), size).depth, () {
          drawBox3D(c, cam, size, V3(tx - 1.1, 0, tz - 1.1),
              V3(tx + 1.1, 1.3, tz + 1.1), const Color(0xFFF4F1E8));
        }));
      }
    }
    items.add(Item3D(cam.project(const V3(-6, 2, 4), size).depth, () {
      for (int k = 0; k < 3; k++) {
        drawBox3D(c, cam, size, V3(-8 + k * 2.4, 0, 2.8),
            V3(-7.4 + k * 2.4, 3, 5.2), const Color(0xFFC8C2B4));
      }
    }));

    // مزدلفة: أعمدة إنارة
    for (int k = 0; k < 5; k++) {
      final lx = 2.0 + k * 3.0, lz = 10.0 + (k.isEven ? 0 : 5.0);
      items.add(Item3D(cam.project(V3(lx, 1, lz), size).depth, () {
        drawBox3D(c, cam, size, V3(lx - .15, 0, lz - .15),
            V3(lx + .15, 3.2, lz + .15), const Color(0xFF5A5A5A));
        if (e < .1) {
          final p = cam.project(V3(lx, 3.4, lz), size);
          c.drawCircle(
              p.o,
              .9 * p.k,
              Paint()
                ..color = const Color(0xAAFFD27A)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        }
      }));
    }

    // عرفة: جبل الرحمة ومنارته البيضاء
    items.add(Item3D(cam.project(const V3(42, 2, -12), size).depth, () {
      _hill(c, cam, size, 42, -12, .9);
      drawBox3D(c, cam, size, const V3(41.7, 5.8, -12.3),
          const V3(42.3, 9.4, -11.7), const Color(0xFFF7F4EA));
    }));
    for (int k = 0; k < 12; k++) {
      final tx = 30.0 + (k % 4) * 3.2, tz = -2.0 + (k ~/ 4) * 3.2;
      items.add(Item3D(cam.project(V3(tx, .5, tz), size).depth, () {
        drawBox3D(c, cam, size, V3(tx - 1.1, 0, tz - 1.1),
            V3(tx + 1.1, 1.3, tz + 1.1), const Color(0xFFF4F1E8));
      }));
    }

    // مؤشر موضعك
    final pp = s.pos();
    items.add(Item3D(cam.project(V3(pp.dx, 1, pp.dy), size).depth, () {
      final g = cam.project(V3(pp.dx, 0, pp.dy), size);
      final bob = 1.8 + .25 * math.sin(s.h * 8);
      final top = cam.project(V3(pp.dx, 3.2 + bob, pp.dy), size);
      c.drawOval(
          Rect.fromCenter(
              center: g.o,
              width: 4.5 * g.k,
              height: 4.5 * g.k * math.max(.25, math.sin(cam.pitch))),
          Paint()..color = AppColors.gold.withOpacity(.35));
      c.drawLine(
          g.o,
          top.o,
          Paint()
            ..color = AppColors.gold
            ..strokeWidth = math.max(2.0, .35 * g.k)
            ..strokeCap = StrokeCap.round);
      c.drawCircle(
          top.o, math.max(5.0, 1.3 * g.k), Paint()..color = AppColors.gold);
      c.drawCircle(
          top.o, math.max(2.5, .6 * g.k), Paint()..color = Colors.white);
    }));

    items.sort((a, b) => b.depth.compareTo(a.depth));
    for (final it in items) {
      it.draw();
    }

    // تعتيم الليل
    if (e < 0) {
      c.drawRect(
          Offset.zero & size,
          Paint()
            ..color = const Color(0xFF020818)
                .withOpacity((-e).clamp(0.0, 1.0).toDouble() * .5));
    }

    // الأسماء
    final cur = hajjTimeline[s.evIndex].site;
    for (int i = 0; i < _sites.length; i++) {
      final q = cam.project(V3(_sites[i].x, 11, _sites[i].z), size);
      if (q.depth > 1) {
        tag3D(c, _sites[i].name, q.o,
            bg: i == cur ? AppColors.gold : const Color(0xCC0F5E45),
            fg: i == cur ? const Color(0xFF3B2A00) : Colors.white,
            size: 12);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════════════════════════════════════════
//  2) غروب عرفة: ابقَ حتى الغروب
// ═══════════════════════════════════════════════════════════

class HajjArafat3DPage extends StatefulWidget {
  const HajjArafat3DPage({super.key});
  @override
  State<HajjArafat3DPage> createState() => _ArafatState();
}

class _ArafatState extends State<HajjArafat3DPage>
    with SingleTickerProviderStateMixin {
  final cam =
      Cam(yaw: math.pi, pitch: .36, dist: 40, target: const V3(0, 3, -6));
  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final List<Offset> crowd = [];
  final List<Offset> near = [];
  double u = 0, speed = 1, _base = 40;
  bool playing = false, voice = true;
  int count = 0, _phase = -1;
  String caption = 'اضغط ▶ لتعيش وقفة عرفة من الزوال حتى الغروب.';

  @override
  void initState() {
    super.initState();
    final r = math.Random(21);
    while (crowd.length < 280) {
      final x = -30 + r.nextDouble() * 60, z = -16 + r.nextDouble() * 30;
      if ((x - 0).abs() < 12 && z < -10) continue;
      crowd.add(Offset(x, z));
    }
    for (int i = 0; i < 60; i++) {
      near.add(Offset(-16 + r.nextDouble() * 32, -4 + r.nextDouble() * 14));
    }
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    HajjVoice.I.stop();
    super.dispose();
  }

  double get elev => math.cos(u * math.pi / 2);

  int get phase {
    if (u < .06) return 0;
    if (u < .3) return 1;
    if (u < .8) return 2;
    if (u < 1) return 3;
    return 4;
  }

  static const _caps = [
    'بعد الزوال: صلِّ الظهر والعصر جمع تقديم قصرًا.',
    'تفرّغ للذكر والدعاء مستقبل القبلة رافعًا يديك.',
    'أكثر من: لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
    'اقترب الغروب: لا تنصرف حتى تغيب الشمس.',
    'غربت الشمس ✓ انصرف إلى مزدلفة بسكينة.',
  ];
  static const _says = [
    'حان الزوال. صلِّ الظهر والعصر جمع تقديم قصرًا.',
    'تفرّغ الآن للذكر والدعاء مستقبل القبلة رافعًا يديك.',
    'أكثر من: لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
    'اقترب الغروب. لا تنصرف حتى تغيب الشمس.',
    'غربت الشمس. انصرف إلى مزدلفة بسكينة.',
  ];

  void _tick(Duration t) {
    final dt = _last == Duration.zero ? 0.0 : (t - _last).inMicroseconds / 1e6;
    _last = t;
    final d = math.min(dt, .05);
    if (playing) {
      u += d * speed / 55;
      if (u >= 1.18) {
        u = 1.18;
        playing = false;
      }
      final p = phase;
      if (p != _phase) {
        _phase = p;
        caption = _caps[p];
        if (voice) HajjVoice.I.speak(_says[p]);
        if (p == 4) HapticFeedback.heavyImpact();
        setState(() {});
      }
    }
    _frame.value++;
  }

  @override
  Widget build(BuildContext context) {
    final sunset = u >= 1;
    return Scaffold(
      backgroundColor: const Color(0xFF040A18),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: (_) => _base = cam.dist,
              onScaleUpdate: (d) {
                cam.yaw += d.focalPointDelta.dx * .008;
                cam.pitch = (cam.pitch + d.focalPointDelta.dy * .006)
                    .clamp(.15, 1.2)
                    .toDouble();
                if (d.scale != 1) {
                  cam.dist = (_base / d.scale).clamp(18.0, 80.0).toDouble();
                }
              },
              child: CustomPaint(painter: _ArafatPainter(this)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(context, 'غروب عرفة', voice, () {
                  setState(() => voice = !voice);
                  if (!voice) HajjVoice.I.stop();
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: glass3D(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Column(
                      children: [
                        Row(
                          children: const [
                            Text('الزوال',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Spacer(),
                            Text('الغروب',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (u / 1).clamp(0.0, 1.0).toDouble(),
                            minHeight: 8,
                            color: AppColors.gold,
                            backgroundColor: Colors.white24,
                          ),
                        ),
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
                      glass3D(
                        child: Row(
                          children: [
                            Text(sunset ? '🌇' : '🎧',
                                style: const TextStyle(fontSize: 22)),
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
                      glass3D(
                        child: Row(
                          children: [
                            roundBtn3D(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded, () {
                              if (u >= 1.18) u = 0;
                              setState(() => playing = !playing);
                              if (!playing) HajjVoice.I.stop();
                            }, big: true),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => count++);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFFD9B45A),
                                    Color(0xFFB88A2E)
                                  ]),
                                ),
                                child: Column(
                                  children: [
                                    const Text('سبّح ولا إله إلا الله',
                                        style: TextStyle(
                                            color: Color(0xFF3B2A00),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12)),
                                    Text('$count',
                                        style: const TextStyle(
                                            color: Color(0xFF3B2A00),
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            Wrap(
                              spacing: 6,
                              children: [
                                pill3D('1×', speed == 1,
                                    () => setState(() => speed = 1)),
                                pill3D('3×', speed == 3,
                                    () => setState(() => speed = 3)),
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
          if (sunset)
            finishCard3D(
              'غربت الشمس',
              'بقيتَ على عرفة حتى الغروب. الآن انصرف إلى مزدلفة بسكينة، وأكثر من الذكر في الطريق.',
              () => Navigator.pop(context),
              () => setState(() {
                u = 0;
                _phase = -1;
                playing = false;
                caption = 'اضغط ▶ لتعيش وقفة عرفة من الزوال حتى الغروب.';
              }),
            ),
        ],
      ),
    );
  }
}

class _ArafatPainter extends CustomPainter {
  final _ArafatState s;
  _ArafatPainter(this.s) : super(repaint: s._frame);

  @override
  void paint(Canvas c, Size size) {
    final cam = s.cam;
    final e = s.elev;
    _sky(c, size, e, .35 + .45 * s.u.clamp(0.0, 1.2).toDouble());

    c.drawPath(
        path3D(cam, size, const [
          V3(-120, 0, -70),
          V3(120, 0, -70),
          V3(120, 0, 70),
          V3(-120, 0, 70)
        ]),
        Paint()..color = const Color(0xFFCDB68C));

    // حشود بعيدة (نقاط بيضاء)
    final dot = Paint()..color = Colors.white.withOpacity(.85);
    for (final p in s.crowd) {
      final q = cam.project(V3(p.dx, .3, p.dy), size);
      if (q.depth > 1) c.drawCircle(q.o, math.max(1.1, .32 * q.k), dot);
    }

    final items = <Item3D>[];

    // جبل الرحمة
    items.add(Item3D(cam.project(const V3(0, 3, -22), size).depth, () {
      _hill(c, cam, size, 0, -22, 1.5);
      drawBox3D(c, cam, size, const V3(-.5, 9.6, -22.5),
          const V3(.5, 14.5, -21.5), const Color(0xFFF7F4EA));
    }));
    items.add(Item3D(cam.project(const V3(-30, 2, -24), size).depth,
        () => _hill(c, cam, size, -30, -24, 1.2)));
    items.add(Item3D(cam.project(const V3(34, 2, -26), size).depth,
        () => _hill(c, cam, size, 34, -26, 1.3)));

    // حدود عرفة ووادي عرنة
    for (int k = 0; k < 8; k++) {
      final bz = -22.0 + k * 5.5;
      items.add(Item3D(cam.project(V3(-36, 2, bz), size).depth, () {
        drawBox3D(c, cam, size, V3(-36.2, 0, bz - .2), V3(-35.8, 4.5, bz + .2),
            const Color(0xFFC0392B));
        drawBox3D(c, cam, size, V3(-36.3, 4.5, bz - .3),
            V3(-35.7, 5.1, bz + .3), Colors.white);
      }));
    }
    items.add(Item3D(cam.project(const V3(-48, 3, -2), size).depth, () {
      drawBox3D(c, cam, size, const V3(-56, 0, -8), const V3(-42, 6, 4),
          const Color(0xFFF2EBDD));
      for (final dz in [-8.0, 4.0]) {
        drawBox3D(c, cam, size, V3(-56, 0, dz - .6), V3(-55, 13, dz + .4),
            const Color(0xFFF7F4EA));
      }
    }));

    // خيام
    for (int k = 0; k < 10; k++) {
      final tx = -26.0 + k * 5.6, tz = 12.0;
      items.add(Item3D(cam.project(V3(tx, .5, tz), size).depth, () {
        drawBox3D(c, cam, size, V3(tx - 1.5, 0, tz - 1.4),
            V3(tx + 1.5, 1.6, tz + 1.4), const Color(0xFFF4F1E8));
      }));
    }

    // حجاج قريبون
    for (int i = 0; i < s.near.length; i++) {
      final p = s.near[i];
      items.add(Item3D(cam.project(V3(p.dx, 0, p.dy), size).depth, () {
        final lift = s.playing ? .03 * math.sin(s.u * 40 + i).abs() : 0.0;
        drawPilgrim3D(c, cam, size, p.dx, p.dy, i % 6 == 0 ? 1 : 0, lift: lift);
      }));
    }

    items.sort((a, b) => b.depth.compareTo(a.depth));
    for (final it in items) {
      it.draw();
    }

    if (e < 0) {
      c.drawRect(
          Offset.zero & size,
          Paint()
            ..color = const Color(0xFF020818)
                .withOpacity((-e).clamp(0.0, 1.0).toDouble() * .55));
    }

    void lab(String t, V3 p, {bool red = false}) {
      final q = cam.project(p, size);
      if (q.depth > 1) {
        tag3D(c, t, q.o,
            bg: red ? const Color(0xCCC0392B) : const Color(0xCC0F5E45),
            size: 11.5);
      }
    }

    lab('جبل الرحمة', const V3(0, 17, -22));
    lab('حدود عرفة', const V3(-36, 7, -2), red: true);
    lab('وادي عرنة: ليس من عرفة', const V3(-49, 14, -2), red: true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════════════════════════════════════════
//  3) رمي الجمرات: تدرّب بفيزياء حقيقية
// ═══════════════════════════════════════════════════════════

class HajjJamarat3DPage extends StatefulWidget {
  const HajjJamarat3DPage({super.key});
  @override
  State<HajjJamarat3DPage> createState() => _JamState();
}

class _JamState extends State<HajjJamarat3DPage>
    with SingleTickerProviderStateMixin {
  static const rx = 4.4, rz = 3.6, idealV = 10.7, throwZ = 13.0;
  final cam =
      Cam(yaw: math.pi, pitch: .3, dist: 25, target: const V3(0, 2.8, -1));
  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final List<Offset> crowd = [];

  int mode = 0; // 0 يوم النحر، 1 أيام التشريق
  int stage = 0, thrown = 0, attempts = 0;
  int assist = 0; // 0 قوية، 1 متوسطة، 2 بدون
  bool flying = false, voice = true, stageDone = false, allDone = false;
  V3 pp = const V3(0, 1.6, throwZ), vv = const V3(0, 0, 0);
  final List<V3> trail = [];
  String msg = 'اسحب بإصبعك بسرعة نحو الأعلى لرمي الحصاة.';

  List<String> get stages => mode == 0
      ? ['جمرة العقبة (الكبرى)']
      : ['الجمرة الصغرى', 'الجمرة الوسطى', 'جمرة العقبة (الكبرى)'];

  @override
  void initState() {
    super.initState();
    final r = math.Random(9);
    while (crowd.length < 34) {
      final x = -15 + r.nextDouble() * 30, z = -8 + r.nextDouble() * 17;
      final k = (x / (rx * 1.35)) * (x / (rx * 1.35)) +
          (z / (rz * 1.35)) * (z / (rz * 1.35));
      if (k < 1) continue;
      crowd.add(Offset(x, z));
    }
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    HajjVoice.I.stop();
    super.dispose();
  }

  void _tick(Duration t) {
    final dt = _last == Duration.zero ? 0.0 : (t - _last).inMicroseconds / 1e6;
    _last = t;
    final d = math.min(dt, .05);
    if (flying) _fly(d);
    _frame.value++;
  }

  void _fly(double d) {
    vv = V3(vv.x, vv.y - 9.8 * d, vv.z);
    pp = V3(pp.x + vv.x * d, pp.y + vv.y * d, pp.z + vv.z * d);
    trail.add(pp);
    if (trail.length > 26) trail.removeAt(0);
    if (pp.z < .6 && pp.z > -.6 && pp.x.abs() < 1.9 && pp.y > 0 && pp.y < 7.5) {
      _result(true, hit: true);
      return;
    }
    if (pp.y <= 0) {
      final ok = (pp.x / rx) * (pp.x / rx) + (pp.z / rz) * (pp.z / rz) <= 1;
      _result(ok);
    }
  }

  void _result(bool ok, {bool hit = false}) {
    flying = false;
    attempts++;
    if (ok) {
      thrown++;
      HapticFeedback.mediumImpact();
      msg = hit ? 'أصابت الجمرة وسقطت في الحوض ✓' : 'وقعت في الحوض ✓';
      if (voice) HajjVoice.I.speak('اللهُ أَكْبَر', rate: .55);
      if (thrown >= 7) _stageComplete();
    } else {
      HapticFeedback.heavyImpact();
      final side = pp.x.abs() > rx
          ? (pp.x > 0 ? ' ومالت إلى اليمين' : ' ومالت إلى اليسار')
          : '';
      msg = pp.z > rz
          ? 'قصّرت ولم تبلغ الحوض$side، فلا تُحتسب. أعد الرمي.'
          : 'تجاوزت الحوض$side، فلا تُحتسب. أعد الرمي.';
    }
    setState(() {});
  }

  void _stageComplete() {
    stageDone = true;
    final last = stage == stages.length - 1;
    if (last) {
      allDone = true;
      msg = 'أتممت رمي ${stages[stage]} ✓ لا تقف للدعاء بعدها وانصرف.';
      if (voice)
        HajjVoice.I.speak(
            'أتممت رمي ${stages[stage]}. لا تقف للدعاء بعد الجمرة الكبرى، وانصرف.');
    } else {
      msg =
          'أتممت ${stages[stage]} ✓ استقبل القبلة وادعُ دعاءً طويلًا، ثم انتقل إلى التالية.';
      if (voice) {
        HajjVoice.I.speak(
            'أتممت ${stages[stage]}. استقبل القبلة وادعُ دعاءً طويلًا، ثم انتقل إلى الجمرة التالية.');
      }
    }
  }

  void _next() {
    setState(() {
      stage++;
      thrown = 0;
      attempts = 0;
      stageDone = false;
      msg = 'ارمِ ${stages[stage]}: سبع حصيات.';
    });
  }

  void _resetAll() {
    setState(() {
      stage = 0;
      thrown = 0;
      attempts = 0;
      stageDone = false;
      allDone = false;
      flying = false;
      trail.clear();
      msg = 'اسحب بإصبعك بسرعة نحو الأعلى لرمي الحصاة.';
    });
  }

  void _throw(Offset v) {
    if (flying || stageDone) return;
    if (v.dy > -350) {
      setState(() => msg = 'اسحب بسرعة أكبر نحو الأعلى.');
      return;
    }
    var ang = math.atan2(v.dx, -v.dy).clamp(-.6, .6).toDouble();
    var vel = (v.distance / 120).clamp(7.0, 18.0).toDouble();
    final a = const [.75, .4, 0.0][assist];
    vel += (idealV - vel) * a;
    ang *= (1 - a);
    final vh = vel * .7071, vy = vel * .7071;
    vv = V3(vh * math.sin(ang), vy, -vh * math.cos(ang));
    pp = const V3(0, 1.6, throwZ);
    trail.clear();
    flying = true;
    HapticFeedback.selectionClick();
    setState(() => msg = 'كبّر: الله أكبر…');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF58B4EC),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanEnd: (d) => _throw(d.velocity.pixelsPerSecond),
              child: CustomPaint(painter: _JamPainter(this)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(context, 'رمي الجمرات', voice, () {
                  setState(() => voice = !voice);
                  if (!voice) HajjVoice.I.stop();
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: glass3D(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(stages[stage],
                                  style: const TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900)),
                            ),
                            dots3D(thrown),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('اجعل مكة عن يسارك ومنى عن يمينك إن تيسر',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11.5)),
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
                      glass3D(
                        child: Row(
                          children: [
                            const Text('🪨', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(msg,
                                  maxLines: 3,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      height: 1.5,
                                      fontSize: 13.5)),
                            ),
                            Text('محاولات $attempts',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      glass3D(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                pill3D('يوم النحر', mode == 0, () {
                                  mode = 0;
                                  _resetAll();
                                }),
                                pill3D('أيام التشريق', mode == 1, () {
                                  mode = 1;
                                  _resetAll();
                                }),
                                pill3D('مساعدة قوية', assist == 0,
                                    () => setState(() => assist = 0)),
                                pill3D('متوسطة', assist == 1,
                                    () => setState(() => assist = 1)),
                                pill3D('بدون', assist == 2,
                                    () => setState(() => assist = 2)),
                              ],
                            ),
                            if (stageDone && !allDone) ...[
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: _next,
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(colors: [
                                      AppColors.green,
                                      AppColors.greenDark
                                    ]),
                                    border: Border.all(color: AppColors.gold),
                                  ),
                                  child: const Text('الجمرة التالية ←',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (allDone)
            finishCard3D(
              'تقبّل الله رميك',
              'أتممت رمي جميع الجمرات بسبع حصيات لكل جمرة، بالتكبير والترتيب الصحيح.',
              () => Navigator.pop(context),
              _resetAll,
            ),
        ],
      ),
    );
  }
}

class _JamPainter extends CustomPainter {
  final _JamState s;
  _JamPainter(this.s) : super(repaint: s._frame);

  @override
  void paint(Canvas c, Size size) {
    final cam = s.cam;
    _sky(c, size, .9, .6);

    c.drawPath(
        path3D(cam, size, const [
          V3(-60, 0, -40),
          V3(60, 0, -40),
          V3(60, 0, 40),
          V3(-60, 0, 40)
        ]),
        Paint()..color = const Color(0xFFD9D4C6));

    // الحوض
    const rx = _JamState.rx, rz = _JamState.rz;
    c.drawPath(
        path3D(cam, size, [
          for (int i = 0; i < 40; i++)
            V3(rx * math.cos(i * math.pi / 20), .02,
                rz * math.sin(i * math.pi / 20))
        ]),
        Paint()..color = const Color(0xFF9E9684));
    final rim = Path();
    for (int i = 0; i <= 40; i++) {
      final o = cam
          .project(
              V3(rx * math.cos(i * math.pi / 20), .05,
                  rz * math.sin(i * math.pi / 20)),
              size)
          .o;
      i == 0 ? rim.moveTo(o.dx, o.dy) : rim.lineTo(o.dx, o.dy);
    }
    c.drawPath(
        rim,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFF6F6858));

    final items = <Item3D>[];

    // جسر الجمرات في الخلف
    items.add(Item3D(cam.project(const V3(0, 5, -15), size).depth, () {
      drawBox3D(c, cam, size, const V3(-30, 0, -16), const V3(30, 9, -14),
          const Color(0xFFDCD6C6));
      drawBox3D(c, cam, size, const V3(-30, 9, -16), const V3(30, 10.4, -8),
          const Color(0xFFCFC9B8));
    }));

    // الجمرة
    items.add(Item3D(cam.project(const V3(0, 4, 0), size).depth, () {
      drawBox3D(c, cam, size, const V3(-1.8, 0, -.5), const V3(1.8, 7.5, .5),
          const Color(0xFFCFC9B8));
      drawBox3D(c, cam, size, const V3(-2.1, 7.5, -.7), const V3(2.1, 8.2, .7),
          const Color(0xFFB8B09C));
    }));

    // الحجاج
    for (int i = 0; i < s.crowd.length; i++) {
      final p = s.crowd[i];
      items.add(Item3D(cam.project(V3(p.dx, 0, p.dy), size).depth, () {
        drawPilgrim3D(c, cam, size, p.dx, p.dy, i % 5 == 0 ? 1 : 0,
            lift: .04 * math.sin(i * 1.7 + s.pp.z).abs());
      }));
    }

    items.sort((a, b) => b.depth.compareTo(a.depth));
    for (final it in items) {
      it.draw();
    }

    // الحصاة ومسارها
    for (int i = 0; i < s.trail.length; i++) {
      final q = cam.project(s.trail[i], size);
      c.drawCircle(q.o, math.max(1.5, .05 * q.k * (i / s.trail.length)),
          Paint()..color = Colors.white.withOpacity(.5 * i / s.trail.length));
    }
    if (s.flying) {
      final g = cam.project(V3(s.pp.x, 0, s.pp.z), size);
      c.drawOval(
          Rect.fromCenter(center: g.o, width: .6 * g.k, height: .25 * g.k),
          Paint()..color = Colors.black26);
      final q = cam.project(s.pp, size);
      c.drawCircle(q.o, math.max(3.0, .14 * q.k),
          Paint()..color = const Color(0xFF6B6558));
      c.drawCircle(q.o.translate(-1, -1), math.max(1.2, .05 * q.k),
          Paint()..color = Colors.white54);
    }

    // مؤشر السحب
    if (!s.flying && !s.stageDone) {
      final y = size.height * .74 +
          6 * math.sin(DateTime.now().millisecondsSinceEpoch / 280);
      c.drawCircle(Offset(size.width / 2, size.height * .80), 11,
          Paint()..color = const Color(0xFF6B6558));
      final p = Path()
        ..moveTo(size.width / 2, y - 14)
        ..lineTo(size.width / 2 - 8, y)
        ..lineTo(size.width / 2 + 8, y)
        ..close();
      c.drawPath(p, Paint()..color = Colors.white.withOpacity(.85));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════════════════════════════════════════
//  4) مزدلفة: التقط سبع حصيات (ليلة العاشر → الفجر)
// ═══════════════════════════════════════════════════════════

class _Peb {
  final V3 p;
  final bool big;
  bool got = false;
  _Peb(this.p, this.big);
}

class HajjMuzdalifah3DPage extends StatefulWidget {
  const HajjMuzdalifah3DPage({super.key});
  @override
  State<HajjMuzdalifah3DPage> createState() => _MuzState();
}

class _MuzState extends State<HajjMuzdalifah3DPage>
    with SingleTickerProviderStateMixin {
  final cam = Cam(yaw: 0, pitch: .62, dist: 20, target: const V3(0, 0, 4));
  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;
  final List<_Peb> pebs = [];
  final List<Offset> crowd = [];
  int count = 0;
  bool voice = true, done = false;
  Size _size = Size.zero;
  String msg = 'المس الحصى الصغيرة (بحجم حبة الفول) والتقط منها سبعًا.';

  @override
  void initState() {
    super.initState();
    final r = math.Random(21);
    for (int k = 0; k < 36; k++) {
      pebs.add(_Peb(
          V3(-8 + r.nextDouble() * 16, 0, -1 + r.nextDouble() * 12), false));
    }
    for (int k = 0; k < 7; k++) {
      pebs.add(_Peb(
          V3(-8 + r.nextDouble() * 16, 0, -1 + r.nextDouble() * 12), true));
    }
    for (int k = 0; k < 16; k++) {
      crowd.add(Offset(-12 + r.nextDouble() * 24, -6 + r.nextDouble() * 3.5));
    }
    _ticker = createTicker((_) => _frame.value++)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (voice) {
        HajjVoice.I.speak(
            'وصلت مزدلفة. التقط سبع حصيات صغيرة بحجم حبة الفول لرمي جمرة العقبة. المس الحصى الصغيرة، وتجنب الحجارة الكبيرة.');
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    HajjVoice.I.stop();
    super.dispose();
  }

  void _tap(Offset pos) {
    if (done || _size == Size.zero) return;
    _Peb? best;
    double bd = 9999;
    for (final p in pebs) {
      if (p.got) continue;
      final q = cam.project(V3(p.p.x, .1, p.p.z), _size);
      if (q.depth <= 1) continue;
      final d = (q.o - pos).distance;
      final lim = p.big ? 38.0 : 32.0;
      if (d < lim && d < bd) {
        bd = d;
        best = p;
      }
    }
    if (best == null) {
      setState(() => msg = 'لا حصاة هنا، قرّب إصبعك من حصاة أخرى.');
      return;
    }
    if (best.big) {
      HapticFeedback.heavyImpact();
      setState(
          () => msg = 'هذا حجر كبير لا يصلح، الحصى بحجم حبة الفول تقريبًا.');
      if (voice) HajjVoice.I.speak('حجر كبير. اختر حصاة صغيرة بحجم حبة الفول.');
      return;
    }
    best.got = true;
    count++;
    HapticFeedback.mediumImpact();
    if (count >= 7) {
      done = true;
      msg = 'التقطت سبع حصيات ✓ ولا يلزم غسلها.';
      if (voice) {
        HajjVoice.I.speak(
            'أحسنت، التقطت سبع حصيات. لا يلزم غسلها. اذكر الله عند المشعر الحرام ثم انصرف إلى منى قبل شروق الشمس.');
      }
    } else {
      msg = 'التقطت $count من 7. تابع.';
    }
    setState(() {});
  }

  void _reset() {
    setState(() {
      for (final p in pebs) {
        p.got = false;
      }
      count = 0;
      done = false;
      msg = 'المس الحصى الصغيرة (بحجم حبة الفول) والتقط منها سبعًا.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040A18),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _tap(d.localPosition),
              onPanUpdate: (d) {
                cam.yaw =
                    (cam.yaw - d.delta.dx * .004).clamp(-.8, .8).toDouble();
                cam.pitch =
                    (cam.pitch + d.delta.dy * .002).clamp(.45, .85).toDouble();
              },
              child: CustomPaint(painter: _MuzPainter(this)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      roundBtn3D(
                          Icons.close_rounded, () => Navigator.pop(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: glass3D(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text('مزدلفة · التقط الحصى',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14)),
                              ),
                              dots3D(count),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      roundBtn3D(
                        voice
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        () {
                          setState(() => voice = !voice);
                          if (!voice) HajjVoice.I.stop();
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  glass3D(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(msg,
                              style: const TextStyle(
                                  color: Colors.white,
                                  height: 1.6,
                                  fontSize: 13.5)),
                        ),
                        roundBtn3D(Icons.refresh_rounded, _reset),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (done)
            finishCard3D(
              'أتممت التقاط الحصى',
              'سبع حصيات صغيرة لرمي جمرة العقبة. اذكر الله عند المشعر الحرام وادعُ حتى يُسفر الجو، ثم انصرف إلى منى قبل الشروق.',
              () => Navigator.pop(context),
              _reset,
            ),
        ],
      ),
    );
  }
}

class _MuzPainter extends CustomPainter {
  final _MuzState s;
  _MuzPainter(this.s) : super(repaint: s._frame);

  @override
  void paint(Canvas c, Size size) {
    s._size = size;
    final e = (-1.0 + s.count * .13).clamp(-1.0, 0.0).toDouble();
    final dawn = ((e + 1) / .9).clamp(0.0, 1.0).toDouble();
    _sky(c, size, e, .5);

    final hz = size.height * .32;
    final band =
        Rect.fromLTWH(0, hz - size.height * .22, size.width, size.height * .22);
    c.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x00FF8A4C),
            Color.fromRGBO(255, 138, 76, .55 * dawn),
          ],
        ).createShader(band),
    );
    final g = Rect.fromLTWH(0, hz, size.width, size.height - hz);
    c.drawRect(
      g,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _mix(const Color(0xFF1B2030), const Color(0xFF7A6652), dawn),
            _mix(const Color(0xFF0D1018), const Color(0xFF4A3F33), dawn),
          ],
        ).createShader(g),
    );

    // حجاج بعيدون
    for (final p in s.crowd) {
      drawPilgrim3D(c, s.cam, size, p.dx, p.dy, p.dx.toInt().abs() % 2);
    }

    final f = s.pebs.where((p) => !p.got).toList()
      ..sort((a, b) => a.p.z.compareTo(b.p.z));
    for (final p in f) {
      final q = s.cam.project(V3(p.p.x, 0, p.p.z), size);
      if (q.depth <= 1) continue;
      final r = math.max(2.0, (p.big ? .55 : .13) * q.k);
      if (!p.big) {
        final pulse = .10 + .08 * math.sin(s._frame.value / 10 + p.p.x);
        c.drawCircle(
            q.o, r * 3.4, Paint()..color = Colors.white.withOpacity(pulse));
      }
      c.drawOval(
        Rect.fromCenter(
            center: q.o.translate(0, r * .35), width: r * 2.3, height: r * .9),
        Paint()..color = Colors.black.withOpacity(.35),
      );
      c.drawOval(
        Rect.fromCenter(center: q.o, width: r * 2, height: r * 1.3),
        Paint()
          ..color = p.big ? const Color(0xFF8D8A85) : const Color(0xFFC9C3B4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
