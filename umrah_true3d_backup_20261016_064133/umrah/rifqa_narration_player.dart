import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'umrah_data.dart';

/// يفضل ملف mp3 المحلي الكامل إن كان موجودًا، وإلا يشغّل المعاينة القصيرة عبر الإنترنت.
/// روابط المعاينات ليست بديلًا عن ملفات التسجيل الكاملة للإصدار النهائي.
class RifqaNarrationPlayer extends StatefulWidget {
  const RifqaNarrationPlayer(
      {super.key, required this.stepIndex, required this.onDua});
  final int stepIndex;
  final VoidCallback onDua;
  @override
  State<RifqaNarrationPlayer> createState() => _RifqaNarrationPlayerState();
}

class _RifqaNarrationPlayerState extends State<RifqaNarrationPlayer> {
  static const emerald = Color(0xFF0B4F3E);
  static const gold = Color(0xFFE5BE69);
  static const _previews = [
    'https://storage.googleapis.com/adm--audio-playback--7d--public/mcp-preview/b2c72ffa-56f8-44a3-a623-e0c3e0210108.mp3',
    'https://storage.googleapis.com/adm--audio-playback--7d--public/mcp-preview/89121c54-c8f6-40d2-83a6-38a68c9abfd7.mp3',
    'https://storage.googleapis.com/adm--audio-playback--7d--public/mcp-preview/fa5d33b5-6b70-4a5a-b3e6-35cd6a9c75fa.mp3',
    'https://storage.googleapis.com/adm--audio-playback--7d--public/mcp-preview/be715f7b-4d54-4d7a-ac10-146685f61144.mp3',
    'https://storage.googleapis.com/adm--audio-playback--7d--public/mcp-preview/d32ab746-c9c9-4eb9-aacb-d83eac58ae22.mp3',
    'https://storage.googleapis.com/adm--audio-playback--7d--public/mcp-preview/306b4d79-228c-437f-ad2d-aab5c0f97ab1.mp3',
    'https://storage.googleapis.com/adm--audio-playback--7d--public/mcp-preview/471830a6-1b11-4180-ade9-c4440f9f9a58.mp3',
  ];
  // Real pre-recorded narration only. No flutter_tts anywhere in this player.
  static const _fullUrls = [
    'https://www.aidocmaker.com/g0/audio?name=54b95cda81e24de3a7aa08cf19889479',
    'https://www.aidocmaker.com/g0/audio?name=c7651c3a138f43008b315e8b5830bec6',
    'https://www.aidocmaker.com/g0/audio?name=7a80681eb13042a693a2fe46f3a2a74e',
    'https://www.aidocmaker.com/g0/audio?name=e5c91e5ee4a24601bb1bbf9e75ab2799',
    'https://www.aidocmaker.com/g0/audio?name=fa08b5c06dc2467f94e4309df7015a66',
    'https://www.aidocmaker.com/g0/audio?name=d3e78b41e32a464eb69adfadd75ecb1a',
    'https://www.aidocmaker.com/g0/audio?name=0615f5d413184ec6bf140fb7e7006039',
  ];
  final AudioPlayer _player = AudioPlayer();
  bool _preview = false;
  StreamSubscription<PlayerState>? _sub;
  int _selected = 0;
  bool _playlist = false;
  bool _loading = false;
  String? _error;
  double _speed = 1;
  @override
  void initState() {
    super.initState();
    _selected = widget.stepIndex;
    _sub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed &&
          _playlist &&
          _selected < 6) {
        _load(_selected + 1, autoplay: true);
      } else if (state.processingState == ProcessingState.completed &&
          _playlist &&
          _selected == 6) {
        setState(() => _playlist = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant RifqaNarrationPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stepIndex != widget.stepIndex) {
      _playlist = false;
      _player.stop();
      setState(() => _selected = widget.stepIndex);
    }
  }

