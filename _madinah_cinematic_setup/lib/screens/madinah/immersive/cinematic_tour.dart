import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../rawdah/rawdah_screen.dart';
import 'cinematic_theme.dart';

// Guided cinematic depth tour. It does NOT imply a navigable 3D building model.
enum CinematicJourneyKind { mosque, rawdah }

class _TourScene {
  const _TourScene(this.picture, this.heading, this.narration, this.info);
  final String picture, heading, narration, info;
}

const _mosqueScenes = <_TourScene>[
  _TourScene('gate_sultan_abdulmajeed.jpg', 'أمام أبواب المسجد النبوي',
      'هنا تبدأ رحلتك. تمهّل، وتأمّل جمال عمارة المسجد النبوي الشريف.', 'المشهد الأول • لحظة الدخول'),
  _TourScene('courtyard_day_umbrella.jpg', 'إلى ساحات المسجد',
      'تأمّل المظلات والمآذن والهدوء الذي يملأ الساحات.', 'المشهد الثاني • ساحات المسجد'),
  _TourScene('quran_courtyard.jpg', 'في أروقة المسجد',
      'هذه مساحة للتأمل والسكينة واستحضار آداب زيارة المسجد.', 'المشهد الثالث • السكينة'),
  _TourScene('minarets_sunset.jpg', 'لحظة في طيبة',
      'صلِّ على رسول الله ﷺ، واترك لهذه اللحظة أثرًا في قلبك.', 'المشهد الرابع • نهاية الجولة'),
];

const _rawdahScenes = <_TourScene>[
  _TourScene('gate_umar.jpg', 'في طريقك إلى الروضة',
      'استعد بالقلب والسكينة، ولا تنشغل عن عبادتك بالهاتف.', 'المشهد الأول • الاستعداد'),
  _TourScene('rawdah_grille.jpg', 'الروضة الشريفة',
      'قال رسول الله ﷺ: ما بين بيتي ومنبري روضة من رياض الجنة. رواه البخاري.',
      'المشهد الثاني • فضل المكان'),
  _TourScene('quran_courtyard.jpg', 'لحظات من الدعاء',
      'اخفض صوتك، وتأنَّ، وادع الله بإخلاص دون تخصيص دعاء لم يثبت.',
      'المشهد الثالث • السكينة والدعاء'),
  _TourScene('rawdah_grille.jpg', 'ذكرى لا تُنسى',
      'أغلق الهاتف عند الزيارة الفعلية، واستشعر نعمة هذه اللحظة.',
      'المشهد الرابع • نهاية الجولة'),
];

class CinematicTourScreen extends StatefulWidget {
  const CinematicTourScreen({super.key, required this.kind});
  final CinematicJourneyKind kind;

  @override
  State<CinematicTourScreen> createState() => _CinematicTourScreenState();
}

