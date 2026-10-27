import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'umrah_screen.dart';

/// RIFQA immersive guide. Photographic mode is the default; 3D mode uses
/// the project's existing GLB assets and is not presented as real footage.
class UmrahUltimatePage extends StatefulWidget {
  const UmrahUltimatePage({super.key});
  @override
  State<UmrahUltimatePage> createState() => _UmrahUltimatePageState();
}

class _Stage {
  final String name, text, image;
  final String? model;
  const _Stage(this.name, this.text, this.image, [this.model]);
}

const _stages = <_Stage>[
  _Stage('الاستعداد للعمرة', 'تبدأ رحلتك بالتهيؤ للنسك والتعرف على أحكام الإحرام.', 'assets/umrah/step_1.jpg'),
  _Stage('الإحرام والتلبية', 'تُحرم من الميقات وتبدأ التلبية بقلب خاشع.', 'assets/umrah/step_2.jpg'),
  _Stage('دخول المسجد الحرام', 'ادخل بسكينة، وقدّم رجلك اليمنى، وقل دعاء دخول المسجد.', 'assets/umrah/step_3.jpg'),
  _Stage('الطواف حول الكعبة', 'سبعة أشواط تبدأ من الحجر الأسود، والكعبة عن يسارك. لا تزاحم الناس.', 'assets/umrah/step_4.jpg', 'assets/models/tawaf_haram_animated.glb'),
  _Stage('ركعتا الطواف وزمزم', 'بعد الطواف تصلّي ركعتين في مكان مناسب ثم تشرب من زمزم.', 'assets/umrah/step_5.jpg'),
  _Stage('السعي بين الصفا والمروة', 'تبدأ بالصفا وتنتهي بالمروة بعد سبعة أشواط.', 'assets/umrah/step_6.jpg', 'assets/models/sai_haram_animated.glb'),
  _Stage('الحلق أو التقصير', 'بإتمام الحلق أو التقصير تنتهي مناسك العمرة. تقبّل الله منك.', 'assets/umrah/step_7.jpg'),
];

class _UmrahUltimatePageState extends State<UmrahUltimatePage> with SingleTickerProviderStateMixin {
  static const _deep = Color(0xFF062F26);
  static const _gold = Color(0xFFE5C47B);
  static const _cream = Color(0xFFFFF7E8);
  final AudioPlayer _audio = AudioPlayer();
  late final AnimationController _camera = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat(reverse: true);
  int _index = 0;
  int _laps = 0;
  bool _show3d = false;
  bool _muted = false;
  bool _loading = false;
  String? _audioMessage;
  int _audioEpoch = 0;

