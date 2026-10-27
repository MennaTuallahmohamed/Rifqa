import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'umrah_voice.dart';
import 'rifqa_world_cinema.dart';
import '../../state/app_state.dart';

// RIFQA — connected mobile-first 3D learning experience.
// Same RifqaPremium3D(kind: 'tawaf'|'sai') contract as the existing journey.
// Progress persists under the SAME keys read by rifqa_premium_journey.dart.
// Camera, narration and milestone ideas are adapted from the existing
// Tawaf3DPage / Sai3DPage (the user's original umrah_3d.dart).
// Images and the GLB are illustrative: this is NOT indoor navigation.

class RifqaPremium3D extends StatefulWidget {
  const RifqaPremium3D({super.key, required this.kind});
  final String kind;

  @override
  State<RifqaPremium3D> createState() => _RifqaPremium3DState();
}

class _RifqaPremium3DState extends State<RifqaPremium3D>
    with TickerProviderStateMixin {
  static const Color emerald = Color(0xFF042E25);
  static const Color forest = Color(0xFF0B4737);
  static const Color gold = Color(0xFFE9C77F);
  static const Color cream = Color(0xFFFFF8EA);

  bool get tawaf => widget.kind == 'tawaf';
  String get storageKey =>
      tawaf ? 'rifqa_premium_tawaf' : 'rifqa_premium_sai';
  String get picture => tawaf
      ? 'assets/umrah/rifqa_premium/rifqa_bridge_tawaf.jpg'
      : 'assets/umrah/rifqa_premium/rifqa_bridge_sai.jpg';
  String get model => tawaf
      ? 'assets/models/rifqa_tawaf_focus.glb'
      : 'assets/models/rifqa_sai_focus.glb';

  late final Ticker _ticker;
  Duration? _lastFrame;
  final TransformationController _zoom = TransformationController();
  int _count = 0;
  int _mode = 0; // 0 clear photo/path; 1 real, orbitable GLB model.
  int _camera = 0; // 0 overhead, 1 eye-level, 2 close.
  double _fraction = 0;
  double _speed = 1;
  bool _running = false;
  bool _autoRotate = false;
  bool _voice = true;
  bool _pathVisible = true;
  bool _isMale = false;
  bool _loading = true;
  int _viewerVersion = 0;
  // Drives only the drifting-light atmosphere overlay above the GLB viewer —
  // kept as its own tiny, always-repeating controller so the dust and glow
  // repaint on their own without rebuilding the whole page every frame.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat();


  String get _title => tawaf ? 'الطواف حول الكعبة' : 'السعي بين الصفا والمروة';
  String get _subtitle => tawaf
      ? 'الكعبة عن يسارك · ابدئي من الحجر الأسود'
      : 'البداية من الصفا · النهاية عند المروة';

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    _load();
  }

  Future<void> _load() async {
    final pref = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _count = (pref.getInt(storageKey) ?? 0).clamp(0, 7).toInt();
      _loading = false;
    });
    _syncOriginalGuide();
  }

  void _tick(Duration time) {
    final previous = _lastFrame;
    _lastFrame = time;
    if (!_running || previous == null || _count >= 7 || !mounted) return;
    final dt = ((time - previous).inMicroseconds / 1000000).clamp(0.0, .08);
    // One illustrated leg is ~18 s. No real-world movement is inferred.
    var value = _fraction + dt * _speed / 18.0;
    if (value >= 1) {
      value -= 1;
      // Visual loop only. Manual + is the ONLY way to update saved lap counts.
      value = value % 1.0;
    }
    if (mounted) setState(() => _fraction = _count >= 7 ? 0 : value);
  }

  Future<void> _changeCount(int next, {bool automatic = false}) async {
    final fixed = next.clamp(0, 7).toInt();
    if (fixed == _count) return;
    if (!mounted) return;
    setState(() {
      _count = fixed;
      if (!automatic) _fraction = 0;
      if (_count >= 7) _running = false;
    });
    HapticFeedback.selectionClick();
    _syncOriginalGuide();
    final pref = await SharedPreferences.getInstance();
    await pref.setInt(storageKey, fixed);
    if (_voice && mounted) {
      final msg = _count == 7
          ? (tawaf
              ? 'تمت الأشواط السبعة في المحاكاة. بعد الطواف صلّي ركعتي الطواف.'
              : 'انتهت الأشواط السبعة في المحاكاة عند المروة. ثم يأتي الحلق أو التقصير.')
          : 'تم الشوط $_count من سبعة في المحاكاة.';
      UVoice.I.speak(msg, rate: .43);
    }
  }

  // Bridge to the ORIGINAL UmrahScreen counters, without replacing it.
  // The Premium Journey separately listens to shared_preferences after pop.
  void _syncOriginalGuide() {
    try {
      final state = AppScope.of(context);
      state.change(() {
        if (tawaf) {
          state.tawaf = _count;
        } else {
          state.sai = _count;
        }
      });
    } catch (_) {
      // Keep the premium simulation usable if AppScope is not an ancestor.
    }
  }

  Future<void> _toggleRun() async {
    if (_loading) return;
    if (_count >= 7) {
      await _changeCount(0);
    }
    setState(() => _running = !_running);
    if (_running && _voice) {
      UVoice.I.speak(tawaf
          ? 'ابدئي من الحجر الأسود، واجعلي الكعبة عن يسارك، واطوفي من خارج الحِجر.'
          : 'ابدئي من الصفا إلى المروة، فالذهاب شوط والعودة شوط آخر.');
    } else {
      UVoice.I.stop();
    }
  }

  void _cameraSet(int n) {
    if (_camera == n) return;
    setState(() {
      _camera = n;
      _viewerVersion++; // Required to apply a new cameraOrbit to model-viewer.
    });
  }

  void _enterModelMode() {
    if (_mode == 1) return;
    setState(() => _mode = 1);
  }

  void _showGuide() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: emerald,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_title,
                    style: const TextStyle(color: gold, fontSize: 23,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                Text(tawaf
                    ? 'ابدئي من محاذاة الحجر الأسود، واتركي الكعبة عن يسارك. يكون الطواف عكس عقارب الساعة من منظور علوي، ومن خارج حِجر إسماعيل. كل دورة كاملة شوط. تجنبي المزاحمة، واذكري الله وادعي بما تشائين.'
                    : 'ابدئي من الصفا متجهة إلى المروة، وهذا الشوط الأول. العودة إلى الصفا هي الشوط الثاني. يستمر السعي سبعة أشواط وتنتهي السابعة عند المروة. بين العلامتين الخضراوين يسرع الرجال إن تيسر، والنساء يمشين بسكينة.',
                    style: const TextStyle(color: cream, fontSize: 16, height: 1.75)),
                const SizedBox(height: 16),
                const Text('هذه تجربة تعلّمية توضيحية، وليست عدّادًا آليًا للمناسك الحقيقية أو خريطة ملاحية.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: gold, fontSize: 12, height: 1.6)),
                const SizedBox(height: 12),
                TextButton(onPressed: () => Navigator.pop(ctx),
                    child: const Text('إغلاق', style: TextStyle(color: gold))),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openOfficialMap() async {
    final uri = Uri.parse('https://alharamain.gov.sa/public/?page=interactive_maps_ar');
    try {
      final result = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!result && mounted) _notice('تعذر فتح الخريطة الرسمية');
    } catch (_) {
      if (mounted) _notice('تحققي من اتصال الإنترنت لفتح الخريطة الرسمية');
    }
  }

  void _notice(String text) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text)),
      );

  @override
  void dispose() {
    _running = false;
    _ticker.dispose();
    _zoom.dispose();
    _ambient.dispose();
    UVoice.I.stop();
    super.dispose();
  }

  Widget _pill(String text, bool active, VoidCallback tap) =>
      OutlinedButton(
        onPressed: tap,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          backgroundColor: active ? gold : emerald,
          foregroundColor: active ? emerald : gold,
          side: const BorderSide(color: gold, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w700)),
      );

  Widget _imageView() => ClipRRect(
    borderRadius: BorderRadius.circular(21),
    child: Stack(fit: StackFit.expand, children: [
      Image.asset(picture, fit: BoxFit.cover,
          color: Colors.black.withValues(alpha: .32), colorBlendMode: BlendMode.darken),
      InteractiveViewer(
        transformationController: _zoom,
        minScale: 1,
        maxScale: 4,
        child: Image.asset(picture,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const ColoredBox(
              color: forest, child: Center(child: Icon(Icons.image,
              color: gold, size: 58))),
        ),
      ),
      if (_pathVisible)
        IgnorePointer(child: CustomPaint(
          painter: _DirectionOverlay(tawaf: tawaf,
              completed: _count, fraction: _fraction),
        )),
      Positioned(top: 10, left: 10, child: IconButton.filledTonal(
        tooltip: 'إعادة التكبير',
        onPressed: () => _zoom.value = Matrix4.identity(),
        icon: const Icon(Icons.center_focus_strong),
      )),
      Positioned(left: 10, right: 10, bottom: 10,
        child: _hintTag('صورة توضيحية · حرّكي الصورة للتكبير')),
    ]),
  );

  String get _orbit {
    switch (_camera) {
      case 1: return '40deg 70deg 120%'; // eye-level
      case 2: return '30deg 60deg 85%'; // close
      default: return '35deg 30deg 135%'; // aerial overview
    }
  }

  Widget _modelView() => ClipRRect(
    borderRadius: BorderRadius.circular(21),
    child: Stack(fit: StackFit.expand, children: [
      ModelViewer(
        key: ValueKey('${widget.kind}-$_camera-$_autoRotate-$_viewerVersion'),
        src: model,
        alt: tawaf ? 'نموذج تعليمي ثلاثي الأبعاد للكعبة والمطاف'
                   : 'نموذج تعليمي ثلاثي الأبعاد للمسعى',
        // Poster → model is a built-in, zero-cost reveal: the existing bridge
        // photo shows instantly while the GLB streams in, then fades to it.
        poster: picture,
        loading: Loading.eager,
        reveal: Reveal.auto,
        // Real-world (AR) viewing is the single biggest "feels real" lever —
        // model-viewer adds its own AR button automatically once enabled.
        ar: true,
        arModes: const ['scene-viewer', 'webxr', 'quick-look'],
        arScale: ArScale.auto,
        arPlacement: ArPlacement.floor,
        cameraControls: true,
        autoRotate: _autoRotate,
        autoRotateDelay: 4500,
        rotationPerSecond: '16deg',
        disableZoom: false,
        backgroundColor: forest,
        cameraOrbit: _orbit,
        cameraTarget: 'auto',
        // Smooths manual drag/zoom interaction so the camera settles rather
        // than snapping.
        interpolationDecay: 180,
        minCameraOrbit: 'auto 8deg auto',
        maxCameraOrbit: 'auto 100deg auto',
        // PBR lighting + a grounded, soft shadow is what sells the illusion
        // that the model is sitting in real light rather than floating flat.
        environmentImage: 'neutral',
        exposure: 1.05,
        shadowIntensity: 1,
        shadowSoftness: .9,
      ),
      IgnorePointer(
        child: AnimatedBuilder(
          animation: _ambient,
          builder: (_, __) =>
              CustomPaint(painter: _AtmosphereOverlay(_ambient.value)),
        ),
      ),
      Positioned(top: 10, left: 10, right: 10,
        child: _hintTag('مجسم 3D قابل للدوران والتقريب · اضغطي زر AR لعرضه في مكانك الحقيقي')),
    ]),
  );

  Widget _hintTag(String text) => Center(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: emerald.withValues(alpha: .93),
        border: Border.all(color: gold.withValues(alpha: .65)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(text, textAlign: TextAlign.center,
            style: const TextStyle(color: cream, fontSize: 11.5,
            fontWeight: FontWeight.w600)),
      ),
    ),
  );

  String get _caption {
    if (_count == 7) return tawaf
        ? 'انتهت سبعة أشواط. الخطوة التالية ركعتا الطواف.'
        : 'انتهى الشوط السابع عند المروة. يلي ذلك الحلق أو التقصير.';
    if (!tawaf) {
      final a = _count.isEven ? 'الصفا' : 'المروة';
      final b = _count.isEven ? 'المروة' : 'الصفا';
      return 'الشوط ${_count + 1}: من $a إلى $b · بين العلامتين الخضراوين ${_isMale ? 'يُسنّ إسراع الرجال' : 'تمشي المرأة بسكينة'}.';
    }
    if (_fraction < .12) return 'محاذاة الحجر الأسود: البداية والتكبير دون مزاحمة.';
    if (_fraction < .36) return 'الكعبة عن اليسار · اجعلي مرورك من خارج حِجر إسماعيل.';
    if (_fraction < .65) return 'أكملي الطواف بسكينة، ولكِ الدعاء والذكر بما تشائين.';
    if (_fraction < .85) return 'الركن اليماني: يُستلم عند التيسّر دون مزاحمة.';
    return 'إلى الحجر الأسود: اكتمل تقريبًا شوط جديد.';
  }

  Widget _controls() => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(11, 8, 11, 10),
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
    decoration: BoxDecoration(
      color: forest,
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: gold.withValues(alpha: .70)),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Expanded(child: Text(_caption,
          style: const TextStyle(color: cream, fontSize: 13, height: 1.45))),
        const SizedBox(width: 9),
        Text('$_count / 7', textDirection: TextDirection.ltr,
          style: const TextStyle(color: gold, fontSize: 23,
              fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 9),
      Row(children: List.generate(7, (i) => Expanded(child: Container(
        height: 6, margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(color: i < _count ? gold : Colors.white24,
            borderRadius: BorderRadius.circular(6)),
      )))),
      const SizedBox(height: 9),
      Row(children: [
        Expanded(child: FilledButton.icon(
          onPressed: _loading ? null : _toggleRun,
          style: FilledButton.styleFrom(
            backgroundColor: gold, foregroundColor: emerald,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded),
          label: Text(_running ? 'إيقاف الجولة' : 'جولة تعليمية'),
        )),
        const SizedBox(width: 8),
        IconButton.outlined(onPressed: _count > 0 ? () => _changeCount(_count - 1) : null,
          tooltip: 'تراجع عن شوط', icon: const Icon(Icons.undo_rounded, color: gold)),
        IconButton.filledTonal(onPressed: _count < 7 ? () => _changeCount(_count + 1) : null,
          tooltip: 'أتممت شوطًا', icon: const Icon(Icons.add_rounded)),
      ]),
      const SizedBox(height: 5),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _pill('من فوق', _camera == 0, () => _cameraSet(0)),
          const SizedBox(width: 6),
          _pill('من الجانب', _camera == 1, () => _cameraSet(1)),
          const SizedBox(width: 6),
          _pill('قريب', _camera == 2, () => _cameraSet(2)),
          const SizedBox(width: 6),
          _pill('الصور والإرشاد', _mode == 0, () => setState(() => _mode = 0)),
        ]),
      ),
      const SizedBox(height: 4),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _pill('×0.7', _speed == .7, () => setState(() => _speed = .7)),
          const SizedBox(width: 6),
          _pill('×1.0', _speed == 1, () => setState(() => _speed = 1)),
          const SizedBox(width: 6),
          _pill('×1.5', _speed == 1.5, () => setState(() => _speed = 1.5)),
          const SizedBox(width: 6),
          _pill('إرشاد صوتي', _voice, () { setState(() => _voice = !_voice); if (!_voice) UVoice.I.stop(); }),
          const SizedBox(width: 6),
          _pill('أسهم المسار', _pathVisible, () => setState(() => _pathVisible = !_pathVisible)),
          const SizedBox(width: 6),
          _pill('رجل', _isMale, () => setState(() => _isMale = true)),
          const SizedBox(width: 6),
          _pill('امرأة', !_isMale, () => setState(() => _isMale = false)),
          if (_mode == 1) ...[
            const SizedBox(width: 6),
            _pill('تدوير تلقائي', _autoRotate, () => setState(() => _autoRotate = !_autoRotate)),
          ],
        ]),
      ),
      const SizedBox(height: 6),
      const Text('العرض المتحرك تعليمي فقط، والعداد لا يزيد إلا بالضغط على +. لا يوجد تتبع للموقع.',
        textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 10.5)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: emerald,
        body: SafeArea(
          child: LayoutBuilder(builder: (_, constraints) {
            final controlsMaxHeight = math.min(310.0, constraints.maxHeight * .46);
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
                child: Row(children: [
                  IconButton(onPressed: () => Navigator.pop(context),
                      tooltip: 'عودة إلى رحلة العمرة',
                      icon: const Icon(Icons.arrow_forward_rounded, color: gold)),
                  Expanded(child: Column(children: [
                    Text(_title, textAlign: TextAlign.center,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: gold, fontSize: 20,
                          fontWeight: FontWeight.w800)),
                    Text(_subtitle, textAlign: TextAlign.center,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: cream, fontSize: 11)),
                  ])),
                  IconButton(onPressed: _showGuide, tooltip: 'الشرح الكامل',
                      icon: const Icon(Icons.menu_book_rounded, color: gold)),
                  IconButton(onPressed: _openOfficialMap, tooltip: 'الخريطة الرسمية',
                      icon: const Icon(Icons.map_rounded, color: gold)),
                ]),
              ),
              // Optional immersive world built on the uploaded realism/world engines.
              if (tawaf)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        _running = false;
                        UVoice.I.stop();
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RifqaWorldCinema(),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: gold, foregroundColor: emerald,
                        minimumSize: const Size.fromHeight(42),
                      ),
                      icon: const Icon(Icons.movie_filter_rounded),
                      label: const Text('جولة الحرم السينمائية 3D — إضاءة وكاميرا ومعلومات'),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                child: Row(children: [
                  Expanded(child: _pill('مشهد مصوّر', _mode == 0,
                    () => setState(() => _mode = 0))),
                  const SizedBox(width: 8),
                  Expanded(child: _pill('مجسم 3D تفاعلي', _mode == 1,
                    _enterModelMode)),
                ]),
              ),
              Expanded(child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 5, 11, 0),
                child: _mode == 0 ? _imageView() : _modelView(),
              )),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: controlsMaxHeight),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _controls(),
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}

