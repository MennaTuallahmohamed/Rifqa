import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../state/app_state.dart';
import 'umrah_data.dart';
import 'rifqa_narration_player.dart';

// RIFQA REAL 3D — GLB 2.0 animated mesh, NOT CustomPainter.
// Original mobile-sized 3D scenes are bundled under assets/models/.
// Audio is routed to the SAME recorded documentary player used by the step screen.
// Visual guide is educational, not a surveying-accurate replica of either holy site.

const _dark = Color(0xFF063D31);
const _green = Color(0xFF0C634D);
const _gold = Color(0xFFE9C37B);
const _cream = Color(0xFFFCF8F0);
const _ink = Color(0xFF163E32);
const _lapSeconds = 28.0;

class Tawaf3DPage extends StatelessWidget {
  const Tawaf3DPage({super.key});
  @override
  Widget build(BuildContext context) => const _Rifqa3DGuide(isTawaf: true);
}

class Sai3DPage extends StatelessWidget {
  const Sai3DPage({super.key});
  @override
  Widget build(BuildContext context) => const _Rifqa3DGuide(isTawaf: false);
}

class _Rifqa3DGuide extends StatefulWidget {
  const _Rifqa3DGuide({required this.isTawaf});
  final bool isTawaf;
  @override
  State<_Rifqa3DGuide> createState() => _Rifqa3DGuideState();
}

class _Rifqa3DGuideState extends State<_Rifqa3DGuide> {
  WebViewController? _web;
  Timer? _clock;
  DateTime? _lastTick;
  double _seconds = 0;
  bool _running = false;
  bool _initialized = false;
  bool _showSettings = false;
  bool _modelReady = false;
  double _speed = 1;
  int _view = 0;
  String? _modelError;

