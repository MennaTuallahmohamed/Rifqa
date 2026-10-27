import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'umrah_3d.dart' show Cam, V3;
import 'umrah_3d_materials.dart';
import 'umrah_realism.dart';

/// ════════════════════════════════════════════════════════════════════
///  عالم الحرم المرسوم بالكود: سماء بأوقات الصلاة، جبال، أفق مكة، رواق بأقواس،
///  أرضية رخام لامعة بانعكاس، كعبة مضاءة بظلال، زحام حجاج، حمام، أشعة شمس.
///  مجسّم توضيحي وليس تصويرًا حقيقيًا ولا مسحًا جغرافيًا.
/// ════════════════════════════════════════════════════════════════════

class WorldState {
  const WorldState({
    required this.clock,
    required this.sky,
    this.materials,
    this.quality = 2,
    this.youAngle = 0,
    this.youRadius = 16,
    this.youVisible = false,
    this.youTrail = 0,
    this.hideYouBody = false,
    this.glow = 0,
    this.labels = false,
  });

  /// ثواني العالم (تستمر حتى أثناء الإيقاف المؤقت ليبقى المكان حيًّا).
  final double clock;
  final Sky sky;
  final Umrah3DMaterials? materials;

  /// 0 منخفضة، 1 متوسطة، 2 عالية.
  final int quality;
  final double youAngle, youRadius, youTrail, glow;
  final bool youVisible, hideYouBody, labels;
}

class _Item {
  _Item(this.depth, this.draw);
  final double depth;
  final VoidCallback draw;
}

class _Ped {
  const _Ped(this.radius, this.phase, this.pace, this.height, this.kind,
      this.skin, this.tone);
  final double radius, phase, pace, height, tone;
  final int kind;
  final Color skin;
}

class _Bird {
  const _Bird(this.radius, this.height, this.speed, this.phase, this.flap);
  final double radius, height, speed, phase, flap;
}

class _Block {
  const _Block(this.angle, this.radius, this.width, this.height, this.tone);
  final double angle, radius, width, height;
  final int tone;
}

class _KFace {
  const _KFace(this.p, this.n, this.door, this.idx);
  final List<V3> p;
  final V3 n;
  final bool door;
  final int idx;
}

class UmrahWorld {
  UmrahWorld._();

  static const Color gold = Color(0xFFE5C47B);

  /// الوجه الذي عليه الباب يستخدم خامة front (كما في umrah_3d.dart).
  /// بدّلها إلى false لو ظهرت الصورة معكوسة بين الوجوه.
  static const bool doorFacesUseFrontTexture = true;

  // ───────────────────────── بيانات ثابتة ─────────────────────────

  static const _skins = <Color>[
    Color(0xFFD2A27C),
    Color(0xFFB98A64),
    Color(0xFF8D5F3F),
    Color(0xFF6B4630),
    Color(0xFFE0B48C),
  ];

  static final List<_Ped> _crowd = _makeCrowd();
  static List<_Ped> _makeCrowd() {
    final r = math.Random(7);
    return List.generate(240, (i) {
      final rad = 11.5 + 33 * math.pow(r.nextDouble(), 1.35).toDouble();
      final roll = r.nextDouble();
      final kind = roll < .44 ? 0 : (roll < .70 ? 1 : (roll < .84 ? 2 : 3));
      final child = r.nextDouble() < .06;
      return _Ped(
        rad,
        r.nextDouble() * math.pi * 2,
        .85 + r.nextDouble() * .7,
        child ? 1.05 + r.nextDouble() * .2 : 1.6 + r.nextDouble() * .25,
        kind,
        _skins[r.nextInt(_skins.length)],
        r.nextDouble(),
      );
    });
  }

  static const _you =
      _Ped(16, 0, 1.4, 1.74, 0, Color(0xFFB98A64), .5);

  static final List<_Bird> _birds = () {
    final r = math.Random(21);
    return List.generate(
        36,
        (i) => _Bird(
              20 + r.nextDouble() * 42,
              14 + r.nextDouble() * 24,
              (r.nextBool() ? 1 : -1) * (.05 + r.nextDouble() * .09),
              r.nextDouble() * math.pi * 2,
              9 + r.nextDouble() * 5,
            ));
  }();

  static final List<_Block> _city = () {
    final r = math.Random(33);
    return List.generate(90, (i) {
      final tall = r.nextDouble() < .1;
      return _Block(
        r.nextDouble() * math.pi * 2,
        150 + math.pow(r.nextDouble(), 1.3).toDouble() * 330,
        22 + r.nextDouble() * 42,
        tall ? 100 + r.nextDouble() * 90 : 18 + r.nextDouble() * 55,
        r.nextInt(4),
      );
    });
  }();

  static const _blockColors = <Color>[
    Color(0xFFC9B99A),
    Color(0xFFB7A98F),
    Color(0xFFD8CBB0),
    Color(0xFFA19B92),
  ];

  static final List<({double az, double el, double size, double phase})>
      _stars = () {
    final r = math.Random(5);
    return List.generate(
        150,
        (i) => (
              az: (r.nextDouble() * 2 - 1) * math.pi,
              el: .04 + r.nextDouble() * 1.4,
              size: r.nextDouble(),
              phase: r.nextDouble() * 6.28,
            ));
  }();

  static const _clouds = <({double az, double el, double w, double speed})>[
    (az: -2.6, el: .35, w: .34, speed: .8),
    (az: -1.7, el: .55, w: .28, speed: 1.1),
    (az: -.6, el: .30, w: .40, speed: .6),
    (az: .4, el: .62, w: .30, speed: 1.0),
    (az: 1.3, el: .38, w: .36, speed: .7),
    (az: 2.2, el: .50, w: .30, speed: .9),
    (az: 3.0, el: .28, w: .38, speed: .5),
  ];

  // ───────────────────────── الإدخال الرئيسي ─────────────────────────

  static void paint(Canvas canvas, Size size, Cam cam, WorldState w) {
    final v = RifqaSceneView(cam, size);
    _sky(canvas, v, w);
    _mountains(canvas, v, w);
    _clockTower(canvas, v, w);
    _hazeBand(canvas, v, w);
    _groundFill(canvas, v, w);
    _floor(canvas, v, w);
    _rings(canvas, v, w);
    if (w.quality >= 1) _kaaba(canvas, v, w, mirror: true);
    _shadows(canvas, v, w);
    _farPass(canvas, v, w);
    _youTrail(canvas, v, w);

    final items = <_Item>[];

    // رواق الحرم
    const segs = 48;
    for (var i = 0; i < segs; i++) {
      final am = (i + .5) * 2 * math.pi / segs;
      final q = v.view(V3(68 * math.cos(am), 8, 68 * math.sin(am)));
      if (q.z < -6) continue;
      if (q.x.abs() > q.z.abs() * (.5 / v.focal + .35) + 10) continue;
      final idx = i;
      items.add(_Item(q.z, () => _arcSeg(canvas, v, w, idx)));
    }

    // الكعبة والحِجر ومقام إبراهيم
    items.add(_Item(v.depthOf(const V3(0, 6.5, 0)), () {
      final north = v.eye.z < -kaabaHd;
      if (!north) _hijr(canvas, v, w);
      _kaaba(canvas, v, w);
      _ledge(canvas, v, w);
      if (north) _hijr(canvas, v, w);
    }));
    items.add(_Item(v.depthOf(const V3(kaabaHw + 10.5, 1.5, .5)),
        () => _maqam(canvas, v, w)));

    // الحجاج
    final crowdN = const [70, 130, 200][w.quality.clamp(0, 2).toInt()];
    final t = w.clock;
    for (var i = 0; i < crowdN && i < _crowd.length; i++) {
      final p = _crowd[i];
      final a = p.phase - t * p.pace / p.radius;
      final r = p.radius + math.sin(t * .7 + p.phase * 5) * .35;
      final x = r * math.cos(a), z = r * math.sin(a);
      final d = v.depthOf(V3(x, 1, z));
      if (d < 2.4 || d > 230) continue;
      final hx = math.sin(a), hz = -math.cos(a);
      final gait = t * p.pace * 4.2 + p.phase * 7;
      items.add(_Item(d, () => _pilgrim(canvas, v, w, x, z, hx, hz, gait, p)));
    }
    if (w.youVisible && !w.hideYouBody) {
      final a = w.youAngle;
      final x = w.youRadius * math.cos(a), z = w.youRadius * math.sin(a);
      final d = v.depthOf(V3(x, 1, z));
      if (d > 2.4) {
        items.add(_Item(
            d,
            () => _pilgrim(canvas, v, w, x, z, math.sin(a), -math.cos(a),
                t * 5.4, _you,
                you: true)));
      }
    }

    // الحمام
    if (w.quality >= 1 && w.sky.lamps < .9) {
      final n = w.quality >= 2 ? _birds.length : 18;
      for (var i = 0; i < n; i++) {
        final b = _birds[i];
        final a = b.phase + t * b.speed;
        final d = v.depthOf(V3(b.radius * math.cos(a), b.height, b.radius * math.sin(a)));
        if (d < 3 || d > 150) continue;
        items.add(_Item(d, () => _bird(canvas, v, w, b)));
      }
    }

    items.sort((a, b) => b.depth.compareTo(a.depth));
    for (final it in items) {
      it.draw();
    }
    _post(canvas, v, w);
    if (w.labels) _labels(canvas, v, w);
  }