class _DirectionOverlay extends CustomPainter {
  const _DirectionOverlay({required this.tawaf,
    required this.completed, required this.fraction});
  final bool tawaf;
  final int completed;
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * .50;
    final y = size.height * .52;
    const green = Color(0xFF13D39B);
    final stroke = Paint()
      ..color = green.withValues(alpha: .78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    const marker = Color(0xFFFFDC8B);
    final glow = Paint()
      ..color = marker.withValues(alpha: .35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    if (tawaf) {
      final radius = math.min(size.width * .22, size.height * .20);
      final oval = Rect.fromCircle(center: Offset(x, y), radius: radius);
      canvas.drawArc(oval, 0, -math.pi * 2, false, stroke);
      // A short comet trail behind the marker — purely a function of the
      // current fraction, so it needs no extra state.
      for (final trail in [.05, .035, .02, 0.0]) {
        final t = -2 * math.pi * (fraction - trail);
        final o = Offset(x + radius * math.cos(t), y + radius * math.sin(t));
        final fade = math.max(.25, 1 - trail * 14);
        if (trail == 0) {
          canvas.drawCircle(o, 13, glow);
          canvas.drawCircle(o, 8, Paint()..color = marker);
        } else {
          canvas.drawCircle(o, 4 * fade,
              Paint()..color = marker.withValues(alpha: fade * .5));
        }
      }
    } else {
      final x0 = size.width * .16;
      final x1 = size.width * .84;
      final yy = size.height * .72;
      canvas.drawLine(Offset(x0, yy), Offset(x1, yy), stroke);
      final from = completed.isEven ? x0 : x1;
      final to = completed.isEven ? x1 : x0;
      for (final trail in [.05, .035, .02, 0.0]) {
        final p = from + (to - from) * math.max(0.0, fraction - trail);
        final fade = math.max(.25, 1 - trail * 14);
        if (trail == 0) {
          canvas.drawCircle(Offset(p, yy), 13, glow);
          canvas.drawCircle(Offset(p, yy), 8, Paint()..color = marker);
        } else {
          canvas.drawCircle(Offset(p, yy), 4 * fade,
              Paint()..color = marker.withValues(alpha: fade * .5));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DirectionOverlay old) =>
      old.fraction != fraction || old.completed != completed || old.tawaf != tawaf;
}

/// Purely cosmetic layer above the real GLB model: a soft cinematic vignette
/// plus a handful of slow, seamlessly-looping specks of golden light, as if
/// drifting through a sunlit courtyard. `t` runs 0→1 on a 40 s loop; every
/// position below is built from integer-multiple sin/cos of `t` so nothing
/// jumps when the animation wraps back to 0.
class _AtmosphereOverlay extends CustomPainter {
  const _AtmosphereOverlay(this.t);
  final double t;
  static const _moteCount = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.05,
          colors: [Colors.transparent, Colors.black.withValues(alpha: .26)],
          stops: const [.6, 1],
        ).createShader(rect),
    );

    for (var i = 0; i < _moteCount; i++) {
      final seed = (i * 0.6180339887) % 1.0; // golden-ratio spacing
      final phase = seed * 2 * math.pi;
      final xCycles = 1 + (i % 3); // integer ⇒ seamless at t wrap
      final yCycles = 1 + (i % 2);
      final x = size.width *
          (.5 + .45 * math.sin(2 * math.pi * xCycles * t + phase));
      final y = size.height * ((yCycles * t + seed) % 1.0);
      final twinkle =
          .3 + .4 * (.5 + .5 * math.sin(2 * math.pi * (3 * t + seed)));
      final radius = 1.1 + (i % 3) * .55;
      canvas.drawCircle(
        Offset(x, y),
        radius * 2.6,
        Paint()
          ..color = const Color(0xFFE9C77F).withValues(alpha: twinkle * .16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = const Color(0xFFFFF3D6).withValues(alpha: twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AtmosphereOverlay old) => old.t != t;
}