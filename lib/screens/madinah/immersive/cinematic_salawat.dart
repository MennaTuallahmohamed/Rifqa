import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'cinematic_theme.dart';

const _voiceFromVideo = 'assets/audio/madinah/salam_entrance_20261020.m4a';

class _SalawatText {
  const _SalawatText(this.title, this.text, this.source, this.note,
      this.cover);
  final String title, text, source, note, cover;
}

const _salawat = <_SalawatText>[
  _SalawatText(
    'أمر القرآن بالصلاة على النبي ﷺ',
    'إِنَّ اللَّهَ وَمَلَائِكَتَهُ يُصَلُّونَ عَلَى النَّبِيِّ ۚ يَا أَيُّهَا الَّذِينَ آمَنُوا صَلُّوا عَلَيْهِ وَسَلِّمُوا تَسْلِيمًا',
    'سورة الأحزاب، الآية 56',
    'آية قرآنية في فضل الصلاة والسلام على النبي ﷺ.',
    'quran_courtyard.jpg',
  ),
  _SalawatText(
    'الصلاة الإبراهيمية',
    'اللهم صل على محمد وعلى آل محمد، كما صليت على إبراهيم وعلى آل إبراهيم، إنك حميد مجيد. اللهم بارك على محمد وعلى آل محمد، كما باركت على إبراهيم وعلى آل إبراهيم، إنك حميد مجيد.',
    'صحيح البخاري، حديث 3370 (أحد الألفاظ المأثورة)',
    'توجد صيغ صحيحة أخرى للصلاة الإبراهيمية.',
    'exterior_sunset_wide.jpg',
  ),
  _SalawatText(
    'اللهم صل وسلم على نبينا محمد',
    'اللهم صل وسلم على نبينا محمد.',
    'صيغة دعاء مختصرة',
    'صيغة مختصرة جائزة، ولا تُعرض على أنها نص حديث مستقل بهذا اللفظ.',
    'minarets_sunset.jpg',
  ),
];

class CinematicSalawatScreen extends StatefulWidget {
  const CinematicSalawatScreen({super.key});

  @override
  State<CinematicSalawatScreen> createState() => _CinematicSalawatScreenState();
}

class _CinematicSalawatScreenState extends State<CinematicSalawatScreen> {
  final AudioPlayer _audio = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  int _narration = -1;
  bool _audioReady = false;
  String? _audioError;

