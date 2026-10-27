import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'umrah_3d.dart' show Cam, V3, P3;

/// ════════════════════════════════════════════════════════════════════
///  RIFQA realism toolkit
///  نفس فكرة المحرك الأصلي (Canvas فقط، بدون WebView ولا مكتبات جديدة)
///  لكن بمنظور حقيقي، قصّ للمستوى القريب، إضاءة، ضباب، وأوقات صلاة.
///  المحاور كما في umrah_3d.dart: x شرق، y أعلى، z جنوب. الوحدة = متر.
/// ════════════════════════════════════════════════════════════════════

typedef VP = ({double x, double y, double z});

/// أبعاد الكعبة (متر) - مطابقة لملف الجولة الأصلي.
const double kaabaHw = 6.0, kaabaHd = 5.5, kaabaH = 13.0;

double clamp01(double v) => v < 0 ? 0.0 : (v > 1 ? 1.0 : v);
double mix(double a, double b, double t) => a + (b - a) * t;
double smooth(double t) {
  final x = clamp01(t);
  return x * x * (3 - 2 * x);
}

double angleMix(double a, double b, double t) {
  final d = math.atan2(math.sin(b - a), math.cos(b - a));
  return a + d * t;
}

int _ch(double v) => (v * 255).round().clamp(0, 255).toInt();

Color rgbaC(double r, double g, double b, [double a = 1]) =>
    Color.fromARGB(_ch(a), _ch(r), _ch(g), _ch(b));
Color mixC(Color a, Color b, double t) => Color.lerp(a, b, clamp01(t))!;
Color withA(Color c, double o) => c.withAlpha(_ch(o));
Color scaleC(Color c, double f) => rgbaC(c.r * f, c.g * f, c.b * f, c.a);

V3 v3Mix(V3 a, V3 b, double t) =>
    V3(mix(a.x, b.x, t), mix(a.y, b.y, t), mix(a.z, b.z, t));

// ───────────────────────── الكاميرا ─────────────────────────

/// كاميرا بزاوية رؤية (focal) وموضع أفق قابلين للتغيير.
/// ترث Cam فتعمل مع أي كود قديم يستدعي cam.project().
class RCam extends Cam {
  double focal, horizon;
  RCam({
    double yaw = -2.4,
    double pitch = .6,
    double dist = 42,
    V3 target = const V3(0, 3, 0),
    this.focal = 1.05,
    this.horizon = .375,
  }) : super(yaw: yaw, pitch: pitch, dist: dist, target: target);

  RCam copy() => RCam(
        yaw: yaw,
        pitch: pitch,
        dist: dist,
        target: target,
        focal: focal,
        horizon: horizon,
      );

  /// كاميرا تنطلق من عين المشاهد (eye) وتنظر بزاوية yaw/pitch.
  /// pos = target - (dist*cos(p)*sin(y), -dist*sin(p), dist*cos(p)*cos(y))
  factory RCam.fromEye(
    V3 eye, {
    required double yaw,
    double pitch = 0,
    double dist = 1.2,
    double focal = 1.05,
    double horizon = .375,
  }) {
    final cp = math.cos(pitch);
    return RCam(
      yaw: yaw,
      pitch: pitch,
      dist: dist,
      focal: focal,
      horizon: horizon,
      target: V3(
        eye.x + dist * cp * math.sin(yaw),
        eye.y - dist * math.sin(pitch),
        eye.z + dist * cp * math.cos(yaw),
      ),
    );
  }

  static RCam lerp(RCam a, RCam b, double t) => RCam(
        yaw: angleMix(a.yaw, b.yaw, t),
        pitch: mix(a.pitch, b.pitch, t),
        dist: mix(a.dist, b.dist, t),
        target: v3Mix(a.target, b.target, t),
        focal: mix(a.focal, b.focal, t),
        horizon: mix(a.horizon, b.horizon, t),
      );

  /// يمنع نزول الكاميرا تحت الأرض.
  void keepAboveGround([double minY = .7]) {
    final s = ((minY - target.y) / dist).clamp(-1.0, 1.0).toDouble();
    final lowest = math.asin(s);
    if (pitch < lowest) pitch = lowest;
  }

  @override
  P3 project(V3 p, Size s) {
    final t = target;
    final vx = p.x - t.x, vy = p.y - t.y, vz = p.z - t.z;
    final cy = math.cos(yaw), sy = math.sin(yaw);
    final x1 = vx * cy - vz * sy;
    final z1 = vx * sy + vz * cy;
    final cp = math.cos(pitch), sp = math.sin(pitch);
    final y2 = vy * cp + z1 * sp;
    final z2 = -vy * sp + z1 * cp;
    final depth = math.max(.5, z2 + dist);
    final k = s.width * focal / depth;
    return P3(
        Offset(s.width / 2 - x1 * k, s.height * horizon - y2 * k), depth, k);
  }
}

