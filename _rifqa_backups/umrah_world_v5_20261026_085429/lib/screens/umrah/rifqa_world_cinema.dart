import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'umrah_3d.dart' show V3;
import 'umrah_3d_materials.dart';
import 'umrah_realism.dart';
import 'umrah_world.dart';
import 'umrah_cinema_3d.dart' show UmrahCinema3D;
import 'umrah_voice.dart';

// RIFQA: a guided educational world using the user's UmrahWorld/RCam/Sky engine.
// This module is additive: the seven-step guide, photo journey, video and
// manual tawaf/sai counters remain owned by their existing screens.
class RifqaWorldCinema extends StatefulWidget {
  const RifqaWorldCinema({super.key});
  @override
  State<RifqaWorldCinema> createState() => _RifqaWorldCinemaState();
}

class _RifqaWorldCinemaState extends State<RifqaWorldCinema>
    with SingleTickerProviderStateMixin {
  static const _deep = Color(0xFF062F26);
  static const _gold = Color(0xFFE9C77F);
  static const _cream = Color(0xFFFFF8E8);
  late final AnimationController _film = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 100),
  );
  Umrah3DMaterials? _materials;
  String? _assetsWarning;
  bool _free = false;
  int _quality = 0; // default low on phones; higher quality is opt-in.
  double _skyPhase = 3.0; // Maghrib. Presets defined by supplied Sky toolkit.
  RCam _orbit = RCam(yaw: -2.45, pitch: .62, dist: 54, target: const V3(0, 5, 0));
  double _startDist = 54;

  static const _titles = [
    'رؤية الحرم من الأعلى',
    'الاقتراب من الكعبة',
    'موضع الحجر الأسود',
    'اتجاه الطواف',
    'مسار الأشواط السبعة',
    'بعد الطواف',
  ];
  static const _details = [
    'تصوّر تعليمي للمطاف والكعبة المشرفة، وليس تصويرًا حقيقيًا.',
    'اجعلي الكعبة عن يسارك مع التزام مسارات الحركة والسكينة.',
    'يبدأ كل شوط عند محاذاة الحجر الأسود، دون مزاحمة.',
    'الطواف عكس عقارب الساعة عند النظر من أعلى، ومن خارج الحِجر.',
    'كل دورة من الحجر الأسود إليه شوط. الحركة هنا محاكاة فقط.',
    'بعد سبعة أشواط تُصلّى ركعتا الطواف ثم يُشرب ماء زمزم.',
  ];

  int _shot(double f) {
    if (f < .13) return 0;
    if (f < .25) return 1;
    if (f < .36) return 2;
    if (f < .49) return 3;
    if (f < .85) return 4;
    return 5;
  }

  static RCam _camera(double f) {
    final scenes = <(double, RCam)>[
      (0, RCam(yaw: -2.8, pitch: 1.05, dist: 82, target: const V3(0, 2, 0))),
      (.13, RCam(yaw: -2.50, pitch: .58, dist: 51, target: const V3(0, 5, 0))),
      (.25, RCam(yaw: -1.65, pitch: .31, dist: 27, target: const V3(4, 3, 4))),
      (.36, RCam(yaw: -2.25, pitch: .28, dist: 37, target: const V3(0, 5, 0))),
      (.49, RCam(yaw: -2.90, pitch: 1.16, dist: 58, target: const V3(0, 1, 0))),
      (.85, RCam(yaw: -1.90, pitch: .72, dist: 67, target: const V3(0, 3, 0))),
      (1, RCam(yaw: -2.50, pitch: .55, dist: 80, target: const V3(0, 5, 0))),
    ];
    var i = 0;
    while (i < scenes.length - 2 && f >= scenes[i + 1].$1) {
      i++;
    }
    final a = scenes[i], b = scenes[i + 1];
    final t = Curves.easeInOutCubic.transform(
      ((f - a.$1) / (b.$1 - a.$1)).clamp(0.0, 1.0).toDouble(),
    );
    return RCam.lerp(a.$2, b.$2, t);
  }

  @override
  void initState() {
    super.initState();
    Umrah3DMaterials.load().then((m) {
      if (mounted) setState(() => _materials = m);
    }).catchError((Object _) {
      if (mounted) {
        setState(() => _assetsWarning = 'تعذر تحميل الخامات؛ سيُستخدم الرسم التوضيحي.');
      }
    });
    _start();
  }

  void _speak() {
    final index = _shot(_film.value);
    UVoice.I.speak('جولة تعليمية حول الكعبة المشرفة. ${_details[index]}');
  }

  void _start() {
    if (_film.value >= 1) _film.value = 0;
    _film.forward();
    _speak();
    if (mounted) setState(() {});
  }

  void _pause() {
    _film.stop();
    UVoice.I.stop();
    if (mounted) setState(() {});
  }

  void _toggleFree() {
    if (!_free) {
      _pause();
      _orbit = _camera(_film.value);
    }
    setState(() => _free = !_free);
  }

  @override
  void dispose() {
    _film.dispose();
    UVoice.I.stop();
    super.dispose();
  }

  void _openNarratedVersion() async {
    _pause();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const UmrahCinema3D()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _deep,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, bounds) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_forward, color: _gold),
                        tooltip: 'الرجوع لرحلة العمرة',
                      ),
                      const Expanded(
                        child: Column(
                          children: [
                            Text('الحرم في جولة سينمائية 3D',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18, color: _gold,
                                    fontWeight: FontWeight.w800)),
                            Text('مشهد تعليمي بالكاميرا والإضاءة التفاعلية',
                                style: TextStyle(color: _cream, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'الشرح الصوتي',
                        onPressed: _speak,
                        icon: const Icon(Icons.record_voice_over_rounded, color: _gold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: _free
                          ? (_) => _startDist = _orbit.dist
                          : null,
                      onScaleUpdate: _free
                          ? (d) => setState(() {
                                _orbit.yaw -= d.focalPointDelta.dx * .008;
                                _orbit.pitch = (_orbit.pitch +
                                        d.focalPointDelta.dy * .004)
                                    .clamp(.06, 1.42).toDouble();
                                _orbit.dist = (_startDist / d.scale)
                                    .clamp(18.0, 120.0).toDouble();
                              })
                          : null,
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _film,
                          builder: (_, __) => CustomPaint(
                            child: const SizedBox.expand(),
                            painter: _CinemaWorldPainter(
                              time: _film.value,
                              free: _free,
                              orbit: _orbit,
                              quality: _quality,
                              skyPhase: _skyPhase,
                              material: _materials,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: math.min(268.0, bounds.maxHeight * .43)),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF104435),
                          border: Border.all(color: _gold.withValues(alpha: .7)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AnimatedBuilder(
                          animation: _film,
                          builder: (_, __) => _controls(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    final index = _shot(_film.value);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(_titles[index],
                  style: const TextStyle(color: _gold, fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ),
            Text('${index + 1} / 6',
                style: const TextStyle(color: _gold, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 5),
        Text(_details[index],
            textAlign: TextAlign.center,
            style: const TextStyle(color: _cream, fontSize: 12, height: 1.5)),
        if (_assetsWarning != null)
          Text(_assetsWarning!, style: const TextStyle(color: _gold, fontSize: 11)),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _gold, inactiveTrackColor: Colors.white24,
            thumbColor: _gold, trackHeight: 3,
          ),
          child: Slider(
            value: _film.value,
            onChangeStart: (_) => _pause(),
            onChanged: (v) {
              _film.value = v;
            },
          ),
        ),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _free ? null : (_film.isAnimating ? _pause : _start),
              icon: Icon(_film.isAnimating
                  ? Icons.pause_rounded : Icons.play_arrow_rounded),
              label: Text(_film.isAnimating ? 'إيقاف' : 'تشغيل'),
              style: FilledButton.styleFrom(
                  backgroundColor: _gold, foregroundColor: _deep),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _toggleFree,
              icon: const Icon(Icons.threed_rotation_rounded),
              label: Text(_free ? 'عودة للكاميرا' : 'تحكم بالكاميرا'),
              style: OutlinedButton.styleFrom(foregroundColor: _gold),
            ),
            const Spacer(),
            PopupMenuButton<int>(
              icon: const Icon(Icons.tune_rounded, color: _gold),
              tooltip: 'جودة المشهد',
              onSelected: (v) => setState(() => _quality = v),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 0, child: Text('أداء أسرع')),
                PopupMenuItem(value: 1, child: Text('جودة متوسطة')),
                PopupMenuItem(value: 2, child: Text('جودة عالية')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            const Text('إضاءة المشهد', style: TextStyle(color: _cream, fontSize: 11)),
            Expanded(
              child: Slider(
                value: _skyPhase,
                min: 0, max: 4,
                divisions: 4,
                activeColor: _gold,
                onChanged: (v) => setState(() => _skyPhase = v),
              ),
            ),
            Text(Sky.names[_skyPhase.round().clamp(0, 4).toInt()],
                style: const TextStyle(color: _gold, fontSize: 11)),
          ],
        ),
        TextButton.icon(
          onPressed: _openNarratedVersion,
          icon: const Icon(Icons.headphones_rounded, size: 17),
          label: const Text('مشهد الطواف بالشرح الصوتي والتوقيت'),
          style: TextButton.styleFrom(foregroundColor: _gold),
        ),
        const Text('المشهد واللفات توضيحية فقط؛ لا يزيد عداد المناسك الفعلية.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _CinemaWorldPainter extends CustomPainter {
  const _CinemaWorldPainter({
    required this.time,
    required this.free,
    required this.orbit,
    required this.quality,
    required this.skyPhase,
    required this.material,
  });
  final double time;
  final bool free;
  final RCam orbit;
  final int quality;
  final double skyPhase;
  final Umrah3DMaterials? material;

  @override
  void paint(Canvas canvas, Size size) {
    final camera = free ? orbit : _RifqaWorldCinemaState._camera(time);
    // WorldState.youTrail only illustrates simulated movement in the scene.
    final walking = time > .36 && time < .85;
    final angle = -time * 14 * math.pi;
    UmrahWorld.paint(
      canvas, size, camera,
      WorldState(
        clock: time * 100,
        sky: Sky.at(skyPhase),
        materials: material,
        quality: quality,
        youAngle: angle,
        youRadius: 16,
        youVisible: walking,
        youTrail: walking ? .8 : 0,
        glow: walking ? .65 : 0,
        labels: !walking,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _CinemaWorldPainter old) =>
      time != old.time || quality != old.quality || skyPhase != old.skyPhase ||
      free != old.free || orbit != old.orbit || material != old.material;
}