class _CinematicTourScreenState extends State<CinematicTourScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient;
  final FlutterTts _tts = FlutterTts();
  int _index = 0;
  bool _audio = false;
  double _pan = 0;
  bool _busy = false;

  List<_TourScene> get _scenes => widget.kind == CinematicJourneyKind.mosque
      ? _mosqueScenes : _rawdahScenes;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 15))
      ..repeat(reverse: true);
    _tts.setLanguage('ar-SA');
    _tts.setSpeechRate(.43);
    _tts.setVolume(.8);
    _tts.setCompletionHandler(() { if (mounted) setState(() => _audio = false); });
    _tts.setErrorHandler((_) { if (mounted) setState(() => _audio = false); });
  }

  Future<void> _stopAudio() async {
    await _tts.stop();
    if (mounted) setState(() => _audio = false);
  }

  Future<void> _toggleAudio() async {
    if (_audio) { await _stopAudio(); return; }
    try {
      setState(() => _audio = true);
      await _tts.speak(_scenes[_index].narration);
    } catch (_) {
      if (mounted) {
        setState(() => _audio = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الصوت غير متاح على هذا الجهاز حاليًا')));
      }
    }
  }

  Future<void> _next() async {
    if (_busy) return;
    if (_index == _scenes.length - 1) { await _stopAudio();
      if (mounted) Navigator.of(context).pop(); return; }
    setState(() { _busy = true; _pan = 0; });
    await _stopAudio();
    if (!mounted) return;
    setState(() { _index++; _busy = false; });
  }

  void _previous() {
    _stopAudio();
    if (_index == 0) { Navigator.of(context).pop(); return; }
    setState(() { _index--; _pan = 0; });
  }

  @override
  void dispose() {
    _tts.stop();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scenes[_index];
    final wide = MediaQuery.sizeOf(context).width > 600;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final name = widget.kind == CinematicJourneyKind.mosque ? 'دخول المسجد النبوي' : 'تجربة الروضة';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: cinematicDeep,
        body: Stack(children: [
          Positioned.fill(child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 1250),
            switchInCurve: Curves.easeInOutCubic,
            child: SizedBox.expand(key: ValueKey(_index), child: AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) {
                final drift = reduceMotion ? 0.0 : _ambient.value;
                return ClipRect(child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(_pan * 38, drift * 10, 0.0)
                    ..scale(1.12 + drift * .06),
                  child: CinematicImage('$cinematicAssets/scenes/${scene.picture}'),
                ));
              },
            )),
          )),
          Positioned.fill(child: IgnorePointer(child: DecoratedBox(
            decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [cinematicDeep.withOpacity(.25), Colors.transparent,
                cinematicDeep.withOpacity(.56), cinematicDeep.withOpacity(.95)],
              stops: const [0, .38, .66, 1],
            )),
          ))),
          SafeArea(child: Padding(
            padding: EdgeInsets.symmetric(horizontal: wide ? 45 : 18, vertical: 14),
            child: Column(children: [
              Row(children: [
                IconButton.filledTonal(
                  style: IconButton.styleFrom(backgroundColor: cinematicDeep.withOpacity(.78)),
                  onPressed: _previous, tooltip: 'رجوع',
                  icon: const Icon(Icons.arrow_forward_ios_rounded, color: cinematicCream)),
                const Spacer(),
                const CinematicPill(text: 'تجربة سينمائية 3D'),
                const Spacer(),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(backgroundColor: cinematicDeep.withOpacity(.78)),
                  tooltip: _audio ? 'إيقاف الصوت' : 'استمعي إلى السرد',
                  onPressed: _toggleAudio,
                  icon: Icon(_audio ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    color: cinematicGold)),
              ]),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 680),
                child: Column(key: ValueKey('scene_$_index'), children: [
                  const Icon(Icons.auto_awesome, size: 23, color: cinematicGold),
                  const SizedBox(height: 12),
                  Text(scene.info, style: const TextStyle(color: cinematicGold, fontSize: 14)),
                  const SizedBox(height: 9),
                  CinematicHeading(scene.heading, subtitle: scene.narration),
                ]),
              ),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(onPressed: () => setState(() => _pan = math.max(-1, _pan - .35)),
                  tooltip: 'انظري يمينًا',
                  icon: const Icon(Icons.chevron_right_rounded, color: cinematicGold, size: 31)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(color: cinematicDeep.withOpacity(.72),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: cinematicGold.withOpacity(.45))),
                  child: const Text('غيّري زاوية المشهد', style: TextStyle(color: cinematicCream, fontSize: 12))),
                IconButton(onPressed: () => setState(() => _pan = math.min(1, _pan + .35)),
                  tooltip: 'انظري يسارًا',
                  icon: const Icon(Icons.chevron_left_rounded, color: cinematicGold, size: 31)),
              ]),
              const SizedBox(height: 16),
              if (widget.kind == CinematicJourneyKind.rawdah) ...[
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    cinematicRoute(const RawdahScreen())),
                  icon: const Icon(Icons.event_available, color: cinematicGold),
                  label: const Text('دليل زيارة الروضة والحجز',
                    style: TextStyle(color: cinematicCream)),
                ),
                const SizedBox(height: 6),
              ],
              Row(children: [
                Expanded(child: Row(children: List.generate(_scenes.length, (i) => Expanded(
                  child: AnimatedContainer(duration: const Duration(milliseconds: 320),
                    height: 4, margin: const EdgeInsets.only(left: 5),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                      color: i <= _index ? cinematicGold : cinematicCream.withOpacity(.28))),
                )))),
                const SizedBox(width: 20),
                CinematicButton(label: _index == _scenes.length - 1 ? 'إنهاء' : 'التالي',
                  onPressed: _busy ? null : _next),
              ]),
              const SizedBox(height: 17),
              Text('مشاهد مستوحاة بصريًا • $name • دون تجسيد للنبي ﷺ',
                textAlign: TextAlign.center,
                style: TextStyle(color: cinematicMuted.withOpacity(.72), fontSize: 10)),
            ]),
          )),
        ]),
      ),
    );
  }
}