  int get _laps => (_seconds / _lapSeconds).floor().clamp(0, 7).toInt();
  bool get _finished => _laps >= 7;
  int get _shownLap => math.min(_laps + 1, 7);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final st = AppScope.of(context);
      _seconds =
          ((widget.isTawaf ? st.tawaf : st.sai).clamp(0, 7)) * _lapSeconds;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  // Wait for the GLB to finish loading before starting the lap timer.
  // This prevents the count advancing while Android WebView still shows a blank canvas.
  Future<void> _awaitModelReady(WebViewController controller) async {
    for (int tries = 0; tries < 80 && mounted; tries++) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted || _web != controller) return;
      try {
        final ready = await controller.runJavaScriptReturningResult(
          "Boolean(document.querySelector('model-viewer') && "
          "document.querySelector('model-viewer').loaded)",
        );
        if (ready == true || ready.toString().toLowerCase() == 'true') {
          if (!mounted) return;
          setState(() {
            _modelReady = true;
            _modelError = null;
          });
          await _js('m.pause();m.currentTime=${_seconds.toStringAsFixed(3)};');
          return;
        }
      } catch (_) {/* WebView DOM can be unavailable during startup. */}
    }
    if (mounted)
      setState(() => _modelError =
          'تعذّر تحميل المجسم. حدّثي Chrome و Android System WebView، ثم أعيدي فتح المحاكاة.');
  }

  Future<void> _js(String script) async {
    final controller = _web;
    if (controller == null) return;
    try {
      await controller.runJavaScript(
        "(function(){const m=document.querySelector('model-viewer');if(m){$script}})();",
      );
    } catch (error) {
      if (mounted)
        setState(() => _modelError =
            'تعذّر التحكم في المشهد. تأكدي من تحديث Chrome / Android System WebView.');
      debugPrint('Rifqa model viewer JavaScript: $error');
    }
  }

  void _saveProgress() {
    if (!mounted) return;
    final st = AppScope.of(context);
    final next = _laps;
    if (widget.isTawaf) {
      if (st.tawaf != next) st.change(() => st.tawaf = next);
    } else {
      if (st.sai != next) st.change(() => st.sai = next);
    }
  }

  void _tick(Timer _) {
    if (!_running || !mounted) return;
    final now = DateTime.now();
    final d = _lastTick == null
        ? 0.25
        : now.difference(_lastTick!).inMilliseconds / 1000;
    _lastTick = now;
    final prev = _laps;
    setState(() {
      _seconds =
          (_seconds + d.clamp(0.0, .5) * _speed).clamp(0.0, 196.0).toDouble();
    });
    if (_laps != prev) {
      _saveProgress();
      HapticFeedback.selectionClick();
    }
    if (_finished) {
      _running = false;
      _clock?.cancel();
      _js('m.pause();m.currentTime=196;');
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _toggle() async {
    if (!_modelReady) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('المجسم بيحمّل حاليًا؛ انتظري ثواني ثم ابدئي المحاكاة.'),
      ));
      return;
    }
    if (_finished) {
      await _reset();
      return;
    }
    setState(() {
      _running = !_running;
      _modelError = null;
    });
    if (_running) {
      _lastTick = DateTime.now();
      await _js(
          'm.currentTime=${_seconds.toStringAsFixed(3)};m.playbackRate=$_speed;m.play();');
      _clock?.cancel();
      _clock = Timer.periodic(const Duration(milliseconds: 250), _tick);
    } else {
      _clock?.cancel();
      await _js('m.pause();');
    }
  }

  Future<void> _reset() async {
    _clock?.cancel();
    setState(() {
      _running = false;
      _seconds = 0;
      _lastTick = null;
    });
    _saveProgress();
    await _js('m.pause();m.currentTime=0;');
  }

  void _changeSpeed(double next) {
    setState(() => _speed = next);
    _js('m.playbackRate=$_speed;');
  }

  Future<void> _setView(int view) async {
    setState(() => _view = view);
    if (widget.isTawaf) {
      await _js("m.cameraTarget='0m 6m 0m';m.cameraOrbit='${[
        '-34deg 67deg 32m',
        '-35deg 61deg 66m',
        '15deg 24deg 73m'
      ][view]}';");
    } else {
      await _js("m.cameraTarget='0m 4m 0m';m.cameraOrbit='${[
        '72deg 77deg 61m',
        '35deg 68deg 110m',
        '8deg 22deg 125m'
      ][view]}';");
    }
  }

  void _openNarration() {
    final step = widget.isTawaf ? 3 : 5;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(29)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          top: 14,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 15,
        ),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 41,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFCBBEAB),
                    borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 14),
            const Text('رِفقة الصوتية',
                style: TextStyle(
                    fontSize: 21, color: _dark, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(
                widget.isTawaf
                    ? 'شرح الطواف بصوت رِفقة الوثائقي'
                    : 'شرح السعي بصوت رِفقة الوثائقي',
                style: const TextStyle(fontSize: 12, color: Color(0xFF68786E))),
            const SizedBox(height: 12),
            RifqaNarrationPlayer(
              stepIndex: step,
              autoStart: true,
              onDua: () => showDialog<void>(
                context: sheetContext,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('دعاء هذه الخطوة'),
                  content: SingleChildScrollView(
                      child: SelectableText(umrahGuide[step].dua,
                          textAlign: TextAlign.center,
                          style: const TextStyle(height: 1.9, fontSize: 18))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('إغلاق'))
                  ],
                ),
              ),
            ),
            const SizedBox(height: 13),
          ]),
        ),
      ),
    );
  }

  String get _caption {
    if (_finished)
      return widget.isTawaf
          ? 'أتممت الأشواط السبعة. تقبّل الله طوافك.'
          : 'أتممت السعي عند المروة. تقبّل الله عمرتك.';
    if (widget.isTawaf) {
      return _running
          ? 'الشوط $_shownLap: الكعبة عن يسارك. لا تزاحم عند الحجر الأسود.'
          : 'ابدئي من محاذاة الحجر الأسود، ثم اضغطي تشغيل للمحاكاة.';
    }
    return _running
        ? (_shownLap.isOdd
            ? 'الشوط $_shownLap: من الصفا إلى المروة.'
            : 'الشوط $_shownLap: من المروة إلى الصفا.')
        : 'الذهاب من الصفا إلى المروة شوط، والعودة شوط آخر.';
  }

  @override
  Widget build(BuildContext context) {
    final isTawaf = widget.isTawaf;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _cream,
          body: Column(children: [
            _topBar(),
            _progress(),
            Expanded(
                child: Stack(children: [
              Positioned.fill(
                  child: ModelViewer(
                key: ValueKey(isTawaf ? 'rifqa_true_tawaf' : 'rifqa_true_sai'),
                src: isTawaf
                    ? 'assets/models/tawaf_haram_animated.glb'
                    : 'assets/models/sai_haram_animated.glb',
                alt: isTawaf
                    ? 'مجسم حقيقي للكعبة والمطاف'
                    : 'مجسم ثلاثي الأبعاد للمسعى',
                ar: false,
                autoRotate: false,
                cameraControls: true,
                autoPlay: false,
                animationName: 'RifqaGuidedWalk',
                backgroundColor: const Color(0xFFF1E9D8),
                cameraTarget: isTawaf ? '0m 6m 0m' : '0m 4m 0m',
                cameraOrbit: isTawaf ? '-34deg 67deg 32m' : '72deg 77deg 61m',
                fieldOfView: '37deg',
                shadowIntensity: 1,
                shadowSoftness: 0.8,
                exposure: 1.14,
                debugLogging: false,
                onWebViewCreated: (controller) {
                  _web = controller;
                  _awaitModelReady(controller);
                },
              )),
              if (!_modelReady)
                Positioned.fill(
                    child: IgnorePointer(
                        child: Container(
                            color: _cream.withOpacity(.82),
                            child: const Center(
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                  CircularProgressIndicator(color: _dark),
                                  SizedBox(height: 14),
                                  Text('جاري تجهيز المجسم الثلاثي الأبعاد...',
                                      style: TextStyle(
                                          color: _ink,
                                          fontWeight: FontWeight.w800))
                                ]))))),
              Positioned(
                  top: 12,
                  right: 16,
                  child: _glassChip(Icons.threed_rotation_rounded,
                      'اسحبي للتدوير • كبّري بإصبعين')),
              Positioned(
                  left: 13,
                  bottom: 13,
                  child: Material(
                    color: _dark.withOpacity(.85),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'شرح صوتي مسجّل',
                      onPressed: _openNarration,
                      icon: const Icon(Icons.headphones_rounded,
                          color: _gold, size: 26),
                    ),
                  )),
              if (_modelError != null)
                Positioned(
                  bottom: 65,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFF3DC),
                        borderRadius: BorderRadius.circular(16)),
                    child: Text(_modelError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _ink, fontSize: 12)),
                  ),
                ),
            ])),
            _controls(),
          ]),
        ),
      ),
    );
  }

  Widget _topBar() => Container(
        padding: EdgeInsets.fromLTRB(
            15, MediaQuery.paddingOf(context).top + 12, 15, 13),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/umrah/tawaf_panorama.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Color(0xD706372C), BlendMode.srcATop),
          ),
        ),
        child: Row(children: [
          Material(
              color: Colors.white12,
              shape: const CircleBorder(),
              child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white))),
          Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
                widget.isTawaf
                    ? 'الطواف حول الكعبة'
                    : 'السعي بين الصفا والمروة',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text('جولة تفاعلية بمشهد ثلاثي الأبعاد حقيقي',
                textAlign: TextAlign.center,
                style: TextStyle(color: _gold.withOpacity(.96), fontSize: 11)),
          ])),
          Material(
              color: const Color(0xFF225B48),
              shape: const CircleBorder(),
              child: IconButton(
                  onPressed: _openNarration,
                  icon: const Icon(Icons.headphones_rounded, color: _gold))),
        ]),
      );

  Widget _progress() => Container(
        padding: const EdgeInsets.fromLTRB(21, 12, 21, 12),
        color: _dark,
        child: Row(children: [
          Text('الشوط $_shownLap من 7',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15)),
          const Spacer(),
          for (var i = 0; i < 7; i++)
            Container(
              margin: const EdgeInsetsDirectional.only(start: 5),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _laps ? _gold : Colors.white30,
                border: i == _laps && !_finished
                    ? Border.all(color: _gold, width: 1.6)
                    : null,
              ),
            ),
        ]),
      );

  Widget _controls() => Container(
        padding: EdgeInsets.fromLTRB(
            17, 11, 17, math.max(MediaQuery.paddingOf(context).bottom, 8) + 10),
        decoration: const BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
                color: Color(0x20093329), blurRadius: 18, offset: Offset(0, -6))
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFDACBAF),
                  borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 9),
          Text(_caption,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  height: 1.5)),
          const SizedBox(height: 11),
          Row(children: [
            Expanded(
                child:
                    _smallAction(Icons.restart_alt_rounded, 'إعادة', _reset)),
            const SizedBox(width: 11),
            Expanded(
                child: _smallAction(
                    Icons.layers_outlined,
                    _view == 0
                        ? 'قريبة'
                        : _view == 1
                            ? 'بانوراما'
                            : 'علوية',
                    () => _setView((_view + 1) % 3))),
            const SizedBox(width: 11),
            Material(
              color: _dark,
              shape: const CircleBorder(),
              child: SizedBox(
                width: 64,
                height: 64,
                child: IconButton(
                  onPressed: _toggle,
                  icon: Icon(
                      _finished
                          ? Icons.replay_rounded
                          : (_running
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded),
                      color: _gold,
                      size: 36),
                  tooltip: _running ? 'إيقاف مؤقت' : 'بدء المحاكاة',
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
                child: _smallAction(Icons.tune_rounded, 'الإعدادات',
                    () => setState(() => _showSettings = !_showSettings))),
          ]),
          if (_showSettings)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final item in [
                    (.75, 'هادئ'),
                    (1.0, 'عادي'),
                    (2.0, 'سريع')
                  ])
                    ChoiceChip(
                        label: Text(item.$2),
                        selected: _speed == item.$1,
                        onSelected: (_) => _changeSpeed(item.$1),
                        selectedColor: const Color(0xFFE8CF99),
                        labelStyle: const TextStyle(color: _ink, fontSize: 11)),
                  TextButton.icon(
                      onPressed: _openNarration,
                      icon: const Icon(Icons.headphones_rounded, size: 18),
                      label: const Text('استمع لشرح رِفقة'),
                      style: TextButton.styleFrom(foregroundColor: _dark)),
                ],
              ),
            ),
          const SizedBox(height: 7),
          const Text(
              'اسحبي المشهد لتغيير الزاوية • المحاكاة تعليمية وليست مسار GPS',
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8C928A), fontSize: 10.2)),
        ]),
      );

  Widget _smallAction(IconData icon, String label, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: _dark, size: 25),
            const SizedBox(height: 4),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _ink, fontWeight: FontWeight.w800, fontSize: 10.5)),
          ]),
        ),
      );

  Widget _glassChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
            color: _dark.withOpacity(.86),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _gold.withOpacity(.7))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: _gold),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 10.5, color: Colors.white)),
        ]),
      );
}