  // ───────────────────────── السماء ─────────────────────────

  static double _horizonY(RifqaSceneView v) {
    final far = V3(v.eye.x + v.fx * 9000, v.eye.y, v.eye.z + v.fz * 9000);
    return v.scr(v.view(far)).dy;
  }

  static void _sky(Canvas c, RifqaSceneView v, WorldState w) {
    final s = w.sky;
    final size = v.size;
    final hy = _horizonY(v);
    if (hy > 0) {
      final skyH = math.max(hy, size.height * .55);
      c.drawRect(
          Rect.fromLTRB(0, 0, size.width, math.min(hy, size.height) + 1),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [s.top, s.mid, s.horizon],
              stops: const [0, .6, 1],
            ).createShader(
                Rect.fromLTRB(0, hy - skyH, size.width, hy)));
    } else {
      c.drawRect(Offset.zero & size, Paint()..color = s.fog);
    }

    // نجوم
    if (s.stars > .02) {
      final p = Paint();
      for (final st in _stars) {
        final ce = math.cos(st.el);
        final o = v.pt(
            V3(v.eye.x + ce * math.sin(st.az) * 5000,
                v.eye.y + math.sin(st.el) * 5000,
                v.eye.z + ce * math.cos(st.az) * 5000),
            near: 1);
        if (o == null || o.dy > hy) continue;
        final tw = .55 + .45 * math.sin(w.clock * (1.5 + st.size) + st.phase);
        p.color = withA(const Color(0xFFFFFAEB),
            s.stars * tw * (.35 + .65 * st.size));
        c.drawCircle(o, .6 + st.size * 1.1, p);
      }
    }

    // شمس أو قمر
    final l = s.light;
    final sq = v.view(V3(v.eye.x + l.x * 6000, v.eye.y + l.y * 6000,
        v.eye.z + l.z * 6000));
    if (sq.z > 1) {
      final so = v.scr(sq);
      if (s.moon > .5) {
        final r = size.width * .035;
        glow(c, so, r * 7, withA(const Color(0xFFBFD2FF), .35 * s.moon));
        c.drawCircle(so, r, Paint()..color = const Color(0xFFF1EFE2));
        final crater = Paint()..color = const Color(0x22000000);
        c.drawCircle(so + Offset(-r * .3, -r * .2), r * .26, crater);
        c.drawCircle(so + Offset(r * .35, r * .25), r * .18, crater);
        c.drawCircle(so + Offset(r * .1, -r * .5), r * .12, crater);
      } else if (s.sunEl > -.12) {
        final pw = clamp01(s.sunPower);
        glow(c, so, size.width * .55, withA(s.sunColor, .5 * pw));
        c.drawCircle(so, math.max(9, size.width * .028),
            Paint()..color = mixC(Colors.white, s.sunColor, .22));
      }
    }