/// إسقاط كامل لإطار واحد: يحسب sin/cos مرة واحدة ويدعم قصّ المضلعات
/// عند مستوى الكاميرا القريب (حتى لا يختفي الأرض أو الجدران قرب العدسة).
class RifqaSceneView {
  RifqaSceneView(Cam c, this.size)
      : cam = c,
        cy = math.cos(c.yaw),
        sy = math.sin(c.yaw),
        cp = math.cos(c.pitch),
        sp = math.sin(c.pitch),
        focal = c is RCam ? c.focal : 1.05,
        hor = c is RCam ? c.horizon : .375,
        eye = c.pos;

  final Cam cam;
  final Size size;
  final double cy, sy, cp, sp, focal, hor;
  final V3 eye;

  /// اتجاه النظر الأفقي.
  double get fx => sy;
  double get fz => cy;

  VP view(V3 p) {
    final t = cam.target;
    final vx = p.x - t.x, vy = p.y - t.y, vz = p.z - t.z;
    final x1 = vx * cy - vz * sy;
    final z1 = vx * sy + vz * cy;
    final y2 = vy * cp + z1 * sp;
    final z2 = -vy * sp + z1 * cp;
    return (x: x1, y: y2, z: z2 + cam.dist);
  }

  Offset scr(VP p) {
    final k = size.width * focal / p.z;
    return Offset(size.width / 2 - p.x * k, size.height * hor - p.y * k);
  }

  double scaleAt(double depth) => size.width * focal / depth;

  /// نقطة على الشاشة أو null إن كانت خلف الكاميرا.
  Offset? pt(V3 p, {double near = .8}) {
    final q = view(p);
    return q.z < near ? null : scr(q);
  }

  P3 proj(V3 p) => cam.project(p, size);

  double depthOf(V3 p) => view(p).z;

  /// مضلع مقصوص على مستوى الكاميرا القريب (Sutherland–Hodgman).
  Path? poly(List<V3> pts, {double near = .8}) {
    final vs = [for (final p in pts) view(p)];
    final out = <Offset>[];
    for (var i = 0; i < vs.length; i++) {
      final a = vs[i], b = vs[(i + 1) % vs.length];
      final ain = a.z >= near, bin = b.z >= near;
      if (ain) out.add(scr(a));
      if (ain != bin) {
        final t = (near - a.z) / (b.z - a.z);
        out.add(scr((x: mix(a.x, b.x, t), y: mix(a.y, b.y, t), z: near)));
      }
    }
    if (out.length < 3) return null;
    final path = Path()..moveTo(out[0].dx, out[0].dy);
    for (var i = 1; i < out.length; i++) {
      path.lineTo(out[i].dx, out[i].dy);
    }
    return path..close();
  }

  /// نقاط خطّ متصل (للحلقات) مع تخطّي ما خلف الكاميرا.
  void strokeLoop(Canvas c, List<V3> pts, Paint paint) {
    Offset? prev;
    for (final p in pts) {
      final o = pt(p);
      if (o != null && prev != null) c.drawLine(prev, o, paint);
      prev = o;
    }
  }
}

// ───────────────────────── السماء وأوقات الصلاة ─────────────────────────

class Sky {
  const Sky({
    required this.top,
    required this.mid,
    required this.horizon,
    required this.fog,
    required this.ambient,
    required this.sunColor,
    required this.grade,
    required this.sunAz,
    required this.sunEl,
    required this.sunPower,
    required this.ambLevel,
    required this.lamps,
    required this.stars,
    required this.moon,
    required this.fogDens,
  });

  final Color top, mid, horizon, fog, ambient, sunColor, grade;
  final double sunAz, sunEl, sunPower, ambLevel, lamps, stars, moon, fogDens;

  static const names = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

