import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'umrah_3d.dart' show Cam, V3;
import 'umrah_3d_materials.dart';

/// RIFQA guided educational Tawaf visualization.
/// Kaaba imagery is mapped from the project's existing photographic textures.
/// This is a 3D illustration, NOT filmed footage or a geographical 3D scan.
/// The seven simulated orbits are instructional, not a count of worship performed.
class UmrahCinema3D extends StatefulWidget {
  const UmrahCinema3D({super.key, this.videoBuilder});

  /// Optional licensed video overlay supplied by the host app for each shot.
  final Widget? Function(BuildContext context, int shot)? videoBuilder;

  @override
  State<UmrahCinema3D> createState() => _UmrahCinema3DState();
}

const _deep = Color(0xFF062F26);
const _gold = Color(0xFFE5C47B);
const _cream = Color(0xFFFFF7E8);
const double _hw = 6, _hd = 5.5, _kh = 13;
const double _walkRadius = 16;
const double _lapStart = .20, _lapEnd = .82;
const double _tawafDirection = -1;
final double _corner = math.atan2(_hd, _hw);

double _clamp01(double a) => a.clamp(0.0, 1.0).toDouble();
double _mix(double a, double b, double t) => a + (b - a) * t;
double _angleMix(double a, double b, double t) {
  final delta = math.atan2(math.sin(b - a), math.cos(b - a));
  return a + delta * t;
}
double _lapFraction(double progress) =>
    _clamp01((progress - _lapStart) / (_lapEnd - _lapStart));
int _simulatedLaps(double progress) =>
    (_lapFraction(progress) * 7).floor().clamp(0, 7).toInt();
double _visitorAngle(double progress) =>
    _corner + _tawafDirection * 7 * math.pi * 2 * _lapFraction(progress);

/// Soft atmospheric haze: things farther from the camera fade toward the
/// horizon tone instead of staying tack-sharp, which is what reads as
/// "depth" rather than a flat cut-out scene.
Color _fogBlend(Color base, double depth) {
  final haze = _clamp01((depth - 18) / 70);
  return Color.lerp(base, const Color(0xFFBFA878), haze * .45) ?? base;
}

const _shotBounds = <double>[0, .08, .18, .27, .64, .82, 1.01];
const _shotNames = <String>[
  'المسجد الحرام من الأعلى',
  'نقترب من الكعبة المشرفة',
  'موضع الحجر الأسود',
  'بداية الطواف',
  'مسار الأشواط السبعة',
  'بعد انتهاء الطواف',
];
const _shotDescriptions = <String>[
  'جولة تعليمية حول الكعبة المشرفة وصحن المطاف.',
  'نقترب من الكعبة. اجعل الكعبة عن يسارك أثناء الطواف.',
  'ابدأ الشوط عند محاذاة الحجر الأسود، ولا تزاحم الناس.',
  'اتبع اتجاه الطواف الصحيح، وامشِ بسكينة وخشوع.',
  'كل دورة كاملة من الحجر الأسود إليه تُحسب شوطًا واحدًا.',
  'بعد سبعة أشواط، صلِّ ركعتين في مكان مناسب ثم اشرب زمزم.',
];
int _shotAt(double f) {
  for (var i = 0; i < _shotNames.length; i++) {
    if (f < _shotBounds[i + 1]) return i;
  }
  return _shotNames.length - 1;
}

