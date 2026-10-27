import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'rifqa_premium_3d.dart';
import 'umrah_screen.dart' show UmrahStepPage;

// RIFQA — one coherent, offline-capable, nine-stage guided Umrah learning journey.
// Illustrative AI imagery / video may depict locations approximately, not as documentary truth.
// Learning progress does not certify performing Umrah.

class _Palette {
  static const dark = Color(0xFF052C24);
  static const green = Color(0xFF075640);
  static const gold = Color(0xFFE7C57B);
  static const ivory = Color(0xFFF9F1DF);
  static const glass = Color(0xEA052C24);
}

class _Stage {
  const _Stage({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.guide,
    required this.dua,
    required this.duaNote,
    required this.image,
    required this.audio,
    required this.facts,
    this.video = false,
    this.counter = '',
    this.gallery = const [],
  });
  final String title, subtitle, body, guide, dua, duaNote, image, audio, counter;
  final List<String> facts;
  final List<String> gallery;
  final bool video;
}

const _prefix = 'assets/umrah/rifqa_premium/';
const _stages = <_Stage>[
  _Stage(
    title: 'الإحرام والنية', subtitle: 'ابدئي عمرتك بقلب مطمئن',
    body: 'تعرّفي على الاستعداد للإحرام، وملابس الإحرام، والنية قبل بدء المناسك.',
    guide: 'اغتسلي واستعدي، ثم أحرمي من الميقات المحدد لطريقك. الرجل يلبس الإزار والرداء، والمرأة تلبس لباسًا ساترًا مشروعًا دون تخصيص لون بعينه. الإحرام هو نية الدخول في النسك، وليس مجرد ارتداء الملابس.',
    dua: 'لَبَّيْكَ اللَّهُمَّ عُمْرَةً',
    duaNote: 'الإهلال بالعمرة عند الإحرام؛ النية محلها القلب.',
    image: '${_prefix}scene_1.jpg', audio: 'step_1.mp3',
    facts: ['الإحرام من الميقات', 'تجنب محظورات الإحرام', 'لا يلزم لباس أبيض للنساء'],
  ),
  _Stage(
    title: 'الميقات والتلبية', subtitle: 'من هنا تبدأ الرحلة',
    body: 'عند الميقات يبدأ الإحرام، ويستمر المعتمر في التلبية حتى بدء الطواف.',
    guide: 'حددي الميقات المناسب قبل السفر. لا تتجاوزي الميقات بنية العمرة دون إحرام. أكثري من التلبية بصوت يناسب موضعك ومن حولك.',
    dua: 'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لَا شَرِيكَ لَكَ',
    duaNote: 'التلبية المأثورة.', image: '${_prefix}scene_2.jpg', audio: 'step_2.mp3',
    facts: ['تبدأ التلبية بعد الإحرام', 'الميقات يختلف باختلاف طريق الوصول', 'النية عمل القلب'],
  ),
  _Stage(
    title: 'دخول المسجد الحرام', subtitle: 'فيديو الدخول ثم ظهور الكعبة',
    body: 'شاهدي مشهد دخول الحرم والاقتراب من صحن المطاف، واستمعي إلى آداب دخول المسجد.',
    guide: 'ادخلي المسجد الحرام بقدمك اليمنى وادعي بدعاء دخول المسجد. حافظي على السكينة واتبعي الإرشادات ومسارات الحركة. الفيديو المرفق تركيب بصري يبدأ بصور للبوابة والممرات، وينتهي بلقطة تمثيلية مولدة للكعبة، وليس توثيقًا متصلًا لمسار حقيقي.',
    dua: 'بِسْمِ اللَّهِ، وَالصَّلَاةُ وَالسَّلَامُ عَلَى رَسُولِ اللَّهِ، اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
    duaNote: 'من دعاء دخول المسجد.', image: '${_prefix}scene_3.jpg',
    audio: 'step_3.mp3', video: true,
    facts: ['الدخول بالقدم اليمنى', 'السكينة وعدم إعاقة المارة', 'المشهد المرئي تمثيلي جزئيًا'],
    gallery: ['${_prefix}gate_umrah.jpg', '${_prefix}haram_hall.jpg'],
  ),
  _Stage(
    title: 'رؤية الكعبة المشرفة', subtitle: 'لحظة عظيمة في قلب الرحلة',
    body: 'تأمّلي الكعبة المشرفة، واستعدّي للطواف من محاذاة الحجر الأسود.',
    guide: 'عند رؤية الكعبة ادعي الله بما شئت؛ لا يثبت دعاء مخصوص لرؤيتها عن النبي ﷺ. ثم توجهي إلى المطاف دون توقف في مسارات الطائفين.',
    dua: 'ادعي بما تحبين من خيري الدنيا والآخرة، ولا يلزم دعاء محدد عند أول رؤية للكعبة.',
    duaNote: 'لا يوجد دعاء مخصوص ثابت لرؤية الكعبة.', image: '${_prefix}scene_4.jpg',
    audio: 'step_3.mp3', facts: ['الكعبة قبلة المسلمين', 'لا تتوقفي في مسار الطائفين', 'تجنبي التزاحم للتصوير'],
  ),
  _Stage(
    title: 'الطواف حول الكعبة', subtitle: 'سبعة أشواط — والكعبة على اليسار',
    body: 'ابدئي من محاذاة الحجر الأسود، واطوفي سبعة أشواط متتابعة حول الكعبة.',
    guide: 'اجعلي الكعبة عن يسارك، وابدئي من الحجر الأسود وأنهي كل شوط عنده. لا تزاحمي لتقبيله. الطواف يكون خارج حِجر إسماعيل. للرجل الرمل في الأشواط الثلاثة الأولى في طواف العمرة إذا تيسر، والاضطباع أثناء الطواف؛ ولا يُشرع ذلك للمرأة.',
    dua: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    duaNote: 'يقال بين الركن اليماني والحجر الأسود. وفيما عدا ذلك يدعو بما شاء.',
    image: '${_prefix}scene_5.jpg', audio: 'step_4.mp3', counter: 'tawaf',
    facts: ['البداية والنهاية عند الحجر الأسود', 'الكعبة تكون عن اليسار', 'الطواف من خارج الحِجر', 'لا تسببي أذى للآخرين'],
  ),
  _Stage(
    title: 'مقام إبراهيم', subtitle: 'ركعتا الطواف بعد إتمام الأشواط',
    body: 'بعد الطواف صلّي ركعتين خلف المقام إن تيسر، أو في مكان مناسب من المسجد.',
    guide: 'بعد إتمام سبعة أشواط، يصلي المعتمر ركعتين. يسن أن تكونا خلف مقام إبراهيم إن تيسر، دون مزاحمة أو تعطيل الطائفين. مقام إبراهيم معلم من معالم الحرم ولا يُشرع التمسح به.',
    dua: 'وَاتَّخِذُوا مِنْ مَقَامِ إِبْرَاهِيمَ مُصَلًّى',
    duaNote: 'جزء من الآية 125 من سورة البقرة.', image: '${_prefix}scene_6.jpg',
    audio: 'step_5.mp3', facts: ['لا تزاحمي عند المقام', 'يمكن أداء الركعتين في موضع آخر مناسب', 'تجنبي التمسح بالمقام'],
    gallery: ['${_prefix}maqam_ibrahim.jpg'],
  ),
  _Stage(
    title: 'ماء زمزم', subtitle: 'اشربي من زمزم وادعي الله',
    body: 'تعرّفي على مواضع ماء زمزم وآداب شربه بعد الطواف.',
    guide: 'اشربي من ماء زمزم وادعي الله بما تحبين. راعي نظافة المكان وتعليمات العاملين، ولا تعيقي حركة الناس. التسجيل الصوتي لهذه المحطة مشترك مع شرح ركعتي الطواف وزمزم.',
    dua: 'ادعي الله بما تشائين عند شرب زمزم؛ ولا يلزم دعاء بعينه.',
    duaNote: 'دعاء عام؛ ليس نصًا مخصوصًا لازمًا.', image: '${_prefix}scene_7.jpg',
    audio: 'step_5.mp3', facts: ['ماء زمزم متاح في نقاط مخصصة', 'اتّبعي تعليمات المكان', 'ادعي بما شئت'],
    gallery: ['${_prefix}zamzam.jpg'],
  ),
  _Stage(
    title: 'السعي بين الصفا والمروة', subtitle: 'سبعة أشواط — البداية من الصفا',
    body: 'من الصفا إلى المروة شوط، والعودة إلى الصفا شوط آخر. ينتهي السابع عند المروة.',
    guide: 'ابدئي من الصفا واتجهي إلى المروة. للرجل الإسراع بين العلامتين الخضراوين إن تيسر، والمرأة تمشي مشيًا عاديًا. أكثري من الدعاء والذكر دون تخصيص دعاء لكل شوط.',
    dua: 'إِنَّ الصَّفَا وَالْمَرْوَةَ مِنْ شَعَائِرِ اللَّهِ',
    duaNote: 'من الآية 158 من سورة البقرة.', image: '${_prefix}scene_8.jpg',
    audio: 'step_6.mp3', counter: 'sai',
    facts: ['الصفا ← المروة = شوط 1', 'الذهاب والرجوع يُحسبان منفصلين', 'الشوط السابع ينتهي عند المروة'],
    gallery: ['${_prefix}safa_start.jpg', '${_prefix}safa_marwa_sign.jpg', '${_prefix}masaa_crowd.jpg'],
  ),
  _Stage(
    title: 'الحلق أو التقصير', subtitle: 'اكتملت مناسك العمرة',
    body: 'بعد السعي يأتي الحلق أو التقصير، وبه يتم التحلل من الإحرام.',
    guide: 'للرجل الحلق أفضل، ويجوز التقصير مع تعميم شعر الرأس. المرأة تقص قدر أنملة من أطراف شعرها ولا تحلق. بعد إتمام ذلك تكون العمرة قد انتهت. هذه الجولة تعليمية فقط ولا تثبت أداء النسك فعليًا.',
    dua: 'اللَّهُمَّ تَقَبَّلْ مِنَّا',
    duaNote: 'دعاء عام بطلب القبول.', image: '${_prefix}scene_9.jpg',
    audio: 'step_7.mp3', facts: ['للرجل الحلق أفضل ويجوز التقصير', 'المرأة تقصّر ولا تحلق', 'التحلل بعد إتمام النسك'],
  ),
];

