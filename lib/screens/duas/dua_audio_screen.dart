import 'package:flutter/material.dart';
import '../../models/dua_model.dart';
import '../../services/duas/duas_audio_service.dart';
import 'dua_premium_theme.dart';

/// Honest audio UI: uses the existing app's audio service, not invented MP3s.
/// If DuasAudioService is TTS on this device, the audio is device-generated.
class DuaAudioScreen extends StatefulWidget {
  const DuaAudioScreen({super.key, required this.dua});
  final Dua dua;
  @override
  State<DuaAudioScreen> createState() => _DuaAudioScreenState();
}

class _DuaAudioScreenState extends State<DuaAudioScreen>
    with SingleTickerProviderStateMixin {
  late final DuasAudioService _audio;
  late final AnimationController _wave;
  int _playToken = 0;
  bool _playing = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _audio = DuasAudioService();
    _wave = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _audio.stop();
    _audio.dispose();
    _wave.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final token = ++_playToken;
    if (_playing) {
      setState(() => _playing = false);
      await _audio.stop();
      return;
    }
    setState(() {
      _playing = true;
      _error = null;
    });
    try {
      // The stop button stays responsive while speak() is awaiting completion.
      await _audio.speak(widget.dua.arabicText);
      if (mounted && token == _playToken) {
        setState(() => _playing = _audio.isPlaying);
      }
    } catch (_) {
      if (mounted && token == _playToken) {
        setState(() {
          _playing = false;
          _error = 'تعذّر تشغيل الصوت على هذا الجهاز.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: DuaPremium.cream,
          body: CustomScrollView(slivers: [
            SliverToBoxAdapter(
                child: DuaPhotoHero(
                    title: 'جولة صوتية',
                    subtitle: 'استمعي إلى الدعاء بتركيز وطمأنينة',
                    image: 'assets/duas/hero_detail.jpg',
                    height: 277,
                    onBack: () => Navigator.pop(context))),
            SliverToBoxAdapter(
                child: Transform.translate(
                    offset: const Offset(0, -23),
                    child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 17),
                        padding: const EdgeInsets.fromLTRB(17, 25, 17, 24),
                        decoration: DuaPremium.card(radius: 32),
                        child: Column(children: [
                          Container(
                              width: 118,
                              height: 118,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: DuaPremium.gold, width: 3),
                                  image: DecorationImage(
                                      image: AssetImage(DuaPremium.imageFor(
                                          widget.dua.category)),
                                      fit: BoxFit.cover))),
                          const SizedBox(height: 12),
                          Text('استمع للدعاء',
                              style:
                                  DuaPremium.type(23, weight: FontWeight.w900)),
                          Text(widget.dua.title,
                              textAlign: TextAlign.center,
                              style:
                                  DuaPremium.type(13, color: DuaPremium.muted)),
                          const SizedBox(height: 21),
                          SizedBox(
                              height: 73,
                              child: AnimatedBuilder(
                                  animation: _wave,
                                  builder: (context, _) {
                                    return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: List.generate(45, (i) {
                                          final baseline =
                                              7.0 + (i * 17 % 24).toDouble();
                                          final phase =
                                              _wave.value * 6.283185 + i * .61;
                                          final height = baseline +
                                              (_playing
                                                  ? 25 *
                                                      (.5 +
                                                          .5 *
                                                              _sinApprox(phase))
                                                  : 0);
                                          return Container(
                                              width: 3.1,
                                              height: height,
                                              decoration: BoxDecoration(
                                                  color: i < 20
                                                      ? DuaPremium.green
                                                      : DuaPremium.gold,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5)));
                                        }));
                                  })),
                          const SizedBox(height: 15),
                          Text(
                              _playing
                                  ? 'جارٍ تشغيل القراءة الصوتية'
                                  : 'جاهز للاستماع',
                              style:
                                  DuaPremium.type(12, color: DuaPremium.muted)),
                          const SizedBox(height: 20),
                          GestureDetector(
                              onTap: _toggle,
                              child: Container(
                                  width: 76,
                                  height: 76,
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(colors: [
                                        DuaPremium.green,
                                        DuaPremium.deep
                                      ]),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Color(0x290C5844),
                                            blurRadius: 19,
                                            offset: Offset(0, 9))
                                      ]),
                                  child: Icon(
                                      _playing
                                          ? Icons.stop_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 41,
                                      color: DuaPremium.gold))),
                          const SizedBox(height: 14),
                          Text(_playing ? 'إيقاف القراءة' : 'ابدئي الاستماع',
                              style:
                                  DuaPremium.type(13, weight: FontWeight.w900)),
                          const SizedBox(height: 18),
                          if (_error != null)
                            Text(_error!,
                                style: DuaPremium.type(11,
                                    color: Colors.redAccent)),
                          Text(
                              'الصوت من خدمة القراءة الموجودة بالتطبيق. مدة التسجيل والتحكم بالتقديم غير متاحين إلا عند إضافة ملف صوت مسجّل.',
                              textAlign: TextAlign.center,
                              style: DuaPremium.type(10.5,
                                  color: DuaPremium.muted, height: 1.8)),
                        ])))),
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(17, 0, 17, 35),
                    child: Container(
                        padding: const EdgeInsets.all(19),
                        decoration: DuaPremium.card(),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('نص الدعاء',
                                  style: DuaPremium.type(15,
                                      weight: FontWeight.w900)),
                              const SizedBox(height: 9),
                              SelectableText(widget.dua.arabicText,
                                  textAlign: TextAlign.center,
                                  style: DuaPremium.type(17, height: 2)),
                              const SizedBox(height: 13),
                              Text(widget.dua.sourceType.label,
                                  style: DuaPremium.type(10,
                                      color: DuaPremium.green)),
                            ])))),
          ]),
        ),
      );

  // A smooth visualizer without claiming waveform samples from unavailable audio.
  double _sinApprox(double x) {
    final t = x % 6.283185;
    final y = t < 3.141593 ? t / 3.141593 : (6.283185 - t) / 3.141593;
    return y * (2 - y);
  }
}