class _UmrahCinema3DState extends State<UmrahCinema3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 96),
  );
  final AudioPlayer _audio = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  Umrah3DMaterials? _materials;
  bool _audioReady = false;
  bool _loading = true;
  bool _silentPlaying = false;
  bool _muted = false;
  bool _free = false;
  bool _wasPlaying = false;
  String? _notice;
  int _lastLap = -1;
  Cam _freeCam = Cam(
    yaw: -2.4,
    pitch: .5,
    dist: 43,
    target: const V3(0, 4, 0),
  );
  double _pinchDistance = 43;

  @override
  void initState() {
    super.initState();
    _progress.addListener(() {
      final lap = _simulatedLaps(_progress.value);
      if (lap > 0 && lap != _lastLap && _progress.value < _lapEnd) {
        HapticFeedback.selectionClick();
      }
      _lastLap = lap;
    });
    _progress.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _silentPlaying = false);
      }
    });
    _positionSub = _audio.positionStream.listen((pos) {
      final total = _audio.duration;
      if (!mounted || !_audioReady || total == null || total.inMilliseconds <= 0) {
        return;
      }
      // Render at display refresh rate and correct significant audio/video drift.
      final fraction = _clamp01(pos.inMilliseconds / total.inMilliseconds);
      if ((_progress.value - fraction).abs() > .035) {
        _progress.value = fraction;
        if (_audio.playing && !_free && fraction < 1) _progress.forward();
      }
    });
    _stateSub = _audio.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        _progress.value = 1;
      }
      setState(() {});
    });
    _boot();
  }

  Future<void> _boot() async {
    try {
      final materials = await Umrah3DMaterials.load();
      if (mounted) setState(() => _materials = materials);
    } catch (_) {
      if (mounted) setState(() => _notice = 'تعذّر تحميل الخامات المصوّرة؛ يظهر المجسم التوضيحي.');
    }
    try {
      final duration = await _audio.setAsset('assets/audio/umrah/step_4.mp3');
      if (!mounted) return;
      _audioReady = true;
      if (duration != null && duration.inMilliseconds > 0) {
        _progress.duration = duration;
      }
      await _audio.setVolume(_muted ? 0 : 1);
    } catch (_) {
      if (!mounted) return;
      _notice = 'ملف شرح الطواف غير متاح؛ يمكنك مشاهدة الجولة بدون صوت.';
    }
    if (!mounted) return;
    setState(() => _loading = false);
    await _play();
  }

  bool get _isPlaying =>
      _audioReady ? _audio.playing : _silentPlaying;

  Future<void> _play() async {
    if (_loading || _free) return;
    if (_progress.value >= .999) {
      _progress.value = 0;
      if (_audioReady) await _audio.seek(Duration.zero);
    }
    _progress.forward();
    if (_audioReady) {
      unawaited(_audio.play().catchError((Object error) {
        if (mounted) setState(() => _notice = 'تعذّر تشغيل التعليق الصوتي.');
      }));
    } else {
      _silentPlaying = true;
    }
    if (mounted) setState(() {});
  }

  Future<void> _pause() async {
    _progress.stop();
    if (_audioReady) {
      await _audio.pause();
    } else {
      _silentPlaying = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _seek(double fraction) async {
    final f = _clamp01(fraction);
    _progress.value = f;
    if (_audioReady) {
      final duration = _audio.duration;
      if (duration != null) {
        await _audio.seek(Duration(milliseconds: (duration.inMilliseconds * f).round()));
      }
    }
  }

  Future<void> _restart() async {
    await _pause();
    await _seek(0);
    if (!_free) await _play();
  }

  Future<void> _toggleFree() async {
    if (!_free) {
      await _pause();
      _freeCam = _cameraAt(_progress.value);
    }
    if (mounted) setState(() => _free = !_free);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _progress.dispose();
    _audio.dispose();
    super.dispose();
  }

  Widget _roundButton(IconData icon, VoidCallback action, String tip) =>
      IconButton.filledTonal(
        tooltip: tip,
        onPressed: action,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xDD062F26),
          foregroundColor: _gold,
          side: const BorderSide(color: _gold),
        ),
        icon: Icon(icon),
      );

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _deep,
          body: Stack(fit: StackFit.expand, children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _free
                  ? (_) => _pinchDistance = _freeCam.dist
                  : null,
              onScaleUpdate: _free
                  ? (details) => setState(() {
                        _freeCam.yaw -= details.focalPointDelta.dx * .008;
                        _freeCam.pitch = (_freeCam.pitch +
                                details.focalPointDelta.dy * .006)
                            .clamp(.06, 1.43)
                            .toDouble();
                        _freeCam.dist = (_pinchDistance / details.scale)
                            .clamp(9.0, 85.0)
                            .toDouble();
                      })
                  : null,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _TawafPainter(
                    progress: _progress,
                    materials: _materials,
                    free: _free,
                    freeCamera: _freeCam,
                  ),
                ),
              ),
            ),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, .23, .58, 1],
                    colors: [
                      Color(0xC700100C),
                      Colors.transparent,
                      Colors.transparent,
                      Color(0xEB04140F),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 8, 15, 0),
                child: Column(children: [
                  Row(children: [
                    _roundButton(Icons.arrow_forward_rounded,
                        () => Navigator.pop(context), 'رجوع'),
                    const Expanded(
                      child: Column(children: [
                        Text('رِفقة',
                            style: TextStyle(
                                color: _gold,
                                fontSize: 26,
                                fontWeight: FontWeight.w900)),
                        Text('الطواف · شرح متزامن مع المجسم 3D',
                            style: TextStyle(
                                color: _cream, fontSize: 12)),
                      ]),
                    ),
                    _roundButton(
                      _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      () async {
                        setState(() => _muted = !_muted);
                        if (_audioReady) {
                          await _audio.setVolume(_muted ? 0 : 1);
                        }
                      },
                      'الصوت',
                    ),
                  ]),
                  const SizedBox(height: 5),
                  const Text(
                    'محاكاة تعليمية ثلاثية الأبعاد — ليست تصويرًا حقيقيًا',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _cream, fontSize: 11),
                  ),
                ]),
              ),
            ),
            if (widget.videoBuilder != null)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 100,
                right: 16,
                width: 148,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (ctx, _) =>
                          widget.videoBuilder!(ctx, _shotAt(_progress.value)) ??
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 14,
              right: 14,
              bottom: MediaQuery.paddingOf(context).bottom + 14,
              child: AnimatedBuilder(
                animation: _progress,
                builder: (_, __) => _controlPanel(),
              ),
            ),
          ]),
        ),
      );

  Widget _controlPanel() {
    final f = _progress.value;
    final shot = _shotAt(f);
    final laps = _simulatedLaps(f);
    final onRoute = f >= _lapStart && f < _lapEnd;
    final duration = _audioReady
        ? (_audio.duration ?? const Duration(seconds: 96))
        : const Duration(seconds: 96);
    final elapsed = Duration(milliseconds: (duration.inMilliseconds * f).round());
    String clock(Duration d) =>
        '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xEF06392E),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _gold.withValues(alpha: .75)),
      ),
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 11),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(
            child: Text(
              _shotNames[shot],
              style: const TextStyle(
                  color: _gold, fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          if (onRoute)
            Text('الشوط ${math.min(7, laps + 1)} / 7',
                style: const TextStyle(
                    color: Colors.white, fontSize: 12)),
        ]),
        const SizedBox(height: 7),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _shotDescriptions[shot],
            key: ValueKey(shot),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _cream, height: 1.5, fontSize: 14),
          ),
        ),
        if (_notice != null) ...[
          const SizedBox(height: 4),
          Text(_notice!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _gold, fontSize: 11)),
        ],
        const SizedBox(height: 10),
        Row(
          children: List.generate(7, (i) {
            final highlighted = i < laps ||
                (onRoute && i == laps);
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: highlighted ? _gold : Colors.white24,
                ),
              ),
            );
          }),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _gold,
            inactiveTrackColor: Colors.white30,
            thumbColor: _gold,
            trackHeight: 3,
          ),
          child: Slider(
            value: f,
            onChangeStart: (_) {
              _wasPlaying = _isPlaying;
              _pause();
            },
            onChanged: (value) => _progress.value = value,
            onChangeEnd: (value) async {
              await _seek(value);
              if (_wasPlaying && !_free) await _play();
            },
          ),
        ),
        Row(children: [
          Text('${clock(elapsed)} / ${clock(duration)}',
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const Spacer(),
          const Text('الطواف المعروض محاكاة، وليس عدّاد نسك فعلي',
              style: TextStyle(color: Colors.white60, fontSize: 10)),
        ]),
        const SizedBox(height: 7),
        Row(children: [
          Material(
            color: _gold,
            shape: const CircleBorder(),
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: _deep,
                size: 29,
              ),
              onPressed: _loading || _free
                  ? null
                  : () => _isPlaying ? _pause() : _play(),
            ),
          ),
          IconButton(
            tooltip: 'إعادة الجولة',
            onPressed: _restart,
            icon: const Icon(Icons.replay_rounded, color: _gold),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _toggleFree,
            style: OutlinedButton.styleFrom(
              foregroundColor: _free ? _deep : _gold,
              backgroundColor: _free ? _gold : Colors.transparent,
              side: const BorderSide(color: _gold),
            ),
            icon: Icon(_free
                ? Icons.movie_filter_rounded
                : Icons.threed_rotation_rounded),
            label: Text(_free ? 'العودة للجولة' : 'تدوير المجسم'),
          ),
        ]),
      ]),
    );
  }
}