  static const presets = <Sky>[
    // الفجر
    Sky(
        top: Color(0xFF0B1A3A),
        mid: Color(0xFF3A4F82),
        horizon: Color(0xFFF2A887),
        fog: Color(0xFF9AA0BC),
        ambient: Color(0xFF8E9FD0),
        sunColor: Color(0xFFFFB98A),
        grade: Color(0xFF5A6FB0),
        sunAz: 1.40,
        sunEl: -.02,
        sunPower: .18,
        ambLevel: .55,
        lamps: .9,
        stars: .35,
        moon: .25,
        fogDens: .0034),
    // الظهر
    Sky(
        top: Color(0xFF2E7BD0),
        mid: Color(0xFF79B6EA),
        horizon: Color(0xFFEAF4FB),
        fog: Color(0xFFDCE8F0),
        ambient: Color(0xFFBFD6F0),
        sunColor: Color(0xFFFFF6E0),
        grade: Color(0xFFFFFFFF),
        sunAz: .35,
        sunEl: 1.15,
        sunPower: 1.0,
        ambLevel: .62,
        lamps: 0,
        stars: 0,
        moon: 0,
        fogDens: .0022),
    // العصر (الساعة الذهبية)
    Sky(
        top: Color(0xFF3F78B9),
        mid: Color(0xFFB4C6D6),
        horizon: Color(0xFFF8DDB0),
        fog: Color(0xFFEBD2AA),
        ambient: Color(0xFFC9D2DE),
        sunColor: Color(0xFFFFD39A),
        grade: Color(0xFFFFB86B),
        sunAz: -1.05,
        sunEl: .55,
        sunPower: .95,
        ambLevel: .55,
        lamps: .08,
        stars: 0,
        moon: 0,
        fogDens: .0028),
    // المغرب
    Sky(
        top: Color(0xFF1B2A57),
        mid: Color(0xFF8C506C),
        horizon: Color(0xFFFF9A52),
        fog: Color(0xFFC88A6C),
        ambient: Color(0xFF8C86B0),
        sunColor: Color(0xFFFF8A40),
        grade: Color(0xFFFF7A3A),
        sunAz: -1.38,
        sunEl: .07,
        sunPower: .6,
        ambLevel: .5,
        lamps: .6,
        stars: .12,
        moon: 0,
        fogDens: .0032),
    // العشاء
    Sky(
        top: Color(0xFF020611),
        mid: Color(0xFF0A1A33),
        horizon: Color(0xFF1E3552),
        fog: Color(0xFF16263B),
        ambient: Color(0xFF5F78B0),
        sunColor: Color(0xFFB9CCFF),
        grade: Color(0xFF2B4A9A),
        sunAz: .9,
        sunEl: .85,
        sunPower: .30,
        ambLevel: .38,
        lamps: 1,
        stars: 1,
        moon: 1,
        fogDens: .0036),
  ];

  /// phase من 0 (الفجر) إلى 4 (العشاء) مع تدرّج سلس بينها.
  static Sky at(double phase) {
    final p = phase.clamp(0.0, 4.0).toDouble();
    final i = math.min(3, p.floor());
    return lerp(presets[i], presets[i + 1], smooth(p - i));
  }

  static Sky lerp(Sky a, Sky b, double t) => Sky(
        top: mixC(a.top, b.top, t),
        mid: mixC(a.mid, b.mid, t),
        horizon: mixC(a.horizon, b.horizon, t),
        fog: mixC(a.fog, b.fog, t),
        ambient: mixC(a.ambient, b.ambient, t),
        sunColor: mixC(a.sunColor, b.sunColor, t),
        grade: mixC(a.grade, b.grade, t),
        sunAz: mix(a.sunAz, b.sunAz, t),
        sunEl: mix(a.sunEl, b.sunEl, t),
        sunPower: mix(a.sunPower, b.sunPower, t),
        ambLevel: mix(a.ambLevel, b.ambLevel, t),
        lamps: mix(a.lamps, b.lamps, t),
        stars: mix(a.stars, b.stars, t),
        moon: mix(a.moon, b.moon, t),
        fogDens: mix(a.fogDens, b.fogDens, t),
      );

  /// اتجاه الشمس (أو القمر ليلًا) كمتجه وحدة يشير نحوها.
  V3 get light {
    final ce = math.cos(sunEl);
    return V3(ce * math.sin(sunAz), math.sin(sunEl), ce * math.cos(sunAz));
  }

  double get dayLum => (ambLevel * .9 + sunPower * .45).clamp(.16, 1.0).toDouble();

  double sunAt(V3 n) {
    final l = light;
    return math.max(0.0, n.x * l.x + n.y * l.y + n.z * l.z) * sunPower;
  }

  /// إضاءة سطح بعمودي n: (محيطة + شمس) كقيم rgb.
  ({double r, double g, double b}) lightAt(V3 n) {
    final s = sunAt(n);
    final a = ambLevel * (.55 + .45 * (n.y * .5 + .5));
    return (
      r: ambient.r * a + sunColor.r * s,
      g: ambient.g * a + sunColor.g * s,
      b: ambient.b * a + sunColor.b * s,
    );
  }

  Color shade(Color base, V3 n, {double boost = 1}) {
    final l = lightAt(n);
    return rgbaC(
        base.r * l.r * boost, base.g * l.g * boost, base.b * l.b * boost, base.a);
  }