  @override
  void initState() {
    super.initState();
    _loadAudio();
    _tts.setLanguage('ar-SA');
    _tts.setSpeechRate(.43);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _narration = -1);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _narration = -1);
    });
  }

  Future<void> _loadAudio() async {
    try {
      await _audio.setAsset(_voiceFromVideo);
      if (mounted) setState(() => _audioReady = true);
    } catch (e) {
      if (mounted) setState(() => _audioError = 'تعذّر تحميل التسجيل. تأكدي من إضافة $_voiceFromVideo إلى pubspec.yaml');
    }
  }

  Future<void> _toggleRecording() async {
    if (!_audioReady) return;
    await _tts.stop();
    if (mounted) setState(() => _narration = -1);
    try {
      if (_audio.playing) {
        await _audio.pause();
      } else {
        if (_audio.processingState == ProcessingState.completed) {
          await _audio.seek(Duration.zero);
        }
        await _audio.play();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('لم نتمكن من تشغيل الصوت المرفق.')));
      }
    }
  }

  Future<void> _read(int index) async {
    await _audio.pause();
    await _tts.stop();
    if (_narration == index) {
      if (mounted) setState(() => _narration = -1);
      return;
    }
    if (mounted) setState(() => _narration = index);
    try {
      await _tts.speak(_salawat[index].text);
    } catch (_) {
      if (mounted) {
        setState(() => _narration = -1);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('لا تتوفر خدمة القراءة العربية على هذا الجهاز.')));
      }
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _audio.dispose();
    super.dispose();
  }

  String _format(Duration time) {
    final minutes = time.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = time.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: const Color(0xFFFCF8F1),
      appBar: AppBar(backgroundColor: const Color(0xFFFCF8F1),
        foregroundColor: cinematicGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => Navigator.pop(context)),
        title: const Text('الصلاة والسلام ﷺ',
          style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.fromLTRB(15, 10, 15, 35), children: [
        ClipRRect(borderRadius: BorderRadius.circular(25),
          child: SizedBox(height: 226, child: Stack(fit: StackFit.expand, children: [
            const CinematicImage('$cinematicAssets/scenes/exterior_sunset_wide.jpg'),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.centerLeft, end: Alignment.centerRight,
              colors: [Color(0x12063223), Color(0xEF043829)]))),
            const Padding(padding: EdgeInsets.all(19), child: Align(
              alignment: Alignment.centerRight,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.favorite_outline_rounded,
                    color: cinematicGold, size: 33),
                  SizedBox(height: 12),
                  Text('اللهم صل وسلم\nعلى نبينا محمد ﷺ',
                    style: TextStyle(color: Colors.white,
                      fontSize: 27, fontWeight: FontWeight.w900, height: 1.4)),
                  SizedBox(height: 10),
                  Text('صيغ مأثورة وتسجيل صوتي هادئ',
                    style: TextStyle(color: Color(0xFFF1E1BC), fontSize: 13)),
                ]),
              ),
            ),
          ]))),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cinematicGreen,
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [BoxShadow(color: Color(0x1B073C2D),
              blurRadius: 18, offset: Offset(0, 8))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.graphic_eq_rounded, color: cinematicGold, size: 28),
              SizedBox(width: 10),
              Expanded(child: Text('السلام عليك يا رسول الله',
                style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 19))),
            ]),
            const SizedBox(height: 7),
            const Text('التسجيل الصوتي من الفيديو الذي أرفقتِه',
              style: TextStyle(color: Color(0xFFE3DBC6), fontSize: 12)),
            const SizedBox(height: 10),
            if (_audioError != null) Text(_audioError!,
              style: const TextStyle(color: Color(0xFFFFD8B5), fontSize: 11)),
            StreamBuilder<Duration>(
              stream: _audio.positionStream,
              initialData: Duration.zero,
              builder: (context, posSnapshot) {
                final duration = _audio.duration ?? const Duration(seconds: 38);
                final maxMs = duration.inMilliseconds.clamp(1, 9999999).toDouble();
                final pos = posSnapshot.data ?? Duration.zero;
                return Column(children: [
                  SliderTheme(data: SliderTheme.of(context).copyWith(
                    activeTrackColor: cinematicGold,
                    inactiveTrackColor: const Color(0xFF527469),
                    thumbColor: cinematicGold),
                    child: Slider(min: 0, max: maxMs,
                      value: pos.inMilliseconds.toDouble().clamp(0, maxMs).toDouble(),
                      onChanged: _audioReady ? (ms) => _audio.seek(
                        Duration(milliseconds: ms.round())) : null,
                    )),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_format(pos), style: const TextStyle(color: Colors.white70)),
                    Text(_format(duration), style: const TextStyle(color: Colors.white70)),
                  ]),
                ]);
              },
            ),
            const SizedBox(height: 10),
            StreamBuilder<PlayerState>(
              stream: _audio.playerStateStream,
              builder: (context, snap) {
                final playing = snap.data?.playing ?? false;
                return SizedBox(width: double.infinity, child: FilledButton.icon(
                  onPressed: _audioReady ? _toggleRecording : null,
                  style: FilledButton.styleFrom(backgroundColor: cinematicGold,
                    foregroundColor: cinematicGreen,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                  icon: Icon(playing ? Icons.pause_circle : Icons.play_circle_fill),
                  label: Text(playing ? 'إيقاف مؤقت' : 'استمعي للتسجيل',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                ));
              },
            ),
          ]),
        ),
        const SizedBox(height: 24),
        const Text('صيغ الصلاة والسلام',
          style: TextStyle(color: cinematicGreen,
            fontSize: 23, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        const Text('اضغطي على أي صيغة لقراءتها بالصوت العربي على جهازك.',
          style: TextStyle(color: Color(0xFF717C73), fontSize: 12)),
        const SizedBox(height: 13),
        for (int i = 0; i < _salawat.length; i++) ...[
          _SalawatCard(item: _salawat[i], active: _narration == i,
            onPlay: () => _read(i)),
          const SizedBox(height: 13),
        ],
        const Text('الصوت المرفق هو تسجيل المستخدم، والقراءة الإضافية صوت آلي من الجهاز. يُراجع توثيق الألفاظ قبل النشر العام.',
          style: TextStyle(color: Color(0xFF7C8279), fontSize: 11,
            height: 1.6), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _SalawatCard extends StatelessWidget {
  const _SalawatCard({required this.item, required this.active, required this.onPlay});
  final _SalawatText item;
  final bool active;
  final VoidCallback onPlay;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white, borderRadius: BorderRadius.circular(24),
    child: Container(padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEE1C8))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(
            width: 90, height: 100,
            child: CinematicImage('$cinematicAssets/scenes/${item.cover}'))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: const TextStyle(color: cinematicGreen,
              fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(item.source, style: const TextStyle(color: Color(0xFF9A782E),
              fontSize: 12, height: 1.5)),
          ])),
        ]),
        const SizedBox(height: 12),
        Text(item.text, textAlign: TextAlign.center, style: const TextStyle(
          color: cinematicGreen, fontSize: 18,
          fontWeight: FontWeight.w600, height: 1.85)),
        const SizedBox(height: 9),
        Text(item.note, style: const TextStyle(color: Color(0xFF6F7870),
          fontSize: 11)),
        const SizedBox(height: 11),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: onPlay,
          style: OutlinedButton.styleFrom(foregroundColor: cinematicGreen,
            side: const BorderSide(color: cinematicGold)),
          icon: Icon(active ? Icons.stop_circle_outlined : Icons.volume_up_rounded),
          label: Text(active ? 'أوقفي القراءة' : 'استمعي للنص'),
        )),
      ]),
    ),
  );
}