  @override
  void dispose() {
    _audioEpoch++;
    _camera.dispose();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _go(int next) async {
    if (next < 0 || next >= _stages.length) return;
    _audioEpoch++;
    await _audio.stop();
    if (!mounted) return;
    _camera.reset();
    _camera.repeat(reverse: true);
    setState(() {
      _index = next;
      _show3d = false;
      _laps = 0;
      _audioMessage = null;
    });
  }

  Future<void> _toggleAudio() async {
    if (_loading) return;
    if (_audio.playing) {
      await _audio.pause();
      return;
    }
    if (_audio.audioSource != null && _audio.processingState != ProcessingState.completed) {
      await _audio.play();
      return;
    }
    final epoch = ++_audioEpoch;
    setState(() { _loading = true; _audioMessage = null; });
    try {
      await _audio.setAsset('assets/audio/umrah/step_${_index + 1}.mp3');
      if (!mounted || epoch != _audioEpoch) return;
      await _audio.setVolume(_muted ? 0 : 1);
      setState(() => _loading = false);
      await _audio.play();
    } catch (_) {
      if (mounted && epoch == _audioEpoch) {
        setState(() {
          _loading = false;
          _audioMessage = 'التسجيل الصوتي لهذه المرحلة غير متاح حاليًا';
        });
      }
    }
  }

  void _finish() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تقبّل الله عمرتك'),
          content: const Text('انتهت الرحلة التعليمية. أداء العمرة الحقيقي يكون بالمناسك في مواضعها.'),
          actions: [TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('العودة'))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stages[_index];
    final screen = MediaQuery.sizeOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _deep,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 850),
              child: _show3d && stage.model != null
                  ? _modelScene(stage)
                  : _photoScene(stage),
            ),
            const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                stops: [0, .28, .65, 1],
                colors: [Color(0xDD062F26), Colors.transparent, Color(0x33062F26), Color(0xFF062F26)]),
            ))),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Column(children: [
                  Row(children: [
                    _circle(Icons.arrow_forward, () => Navigator.pop(context)),
                    const Expanded(child: Column(children: [
                      Text('رِفقة', style: TextStyle(color: _gold, fontSize: 27, fontWeight: FontWeight.w900)),
                      Text('رحلة العمرة التفاعلية', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ])),
                    _circle(Icons.menu_book_outlined, () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => UmrahStepPage(index: _index)))),
                  ]),
                  const SizedBox(height: 23),
                  Row(children: List.generate(_stages.length, (i) => Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 270), height: 5,
                      decoration: BoxDecoration(color: i <= _index ? _gold : Colors.white38,
                        borderRadius: BorderRadius.circular(8))),
                  )))),
                  const SizedBox(height: 12),
                  Text('${_index + 1} من ${_stages.length}', style: const TextStyle(color: _gold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(stage.name, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 12)])),
                  if (_show3d) const Padding(padding: EdgeInsets.only(top: 8),
                    child: Text('نموذج ثلاثي الأبعاد توضيحي — ليس تصويرًا حقيقيًا',
                      style: TextStyle(color: _cream, fontSize: 12))),
                ]),
              ),
            ),
            Positioned(
              right: 17, left: 17, bottom: bottom + 16,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                decoration: BoxDecoration(color: const Color(0xEE06392E),
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: _gold.withValues(alpha: .72), width: 1.1)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(stage.text, textAlign: TextAlign.center,
                    style: const TextStyle(color: _cream, fontSize: 16, height: 1.6)),
                  if (_audioMessage != null) Padding(padding: const EdgeInsets.only(top: 7),
                    child: Text(_audioMessage!, style: const TextStyle(color: _gold, fontSize: 12))),
                  const SizedBox(height: 12),
                  Row(children: [
                    _circle(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, () async {
                      setState(() => _muted = !_muted);
                      await _audio.setVolume(_muted ? 0 : 1);
                    }),
                    const SizedBox(width: 8),
                    Expanded(child: StreamBuilder<Duration>(
                      stream: _audio.positionStream,
                      builder: (_, snapshot) {
                        final total = _audio.duration ?? Duration.zero;
                        final position = snapshot.data ?? Duration.zero;
                        final fraction = total.inMilliseconds == 0 ? 0.0 :
                            (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
                        return LinearProgressIndicator(value: fraction, color: _gold,
                          minHeight: 5, backgroundColor: Colors.white24, borderRadius: BorderRadius.circular(5));
                      },
                    )),
                    const SizedBox(width: 8),
                    StreamBuilder<PlayerState>(
                      stream: _audio.playerStateStream,
                      builder: (_, snapshot) => _circle(_loading ? Icons.hourglass_top_rounded :
                        (snapshot.data?.playing == true ? Icons.pause_rounded : Icons.play_arrow_rounded), _toggleAudio,
                        filled: true),
                    ),
                  ]),
                  if (stage.model != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _show3d = !_show3d),
                      style: OutlinedButton.styleFrom(foregroundColor: _gold,
                        side: const BorderSide(color: _gold), minimumSize: const Size.fromHeight(45)),
                      icon: Icon(_show3d ? Icons.photo_camera_rounded : Icons.view_in_ar_rounded),
                      label: Text(_show3d ? 'العودة للصورة الواقعية' : 'استكشفي المجسم 3D أثناء الشرح'),
                    ),
                    if (_show3d) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('الأشواط: $_laps / 7', style: const TextStyle(color: _cream)),
                      const SizedBox(width: 14),
                      TextButton.icon(onPressed: _laps < 7 ? () => setState(() => _laps++) : null,
                        icon: const Icon(Icons.add_circle_outline), label: const Text('أتممت شوطًا'),
                        style: TextButton.styleFrom(foregroundColor: _gold)),
                      IconButton(onPressed: () => setState(() => _laps = 0),
                        icon: const Icon(Icons.restart_alt, color: _gold)),
                    ]),
                  ],
                  const SizedBox(height: 11),
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: _index == 0 ? null : () => _go(_index - 1),
                      style: OutlinedButton.styleFrom(foregroundColor: _gold,
                        side: const BorderSide(color: _gold), minimumSize: const Size.fromHeight(48)),
                      child: const Text('السابق'),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: FilledButton(
                      onPressed: _index == _stages.length - 1 ? _finish : () => _go(_index + 1),
                      style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _deep,
                        minimumSize: const Size.fromHeight(48)),
                      child: Text(_index == _stages.length - 1 ? 'إنهاء الرحلة' : 'التالي',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    )),
                  ]),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoScene(_Stage stage) => AnimatedBuilder(
    key: ValueKey('photo-$_index'),
    animation: _camera,
    builder: (context, child) => Transform.scale(
      scale: 1.04 + .075 * Curves.easeInOut.transform(_camera.value),
      child: child,
    ),
    child: SizedBox.expand(child: Image.asset(stage.image, fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => const ColoredBox(color: _deep,
        child: Center(child: Icon(Icons.mosque_rounded, color: _gold, size: 80))),
    )),
  );

  Widget _modelScene(_Stage stage) => ColoredBox(
    key: ValueKey('model-$_index'), color: const Color(0xFFF0E7D6),
    child: Padding(
      padding: EdgeInsets.only(top: MediaQuery.sizeOf(context).height * .19,
        bottom: MediaQuery.sizeOf(context).height * .28),
      child: ModelViewer(
        src: stage.model!,
        alt: 'نموذج تعليمي ثلاثي الأبعاد لمرحلة ${stage.name}',
        cameraControls: true,
        autoRotate: true,
        disableZoom: false,
        backgroundColor: const Color(0xFFF0E7D6),
      ),
    ),
  );

  Widget _circle(IconData icon, VoidCallback action, {bool filled = false}) =>
      Material(color: filled ? _gold : const Color(0xCC073D31), shape: const CircleBorder(),
        child: IconButton(onPressed: action,
          icon: Icon(icon, color: filled ? _deep : _gold), iconSize: 25));
}
