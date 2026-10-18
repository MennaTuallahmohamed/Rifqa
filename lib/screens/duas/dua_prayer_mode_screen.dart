import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/dua_model.dart';
import '../../services/duas/duas_audio_service.dart';
import '../../services/duas/duas_repository.dart';
import 'dua_premium_theme.dart';

class DuaPrayerModeScreen extends StatefulWidget {
  const DuaPrayerModeScreen(
      {super.key,
      required this.repository,
      required this.duas,
      required this.initialIndex});
  final DuasRepository repository;
  final List<Dua> duas;
  final int initialIndex;
  @override
  State<DuaPrayerModeScreen> createState() => _DuaPrayerModeScreenState();
}

class _DuaPrayerModeScreenState extends State<DuaPrayerModeScreen> {
  late final PageController _pager;
  late final DuasAudioService _audio;
  late int _index;
  final Map<String, int> _count = {};
  bool _playing = false;
  bool _controls = true;
  Dua get _current => widget.duas[_index];
  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.duas.length - 1);
    _pager = PageController(initialPage: _index);
    _audio = DuasAudioService();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _audio.stop();
    _audio.dispose();
    _pager.dispose();
    super.dispose();
  }

  void _inc() {
    final v = _count[_current.id] ?? 0;
    if (_current.repeatCount > 1 && v >= _current.repeatCount) return;
    setState(() => _count[_current.id] = v + 1);
    if (v + 1 == _current.repeatCount)
      HapticFeedback.heavyImpact();
    else
      HapticFeedback.selectionClick();
  }

  Future<void> _voice() async {
    if (_playing) {
      setState(() => _playing = false);
      await _audio.stop();
    } else {
      setState(() => _playing = true);
      try {
        await _audio.speak(_current.arabicText);
      } catch (_) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('تعذّر تشغيل الصوت')));
      }
      if (mounted) setState(() => _playing = _audio.isPlaying);
    }
  }

  void _go(int direction) {
    if (direction < 0 && _index > 0) {
      _pager.previousPage(
          duration: const Duration(milliseconds: 290),
          curve: Curves.easeOutCubic);
    } else if (direction > 0 && _index < widget.duas.length - 1) {
      _pager.nextPage(
          duration: const Duration(milliseconds: 290),
          curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: DuaPremium.cream,
          body: SafeArea(
              child: Stack(children: [
            Positioned.fill(
                child: Column(children: [
              Container(
                  width: double.infinity,
                  height: 116,
                  decoration: const BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage('assets/duas/hero_kaaba.jpg'),
                          fit: BoxFit.cover)),
                  child: const DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                    Color(0xE3063D30),
                    Color(0x9A063D30)
                  ])))),
              Expanded(
                  child: PageView.builder(
                      controller: _pager,
                      itemCount: widget.duas.length,
                      onPageChanged: (value) async {
                        await _audio.stop();
                        if (!mounted) return;
                        setState(() {
                          _index = value;
                          _playing = false;
                        });
                      },
                      itemBuilder: (context, i) {
                        final d = widget.duas[i];
                        return GestureDetector(
                            onTap: () => setState(() => _controls = !_controls),
                            child: Center(
                                child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                        22, 38, 22, 193),
                                    child: Column(children: [
                                      Text(d.title,
                                          textAlign: TextAlign.center,
                                          style: DuaPremium.type(19,
                                              weight: FontWeight.w900)),
                                      const SizedBox(height: 8),
                                      Text(d.sourceType.label,
                                          style: DuaPremium.type(11,
                                              color: DuaPremium.green)),
                                      const SizedBox(height: 20),
                                      Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 17, vertical: 27),
                                          decoration:
                                              DuaPremium.card(radius: 26),
                                          child: SelectableText(d.arabicText,
                                              textAlign: TextAlign.center,
                                              style: DuaPremium.type(
                                                  23 *
                                                      widget
                                                          .repository.fontScale,
                                                  height: 2.0,
                                                  weight: FontWeight.w700))),
                                      if (d.reference.isNotEmpty) ...[
                                        const SizedBox(height: 15),
                                        Text(d.reference,
                                            textAlign: TextAlign.center,
                                            style: DuaPremium.type(10.5,
                                                color: DuaPremium.muted)),
                                      ],
                                    ]))));
                      })),
            ])),
            if (_controls) ...[
              Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(children: [
                    DuaCircleAction(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context)),
                    const Spacer(),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 17, vertical: 7),
                        decoration: BoxDecoration(
                            color: DuaPremium.deep,
                            borderRadius: BorderRadius.circular(18)),
                        child: Text('${_index + 1} / ${widget.duas.length}',
                            style: DuaPremium.type(11,
                                color: Colors.white, weight: FontWeight.w800))),
                    const Spacer(),
                    DuaCircleAction(
                        icon: widget.repository.isFavorite(_current.id)
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        onTap: () {
                          widget.repository.toggleFavorite(_current.id);
                          setState(() {});
                        }),
                  ])),
              Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                      padding: const EdgeInsets.fromLTRB(13, 14, 13, 15),
                      decoration: DuaPremium.card(radius: 29),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                  tooltip: 'تصغير الخط',
                                  onPressed: () => setState(() {
                                        widget.repository.setFontScale(
                                            widget.repository.fontScale - .1);
                                      }),
                                  icon: const Icon(Icons.text_decrease_rounded,
                                      color: DuaPremium.deep)),
                              const SizedBox(width: 12),
                              Material(
                                  color: DuaPremium.deep,
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                      tooltip:
                                          _playing ? 'إيقاف القراءة' : 'استمعي',
                                      onPressed: _voice,
                                      icon: Icon(
                                          _playing
                                              ? Icons.stop_rounded
                                              : Icons.volume_up_rounded,
                                          color: DuaPremium.gold))),
                              const SizedBox(width: 12),
                              IconButton(
                                  tooltip: 'تكبير الخط',
                                  onPressed: () => setState(() {
                                        widget.repository.setFontScale(
                                            widget.repository.fontScale + .1);
                                      }),
                                  icon: const Icon(Icons.text_increase_rounded,
                                      color: DuaPremium.deep)),
                            ]),
                        if (_current.repeatCount > 1) ...[
                          const SizedBox(height: 7),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                    onPressed: () =>
                                        setState(() => _count[_current.id] = 0),
                                    icon: const Icon(Icons.refresh_rounded,
                                        color: DuaPremium.green)),
                                const SizedBox(width: 8),
                                FilledButton(
                                    onPressed: _inc,
                                    style: FilledButton.styleFrom(
                                        backgroundColor: DuaPremium.deep),
                                    child: Text(
                                        '${_count[_current.id] ?? 0} / ${_current.repeatCount}',
                                        style: DuaPremium.type(12,
                                            color: Colors.white))),
                              ]),
                        ],
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: OutlinedButton.icon(
                                  onPressed: _index > 0 ? () => _go(-1) : null,
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label: const Text('السابق'))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: DuaPremium.deep),
                                  onPressed: _index < widget.duas.length - 1
                                      ? () => _go(1)
                                      : null,
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  label: const Text('التالي'))),
                        ]),
                      ]))),
            ],
          ])),
        ),
      );
}