class RifqaPremiumJourney extends StatefulWidget {
  const RifqaPremiumJourney({super.key, this.initialStage});
  final int? initialStage;
  @override
  State<RifqaPremiumJourney> createState() => _RifqaPremiumJourneyState();
}

class _RifqaPremiumJourneyState extends State<RifqaPremiumJourney>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _voice = AudioPlayer();
  VideoPlayerController? _video;
  late final AnimationController _motion = AnimationController(
    vsync: this, duration: const Duration(seconds: 19),
  )..repeat(reverse: true);
  StreamSubscription<PlayerState>? _sub;
  int _index = 0;
  int _request = 0;
  int _tawaf = 0, _sai = 0;
  bool _playing = false, _loading = false, _missingAudio = false, _mute = false;
  double _speed = 1.0;
  bool _completed = false;
  bool _immersive = false;

  @override
  void initState() {
    super.initState();
    _sub = _voice.playerStateStream.listen((state) {
      if (mounted) setState(() {});
    });
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _tawaf = prefs.getInt('rifqa_premium_tawaf') ?? 0;
    _sai = prefs.getInt('rifqa_premium_sai') ?? 0;
    _index = (widget.initialStage ?? prefs.getInt('rifqa_premium_step') ?? 0).clamp(0, 8).toInt();
    setState(() {});
    await _switchTo(_index, initial: true);
  }

  Future<void> _switchTo(int next, {bool initial = false}) async {
    if (next == _stages.length) {
      await _voice.stop();
      await _video?.pause();
      if (!mounted) return;
      setState(() { _completed = true; _playing = false; });
      return;
    }
    if (next < 0 || next >= _stages.length) return;
    final request = ++_request;
    final oldVideo = _video;
    _video = null;
    await _voice.stop();
    await oldVideo?.dispose();
    if (!mounted || request != _request) return;
    setState(() {
      _index = next;
      _missingAudio = false;
      _loading = true;
      _playing = false;
      _completed = false;
    });
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rifqa_premium_step', next);
    if (!mounted || request != _request) return;
    try {
      await _voice.setAsset('assets/audio/umrah/${_stages[next].audio}');
      await _voice.setSpeed(_speed);
      await _voice.setVolume(_mute ? 0 : 1);
    } catch (_) {
      _missingAudio = true;
    }
    if (next == 2) {
      try {
        final video = VideoPlayerController.asset('assets/video/umrah/entrance_cinematic.mp4');
        await video.initialize();
        if (!mounted || request != _request) { await video.dispose(); return; }
        _video = video;
        await video.setLooping(true);
        await video.setVolume(0);
        await video.play();
      } catch (_) {
        _video = null;
      }
    }
    if (!mounted || request != _request) return;
    setState(() => _loading = false);
    if (!_missingAudio) {
      if (mounted) setState(() => _playing = true);
      unawaited(_voice.play());
    } else if (_video?.value.isInitialized ?? false) {
      if (mounted) setState(() => _playing = true);
    }
  }

  Future<void> _playPause() async {
    if (_loading || _completed) return;
    if (_playing) {
      await _voice.pause();
      await _video?.pause();
    } else {
      if (!_missingAudio) {
        if (_voice.processingState == ProcessingState.completed) await _voice.seek(Duration.zero);
        unawaited(_voice.play());
      }
      await _video?.play();
    }
    if (mounted) setState(() => _playing = !_playing);
  }

  Future<void> _seek(int seconds) async {
    if (_missingAudio) return;
    final len = _voice.duration;
    if (len == null) return;
    final ms = (_voice.position.inMilliseconds + seconds * 1000).clamp(0, len.inMilliseconds).toInt();
    await _voice.seek(Duration(milliseconds: ms));
  }

  Future<void> _setSpeed(double next) async {
    _speed = next;
    await _voice.setSpeed(next);
    if (mounted) setState(() {});
  }

  Future<void> _counter(int by) async {
    if (_stages[_index].counter.isEmpty) return;
    final pref = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      if (_stages[_index].counter == 'tawaf') {
        _tawaf = (_tawaf + by).clamp(0, 7).toInt();
      } else {
        _sai = (_sai + by).clamp(0, 7).toInt();
      }
    });
    await pref.setInt('rifqa_premium_tawaf', _tawaf);
    await pref.setInt('rifqa_premium_sai', _sai);
    HapticFeedback.mediumImpact();
  }

  void _sheet(String title, String body, {String? note}) {
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _Palette.dark,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _Palette.gold.withValues(alpha: .6)),
            ),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: _Palette.gold, fontSize: 23, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                SelectableText(body, style: const TextStyle(color: _Palette.ivory, fontSize: 16, height: 1.9)),
                if (note != null) ...[
                  const SizedBox(height: 12),
                  Text(note, style: const TextStyle(color: _Palette.gold, fontSize: 13, height: 1.5)),
                ],
                const SizedBox(height: 15),
                Align(alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () { Clipboard.setData(ClipboardData(text: body)); Navigator.pop(context); },
                    icon: const Icon(Icons.copy_all_rounded), label: const Text('نسخ النص'),
                    style: OutlinedButton.styleFrom(foregroundColor: _Palette.gold),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _openGallery() {
    final gallery = _stages[_index].gallery;
    final images = <String>[_stages[_index].image, ...gallery];
    showModalBottomSheet<void>(context: context, backgroundColor: _Palette.dark, isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SizedBox(height: MediaQuery.sizeOf(context).height * .72,
          child: PageView(children: images.map((src) => InteractiveViewer(
            minScale: 1, maxScale: 4,
            child: Image.asset(src, fit: BoxFit.contain),
          )).toList()),
        ),
      ),
    );
  }

  // Preserve the rich original 7-step written guide instead of hiding it.
  Future<void> _openOriginalGuide() async {
    const mapping = <int>[0, 1, 2, 2, 3, 4, 4, 5, 6];
    await _voice.pause();
    await _video?.pause();
    if (!mounted) return;
    setState(() => _playing = false);
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => UmrahStepPage(index: mapping[_index]),
    ));
  }

  void _open3D() async {
    final kind = _stages[_index].counter;
    if (kind.isEmpty) return;
    await _voice.pause();
    await _video?.pause();
    if (mounted) setState(() => _playing = false);
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => RifqaPremium3D(kind: kind),
    ));
    final pref = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _tawaf = pref.getInt('rifqa_premium_tawaf') ?? _tawaf;
      _sai = pref.getInt('rifqa_premium_sai') ?? _sai;
    });
  }

  @override
  void dispose() {
    ++_request;
    _sub?.cancel();
    _motion.dispose();
    _voice.dispose();
    _video?.dispose();
    super.dispose();
  }

  Widget _scenery(_Stage step) {
    final vid = _video;
    if (step.video && vid != null && vid.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(width: vid.value.size.width, height: vid.value.size.height,
          child: VideoPlayer(vid)),
      );
    }
    return AnimatedBuilder(
      animation: _motion,
      builder: (_, __) => Transform.scale(
        scale: 1.06 + _motion.value * .07,
        child: Image.asset(step.image, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: _Palette.green,
            child: Center(child: Icon(Icons.mosque_rounded, color: _Palette.gold, size: 85)),
          ),
        ),
      ),
    );
  }

  Widget _dotProgress() => Row(children: List.generate(_stages.length, (i) => Expanded(
    child: InkWell(
      onTap: () => _switchTo(i),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Container(height: 5, decoration: BoxDecoration(
          color: i <= _index ? _Palette.gold : Colors.white38,
          borderRadius: BorderRadius.circular(5),
        )),
      ),
    ),
  )));

  Widget _circle(IconData icon, VoidCallback onTap, {bool gold = false}) => Material(
    color: gold ? _Palette.gold : _Palette.dark.withValues(alpha: .83),
    shape: CircleBorder(side: BorderSide(color: _Palette.gold.withValues(alpha: .75))),
    child: IconButton(icon: Icon(icon, color: gold ? _Palette.dark : _Palette.gold), onPressed: onTap),
  );

  Widget _feature(IconData icon, String label, VoidCallback onTap) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 64, padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          border: Border.all(color: _Palette.gold.withValues(alpha: .35)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withValues(alpha: .15),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: _Palette.gold, size: 22),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _Palette.ivory, fontSize: 11)),
        ]),
      ),
    ),
  );

  String _format(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  Widget _audioControls() => StreamBuilder<Duration>(
    stream: _voice.positionStream,
    builder: (_, snapshot) {
      final duration = _voice.duration ?? Duration.zero;
      final position = snapshot.data ?? Duration.zero;
      final end = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;
      final progress = position.inMilliseconds.clamp(0, end).toDouble();
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Text(_format(position), style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Expanded(child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _Palette.gold, inactiveTrackColor: Colors.white24,
              thumbColor: _Palette.gold, trackHeight: 3,
            ),
            child: Slider(value: progress, max: end.toDouble(),
              onChanged: _missingAudio || duration == Duration.zero ? null : (v) => _voice.seek(Duration(milliseconds: v.round()))),
          )),
          Text(_format(duration), style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          TextButton(onPressed: () => _setSpeed(_speed == 1 ? 1.25 : _speed == 1.25 ? .85 : 1),
            child: Text('${_speed}×', style: const TextStyle(color: _Palette.gold, fontWeight: FontWeight.bold))),
          IconButton(onPressed: () => _seek(-15), icon: const Icon(Icons.replay_10_rounded, color: _Palette.ivory)),
          _circle(_loading ? Icons.hourglass_top_rounded : _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            _playPause, gold: true),
          IconButton(onPressed: () => _seek(15), icon: const Icon(Icons.forward_10_rounded, color: _Palette.ivory)),
          IconButton(onPressed: () async {
            setState(() => _mute = !_mute);
            await _voice.setVolume(_mute ? 0 : 1);
          }, icon: Icon(_mute ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: _Palette.gold)),
        ]),
        if (_missingAudio)
          const Text('ملف الشرح الصوتي غير متاح لهذه الخطوة',
            style: TextStyle(fontSize: 11, color: _Palette.gold)),
      ]);
    },
  );

  Widget _counterUI(_Stage st) {
    if (st.counter.isEmpty) return const SizedBox.shrink();
    final isTawaf = st.counter == 'tawaf';
    final count = isTawaf ? _tawaf : _sai;
    final direction = isTawaf ? 'الكعبة عن يسارك · عكس عقارب الساعة'
        : count.isEven ? 'المسار التالي: الصفا ← المروة' : 'المسار التالي: المروة ← الصفا';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .26), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text('عداد ${isTawaf ? 'الطواف' : 'السعي'} · $count من 7',
              style: const TextStyle(color: _Palette.gold, fontWeight: FontWeight.bold))),
          IconButton(onPressed: () => _counter(-1), tooltip: 'تراجع شوط',
            icon: const Icon(Icons.remove_circle_outline, color: _Palette.ivory)),
          FilledButton.icon(onPressed: count < 7 ? () => _counter(1) : null,
            icon: const Icon(Icons.add, size: 18), label: const Text('أتممت شوطًا'),
            style: FilledButton.styleFrom(backgroundColor: _Palette.gold, foregroundColor: _Palette.dark)),
        ]),
        Text(count == 7 ? 'اكتملت الأشواط السبعة' : direction,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _Palette.ivory, fontSize: 11)),
      ]),
    );
  }

  Widget _bottomDock(_Stage st, Size size) => Positioned(
    right: 12, left: 12, bottom: MediaQuery.paddingOf(context).bottom + 9,
    child: Container(
      constraints: BoxConstraints(maxHeight: size.height * .49),
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 10),
      decoration: BoxDecoration(
        color: _Palette.glass,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Palette.gold.withValues(alpha: .6)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(st.body, textAlign: TextAlign.center,
            style: const TextStyle(color: _Palette.ivory, fontSize: 14, height: 1.55)),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => _sheet('دعاء المرحلة', st.dua, note: st.duaNote),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _Palette.gold.withValues(alpha: .10),
                border: Border.all(color: _Palette.gold.withValues(alpha: .35)),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(children: [
                const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.volunteer_activism_outlined, size: 16, color: _Palette.gold),
                  SizedBox(width: 6),
                  Text('الدعاء والذكر', style: TextStyle(color: _Palette.gold,
                      fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 5),
                Text(st.dua, maxLines: 3, overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _Palette.ivory, fontSize: 14, height: 1.6)),
              ]),
            ),
          ),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(
            onPressed: () => _sheet('الشرح التفصيلي — ${st.title}', st.guide),
            icon: const Icon(Icons.expand_more_rounded, size: 17),
            label: const Text('اقرئي شرح المرحلة كاملًا'),
            style: TextButton.styleFrom(foregroundColor: _Palette.gold),
          )),
          if (st.video) const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Text('فيديو مركّب من صور واقعية ولقطة تمثيلية مولّدة بالذكاء الاصطناعي',
              textAlign: TextAlign.center,
              style: TextStyle(color: _Palette.gold, fontSize: 10)),
          ),
          _counterUI(st),
          _audioControls(),
          const SizedBox(height: 7),
          Row(children: [
            _feature(Icons.menu_book_rounded, 'الشرح الأصلي', _openOriginalGuide),
            const SizedBox(width: 6),
            _feature(Icons.front_hand_outlined, 'الدعاء كاملًا', () => _sheet('دعاء المرحلة', st.dua, note: st.duaNote)),
            const SizedBox(width: 6),
            _feature(Icons.photo_library_rounded, 'الصور', _openGallery),
            const SizedBox(width: 6),
            _feature(st.counter.isNotEmpty ? Icons.view_in_ar_rounded : Icons.info_outline_rounded,
              st.counter.isNotEmpty ? 'المسار / 3D' : 'معالم', st.counter.isNotEmpty ? _open3D : () => _sheet('معلومات مهمة', st.facts.join('\n\n'))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: _index > 0 ? () => _switchTo(_index - 1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('السابق'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _Palette.gold,
                side: const BorderSide(color: _Palette.gold),
                minimumSize: const Size(10, 44),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: FilledButton.icon(
              onPressed: () => _switchTo(_index + 1),
              icon: const Icon(Icons.chevron_left_rounded),
              label: Text(_index == 8 ? 'إنهاء الجولة' : 'التالي'),
              style: FilledButton.styleFrom(
                backgroundColor: _Palette.gold, foregroundColor: _Palette.dark,
                minimumSize: const Size(10, 44),
              ),
            )),
          ]),
        ]),
      ),
    ),
  );

  Widget _finish() => Scaffold(
    backgroundColor: _Palette.dark,
    body: Stack(fit: StackFit.expand, children: [
      Image.asset('${_prefix}scene_4.jpg', fit: BoxFit.cover),
      Container(color: _Palette.dark.withValues(alpha: .7)),
      SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.verified_rounded, size: 96, color: _Palette.gold),
          const SizedBox(height: 18),
          const Text('أكملتِ الرحلة التعليمية', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 29, color: _Palette.gold, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text('نسأل الله أن يتقبل منكِ، ويجعل لكِ عمرة مبرورة.\nإكمال الجولة في التطبيق لا يعني أداء المناسك فعليًا.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _Palette.ivory, fontSize: 16, height: 1.7)),
          const SizedBox(height: 26),
          FilledButton.icon(onPressed: () => _switchTo(0),
            icon: const Icon(Icons.replay_rounded), label: const Text('إعادة الجولة'),
            style: FilledButton.styleFrom(backgroundColor: _Palette.gold, foregroundColor: _Palette.dark)),
          TextButton(onPressed: () => Navigator.of(context).pop(),
            child: const Text('العودة للرئيسية', style: TextStyle(color: _Palette.ivory))),
        ]),
      ))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    if (_completed) return Directionality(textDirection: TextDirection.rtl, child: _finish());
    final st = _stages[_index];
    final size = MediaQuery.sizeOf(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _Palette.dark,
        body: Stack(fit: StackFit.expand, children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _immersive = !_immersive),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 720),
              child: SizedBox.expand(key: ValueKey(_index), child: _scenery(st)),
            ),
          ),
          const IgnorePointer(child: DecoratedBox(
            decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              stops: [0, .20, .53, 1],
              colors: [Color(0xD9052821), Color(0x52052821), Colors.transparent, Color(0xA6052821)],
            )),
          )),
          SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(17, 7, 17, 0),
            child: Column(children: [
              Row(children: [
                _circle(Icons.arrow_forward_rounded, () => Navigator.pop(context)),
                const Expanded(child: Column(children: [
                  Text('رِفقة | رحلة العمرة',
                    style: TextStyle(fontSize: 21, color: _Palette.gold, fontWeight: FontWeight.w900)),
                  Text('دليل مرئي وصوتي خطوة بخطوة',
                    style: TextStyle(fontSize: 11, color: _Palette.ivory)),
                ])),
                _circle(_immersive ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                  () => setState(() => _immersive = !_immersive)),
                const SizedBox(width: 5),
                _circle(Icons.menu_book_outlined, () => _sheet(st.title, st.guide)),
              ]),
              const SizedBox(height: 14),
              _dotProgress(),
              const SizedBox(height: 12),
              Text('${_index + 1} من ${_stages.length}',
                style: const TextStyle(color: _Palette.gold, fontSize: 12)),
              const SizedBox(height: 6),
              Text(st.title, textAlign: TextAlign.center,
                style: const TextStyle(color: _Palette.ivory, fontSize: 25, fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 8)])),
              Text(st.subtitle, textAlign: TextAlign.center,
                style: const TextStyle(color: _Palette.ivory, fontSize: 13)),
            ]),
          )),
          if (!_immersive) _bottomDock(st, size),
          if (_immersive)
            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + 24,
              left: 18, right: 18,
              child: FilledButton.icon(
                onPressed: () => setState(() => _immersive = false),
                icon: const Icon(Icons.fullscreen_exit_rounded),
                label: const Text('إظهار الشرح والتحكم'),
                style: FilledButton.styleFrom(
                  backgroundColor: _Palette.gold,
                  foregroundColor: _Palette.dark,
                  minimumSize: const Size(10, 52),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