class _VertexFace {
  const _VertexFace(this.points, this.normal, this.front);
  final List<V3> points;
  final V3 normal;
  final bool front;
}

class _TawafPainter extends CustomPainter {
  _TawafPainter({
    required this.progress,
    required this.materials,
    required this.free,
    required this.freeCamera,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Umrah3DMaterials? materials;
  final bool free;
  final Cam freeCamera;

  static const _light = V3(-.35, .8, .42);
  static final _pilgrims = List.generate(62, (i) {
    final random = math.Random(200 + i * 31);
    return (
      radius: 18 + random.nextDouble() * 28,
      phase: random.nextDouble() * math.pi * 2,
      dark: random.nextDouble() < .24,
      pace: .7 + random.nextDouble() * .6,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final f = progress.value;
    final camera = free ? freeCamera : _cameraAt(f);
    final seconds = f * 96;
    final entire = Offset.zero & size;
    canvas.drawRect(entire, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF04141C), Color(0xFF174039), Color(0xFF9B8060)],
      ).createShader(entire));

    // A soft golden-hour glow, low and off-center, so the sky reads as lit
    // rather than a flat gradient fill.
    final sunCenter = Offset(size.width * .76, size.height * .18);
    final sunRadius = size.width * .30;
    canvas.drawCircle(
      sunCenter,
      sunRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [_gold.withValues(alpha: .28), _gold.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius)),
    );

    // A handful of slow, drifting birds — pure atmosphere, not part of the
    // ritual itself.
    final birdPaint = Paint()
      ..color = const Color(0x8A2B241E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final bx =
          (size.width * (.06 + i * .24) + seconds * (2.6 + i * .5)) %
                  (size.width + 70) -
              35;
      final by = size.height * (.09 + .04 * math.sin(seconds * .22 + i * 1.7));
      final wing = 5.0 + (i % 2) * 2;
      final bird = Path()
        ..moveTo(bx - wing, by + wing * .55)
        ..quadraticBezierTo(bx, by - wing * .6, bx + wing, by + wing * .55);
      canvas.drawPath(bird, birdPaint);
    }

    final floor = Paint()..color = const Color(0xFFD9CEB8);
    final p0 = camera.project(const V3(-160, -.2, -160), size);
    final p1 = camera.project(const V3(160, -.2, -160), size);
    final p2 = camera.project(const V3(160, -.2, 160), size);
    final p3 = camera.project(const V3(-160, -.2, 160), size);
    if ([p0, p1, p2, p3].every((p) => p.depth > .5)) {
      final path = Path()..moveTo(p0.o.dx, p0.o.dy)
        ..lineTo(p1.o.dx, p1.o.dy)
        ..lineTo(p2.o.dx, p2.o.dy)
        ..lineTo(p3.o.dx, p3.o.dy)
        ..close();
      canvas.drawPath(path, floor);
    }

    // Light rings are guide markings, not part of the real mosque floor.
    _ring(canvas, camera, size, 16.5, 0,
        const Color(0xCCDBC18A), 2.3);
    _ring(canvas, camera, size, 48, 0,
        const Color(0x55857766), 1);
    _ring(canvas, camera, size, 67, 0,
        const Color(0x55857766), 1);

    // Projected Haram courtyard columns as atmospheric geometry.
    for (var i = 0; i < 32; i++) {
      final a = i * 2 * math.pi / 32;
      final x = 70 * math.cos(a);
      final z = 70 * math.sin(a);
      final foot = camera.project(V3(x, 0, z), size);
      final top = camera.project(V3(x, 25, z), size);
      if (foot.depth <= 1 || top.depth <= 1) continue;
      canvas.drawLine(foot.o, top.o,
          Paint()..strokeWidth = math.max(2.0, foot.k * .7)
              ..color = const Color(0xFFA99C7F));
      canvas.drawCircle(top.o, math.max(2.0, top.k * .35),
          Paint()..color = _gold);
    }

    final drawItems = <({double depth, void Function() draw})>[];
    for (final p in _pilgrims) {
      final a = p.phase - seconds * .12 * p.pace / p.radius;
      final x = p.radius * math.cos(a);
      final z = p.radius * math.sin(a);
      final projected = camera.project(V3(x, 0, z), size);
      if (projected.depth <= 1) continue;
      drawItems.add((depth: projected.depth, draw: () {
        final foot = camera.project(V3(x, 0, z), size);
        final head = camera.project(V3(x, 1.8, z), size);
        final body = p.dark ? const Color(0xFF222528) : const Color(0xFFEFEDE6);
        canvas.drawLine(foot.o, head.o,
            Paint()..color = body
                ..strokeWidth = math.max(2.0, foot.k * .46)
                ..strokeCap = StrokeCap.round);
        canvas.drawCircle(head.o, math.max(1.5, foot.k * .18),
            Paint()..color = const Color(0xFFD4B59A));
      }));
    }
    drawItems.add((depth: camera.project(const V3(0, 7, 0), size).depth,
        draw: () => _drawKaaba(canvas, camera, size)));
    drawItems.sort((a, b) => b.depth.compareTo(a.depth));
    for (final it in drawItems) {
      it.draw();
    }

    if (f >= .14 && f <= .33) {
      final corner = camera.project(const V3(_hw, 1.8, _hd), size);
      if (corner.depth > 1) {
        canvas.drawCircle(corner.o, math.max(8, corner.k * 1.6),
            Paint()..color = _gold.withValues(alpha: .17));
        canvas.drawCircle(corner.o, math.max(3.5, corner.k * .24),
            Paint()..color = _gold);
      }
    }
  }

