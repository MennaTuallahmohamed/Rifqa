import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'umrah_data.dart';
import 'umrah_screen.dart';
import 'umrah_cinema_3d.dart';

/// RIFQA cinematic guide: photographic motion, not a simulated 3D Haram.
/// Uses existing assets/umrah/step_1.jpg ... step_7.jpg and recorded MP3s.
class UmrahCinematicV2 extends StatefulWidget {
  const UmrahCinematicV2({super.key});

  @override
  State<UmrahCinematicV2> createState() => _UmrahCinematicV2State();
}

class _UmrahCinematicV2State extends State<UmrahCinematicV2>
    with SingleTickerProviderStateMixin {
  static const _deep = Color(0xFF062D25);
  static const _gold = Color(0xFFE0C485);
  static const _titles = [
    'الاستعداد للعمرة',
    'الإحرام والتلبية',
    'دخول المسجد الحرام',
    'الطواف حول الكعبة',
    'ركعتا الطواف وزمزم',
    'السعي بين الصفا والمروة',
    'الحلق أو التقصير',
  ];
  static const _captions = [
    'تبدأ الرحلة بنية خالصة واستعداد يملؤه السكون.',
    'من الميقات تبدأ التلبية، ويبدأ معها النسك.',
    'ادخل بسكينة، وقدّم قدمك اليمنى، واذكر دعاء الدخول.',
    'سبعة أشواط تبدأ من الحجر الأسود، والكعبة عن يسارك.',
    'صلِّ ركعتين حيث يتيسر، ثم اشرب من ماء زمزم.',
    'سبعة أشواط تبدأ بالصفا وتنتهي بالمروة.',
    'بالحلق أو التقصير تكتمل مناسك العمرة.',
  ];
  final AudioPlayer _audio = AudioPlayer();
  late final AnimationController _camera;
  StreamSubscription<PlayerState>? _listener;
  int _stage = 0;
  bool _busy = false;
  bool _playSequence = false;
  bool _muted = false;
  String? _audioNotice;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _camera = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..forward();
    _listener = _audio.playerStateStream.listen((s) {
      if (!mounted || !_playSequence || _busy) return;
      if (s.processingState == ProcessingState.completed) {
        if (_stage < 6) {
          _changeStage(_stage + 1, autoplay: true);
        } else {
          setState(() => _playSequence = false);
        }
      }
    });
  }

  Future<void> _changeStage(int next, {bool autoplay = false}) async {
    if (next < 0 || next > 6) return;
    ++_requestId;
    await _audio.stop();
    if (!mounted) return;
    setState(() {
      _stage = next;
      _busy = false;
      _audioNotice = null;
    });
    _camera.forward(from: 0);
    HapticFeedback.selectionClick();
    if (autoplay) await _playAudio();
  }

  Future<void> _playAudio() async {
    if (_busy) return;
    if (_audio.playing) {
      await _audio.pause();
      return;
    }
    if (_audio.processingState == ProcessingState.ready &&
        _audio.position < (_audio.duration ?? Duration.zero)) {
      await _audio.play();
      return;
    }
    final id = ++_requestId;
    setState(() {
      _busy = true;
      _audioNotice = null;
    });
    try {
      await _audio.setAsset('assets/audio/umrah/step_${_stage + 1}.mp3');
      if (!mounted || id != _requestId) return;
      setState(() => _busy = false);
      if (!_muted) await _audio.play();
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _busy = false;
        _playSequence = false;
        _audioNotice = 'تسجيل هذه المرحلة غير متاح حاليًا';
      });
    }
  }

  Future<void> _startSequence() async {
    if (_playSequence) {
      setState(() => _playSequence = false);
      await _audio.pause();
      return;
    }
    setState(() => _playSequence = true);
    await _playAudio();
  }

  @override
  void dispose() {
    ++_requestId;
    _listener?.cancel();
    _audio.dispose();
    _camera.dispose();
    super.dispose();
  }

  Widget _image(int index) => Image.asset(
        (index == 3 ? 'assets/umrah/rifqa_real_kaaba.jpg' : 'assets/umrah/step_${index + 1}.jpg'),
        fit: BoxFit.cover,
        alignment: index == 2 ? Alignment.centerLeft : Alignment.center,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: _deep,
          child: Center(child: Icon(Icons.mosque, color: _gold, size: 100)),
        ),
      );

  Widget _backdrop() => AnimatedSwitcher(
        duration: const Duration(milliseconds: 1050),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        child: SizedBox.expand(
          key: ValueKey(_stage),
          child: AnimatedBuilder(
            animation: _camera,
            child: _image(_stage),
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_camera.value);
              return Transform.scale(
                scale: 1.04 + 0.12 * t,
                child: Transform.translate(
                  offset: Offset(-11 * t, -7 * t),
                  child: child,
                ),
              );
            },
          ),
        ),
      );

  Widget _round(IconData icon, VoidCallback action, String label) =>
      IconButton.filledTonal(
        tooltip: label,
        onPressed: action,
        style: IconButton.styleFrom(
          backgroundColor: _deep.withOpacity(.83),
          foregroundColor: _gold,
          side: const BorderSide(color: Color(0x77E0C485)),
        ),
        icon: Icon(icon),
      );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _deep,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _backdrop(),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, .22, .52, .82, 1],
                    colors: [
                      Color(0xD9062D25),
                      Color(0x66062D25),
                      Colors.transparent,
                      Color(0xBB062D25),
                      Color(0xFA062D25),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: top + 8,
              right: 14,
              left: 14,
              child: Row(
                children: [
                  _round(Icons.arrow_forward, () => Navigator.pop(context), 'رجوع'),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      children: [
                        Text('رِفقة', style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800, color: _gold,
                        )),
                        Text('رحلة العمرة السينمائية', style: TextStyle(
                          fontSize: 11, color: Colors.white,
                        )),
                      ],
                    ),
                  ),
                  _round(Icons.menu_book_outlined, () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const UmrahScreen(),
                    ));
                  }, 'الدليل التفصيلي'),
                ],
              ),
            ),
            Positioned(
              bottom: bottom + 20,
              right: 18,
              left: 18,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(7, (i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= _stage ? _gold : Colors.white38,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 18),
                  Text('المشهد ${_stage + 1} من 7', textAlign: TextAlign.center,
                    style: const TextStyle(color: _gold, fontSize: 12)),
                  const SizedBox(height: 7),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    child: Text(_titles[_stage], key: ValueKey(_stage),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white,
                        fontSize: 29, fontWeight: FontWeight.w900, height: 1.35)),
                  ),
                  const SizedBox(height: 8),
                  Text(_captions[_stage], textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFF1E9D9),
                      fontSize: 14, height: 1.7)),
                  if (_audioNotice != null) ...[
                    const SizedBox(height: 8),
                    Text(_audioNotice!, textAlign: TextAlign.center,
                      style: const TextStyle(color: _gold, fontSize: 12)),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xB8062D25),
                      border: Border.all(color: const Color(0x88E0C485)),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(children: [
                      StreamBuilder<PlayerState>(
                        stream: _audio.playerStateStream,
                        builder: (_, snapshot) => IconButton(
                          tooltip: 'تشغيل أو إيقاف التعليق الصوتي',
                          onPressed: _busy ? null : _playAudio,
                          icon: _busy
                              ? const SizedBox(width: 21, height: 21,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _gold))
                              : Icon(snapshot.data?.playing == true
                                  ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                  color: _gold, size: 34),
                        ),
                      ),
                      Expanded(child: StreamBuilder<Duration>(
                        stream: _audio.positionStream,
                        builder: (_, snapshot) {
                          final total = _audio.duration ?? Duration.zero;
                          final progress = total.inMilliseconds == 0 ? 0.0
                              : (snapshot.data?.inMilliseconds ?? 0) / total.inMilliseconds;
                          return LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            color: _gold, backgroundColor: Colors.white24,
                            minHeight: 4, borderRadius: BorderRadius.circular(6),
                          );
                        },
                      )),
                      IconButton(
                        tooltip: _muted ? 'تفعيل الصوت' : 'كتم الصوت',
                        onPressed: () async {
                          setState(() => _muted = !_muted);
                          await _audio.setVolume(_muted ? 0 : 1);
                        },
                        icon: Icon(_muted ? Icons.volume_off : Icons.volume_up,
                          color: _gold),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  if (_stage == 3) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _audio.pause();
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const UmrahCinema3D()));
                        },
                        icon: const Icon(Icons.threed_rotation_rounded),
                        label: const Text('جولة الطواف 3D مع الشرح الصوتي'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _gold,
                          side: const BorderSide(color: _gold),
                          minimumSize: const Size.fromHeight(47),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    onPressed: _startSequence,
                    icon: Icon(_playSequence ? Icons.pause : Icons.movie_filter_outlined),
                    label: Text(_playSequence ? 'إيقاف الرحلة التلقائية' : 'ابدئي الجولة بالصوت'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: _deep,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      onPressed: _stage == 0 ? null : () {
                        _playSequence = false;
                        _changeStage(_stage - 1);
                      },
                      icon: const Icon(Icons.chevron_right), label: const Text('السابق'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _gold,
                        side: const BorderSide(color: _gold),
                      ),
                    )),
                    const SizedBox(width: 9),
                    Expanded(child: FilledButton.icon(
                      onPressed: () {
                        if (_stage == 6) {
                          showDialog<void>(context: context, builder: (d) =>
                            AlertDialog(
                              title: const Text('تقبّل الله عمرتك'),
                              content: const Text('اكتملت الجولة التعليمية. يمكنك مراجعة المناسك في الدليل.'),
                              actions: [TextButton(onPressed: () => Navigator.pop(d),
                                child: const Text('إغلاق'))],
                            ));
                        } else {
                          _playSequence = false;
                          _changeStage(_stage + 1);
                        }
                      },
                      icon: Icon(_stage == 6 ? Icons.check : Icons.chevron_left),
                      label: Text(_stage == 6 ? 'الختام' : 'التالي'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0D7157),
                        foregroundColor: Colors.white,
                      ),
                    )),
                  ]),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => UmrahStepPage(index: _stage))),
                    icon: const Icon(Icons.auto_stories_outlined, size: 17),
                    label: const Text('شرح المناسك والأدعية لهذه المرحلة'),
                    style: TextButton.styleFrom(foregroundColor: _gold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