    // غيوم ناعمة
    if (w.quality >= 1) {
      final tint = mixC(Colors.white, s.sunColor, .55);
      final a = .22 * (1 - s.stars * .75);
      for (final cl in _clouds) {
        final az = cl.az + w.clock * cl.speed * .0012;
        final ce = math.cos(cl.el);
        final o = v.pt(
            V3(v.eye.x + ce * math.sin(az) * 4000,
                v.eye.y + math.sin(cl.el) * 4000,
                v.eye.z + ce * math.cos(az) * 4000),
            near: 1);
        if (o == null) continue;
        final rx = cl.w * size.width * v.focal * 1.4;
        for (var k = -1; k <= 1; k++) {
          c.save();
          c.translate(o.dx + k * rx * .55, o.dy + (k == 0 ? -rx * .03 : 0));
          c.scale(1, .22);
          final rr = rx * (k == 0 ? .8 : .55);
          c.drawCircle(
              Offset.zero,
              rr,
              Paint()
                ..shader = RadialGradient(
                  colors: [withA(tint, a), withA(tint, 0)],
                ).createShader(Rect.fromCircle(center: Offset.zero, radius: rr)));
          c.restore();
        }
      }
    }
  }

  static void _mountains(Canvas c, RifqaSceneView v, WorldState w) {
    final s = w.sky;
    for (var layer = 0; layer < 2; layer++) {
      final dist = layer == 0 ? 2300.0 : 1650.0;
      final amp = layer == 0 ? 360.0 : 250.0;
      final rock = mixC(const Color(0xFF6B5846), s.fog, layer == 0 ? .6 : .4);
      final lit = scaleC(rock, .35 + .65 * s.dayLum);
      const n = 220;
      final path = Path();
      Offset? pt0, pb0;
      for (var i = 0; i <= n; i++) {
        final th = i * 2 * math.pi / n + layer * .7;
        final hgt = amp *
            (.55 +
                .25 * math.sin(3 * th + 1.3 + layer) +
                .15 * math.sin(7 * th + .4) +
                .10 * math.sin(17 * th + 2.2) +
                .06 * math.sin(41 * th));
        final x = dist * math.cos(th), z = dist * math.sin(th);
        final top = v.pt(V3(x, hgt, z), near: 1);
        final bot = v.pt(V3(x, 0, z), near: 1);
        if (top != null && bot != null && pt0 != null && pb0 != null) {
          path.addPolygon([pt0, top, bot, pb0], true);
        }
        pt0 = top;
        pb0 = bot;
      }
      c.drawPath(path, Paint()..color = lit..isAntiAlias = false);
    }
  }

  static List<Offset>? _bb(RifqaSceneView v, double x, double z, double hw0, double hw1,
      double y0, double y1) {
    final rx = v.cy, rz = -v.sy;
    final a = v.pt(V3(x + rx * hw1, y1, z + rz * hw1));
    final b = v.pt(V3(x - rx * hw1, y1, z - rz * hw1));
    final c = v.pt(V3(x - rx * hw0, y0, z - rz * hw0));
    final d = v.pt(V3(x + rx * hw0, y0, z + rz * hw0));
    if (a == null || b == null || c == null || d == null) return null;
    return [a, b, c, d];
  }

  /// أفق مكة: برج الساعة وأبراج الفندق خلف الحرم (مبسّط توضيحي).
  static void _clockTower(Canvas c, RifqaSceneView v, WorldState w) {
    const bx = -170.0, bz = 560.0;
    final s = w.sky;
    final d = v.depthOf(const V3(bx, 100, bz));
    if (d < 50) return;
    Color col(Color base, [double f = 1]) =>
        s.fogged(scaleC(base, (.4 + s.dayLum * .7) * f), d, .5);
    void part(double hw0, double hw1, double y0, double y1, Color color,
        {double ox = 0}) {
      final q = _bb(v, bx + ox, bz, hw0, hw1, y0, y1);
      if (q == null) return;
      c.drawPath(Path()..addPolygon(q, true), Paint()..color = color);
    }

    part(130, 130, 0, 60, col(const Color(0xFFB9AE98)));
    part(28, 26, 0, 290, col(const Color(0xFFA79E8E), .95), ox: -95);
    part(26, 24, 0, 250, col(const Color(0xFFA79E8E), .9), ox: 95);
    part(22, 20, 0, 200, col(const Color(0xFFA79E8E), .85), ox: -150);
    part(36, 30, 60, 470, col(const Color(0xFFC9C0AE)));
    part(17, 14, 60, 470, col(const Color(0xFFD9D1C0), 1.05), ox: 6);
    part(52, 52, 470, 545, col(const Color(0xFFBDB4A0)));
    part(52, 52, 480, 486, col(const Color(0xFF2F7F5C)));
    part(52, 52, 530, 536, col(const Color(0xFF2F7F5C)));
    part(34, 20, 545, 575, col(const Color(0xFFC9C0AE)));
    part(20, 3, 575, 592, col(const Color(0xFFD9B45A), 1.1));
    part(2, .5, 592, 604, col(const Color(0xFFD9B45A), 1.1));

    final cc = v.proj(const V3(bx, 507, bz));
    if (cc.depth > 50) {
      final r = 24 * cc.k;
      c.drawCircle(cc.o, r, Paint()..color = col(const Color(0xFFF5F2EA), 1.1));
      c.drawCircle(
          cc.o,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1, r * .12)
            ..color = col(const Color(0xFFD9B45A), 1.1));
      final hand = Paint()
        ..color = col(const Color(0xFF2A2A2A))
        ..strokeWidth = math.max(1, r * .08);
      c.drawLine(cc.o, cc.o + Offset(r * .0, -r * .7), hand);
      c.drawLine(cc.o, cc.o + Offset(r * .45, r * .1), hand);
      if (s.lamps > .05) {
        glow(c, cc.o, r * 3.2, withA(const Color(0xFF9BFFC4), .5 * s.lamps));
      }
    }
  }

  static void _hazeBand(Canvas c, RifqaSceneView v, WorldState w) {
    final s = w.sky;
    final hy = _horizonY(v);
    final h = v.size.height * .15;
    if (hy < 0 || hy - h > v.size.height) return;
    final rect = Rect.fromLTRB(0, hy - h, v.size.width, hy + 2);
    c.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [withA(s.fog, 0), withA(s.fog, .8)],
          ).createShader(rect));
  }

  static void _groundFill(Canvas c, RifqaSceneView v, WorldState w) {
    final s = w.sky;
    final size = v.size;
    final top = math.max(0.0, _horizonY(v));
    if (top >= size.height) return;
    final base = s.shade(const Color(0xFFD6CBB5), const V3(0, 1, 0));
    final far = mixC(base, s.fog, .8);
    final rect = Rect.fromLTRB(0, top - 1, size.width, size.height);
    c.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [s.fog, far, base],
            stops: const [0, .3, 1],
          ).createShader(rect));
  }

  // ───────────────────────── الأرضية ─────────────────────────

  /// شبكة قطبية حول موضع الكاميرا: خلايا دقيقة قربها وكبيرة بعيدًا،
  /// فتبقى الخامة مستقرة بمنظور صحيح بدل أن «تسبح» كما في الشبكة الخطية.
  static void _floor(Canvas c, RifqaSceneView v, WorldState w) {
    final s = w.sky;
    final mat = w.materials;
    final nR = w.quality >= 2 ? 28 : (w.quality == 1 ? 22 : 16);
    final nA = w.quality >= 2 ? 72 : (w.quality == 1 ? 56 : 40);
    final gx = v.eye.x, gz = v.eye.z, ey2 = v.eye.y * v.eye.y;
    final growth = math.pow(320 / .9, 1 / (nR - 1)).toDouble();
    final stride = nA + 1;
    final count = nR * stride;
    final pos = Float32List(count * 2);
    final uv = Float32List(count * 2);
    final col = Int32List(count);
    final fogCol = Int32List(count);
    final ok = List<bool>.filled(count, false);
    final base = s.lightAt(const V3(0, 1, 0));
    const tile = 7.0;
    final tw = mat?.marble.width.toDouble() ?? 256.0;
    final th = mat?.marble.height.toDouble() ?? 256.0;
    final fr = mat == null ? .85 : 1.0;
    final fg = mat == null ? .81 : 1.0;
    final fb = mat == null ? .72 : 1.0;
    var vi = 0;
    for (var i = 0; i < nR; i++) {
      final r = .9 * math.pow(growth, i).toDouble();
      for (var j = 0; j <= nA; j++) {
        final a = j * math.pi * 2 / nA;
        final wx = gx + r * math.cos(a), wz = gz + r * math.sin(a);
        final q = v.view(V3(wx, 0, wz));
        final valid = q.z >= .9;
        ok[vi] = valid;
        final o = valid ? v.scr(q) : Offset.zero;
        pos[vi * 2] = o.dx;
        pos[vi * 2 + 1] = o.dy;
        uv[vi * 2] = wx / tile * tw;
        uv[vi * 2 + 1] = wz / tile * th;
        final dO = math.sqrt(wx * wx + wz * wz);
        final pool = s.lamps * math.exp(-dO * dO / (2 * 40 * 40));
        final dim = mix(1.0, .5, smooth((dO - 66) / 20));
        col[vi] = rgbaC(
          clamp01(base.r * dim * fr + pool * .95),
          clamp01(base.g * dim * fg + pool * .78),
          clamp01(base.b * dim * fb + pool * .50),
        ).toARGB32();
        fogCol[vi] = withA(s.fog, s.fogT(math.sqrt(r * r + ey2))).toARGB32();
        vi++;
      }
    }
    final idx = <int>[];
    for (var i = 0; i < nR - 1; i++) {
      for (var j = 0; j < nA; j++) {
        final a = i * stride + j, b = a + 1, d = a + stride, e = d + 1;
        if (ok[a] && ok[b] && ok[d] && ok[e]) idx.addAll([a, b, d, b, e, d]);
      }
    }
    if (idx.isEmpty) return;
    final indices = Uint16List.fromList(idx);

    if (mat != null) {
      final m = Float64List(16);
      m[0] = m[5] = m[10] = m[15] = 1;
      final shader = ui.ImageShader(
          mat.marble, ui.TileMode.repeated, ui.TileMode.repeated, m,
          filterQuality: FilterQuality.medium);
      final tv = ui.Vertices.raw(ui.VertexMode.triangles, pos,
          textureCoordinates: uv, colors: col, indices: indices);
      c.drawVertices(tv, BlendMode.modulate, Paint()..shader = shader);
      tv.dispose();
      shader.dispose();
    } else {
      final tv = ui.Vertices.raw(ui.VertexMode.triangles, pos,
          colors: col, indices: indices);
      c.drawVertices(tv, BlendMode.src, Paint());
      tv.dispose();
    }
    final fv = ui.Vertices.raw(ui.VertexMode.triangles, pos,
        colors: fogCol, indices: indices);
    c.drawVertices(fv, BlendMode.src, Paint());
    fv.dispose();
  }

  static void _ring(Canvas c, RifqaSceneView v, double r, Color color, double width,
      {double y = .03}) {
    final pts = <V3>[
      for (var i = 0; i <= 120; i++)
        V3(r * math.cos(i * math.pi * 2 / 120), y,
            r * math.sin(i * math.pi * 2 / 120))
    ];
    v.strokeLoop(
        c,
        pts,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width);
  }

  static void _rings(Canvas c, RifqaSceneView v, WorldState w) {
    final s = w.sky;
    final fade = 1 - s.fogT(30) * .5;
    _ring(c, v, 9.2, withA(const Color(0xFFD9B45A), .45 * fade), 1.6);
    _ring(c, v, 16, withA(const Color(0xFFDBC18A), .55 * fade), 2.2);
    _ring(c, v, 30, withA(const Color(0xFF857766), .22 * fade), 1);
    _ring(c, v, 46, withA(const Color(0xFF857766), .18 * fade), 1);

    // خط محاذاة الحجر الأسود (ضوء أخضر)
    final a = v.pt(const V3(kaabaHw + .3, .05, kaabaHd));
    final b = v.pt(const V3(kaabaHw + 16, .05, kaabaHd));
    if (a != null && b != null) {
      final pulse = .6 + .4 * math.sin(w.clock * 3);
      c.drawLine(
          a,
          b,
          Paint()
            ..color = withA(const Color(0xFF2EE59D), .30 * pulse)
            ..strokeWidth = 9
            ..strokeCap = StrokeCap.round);
      c.drawLine(
          a,
          b,
          Paint()
            ..color = const Color(0xFF2EE59D)
            ..strokeWidth = 2.6
            ..strokeCap = StrokeCap.round);
    }
  }

  // ───────────────────────── الظلال ─────────────────────────

  static List<Offset> _hull(List<Offset> pts) {
    final p = [...pts]..sort((a, b) =>
        a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
    double cross(Offset o, Offset a, Offset b) =>
        (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
    final lower = <Offset>[];
    for (final q in p) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower.last, q) <= 0) {
        lower.removeLast();
      }
      lower.add(q);
    }
    final upper = <Offset>[];
    for (final q in p.reversed) {
      while (upper.length >= 2 &&
          cross(upper[upper.length - 2], upper.last, q) <= 0) {
        upper.removeLast();
      }
      upper.add(q);
    }
    lower.removeLast();
    upper.removeLast();
    return [...lower, ...upper];
  }

  static void _shadows(Canvas c, RifqaSceneView v, WorldState w) {
    if (w.quality < 1) return;
    final s = w.sky;
    // ظلّ تماس حول القاعدة (دائم) + ظل ساقط من الشمس/القمر
    final contact = v.poly(const [
      V3(-kaabaHw - 1.6, .03, -kaabaHd - 1.6),
      V3(kaabaHw + 1.6, .03, -kaabaHd - 1.6),
      V3(kaabaHw + 1.6, .03, kaabaHd + 1.6),
      V3(-kaabaHw - 1.6, .03, kaabaHd + 1.6),
    ]);
    if (contact != null) {
      c.drawPath(
          contact,
          Paint()
            ..color = const Color(0x40100E0A)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    }
    final a = s.shadowAlpha;
    if (a < .03) return;
    final k = s.shadowStretch, d = s.shadowDir;
    final pts = <Offset>[];
    for (final sx in const [-kaabaHw, kaabaHw]) {
      for (final sz in const [-kaabaHd, kaabaHd]) {
        pts.add(Offset(sx, sz));
        pts.add(Offset(sx + d.dx * kaabaH * k, sz + d.dy * kaabaH * k));
      }
    }
    final hull = _hull(pts);
    final path = v.poly([for (final p in hull) V3(p.dx, .02, p.dy)]);
    if (path != null) {
      c.drawPath(
          path,
          Paint()
            ..color = withA(const Color(0xFF1B1A2A), .5 * a)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
  }

  // ───────────────────────── مجموعات بعيدة ─────────────────────────

  static void _farPass(Canvas c, RifqaSceneView v, WorldState w) {
    final s = w.sky;
    final list = <_Item>[];
    for (final b in _city) {
      final x = b.radius * math.cos(b.angle), z = b.radius * math.sin(b.angle);
      final d = v.depthOf(V3(x, b.height * .5, z));
      if (d < 20) continue;
      list.add(_Item(d, () {
        final q = _bb(v, x, z, b.width / 2, b.width / 2, 0, b.height);
        if (q == null) return;
        final base = _blockColors[b.tone];
        final color = mixC(scaleC(base, .35 + .65 * s.dayLum), s.fog,
            math.min(.82, s.fogT(d) * .78));
        c.drawPath(Path()..addPolygon(q, true), Paint()..color = color);
        if (s.lamps > .3 && d < 380) {
          final pts = <Offset>[];
          for (var r = 1; r <= 4; r++) {
            for (var k = 1; k <= 3; k++) {
              final u = k / 4, t = r / 5;
              pts.add(Offset.lerp(Offset.lerp(q[0], q[1], u)!,
                  Offset.lerp(q[3], q[2], u)!, t)!);
            }
          }
          c.drawPoints(
              ui.PointMode.points,
              pts,
              Paint()
                ..color = withA(const Color(0xFFFFD08A), .6 * s.lamps)
                ..strokeWidth = 2.2
                ..strokeCap = StrokeCap.square);
        }
      }));
    }
    for (var i = 0; i < 9; i++) {
      final a = i * 2 * math.pi / 9 + .3;
      final d = v.depthOf(V3(98 * math.cos(a), 40, 98 * math.sin(a)));
      if (d < 4) continue;
      final idx = i;
      list.add(_Item(d, () => _minaret(c, v, w, idx)));
    }
    list.sort((a, b) => b.depth.compareTo(a.depth));
    for (final it in list) {
      it.draw();
    }
  }

  static void _minaret(Canvas c, RifqaSceneView v, WorldState w, int i) {
    final s = w.sky;
    final a = i * 2 * math.pi / 9 + .3;
    final x = 98 * math.cos(a), z = 98 * math.sin(a);
    final d = v.depthOf(V3(x, 40, z));
    Color col(Color base, [double f = 1]) =>
        s.fogged(scaleC(base, (.38 + .7 * s.dayLum) * f), d);
    const sand = Color(0xFFE2D7BE);
    final shaft = _bb(v, x, z, 2.9, 1.9, 0, 66);
    if (shaft != null) {
      final path = Path()..addPolygon(shaft, true);
      c.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
              colors: [col(sand, 1.1), col(sand, .78)],
            ).createShader(path.getBounds()));
    }
    void fill(List<Offset>? q, Color color) {
      if (q != null) c.drawPath(Path()..addPolygon(q, true), Paint()..color = color);
    }

    fill(_bb(v, x, z, 3.7, 3.7, 66, 69), col(const Color(0xFFCDBF9F), .95));
    fill(_bb(v, x, z, 2.0, 1.6, 69, 82), col(sand, .95));
    fill(_bb(v, x, z, 3.0, 3.0, 82, 84), col(const Color(0xFFCDBF9F), .95));
    fill(_bb(v, x, z, 1.7, .15, 84, 95), col(const Color(0xFFD9B45A), 1.1));
    final tip = v.pt(V3(x, 97.5, z));
    if (tip != null) {
      c.drawCircle(
          tip,
          math.max(1.2, v.scaleAt(d) * 1.0),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1, v.scaleAt(d) * .25)
            ..color = col(const Color(0xFFD9B45A), 1.2));
    }
    if (s.lamps > .05) {
      for (final y in const [67.5, 83.0]) {
        final o = v.pt(V3(x, y, z));
        if (o != null) {
          glow(c, o, math.max(6, v.scaleAt(d) * 9),
              withA(const Color(0xFF7DFFB0), .5 * s.lamps));
        }
      }
    }
  }

  // ───────────────────────── رواق الحرم ─────────────────────────

  static void _arcSeg(Canvas c, RifqaSceneView v, WorldState w, int i) {
    const n = 48;
    const rad = 68.0;
    const wallH = 24.0;
    final s = w.sky;
    final a0 = i * 2 * math.pi / n, a1 = (i + 1) * 2 * math.pi / n;
    final am = (a0 + a1) / 2;
    final b0 = V3(rad * math.cos(a0), 0, rad * math.sin(a0));
    final b1 = V3(rad * math.cos(a1), 0, rad * math.sin(a1));
    final chord = 2 * rad * math.sin(math.pi / n);
    V3 p(double u, double y) => V3(mix(b0.x, b1.x, u), y, mix(b0.z, b1.z, u));
    final nrm = V3(-math.cos(am), 0, -math.sin(am));
    final depth = v.depthOf(p(.5, 10));
    Color fg(Color base, [double lit = 1]) =>
        s.fogged(s.shade(base, nrm, boost: lit), depth);
    final lamp = s.lamps;

    // الجدار
    final wall = v.poly([p(0, 0), p(1, 0), p(1, wallH), p(0, wallH)]);
    if (wall != null) {
      final b = wall.getBounds();
      c.drawPath(
          wall,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [fg(const Color(0xFFEDE3CC), 1.08), fg(const Color(0xFFD9CDB0), .9)],
            ).createShader(b));
    }

    // القوس السفلي
    const ra = 2.6, spring = 7.0;
    final au0 = .5 - ra / chord, au1 = .5 + ra / chord;
    final arch = <V3>[p(au0, 0), p(au0, spring)];
    for (var k = 1; k < 8; k++) {
      final phi = math.pi - k * math.pi / 8;
      arch.add(p(.5 + ra * math.cos(phi) / chord, spring + ra * math.sin(phi)));
    }
    arch..add(p(au1, spring))..add(p(au1, 0));
    final archPath = v.poly(arch);
    if (archPath != null) {
      c.drawPath(
          archPath,
          Paint()
            ..color = s.fogged(
                mixC(const Color(0xFF30251B), const Color(0xFFFFB45E), lamp * .8),
                depth));
      c.drawPath(
          archPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1, v.scaleAt(depth) * .14)
            ..color = s.fogged(const Color(0xFFD8B35A), depth));
    }

    // نوافذ الدور العلوي
    for (final cu in const [.2, .5, .8]) {
      const hw = .65, y0 = 13.0, y1 = 16.2;
      final u0 = cu - hw / chord, u1 = cu + hw / chord;
      final win = <V3>[p(u0, y0), p(u0, y1)];
      for (var k = 1; k < 5; k++) {
        final phi = math.pi - k * math.pi / 5;
        win.add(p(cu + hw * math.cos(phi) / chord, y1 + hw * math.sin(phi)));
      }
      win..add(p(u1, y1))..add(p(u1, y0));
      final wp = v.poly(win);
      if (wp != null) {
        c.drawPath(
            wp,
            Paint()
              ..color = s.fogged(
                  mixC(const Color(0xFF55646E), const Color(0xFFFFD08A), lamp * .9),
                  depth));
      }
    }

    // الكورنيش
    final cornice = v.poly([p(0, 21.6), p(1, 21.6), p(1, 24.4), p(0, 24.4)]);
    if (cornice != null) {
      c.drawPath(cornice, Paint()..color = fg(const Color(0xFFCDBF9F), 1.05));
    }
    final stripe = v.poly([p(0, 21.2), p(1, 21.2), p(1, 21.9), p(0, 21.9)]);
    if (stripe != null) {
      c.drawPath(stripe, Paint()..color = fg(const Color(0xFFD8B35A), 1.1));
    }

    // العمود
    V3 cp(double sg, double y) => V3(b0.x - math.sin(a0) * .55 * sg, y,
        b0.z + math.cos(a0) * .55 * sg);
    final col = v.poly([cp(-1, wallH + .6), cp(1, wallH + .6), cp(1, 0), cp(-1, 0)]);
    if (col != null) {
      c.drawPath(col, Paint()..color = fg(const Color(0xFFF3ECDA), 1.1));
    }
    if (lamp > .05) {
      final o = v.pt(V3(b0.x * .985, wallH + 1.5, b0.z * .985));
      if (o != null) {
        glow(c, o, math.max(8, v.scaleAt(depth) * 2.4),
            withA(const Color(0xFFFFC978), .55 * lamp));
      }
    }
  }

  // ───────────────────────── الكعبة ─────────────────────────

  static bool _quad(Canvas c, RifqaSceneView v, WorldState w, List<V3> pts, V3 n,
      Color base,
      {double alpha = 1, double boost = 1, bool twoSided = false}) {
    var cx = 0.0, cy = 0.0, cz = 0.0;
    for (final p in pts) {
      cx += p.x;
      cy += p.y;
      cz += p.z;
    }
    cx /= pts.length;
    cy /= pts.length;
    cz /= pts.length;
    final facing =
        n.x * (v.eye.x - cx) + n.y * (v.eye.y - cy) + n.z * (v.eye.z - cz);
    if (!twoSided && facing <= 0) return false;
    final path = v.poly(pts);
    if (path == null) return false;
    final depth = v.depthOf(V3(cx, cy, cz));
    final color = w.sky.fogged(w.sky.shade(base, n, boost: boost), depth);
    c.drawPath(path, Paint()..color = alpha < 1 ? withA(color, alpha) : color);
    return true;
  }

  static void _kaaba(Canvas c, RifqaSceneView v, WorldState w, {bool mirror = false}) {
    final s = w.sky;
    final mat = w.materials;
    const hw = kaabaHw, hd = kaabaHd, h = kaabaH;
    final e = v.eye;
    V3 m(V3 p) => mirror ? V3(p.x, -p.y, p.z) : p;
    const frontOnX = doorFacesUseFrontTexture;
    final faces = <_KFace>[
      _KFace(const [V3(hw, h, hd), V3(hw, h, -hd), V3(hw, 0, -hd), V3(hw, 0, hd)],
          const V3(1, 0, 0), frontOnX, 0),
      _KFace(const [V3(-hw, h, -hd), V3(-hw, h, hd), V3(-hw, 0, hd), V3(-hw, 0, -hd)],
          const V3(-1, 0, 0), frontOnX, 1),
      _KFace(const [V3(-hw, h, hd), V3(hw, h, hd), V3(hw, 0, hd), V3(-hw, 0, hd)],
          const V3(0, 0, 1), !frontOnX, 2),
      _KFace(const [V3(hw, h, -hd), V3(-hw, h, -hd), V3(-hw, 0, -hd), V3(hw, 0, -hd)],
          const V3(0, 0, -1), !frontOnX, 3),
    ];

    for (final f in faces) {
      final cx = (f.p[0].x + f.p[2].x) / 2, cz = (f.p[0].z + f.p[2].z) / 2;
      if (f.n.x * (e.x - cx) + f.n.z * (e.z - cz) <= 0) continue;
      final pts = [for (final p in f.p) m(p)];
      final light = s.lightAt(f.n);
      final depth = v.depthOf(m(V3(cx, h * .5, cz)));
      final al = mirror ? .30 : 1.0;

      if (mat != null) {
        final subs = depth < 25 ? 18 : (depth < 50 ? 12 : 8);
        texturedQuad(
          c,
          v,
          f.door ? mat.front : mat.side,
          pts,
          nu: subs,
          nv: subs,
          tint: (u, t) {
            final y = (1 - t) * h;
            final ao = mix(.60, 1.0, smooth(y / 3.2)) *
                mix(1.0, .9, smooth((y - 8) / 5));
            final fold = 1 - .05 * (.5 + .5 * math.sin(u * 40));
            final k = ao * fold;
            final a = mirror ? .30 * (1 - (y / h) * .8) : 1.0;
            return rgbaC(light.r * k, light.g * k, light.b * k, a);
          },
        );
      } else {
        final path = v.poly(pts);
        if (path != null) {
          c.drawPath(path,
              Paint()..color = withA(s.shade(const Color(0xFF1A1A1C), f.n, boost: 1.5), al));
        }
      }

      // حزام الكسوة الذهبي
      const y0 = h * .70, y1 = h * .80;
      V3 fpnt(double u, double y) {
        final t = 1 - y / h;
        return v3Mix(v3Mix(pts[0], pts[1], u), v3Mix(pts[3], pts[2], u), t);
      }

      final band = v.poly([fpnt(0, y1), fpnt(1, y1), fpnt(1, y0), fpnt(0, y0)]);
      if (band != null) {
        final g1 = s.shade(const Color(0xFFE9C36A), f.n, boost: 1.15);
        final g2 = s.shade(const Color(0xFFA97B25), f.n, boost: 1.15);
        c.drawPath(
            band,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [withA(g1, al), withA(g2, al), withA(g1, al)],
              ).createShader(band.getBounds()));
        final dx = pts[1].x - pts[0].x, dz = pts[1].z - pts[0].z;
        final width = math.sqrt(dx * dx + dz * dz);
        const cnt = 4;
        for (var i = 0; i < cnt; i++) {
          final uc = (i + .5) / cnt;
          final ell = <V3>[
            for (var k = 0; k < 12; k++)
              fpnt(uc + 1.05 * math.cos(k * math.pi * 2 / 12) / width,
                  h * .75 + .42 * math.sin(k * math.pi * 2 / 12))
          ];
          final ep = v.poly(ell);
          if (ep != null) {
            c.drawPath(ep, Paint()..color = withA(const Color(0xFF7A5512), .55 * al));
            c.drawPath(
                ep,
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1
                  ..color = withA(const Color(0xFFF6DC8C), .8 * al));
          }
        }
        final l1a = v.pt(fpnt(0, y1)), l1b = v.pt(fpnt(1, y1));
        final l2a = v.pt(fpnt(0, y0)), l2b = v.pt(fpnt(1, y0));
        final edge = Paint()
          ..color = withA(const Color(0xFFF2D27A), .9 * al)
          ..strokeWidth = 1.6;
        if (l1a != null && l1b != null) c.drawLine(l1a, l1b, edge);
        if (l2a != null && l2b != null) c.drawLine(l2a, l2b, edge);
      }
      if (mirror) continue;

      final fpath = v.poly(pts);
      if (fpath != null) {
        final b = fpath.getBounds();
        // لمعان الساتان المتحرك
        final sd = s.sunAt(f.n);
        if (sd > .05) {
          final pos = (w.clock * .045 + f.idx * .27) % 1.0;
          final lo = math.max(0.0, pos - .14), hi = math.min(1.0, pos + .14);
          c.drawPath(
              fpath,
              Paint()
                ..blendMode = BlendMode.plus
                ..shader = LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    withA(s.sunColor, 0),
                    withA(s.sunColor, 0),
                    withA(s.sunColor, .16 * sd),
                    withA(s.sunColor, 0),
                    withA(s.sunColor, 0),
                  ],
                  stops: [0, lo, pos.clamp(lo, hi).toDouble(), hi, 1],
                ).createShader(b));
        }
        // إضاءة الكشافات ليلًا
        if (s.lamps > .05) {
          c.drawPath(
              fpath,
              Paint()
                ..blendMode = BlendMode.plus
                ..shader = LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    withA(const Color(0xFFFFC27A), .42 * s.lamps),
                    withA(const Color(0xFFFFC27A), 0),
                  ],
                  stops: const [0, .62],
                ).createShader(b));
        }
        // طيّات القماش
        final foldPaint = Paint()
          ..strokeWidth = 1
          ..color = const Color(0x1A000000);
        for (var i = 1; i < 22; i++) {
          final u = i / 22 + math.sin(i * 12.9898) * .012;
          final a = v.pt(v3Mix(pts[0], pts[1], u));
          final bb = v.pt(v3Mix(pts[3], pts[2], u));
          if (a != null && bb != null) c.drawLine(a, bb, foldPaint);
        }
      }

      // باب الكعبة الذهبي على الوجه الشرقي
      if (f.idx == 0) _door(c, v, w);
    }

    if (mirror) return;

    // سقف الكعبة
    if (e.y > h) {
      final roof = v.poly(const [
        V3(-hw, h, -hd),
        V3(hw, h, -hd),
        V3(hw, h, hd),
        V3(-hw, h, hd),
      ]);
      if (roof != null) {
        c.drawPath(roof,
            Paint()..color = s.shade(const Color(0xFF2A2623), const V3(0, 1, 0), boost: 1.4));
      }
    }

    // الحجر الأسود في الركن الجنوبي الشرقي
    if (e.x > hw - .5 || e.z > hd - .5) {
      final bp = v.proj(const V3(hw + .05, 1.5, hd + .05));
      if (bp.depth > 1.5) {
        final k = bp.k;
        if (w.glow > 0) {
          final pulse = .65 + .35 * math.sin(w.clock * 4);
          glow(c, bp.o, k * (2.2 + pulse), withA(gold, .55 * w.glow));
        }
        c.drawCircle(
            bp.o,
            .62 * k,
            Paint()
              ..shader = RadialGradient(
                colors: const [Color(0xFFEFEDE8), Color(0xFF8F9197)],
              ).createShader(Rect.fromCircle(center: bp.o, radius: .62 * k)));
        c.drawCircle(bp.o, .43 * k, Paint()..color = const Color(0xFF1B191C));
        c.drawCircle(bp.o + Offset(-.12 * k, -.12 * k), .10 * k,
            Paint()..color = const Color(0x33FFFFFF));
      }
    }
  }

  static void _door(Canvas c, RifqaSceneView v, WorldState w) {
    final s = w.sky;
    const n = V3(1, 0, 0);
    V3 dp(double z, double y) => V3(kaabaHw + .03, y, z);
    final frame = v.poly([dp(3.6, 5.8), dp(1.2, 5.8), dp(1.2, 2.2), dp(3.6, 2.2)]);
    if (frame != null) {
      c.drawPath(frame, Paint()..color = s.shade(const Color(0xFFF0CE78), n, boost: 1.25));
    }
    final panel = v.poly([dp(3.4, 5.6), dp(1.4, 5.6), dp(1.4, 2.4), dp(3.4, 2.4)]);
    if (panel != null) {
      c.drawPath(
          panel,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                s.shade(const Color(0xFFC79A38), n, boost: 1.2),
                s.shade(const Color(0xFF8E6A1C), n, boost: 1.2),
              ],
            ).createShader(panel.getBounds()));
    }
    final line = Paint()
      ..color = withA(const Color(0xFFF6DC8C), .75)
      ..strokeWidth = 1.2;
    for (final y in const [3.2, 4.8]) {
      final a = v.pt(dp(3.4, y)), b = v.pt(dp(1.4, y));
      if (a != null && b != null) c.drawLine(a, b, line);
    }
    final med = <V3>[
      for (var k = 0; k < 14; k++)
        dp(2.4 + .5 * math.cos(k * math.pi * 2 / 14), 4.0 + .5 * math.sin(k * math.pi * 2 / 14))
    ];
    final mp = v.poly(med);
    if (mp != null) {
      c.drawPath(mp, Paint()..color = withA(const Color(0xFFF0CE78), .9));
    }
    if (s.lamps > .05) {
      final o = v.pt(dp(2.4, 4.0));
      if (o != null) {
        glow(c, o, v.scaleAt(v.depthOf(dp(2.4, 4.0))) * 3.2,
            withA(const Color(0xFFFFC978), .45 * s.lamps));
      }
    }
  }

  /// قاعدة الشاذروان حول الكعبة.
  static void _ledge(Canvas c, RifqaSceneView v, WorldState w) {
    const hw = kaabaHw, hd = kaabaHd;
    const ox = hw + .6, oz = hd + .6, y = .38;
    const base = Color(0xFFE9DFC9);
    const up = V3(0, 1, 0);
    _quad(c, v, w, const [V3(hw, y, hd), V3(hw, y, -hd), V3(ox, y, -oz), V3(ox, y, oz)], up, base);
    _quad(c, v, w, const [V3(-hw, y, -hd), V3(-hw, y, hd), V3(-ox, y, oz), V3(-ox, y, -oz)], up, base);
    _quad(c, v, w, const [V3(-hw, y, hd), V3(hw, y, hd), V3(ox, y, oz), V3(-ox, y, oz)], up, base);
    _quad(c, v, w, const [V3(hw, y, -hd), V3(-hw, y, -hd), V3(-ox, y, -oz), V3(ox, y, -oz)], up, base);
    _quad(c, v, w, const [V3(ox, y, oz), V3(ox, y, -oz), V3(ox, 0, -oz), V3(ox, 0, oz)], const V3(1, 0, 0), base, boost: .95);
    _quad(c, v, w, const [V3(-ox, y, -oz), V3(-ox, y, oz), V3(-ox, 0, oz), V3(-ox, 0, -oz)], const V3(-1, 0, 0), base, boost: .95);
    _quad(c, v, w, const [V3(-ox, y, oz), V3(ox, y, oz), V3(ox, 0, oz), V3(-ox, 0, oz)], const V3(0, 0, 1), base, boost: .95);
    _quad(c, v, w, const [V3(ox, y, -oz), V3(-ox, y, -oz), V3(-ox, 0, -oz), V3(ox, 0, -oz)], const V3(0, 0, -1), base, boost: .95);
  }

  /// حِجر إسماعيل: جدار رخامي نصف دائري خلف الكعبة.
  static void _hijr(Canvas c, RifqaSceneView v, WorldState w) {
    const segs = 28;
    const ro = 6.0, ri = 4.8, hh = 1.35, cz = -kaabaHd;
    V3 pt(double r, double a, double y) =>
        V3(r * math.cos(a), y, cz - r * math.sin(a));
    final floor = v.poly([
      for (var i = 0; i <= segs; i++) pt(ri, i * math.pi / segs, .04),
    ]);
    if (floor != null) {
      c.drawPath(floor,
          Paint()..color = w.sky.fogged(w.sky.shade(const Color(0xFFEAE2CE), const V3(0, 1, 0)), 40));
    }
    final order = <({double d, int i})>[
      for (var i = 0; i < segs; i++)
        (d: v.depthOf(pt((ri + ro) / 2, (i + .5) * math.pi / segs, .7)), i: i)
    ]..sort((a, b) => b.d.compareTo(a.d));
    const marble = Color(0xFFF3ECDD);
    for (final o in order) {
      final a0 = o.i * math.pi / segs, a1 = (o.i + 1) * math.pi / segs;
      final am = (a0 + a1) / 2;
      final out = V3(math.cos(am), 0, -math.sin(am));
      _quad(c, v, w, [pt(ri, a0, 0), pt(ri, a1, 0), pt(ri, a1, hh), pt(ri, a0, hh)],
          V3(-out.x, 0, -out.z), marble, boost: .92);
      _quad(c, v, w, [pt(ri, a0, hh), pt(ri, a1, hh), pt(ro, a1, hh), pt(ro, a0, hh)],
          const V3(0, 1, 0), marble, boost: 1.05);
      _quad(c, v, w, [pt(ro, a0, 0), pt(ro, a1, 0), pt(ro, a1, hh), pt(ro, a0, hh)],
          out, marble);
    }
  }

  /// مقام إبراهيم: قبة ذهبية زجاجية صغيرة.
  static void _maqam(Canvas c, RifqaSceneView v, WorldState w) {
    const mx = kaabaHw + 10.5, mz = .5;
    const gx = Color(0xFFE2BE6A);
    // قاعدة
    const b = 1.7, bh = .45;
    _quad(c, v, w, const [V3(mx - b, bh, mz - b), V3(mx + b, bh, mz - b), V3(mx + b, bh, mz + b), V3(mx - b, bh, mz + b)],
        const V3(0, 1, 0), const Color(0xFFE9DFC9));
    _quad(c, v, w, const [V3(mx + b, bh, mz + b), V3(mx + b, bh, mz - b), V3(mx + b, 0, mz - b), V3(mx + b, 0, mz + b)],
        const V3(1, 0, 0), const Color(0xFFE9DFC9));
    _quad(c, v, w, const [V3(mx - b, bh, mz - b), V3(mx - b, bh, mz + b), V3(mx - b, 0, mz + b), V3(mx - b, 0, mz - b)],
        const V3(-1, 0, 0), const Color(0xFFE9DFC9));
    _quad(c, v, w, const [V3(mx - b, bh, mz + b), V3(mx + b, bh, mz + b), V3(mx + b, 0, mz + b), V3(mx - b, 0, mz + b)],
        const V3(0, 0, 1), const Color(0xFFE9DFC9));
    _quad(c, v, w, const [V3(mx + b, bh, mz - b), V3(mx - b, bh, mz - b), V3(mx - b, 0, mz - b), V3(mx + b, 0, mz - b)],
        const V3(0, 0, -1), const Color(0xFFE9DFC9));
    // زجاج الفانوس
    const g = .95, top = 3.3;
    final glassA = .20 + .15 * w.sky.lamps;
    const glass = Color(0xFFFFE9A8);
    final y0 = bh;
    for (final side in const [
      [V3(1, 0, 0), 1.0, 0.0],
      [V3(-1, 0, 0), -1.0, 0.0],
      [V3(0, 0, 1), 0.0, 1.0],
      [V3(0, 0, -1), 0.0, -1.0],
    ]) {
      final nrm = side[0] as V3;
      final sx = side[1] as double, sz = side[2] as double;
      final pts = sx != 0
          ? [V3(mx + sx * g, top, mz - g), V3(mx + sx * g, top, mz + g), V3(mx + sx * g, y0, mz + g), V3(mx + sx * g, y0, mz - g)]
          : [V3(mx - g, top, mz + sz * g), V3(mx + g, top, mz + sz * g), V3(mx + g, y0, mz + sz * g), V3(mx - g, y0, mz + sz * g)];
      _quad(c, v, w, pts, nrm, glass, alpha: glassA, boost: 1.2);
    }
    // إطار ذهبي
    final fr = Paint()
      ..color = w.sky.shade(gx, const V3(0, 1, 0), boost: 1.2)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (final dx in const [-g, g]) {
      for (final dz in const [-g, g]) {
        final a = v.pt(V3(mx + dx, y0, mz + dz)), t = v.pt(V3(mx + dx, top, mz + dz));
        if (a != null && t != null) c.drawLine(a, t, fr);
      }
    }
    // سقف هرمي
    const cap = 4.8, e = 1.15;
    final apex = V3(mx, cap, mz);
    final corners = const [
      V3(mx - e, top, mz - e),
      V3(mx + e, top, mz - e),
      V3(mx + e, top, mz + e),
      V3(mx - e, top, mz + e),
    ];
    final tris = <({double d, int i})>[
      for (var i = 0; i < 4; i++)
        (d: v.depthOf(V3((corners[i].x + corners[(i + 1) % 4].x) / 2, top + .5, (corners[i].z + corners[(i + 1) % 4].z) / 2)), i: i)
    ]..sort((a, b) => b.d.compareTo(a.d));
    for (final t in tris) {
      final p0 = corners[t.i], p1 = corners[(t.i + 1) % 4];
      final nx = (p0.z + p1.z) / 2 - mz, nz = (p0.x + p1.x) / 2 - mx;
      _quad(c, v, w, [p0, p1, apex], V3(-nx * 0 + (p0.x + p1.x) / 2 - mx, .9, (p0.z + p1.z) / 2 - mz), gx,
          boost: 1.15, twoSided: true);
      // لإبقاء الحدود الذهبية واضحة
      final a = v.pt(p0), bq = v.pt(apex);
      if (a != null && bq != null) {
        c.drawLine(a, bq, Paint()..color = withA(const Color(0xFFFFE9A8), .6)..strokeWidth = 1);
      }
      // متغيرات غير مستخدمة بعد الآن
      assert(nx == nx && nz == nz);
    }
    if (w.sky.lamps > .05) {
      final o = v.pt(V3(mx, 2.2, mz));
      if (o != null) {
        glow(c, o, v.scaleAt(v.depthOf(V3(mx, 2.2, mz))) * 3.4,
            withA(const Color(0xFFFFC978), .45 * w.sky.lamps));
      }
    }
  }

  // ───────────────────────── الحجاج ─────────────────────────

  static void _pilgrim(Canvas c, RifqaSceneView v, WorldState w, double x, double z,
      double hx, double hz, double gait, _Ped st,
      {bool you = false}) {
    final s = w.sky;
    final foot = v.proj(V3(x, 0, z));
    final depth = foot.depth;
    if (depth < 2.4) return;
    final k = foot.k;
    final hgt = st.height;
    final o = foot.o;
    final size = v.size;
    if (o.dx < -80 || o.dx > size.width + 80) return;
    if (o.dy < -hgt * k - 40 || o.dy - hgt * k > size.height + 40) return;

    final lum = s.dayLum;
    final fogT = s.fogT(depth);
    Color col(Color base, [double f = 1]) =>
        mixC(scaleC(base, (.42 + .75 * lum) * f), s.fog, fogT * .9);
    final px = -hz, pz = hx; // اليمين
    Offset q(double side, double fwd, double y) =>
        v.proj(V3(x + px * side + hx * fwd, y, z + pz * side + hz * fwd)).o;

    final skin = col(st.skin);
    final dressKind = st.kind;
    if (depth > 62 && !you) {
      final head = q(0, 0, hgt);
      final body = dressKind == 1
          ? const Color(0xFF222428)
          : const Color(0xFFEFEDE6);
      c.drawLine(
          o,
          head,
          Paint()
            ..color = col(body)
            ..strokeWidth = math.max(1.6, .5 * k)
            ..strokeCap = StrokeCap.round);
      c.drawCircle(head, math.max(1.1, .13 * k), Paint()..color = skin);
      return;
    }

    // الظل
    if (s.shadowAlpha > .05) {
      final d = s.shadowDir, len = hgt * s.shadowStretch * .9;
      final tip = v.proj(V3(x + d.dx * len, 0, z + d.dy * len)).o;
      c.drawLine(
          o,
          tip,
          Paint()
            ..color = withA(const Color(0xFF14130F), .20 * s.shadowAlpha)
            ..strokeWidth = math.max(1.5, .36 * k)
            ..strokeCap = StrokeCap.round);
    }
    c.drawOval(Rect.fromCenter(center: o, width: .85 * k, height: .28 * k),
        Paint()..color = const Color(0x420E0D0A));

    final swing = math.sin(gait) * .30;
    final liftL = math.max(0.0, math.cos(gait)) * .07;
    final liftR = math.max(0.0, -math.cos(gait)) * .07;
    final hipY = hgt * .5, shY = hgt * .82, headY = hgt * .935;
    final footL = q(-.1, swing, liftL), footR = q(.1, -swing, liftR);
    final hipL = q(-.1, 0, hipY), hipR = q(.1, 0, hipY);
    final shL = q(-.2, 0, shY), shR = q(.2, 0, shY);
    final waistL = q(-.17, 0, hipY + .1), waistR = q(.17, 0, hipY + .1);
    final handL = q(-.25, -swing * .9, hipY + .06);
    final handR = q(.25, swing * .9, hipY + .06);
    final head = q(0, 0, headY);
    final headR = math.max(1.1, .105 * k);
    final facing = hx * (v.eye.x - x) + hz * (v.eye.z - z) > 0;
    final limb = math.max(1.2, .09 * k);

    Paint line(Color color, double wd) => Paint()
      ..color = color
      ..strokeWidth = wd
      ..strokeCap = StrokeCap.round;
    void poly(List<Offset> pts, Color color) =>
        c.drawPath(Path()..addPolygon(pts, true), Paint()..color = color);

    switch (dressKind) {
      case 0: // رجل بإحرام أبيض
        final white = col(const Color(0xFFF2F0E8), .8 + .3 * st.tone);
        c.drawLine(hipL, footL, line(skin, limb));
        c.drawLine(hipR, footR, line(skin, limb));
        poly([waistL, waistR, q(.2, -swing * .45, hgt * .1), q(-.2, swing * .45, hgt * .1)], white);
        poly([shL, shR, q(.18, 0, hipY + .02), q(-.18, 0, hipY + .02)],
            col(const Color(0xFFE9E7DE)));
        poly([q(.05, 0, shY + .03), shR, q(.21, 0, shY - .16), q(.07, 0, shY - .1)], skin);
        c.drawLine(shR, handR, line(skin, limb));
        c.drawLine(shL, handL, line(white, limb * 1.15));
        c.drawCircle(head, headR, Paint()..color = skin);
        final hair = Paint()..color = col(const Color(0xFF1F1812));
        if (facing) {
          c.drawArc(Rect.fromCircle(center: head, radius: headR), math.pi, math.pi, true, hair);
        } else {
          c.drawCircle(head, headR, hair);
        }
        break;
      case 1: // امرأة بعباءة سوداء
      case 2: // امرأة بلباس فاتح
        final robe = dressKind == 1
            ? col(const Color(0xFF1B1B20))
            : col(const Color(0xFFEDEBE4), .85 + .2 * st.tone);
        final scarf = dressKind == 1
            ? col(const Color(0xFF15151A))
            : col(mixC(const Color(0xFFF2F0EA), const Color(0xFFD9C7E8), st.tone * .7));
        poly([shL, shR, q(.32, -swing * .3, hgt * .03), q(-.32, swing * .3, hgt * .03)], robe);
        c.drawLine(shR, handR, line(robe, limb * 1.2));
        c.drawLine(shL, handL, line(robe, limb * 1.2));
        c.drawCircle(head, headR * 1.2, Paint()..color = scarf);
        if (facing) {
          c.drawCircle(head + Offset(0, headR * .1), headR * .62, Paint()..color = skin);
        }
        break;
      default: // رجل بثوب وغترة
        final thobe = col(const Color(0xFFF4F2EA), .9 + .15 * st.tone);
        poly([shL, shR, q(.26, -swing * .3, hgt * .03), q(-.26, swing * .3, hgt * .03)], thobe);
        c.drawLine(shR, handR, line(thobe, limb * 1.2));
        c.drawLine(shL, handL, line(thobe, limb * 1.2));
        c.drawCircle(head, headR * 1.16, Paint()..color = col(const Color(0xFFF7F5EE)));
        c.drawArc(
            Rect.fromCircle(center: head + Offset(0, -headR * .45), radius: headR * 1.1),
            math.pi * 1.1, math.pi * .8, false,
            line(col(const Color(0xFF1A1A1A)), math.max(1, .03 * k)));
        if (facing) {
          c.drawCircle(head + Offset(0, headR * .2), headR * .58, Paint()..color = skin);
        }
    }

    if (you) {
      // حلقة ذهبية وشعاع ضوئي ووسم «أنت»
      final ring = <Offset>[];
      for (var i = 0; i < 28; i++) {
        final a = i * math.pi * 2 / 28;
        final p = v.pt(V3(x + .95 * math.cos(a), .03, z + .95 * math.sin(a)));
        if (p != null) ring.add(p);
      }
      if (ring.length > 6) {
        c.drawPath(
            Path()..addPolygon(ring, true),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(1.5, .07 * k)
              ..color = withA(gold, .95));
      }
      glow(c, o, k * 1.7, withA(gold, .35));
      final top = q(0, 0, 7.5);
      c.drawLine(
          o,
          top,
          Paint()
            ..blendMode = BlendMode.plus
            ..strokeWidth = math.max(2, .5 * k)
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [withA(gold, .5), withA(gold, 0)],
            ).createShader(Rect.fromPoints(o, top).inflate(2)));
      final tp = TextCache.get('أنت', 12, const Color(0xFF3B2A00));
      final at = head + Offset(0, -headR * 3.2 - 16);
      final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: at, width: tp.width + 14, height: tp.height + 6),
          const Radius.circular(10));
      c.drawRRect(r, Paint()..color = gold);
      tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
    }
  }

  static void _youTrail(Canvas c, RifqaSceneView v, WorldState w) {
    if (!w.youVisible || w.youTrail <= 0) return;
    const steps = 26;
    Offset? prev;
    for (var i = 0; i <= steps; i++) {
      final a = w.youAngle + w.youTrail * i / steps;
      final p = V3(w.youRadius * math.cos(a), .06, w.youRadius * math.sin(a));
      final o = v.pt(p);
      if (o != null && prev != null) {
        final fade = math.pow(1 - i / steps, 1.6).toDouble();
        c.drawLine(
            prev,
            o,
            Paint()
              ..blendMode = BlendMode.plus
              ..color = withA(gold, .6 * fade)
              ..strokeWidth = math.max(1.5, .45 * v.scaleAt(v.depthOf(p)))
              ..strokeCap = StrokeCap.round);
      }
      prev = o;
    }
  }

  // ───────────────────────── الحمام ─────────────────────────

  static void _bird(Canvas c, RifqaSceneView v, WorldState w, _Bird b) {
    final s = w.sky;
    final t = w.clock;
    final a = b.phase + t * b.speed;
    final y = b.height + math.sin(t * .8 + b.phase * 3) * 1.4;
    final x = b.radius * math.cos(a), z = b.radius * math.sin(a);
    final sg = b.speed >= 0 ? 1.0 : -1.0;
    final hx = -math.sin(a) * sg, hz = math.cos(a) * sg;
    final px = -hz, pz = hx;
    final flap = math.sin(t * b.flap + b.phase) * .5;
    Offset q(double side, double fwd, double dy) =>
        v.proj(V3(x + px * side + hx * fwd, y + dy, z + pz * side + hz * fwd)).o;
    final depth = v.depthOf(V3(x, y, z));
    final color = mixC(scaleC(const Color(0xFFB6B0A6), .4 + .7 * s.dayLum), s.fog,
        s.fogT(depth) * .8);
    final alpha = 1 - s.lamps * .85;
    final path = Path()
      ..addPolygon([
        q(-.7, -.05, flap * .8),
        q(0, .32, 0),
        q(.7, -.05, flap * .8),
        q(0, -.34, 0),
      ], true);
    c.drawPath(path, Paint()..color = withA(color, alpha));
  }

  // ───────────────────────── المؤثرات اللاحقة ─────────────────────────

  static void _post(Canvas c, RifqaSceneView v, WorldState w) {
    final s = w.sky;
    final size = v.size;
    final rect = Offset.zero & size;
    final diag = size.longestSide;
    final center = size.center(Offset.zero);
    final l = s.light;
    final q = v.view(V3(v.eye.x + l.x * 6000, v.eye.y + l.y * 6000,
        v.eye.z + l.z * 6000));

    // هالة الكعبة ليلًا
    if (s.lamps > .2) {
      final o = v.pt(const V3(0, 7, 0));
      if (o != null) {
        glow(c, o, v.scaleAt(v.depthOf(const V3(0, 7, 0))) * 17,
            withA(const Color(0xFFFFD18A), .2 * s.lamps));
      }
    }

    if (q.z > 1 && s.moon < .5 && s.sunPower > .12) {
      final so = v.scr(q);
      final off = (so - center).distance;
      final vis = clamp01(1.25 - off / (diag * .85));
      final power = clamp01(s.sunPower) * smooth((s.sunEl + .1) / .25);
      glow(c, so, diag * .75, withA(s.sunColor, .30 * power * vis));

      // أشعة الشمس
      if (w.quality >= 1 && vis > .05) {
        final len = diag * 1.5;
        final path = Path();
        const rays = 14;
        for (var i = 0; i < rays; i++) {
          final ang = i * math.pi * 2 / rays + math.sin(i * 7.1) * .12;
          final wd = (.035 + .02 * (.5 + .5 * math.sin(w.clock * .35 + i * 1.7)));
          path
            ..moveTo(so.dx, so.dy)
            ..lineTo(so.dx + math.cos(ang - wd) * len, so.dy + math.sin(ang - wd) * len)
            ..lineTo(so.dx + math.cos(ang + wd) * len, so.dy + math.sin(ang + wd) * len)
            ..close();
        }
        c.drawPath(
            path,
            Paint()
              ..blendMode = BlendMode.plus
              ..shader = RadialGradient(
                colors: [withA(s.sunColor, .20 * power * vis), withA(s.sunColor, 0)],
              ).createShader(Rect.fromCircle(center: so, radius: len)));
      }

      // انعكاس لامع على الرخام
      final hy = _horizonY(v);
      if (s.sunEl > .04 && hy < size.height) {
        final cy = hy + (size.height - hy) * .3;
        c.save();
        c.translate(so.dx, cy);
        c.scale(.45, 1.6);
        glow(c, Offset.zero, diag * .22, withA(s.sunColor, .22 * power * vis));
        c.restore();
      }

      // بقع العدسة
      if (w.quality >= 2 && vis > .25) {
        for (final f in const [.35, .62, .9, 1.25]) {
          final p = Offset.lerp(so, center, f)!;
          final r = diag * (.02 + .025 * f);
          c.drawCircle(
              p,
              r,
              Paint()
                ..blendMode = BlendMode.plus
                ..color = withA(s.sunColor, .06 * power * vis));
          c.drawCircle(
              p,
              r,
              Paint()
                ..blendMode = BlendMode.plus
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.2
                ..color = withA(s.sunColor, .08 * power * vis));
        }
      }
    }

    // غبار عائم في الضوء
    if (w.quality >= 1) {
      final n = w.quality >= 2 ? 70 : 36;
      final t = w.clock;
      final tg = v.cam.target;
      final lightK = math.max(s.sunPower * .8, s.lamps * .3);
      final dust = Paint()..blendMode = BlendMode.plus;
      for (var i = 0; i < n; i++) {
        double h(int k) => (math.sin((i * 3 + k) * 91.345) * 43758.5453).abs() % 1;
        final dx = ((h(1) * 60 + t * (.25 + .3 * h(2))) % 60) - 30;
        final dz = ((h(3) * 60 + t * (.15 + .2 * h(1))) % 60) - 30;
        final p = V3(tg.x + dx, 1 + h(2) * 18 + math.sin(t * .5 + i) * .6, tg.z + dz);
        final o = v.pt(p);
        if (o == null) continue;
        final r = (.07 * v.scaleAt(v.depthOf(p))).clamp(.7, 2.4).toDouble();
        final a = (.5 + .5 * math.sin(t * 1.3 + i * 2.1)) * .55 * lightK;
        dust.color = withA(const Color(0xFFFFEFC8), a);
        c.drawCircle(o, r, dust);
      }
    }

    // تدرّج لوني وتعتيم الأطراف
    c.drawRect(rect, Paint()..blendMode = BlendMode.softLight..color = withA(s.grade, .22));
    c.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            radius: .95,
            colors: [const Color(0x00000000), withA(Colors.black, .38)],
            stops: const [.55, 1],
          ).createShader(rect));
  }

  // ───────────────────────── الوسوم ─────────────────────────

  static void _labels(Canvas c, RifqaSceneView v, WorldState w) {
    const items = <(String, V3)>[
      ('الحجر الأسود', V3(kaabaHw, 2.9, kaabaHd)),
      ('باب الكعبة', V3(kaabaHw, 6.6, 2.4)),
      ('الحِجر', V3(0, 2.6, -kaabaHd - 3.6)),
      ('الركن اليماني', V3(-kaabaHw, 5.2, kaabaHd)),
      ('الركن العراقي', V3(kaabaHw, 5.2, -kaabaHd)),
      ('الركن الشامي', V3(-kaabaHw, 5.2, -kaabaHd)),
      ('مقام إبراهيم', V3(kaabaHw + 10.5, 5.4, .5)),
    ];
    for (final it in items) {
      final d = v.depthOf(it.$2);
      if (d < 3) continue;
      final o = v.pt(it.$2);
      if (o == null) continue;
      final a = 1 - smooth((d - 70) / 40);
      if (a <= .02) continue;
      final tp = TextCache.get(it.$1, 12, Colors.white);
      final r = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: o + const Offset(0, -18),
              width: tp.width + 16,
              height: tp.height + 8),
          const Radius.circular(10));
      c.drawLine(o, o + const Offset(0, -10), Paint()..color = withA(gold, .8 * a)..strokeWidth = 1);
      c.drawCircle(o, 3, Paint()..color = withA(gold, a));
      c.drawRRect(r, Paint()..color = withA(const Color(0xFF062F26), .82 * a));
      c.drawRRect(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = withA(gold, .8 * a));
      tp.paint(c, o + Offset(-tp.width / 2, -18 - tp.height / 2));
    }
  }
}