  void _ring(Canvas canvas, Cam cam, Size size, double radius,
      double height, Color color, double width) {
    final p = Paint()..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    const segments = 80;
    Offset? prev;
    for (var i = 0; i <= segments; i++) {
      final a = i * math.pi * 2 / segments;
      final projected = cam.project(
          V3(radius * math.cos(a), height, radius * math.sin(a)), size);
      if (projected.depth > 1 && prev != null) {
        canvas.drawLine(prev, projected.o, p);
      }
      prev = projected.depth > 1 ? projected.o : null;
    }
  }

  void _drawKaaba(Canvas c, Cam cam, Size s) {
    final eye = cam.pos;
    const a = V3(-_hw, 0, -_hd);
    const b = V3(_hw, _kh, _hd);
    final faces = <_VertexFace>[
      _VertexFace([V3(b.x, a.y, b.z), V3(b.x, a.y, a.z),
                   V3(b.x, b.y, a.z), V3(b.x, b.y, b.z)],
                  const V3(1, 0, 0), false),
      _VertexFace([V3(a.x, a.y, a.z), V3(a.x, a.y, b.z),
                   V3(a.x, b.y, b.z), V3(a.x, b.y, a.z)],
                  const V3(-1, 0, 0), false),
      _VertexFace([V3(a.x, a.y, b.z), V3(b.x, a.y, b.z),
                   V3(b.x, b.y, b.z), V3(a.x, b.y, b.z)],
                  const V3(0, 0, 1), true),
      _VertexFace([V3(b.x, a.y, a.z), V3(a.x, a.y, a.z),
                   V3(a.x, b.y, a.z), V3(b.x, b.y, a.z)],
                  const V3(0, 0, -1), true),
    ];
    for (final face in faces) {
      final center = V3(
        face.points.map((v) => v.x).reduce((a, b) => a + b) / 4,
        face.points.map((v) => v.y).reduce((a, b) => a + b) / 4,
        face.points.map((v) => v.z).reduce((a, b) => a + b) / 4,
      );
      final facing = (eye.x - center.x) * face.normal.x +
          (eye.y - center.y) * face.normal.y +
          (eye.z - center.z) * face.normal.z;
      if (facing <= 0) continue;
      final projected = face.points.map((v) => cam.project(v, s)).toList();
      if (projected.any((v) => v.depth <= 1)) continue;
      final offsets = projected.map((v) => v.o).toList();
      final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (final v in offsets.skip(1)) {
        path.lineTo(v.dx, v.dy);
      }
      path.close();
      final material = materials;
      if (material != null) {
        Umrah3DMaterials.quad(
          c,
          [offsets[3], offsets[2], offsets[1], offsets[0]],
          face.front ? material.front : material.side,
          subdivisions: 8,
        );
        c.drawPath(path, Paint()..color = const Color(0x2A000000));
      } else {
        c.drawPath(path, Paint()..color = const Color(0xFF171718));
        final band = Path();
        Offset p(int i, int j, double t) => Offset.lerp(offsets[i], offsets[j], t)!;
        band.moveTo(p(0, 3, .68).dx, p(0, 3, .68).dy);
        band.lineTo(p(1, 2, .68).dx, p(1, 2, .68).dy);
        band.lineTo(p(1, 2, .77).dx, p(1, 2, .77).dy);
        band.lineTo(p(0, 3, .77).dx, p(0, 3, .77).dy);
        band.close();
        c.drawPath(band, Paint()..color = _gold);
      }
    }
    if (eye.y > _kh) {
      final ps = <V3>[
        V3(a.x, b.y, a.z), V3(b.x, b.y, a.z),
        V3(b.x, b.y, b.z), V3(a.x, b.y, b.z),
      ];
      final projected = ps.map((v) => cam.project(v, s)).toList();
      if (projected.every((p) => p.depth > 1)) {
        final path = Path()..moveTo(projected[0].o.dx, projected[0].o.dy);
        for (final p in projected.skip(1)) {
          path.lineTo(p.o.dx, p.o.dy);
        }
        path.close();
        c.drawPath(path, Paint()..color = const Color(0xFF332E29));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TawafPainter old) => true;
}

Cam _cameraAt(double f) {
  final centered = _clamp01(f);
  if (centered < .18) {
    final t = Curves.easeInOutCubic.transform(centered / .18);
    return Cam(
      yaw: _angleMix(-2.75, -2, t),
      pitch: _mix(.57, .31, t),
      dist: _mix(57, 32, t),
      target: V3(0, _mix(6, 4, t), 0),
    );
  }
  if (centered < _lapStart) {
    final t = Curves.easeInOutCubic.transform((centered - .18) / (.02));
    return Cam(
      yaw: _angleMix(-2, -.85, t),
      pitch: _mix(.31, .20, t),
      dist: _mix(32, 23, t),
      target: V3(_mix(0, _hw, t), 2.5, _mix(0, _hd, t)),
    );
  }
  if (centered < _lapEnd) {
    final angle = _visitorAngle(centered);
    return Cam(
      yaw: angle + math.pi,
      pitch: .26,
      dist: 21,
      target: V3(
        _walkRadius * math.cos(angle),
        2.2,
        _walkRadius * math.sin(angle),
      ),
    );
  }
  final t = Curves.easeInOutCubic.transform(
      (centered - _lapEnd) / (1 - _lapEnd));
  return Cam(
    yaw: _angleMix(-1.6, -2.55, t),
    pitch: _mix(.98, .48, t),
    dist: _mix(48, 58, t),
    target: V3(0, _mix(3, 6, t), 0),
  );
}