  /// نسبة الضباب عند مسافة d (0..1).
  double fogT(double d) {
    final near = 1 - math.exp(-d * fogDens);
    final far = smooth((d - 120) / 160) * .9;
    return clamp01(near + far);
  }

  Color fogged(Color c, double depth, [double strength = 1]) =>
      mixC(c, fog, fogT(depth) * strength);

  /// ارتفاع الظلّ: طول الظلّ لكل متر ارتفاع.
  double get shadowStretch {
    final el = math.max(sunEl, .2);
    return math.min(6.0, 1 / math.tan(el));
  }

  /// قوة الظلّ المرسوم على الأرض.
  double get shadowAlpha =>
      clamp01(sunPower * 1.1) * smooth((sunEl + .02) / .12);

  /// اتجاه سقوط الظلّ على الأرض (xz).
  Offset get shadowDir => Offset(-math.sin(sunAz), -math.cos(sunAz));
}

// ───────────────────────── أدوات الرسم ─────────────────────────

class TextCache {
  static final Map<String, TextPainter> _m = {};
  static TextPainter get(String text, double size, Color color,
      {FontWeight weight = FontWeight.w800}) {
    final key = '$text|$size|${color.hashCode}|${weight.index}';
    var tp = _m[key];
    if (tp == null) {
      if (_m.length > 160) _m.clear();
      tp = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                fontSize: size, color: color, fontWeight: weight, height: 1.1)),
        textDirection: TextDirection.rtl,
      )..layout();
      _m[key] = tp;
    }
    return tp;
  }
}

/// يرسم سطحًا مستطيلًا بخامة صورة بتقسيم حقيقي في العالم ثم إسقاط كل رأس
/// بمنظور صحيح، مع لون إضاءة لكل رأس (tint). [corners] = أعلى-يسار، أعلى-يمين،
/// أسفل-يمين، أسفل-يسار كما في الخامات الأصلية.
void texturedQuad(
  Canvas canvas,
  RifqaSceneView v,
  ui.Image tex,
  List<V3> corners, {
  int nu = 12,
  int nv = 12,
  Color Function(double u, double t)? tint,
  double repeatU = 1,
  double repeatV = 1,
  double near = .9,
}) {
  if (corners.length != 4) return;
  final pos = <double>[];
  final uvs = <double>[];
  final cols = <int>[];
  final ok = <bool>[];
  final w = tex.width.toDouble(), h = tex.height.toDouble();
  for (var j = 0; j <= nv; j++) {
    final t = j / nv;
    for (var i = 0; i <= nu; i++) {
      final u = i / nu;
      final top = v3Mix(corners[0], corners[1], u);
      final bot = v3Mix(corners[3], corners[2], u);
      final p = v3Mix(top, bot, t);
      final q = v.view(p);
      final valid = q.z >= near;
      ok.add(valid);
      final o = valid ? v.scr(q) : Offset.zero;
      pos..add(o.dx)..add(o.dy);
      uvs..add(u * w * repeatU)..add(t * h * repeatV);
      cols.add((tint?.call(u, t) ?? Colors.white).toARGB32());
    }
  }
  final idx = <int>[];
  final stride = nu + 1;
  for (var j = 0; j < nv; j++) {
    for (var i = 0; i < nu; i++) {
      final a = j * stride + i, b = a + 1, d = a + stride, e = d + 1;
      if (ok[a] && ok[b] && ok[d] && ok[e]) idx.addAll([a, b, d, b, e, d]);
    }
  }
  if (idx.isEmpty) return;
  final m = Float64List(16);
  m[0] = m[5] = m[10] = m[15] = 1;
  final shader = ui.ImageShader(
      tex, ui.TileMode.repeated, ui.TileMode.repeated, m,
      filterQuality: FilterQuality.medium);
  final verts = ui.Vertices.raw(
    ui.VertexMode.triangles,
    Float32List.fromList(pos),
    textureCoordinates: Float32List.fromList(uvs),
    colors: Int32List.fromList(cols),
    indices: Uint16List.fromList(idx),
  );
  canvas.drawVertices(
      verts, BlendMode.modulate, Paint()..shader = shader..isAntiAlias = true);
  verts.dispose();
  shader.dispose();
}

/// وهج ناعم مضاف (للأضواء والشمس).
void glow(Canvas c, Offset at, double radius, Color color,
    {BlendMode mode = BlendMode.plus}) {
  if (radius < 1) return;
  final rect = Rect.fromCircle(center: at, radius: radius);
  c.drawCircle(
      at,
      radius,
      Paint()
        ..blendMode = mode
        ..shader = RadialGradient(
          colors: [color, withA(color, color.a * .35), withA(color, 0)],
          stops: const [0, .35, 1],
        ).createShader(rect));
}