  Future<void> _load(int idx, {bool autoplay = false}) async {
    if (!mounted) return;
    setState(() {
      _selected = idx;
      _loading = true;
      _error = null;
    });
    try {
      await _player.stop();
      _preview = false;
      // Priority: local full narration -> online full narration -> local
      // recorded preview -> online recorded preview. NEVER synthesize speech.
      try {
        await _player.setAsset('assets/audio/umrah/step_${idx + 1}.mp3');
      } catch (_) {
        try {
          await _player
              .setUrl(_fullUrls[idx])
              .timeout(const Duration(seconds: 8));
        } catch (_) {
          _preview = true;
          try {
            await _player.setAsset('assets/audio/umrah/preview_${idx + 1}.mp3');
          } catch (_) {
            await _player.setUrl(_previews[idx]);
          }
        }
      }
      await _player.setSpeed(_speed);
      if (!mounted) return;
      setState(() => _loading = false);
      if (autoplay) await _player.play();
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _playlist = false;
          _error =
              'تعذر تشغيل الصوت. تأكدي من الإنترنت أو أضيفي ملفات MP3 الكاملة.';
        });
    }
  }

  Future<void> _toggle() async {
    if (_loading) return;
    if (_player.playing) {
      await _player.pause();
      return;
    }
    if (_player.audioSource == null ||
        _player.processingState == ProcessingState.completed) {
      await _load(_selected, autoplay: true);
    } else {
      await _player.play();
    }
  }

  Future<void> _seek(Duration delta) async {
    final d = _player.duration;
    if (d == null) return;
    final ms = (_player.position + delta)
        .inMilliseconds
        .clamp(0, d.inMilliseconds)
        .toInt();
    await _player.seek(Duration(milliseconds: ms));
  }

  String _time(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  @override
  void dispose() {
    _sub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE9DAC0)),
        boxShadow: [
          BoxShadow(
              color: emerald.withOpacity(.09),
              blurRadius: 22,
              offset: const Offset(0, 9))
        ],
      ),
      child: Column(children: [
        const Text('استمع للشرح',
            style: TextStyle(
                color: emerald, fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('الخطوة ${_selected + 1} — ${umrahGuide[_selected].title}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF626D66), fontSize: 12.5)),
        const SizedBox(height: 16),
        StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, snapshot) {
              final total = _player.duration?.inMilliseconds ?? 0;
              final current = snapshot.data?.inMilliseconds ?? 0;
              final fraction = total <= 0
                  ? 0.0
                  : (current / total).clamp(0.0, 1.0).toDouble();
              return SizedBox(
                  height: 45,
                  width: double.infinity,
                  child: CustomPaint(
                      painter: _AudioWaves(
                          progressColor: emerald,
                          inactiveColor: const Color(0xFFC7B891),
                          progress: fraction)));
            }),
        const SizedBox(height: 5),
        StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, snapshot) {
              final current = snapshot.data ?? Duration.zero;
              final total = _player.duration ?? Duration.zero;
              final maxMs = total.inMilliseconds > 0
                  ? total.inMilliseconds.toDouble()
                  : 1.0;
              return Column(children: [
                SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                        activeTrackColor: emerald,
                        inactiveTrackColor: const Color(0xFFE3DDD2),
                        thumbColor: emerald,
                        trackHeight: 3,
                        overlayColor: emerald.withOpacity(.1)),
                    child: Slider(
                        min: 0,
                        max: maxMs,
                        value:
                            current.inMilliseconds.toDouble().clamp(0, maxMs),
                        onChanged: total == Duration.zero
                            ? null
                            : (v) => _player
                                .seek(Duration(milliseconds: v.toInt())))),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_time(current),
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                  color: Color(0xFF5A685F), fontSize: 11)),
                          Text(_time(total),
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                  color: Color(0xFF5A685F), fontSize: 11)),
                        ])),
              ]);
            }),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              tooltip: 'الرجوع عشر ثوانٍ',
              onPressed: () => _seek(const Duration(seconds: -10)),
              icon: const Icon(Icons.replay_10_rounded,
                  color: emerald, size: 32)),
          const SizedBox(width: 14),
          StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                return Material(
                    color: emerald,
                    shape: const CircleBorder(),
                    child: SizedBox(
                        width: 69,
                        height: 69,
                        child: IconButton(
                          onPressed: _loading ? null : _toggle,
                          icon: _loading
                              ? const SizedBox(
                                  width: 25,
                                  height: 25,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: gold))
                              : Icon(
                                  playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 39,
                                  color: Colors.white),
                        )));
              }),
          const SizedBox(width: 14),
          IconButton(
              tooltip: 'التقديم عشر ثوانٍ',
              onPressed: () => _seek(const Duration(seconds: 10)),
              icon: const Icon(Icons.forward_10_rounded,
                  color: emerald, size: 32)),
        ]),
        const SizedBox(height: 17),
        Row(children: [
          Expanded(
              child: _ControlTile(
                  title: 'الدعاء',
                  icon: Icons.menu_book_outlined,
                  onTap: widget.onDua)),
          const SizedBox(width: 8),
          Expanded(
              child: _ControlTile(
                  title: '${_speed}×',
                  icon: Icons.speed_rounded,
                  onTap: () async {
                    final next =
                        _speed == 1 ? 1.25 : (_speed == 1.25 ? .75 : 1.0);
                    setState(() => _speed = next);
                    await _player.setSpeed(next);
                  })),
          const SizedBox(width: 8),
          Expanded(
              child: _ControlTile(
                  title: _playlist ? 'إيقاف الجولة' : 'الجولة',
                  icon: Icons.queue_music_rounded,
                  onTap: () {
                    if (_playlist) {
                      setState(() => _playlist = false);
                      _player.pause();
                    } else {
                      setState(() => _playlist = true);
                      _load(_selected, autoplay: true);
                    }
                  })),
        ]),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Color(0xFFB05444), fontSize: 12))),
        const SizedBox(height: 11),
        Text(
            _preview
                ? 'دي معاينة مسجلة قصيرة؛ نزّلي تسجيلات MP3 الكاملة لسماع الشرح كله دون إنترنت.'
                : 'صوت رِفقة الوثائقي المسجّل — بلا قراءة آلية.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFF899087), fontSize: 10.5, height: 1.4)),
      ]),
    );
  }
}

class _ControlTile extends StatelessWidget {
  const _ControlTile(
      {required this.title, required this.icon, required this.onTap});
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
      color: const Color(0xFFF7F2E9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
              height: 58,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: const Color(0xFF0B4F3E), size: 21),
                    const SizedBox(height: 3),
                    Text(title,
                        maxLines: 1,
                        style: const TextStyle(
                            color: Color(0xFF0B4F3E),
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ]))));
}

class _AudioWaves extends CustomPainter {
  const _AudioWaves(
      {required this.progressColor,
      required this.inactiveColor,
      required this.progress});
  final Color progressColor;
  final Color inactiveColor;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    const bars = 61;
    final width = size.width / bars;
    for (var i = 0; i < bars; i++) {
      final a = i / bars;
      final rhythm =
          (0.43 + 0.31 * _sine(i * 1.82) + 0.26 * _sine(i * .43)).abs();
      final height = 7 + rhythm * 34;
      final r = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(i * width + width / 2, size.height / 2),
              width: width * .48,
              height: height),
          const Radius.circular(4));
      canvas.drawRRect(
          r, Paint()..color = a < progress ? progressColor : inactiveColor);
    }
  }

  double _sine(double input) => math.sin(input * 1.7 - input * input * .01);
  @override
  bool shouldRepaint(covariant _AudioWaves oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.progressColor != progressColor;
}
