import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'cinematic_theme.dart';

class SeerahStory {
  const SeerahStory({required this.id, required this.title, required this.summary,
    required this.source, required this.category, required this.cover});
  final int id;
  final String title, summary, source, category, cover;

  factory SeerahStory.fromJson(Map<String, dynamic> data) => SeerahStory(
    id: data['id'] as int,
    title: data['title'] as String,
    summary: data['summary'] as String,
    source: data['source'] as String,
    category: data['category'] as String,
    cover: data['cover'] as String,
  );

  static Future<List<SeerahStory>> load() async {
    final raw = await rootBundle.loadString('assets/data/madinah_cinematic/stories.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => SeerahStory.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class SeerahMuseumScreen extends StatefulWidget {
  const SeerahMuseumScreen({super.key});
  @override
  State<SeerahMuseumScreen> createState() => _SeerahMuseumScreenState();
}

class _SeerahMuseumScreenState extends State<SeerahMuseumScreen> {
  late final Future<List<SeerahStory>> _stories = SeerahStory.load();
  final TextEditingController _search = TextEditingController();
  final PageController _cards = PageController(viewportFraction: .76);
  String category = 'الكل';
  static const categories = <String>[
    'الكل', 'محبته لأمته', 'مواقف الرحمة', 'المواساة والوفاء',
    'التوبة والعدل', 'رحلة الرسالة',
  ];

  @override
  void dispose() {
    _search.dispose();
    _cards.dispose();
    super.dispose();
  }

  void _open(SeerahStory story) => Navigator.of(context).push(
    cinematicRoute(SeerahStoryExperience(story: story)));

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: cinematicDeep,
      body: FutureBuilder<List<SeerahStory>>(
        future: _stories,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('لم نتمكن من فتح الحكايات: ${snapshot.error}',
              style: const TextStyle(color: cinematicCream)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: cinematicGold));
          }
          final term = _search.text.trim();
          final data = snapshot.data!.where((story) =>
            (category == 'الكل' || story.category == category) &&
            (term.isEmpty || story.title.contains(term) ||
              story.summary.contains(term) || story.source.contains(term))).toList();
          return CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: 320, pinned: true,
              backgroundColor: cinematicGreen,
              leading: IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: cinematicCream),
                onPressed: () => Navigator.pop(context)),
              title: const Text('معرض السيرة النبوية', style: TextStyle(color: cinematicCream)),
              flexibleSpace: FlexibleSpaceBar(background: Stack(fit: StackFit.expand, children: [
                const CinematicImage('$cinematicAssets/scenes/quran_courtyard.jpg'),
                const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0x15041710), Color(0x8A041710), cinematicDeep]))),
                const SafeArea(child: Align(alignment: Alignment.bottomCenter,
                  child: Padding(padding: EdgeInsets.fromLTRB(22, 0, 22, 20),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      CinematicPill(text: '50 قصة وموقفًا'),
                      SizedBox(height: 14),
                      CinematicHeading('حكايات عن رسول الله ﷺ',
                        subtitle: 'مواقف في الرحمة والوفاء والتوبة والسيرة، بمراجعها'),
                    ]),
                  )),
                ),
              ])),
            ),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  controller: _search,
                  onChanged: (_) {
                    setState(() {});
                    if (_cards.hasClients) _cards.jumpToPage(0);
                  },
                  style: const TextStyle(color: cinematicCream),
                  decoration: InputDecoration(
                    hintText: 'ابحثي عن موقف أو حديث أو اسم...',
                    hintStyle: const TextStyle(color: cinematicMuted),
                    prefixIcon: const Icon(Icons.search, color: cinematicGold),
                    filled: true, fillColor: cinematicGreen.withOpacity(.65),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: cinematicGold.withOpacity(.25))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: cinematicGold)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(height: 45, child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final label = categories[i];
                    final active = label == category;
                    return ChoiceChip(
                      label: Text(label), selected: active,
                      backgroundColor: cinematicGreen,
                      selectedColor: cinematicGold,
                      checkmarkColor: cinematicDeep,
                      labelStyle: TextStyle(color: active ? cinematicDeep : cinematicCream,
                        fontWeight: FontWeight.w700),
                      side: BorderSide(color: cinematicGold.withOpacity(.4)),
                      onSelected: (_) {
                        setState(() => category = label);
                        if (_cards.hasClients) _cards.jumpToPage(0);
                      },
                    );
                  },
                )),
                const SizedBox(height: 20),
                Text('جولة الصور • ${data.length} قصة',
                  style: const TextStyle(color: cinematicCream, fontSize: 21,
                    fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('اسحبي البطاقات، واضغطي على الحكاية لقراءتها ومراجعة مصدرها، والصوت البشري عند توفره.',
                  style: TextStyle(color: cinematicMuted, height: 1.55)),
              ]),
            )),
            SliverToBoxAdapter(child: SizedBox(height: 335,
              child: data.isEmpty ? const Center(child: Text('لا توجد نتائج',
                style: TextStyle(color: cinematicCream)))
                : PageView.builder(
                  controller: _cards,
                  itemCount: data.length,
                  itemBuilder: (context, i) => AnimatedBuilder(
                    animation: _cards,
                    child: _SeerahPoster(story: data[i], onTap: () => _open(data[i])),
                    builder: (context, child) {
                      double page = i.toDouble();
                      if (_cards.hasClients && _cards.position.haveDimensions) {
                        page = _cards.page ?? i.toDouble();
                      }
                      final delta = (i - page).clamp(-2.0, 2.0).toDouble();
                      final matrix = Matrix4.identity()
                        ..setEntry(3, 2, .001)
                        ..rotateY(delta * -.10)
                        ..scale(1 - math.min(delta.abs() * .12, .25));
                      return Transform(alignment: Alignment.center, transform: matrix,
                        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 7), child: child));
                    },
                  ),
                ),
            )),
            const SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Text('جميع الحكايات', style: TextStyle(
                color: cinematicCream, fontSize: 22, fontWeight: FontWeight.bold)),
            )),
            SliverList(delegate: SliverChildBuilderDelegate((context, i) {
              final story = data[i];
              return Padding(padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
                child: Material(color: cinematicGreen.withOpacity(.76),
                  borderRadius: BorderRadius.circular(19),
                  child: InkWell(borderRadius: BorderRadius.circular(19),
                    onTap: () => _open(story),
                    child: Padding(padding: const EdgeInsets.all(9), child: Row(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12),
                        child: SizedBox(height: 85, width: 78,
                          child: CinematicImage(story.cover))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(story.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: cinematicCream,
                              fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(story.category, style: const TextStyle(
                            color: cinematicGold, fontSize: 12)),
                          Text(story.source, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: cinematicMuted, fontSize: 11)),
                        ])),
                      const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 17, color: cinematicGold),
                    ])),
                  ),
                ),
              );
            }, childCount: data.length)),
            const SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.fromLTRB(22, 18, 22, 40),
              child: Text(
                '$cinematicIllustrationNote\nالمراجع من ملف المحتوى المقدم، وتحتاج مراجعة علمية وتحريرية قبل النشر.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cinematicMuted, height: 1.7, fontSize: 11)),
            )),
          ]);
        },
      ),
    ),
  );
}

class _SeerahPoster extends StatelessWidget {
  const _SeerahPoster({required this.story, required this.onTap});
  final SeerahStory story;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: cinematicGreen,
    elevation: 12,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(22),
      child: ClipRRect(borderRadius: BorderRadius.circular(22), child: Stack(
        fit: StackFit.expand, children: [
          CinematicImage(story.cover),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0xBB031B13), cinematicDeep],
            stops: [0, .6, 1]))),
          Padding(padding: const EdgeInsets.all(18), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              CinematicPill(text: 'الحكاية ${story.id}'),
              const Spacer(),
              Text(story.title, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: cinematicCream,
                  fontSize: 23, fontWeight: FontWeight.bold, height: 1.35)),
              const SizedBox(height: 8),
              Text(story.source, maxLines: 2,
                style: const TextStyle(color: cinematicGold, fontSize: 12)),
              const SizedBox(height: 10),
              const Row(children: [Icon(Icons.play_circle_fill_rounded,
                color: cinematicGold), SizedBox(width: 8),
                Text('افتحي التجربة', style: TextStyle(color: cinematicCream))]),
            ]),
          ),
        ]),
      ),
    ),
  );
}

/// Story artwork may be illustrative. This is a human-recording-only player:
/// it never synthesizes a woman's voice and never imitates historical figures.
class SeerahStoryExperience extends StatefulWidget {
  const SeerahStoryExperience({super.key, required this.story});
  final SeerahStory story;

  @override
  State<SeerahStoryExperience> createState() => _SeerahStoryExperienceState();
}

class _SeerahStoryExperienceState extends State<SeerahStoryExperience>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  late final AnimationController _breath;
  int _step = 0;
  bool _recordingAvailable = false;
  bool _checking = true;
  String? _loadedRecording;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(vsync: this,
      duration: const Duration(seconds: 11))..repeat(reverse: true);
    _loadHumanRecording();
  }

  Future<void> _loadHumanRecording() async {
    final name = 'story_${widget.story.id.toString().padLeft(2, '0')}';
    final candidates = <String>[
      'assets/audio/madinah/stories/$name.mp3',
      'assets/audio/madinah/stories/$name.m4a',
    ];
    for (final path in candidates) {
      try {
        // Use the bundled AI narration audio files at these paths.
        await rootBundle.load(path);
        await _player.setAsset(path);
        if (!mounted) return;
        setState(() {
          _recordingAvailable = true;
          _loadedRecording = path;
          _checking = false;
        });
        return;
      } catch (_) {
        // This story has no narrator recording packaged yet.
      }
    }
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _toggleRecording() async {
    if (!_recordingAvailable) return;
    try {
      if (_player.playing) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تشغيل تسجيل الراوية: $e')),
      );
    }
  }

  void _move(int delta) {
    _player.pause();
    setState(() { _step = (_step + delta).clamp(0, 2).toInt(); });
  }

  @override
  void dispose() {
    _player.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final String title;
    final String desc;
    switch (_step) {
      case 0:
        title = story.title;
        desc = 'موقف من السيرة النبوية، تقدمه رفقة بمصدره مع صورة توضيحية.';
        break;
      case 1:
        title = 'الحكاية';
        desc = story.summary;
        break;
      default:
        title = 'المصدر والتوثيق';
        desc = '${story.source}\n\nالملخص صياغة تحريرية وليس اقتباسًا حرفيًا من الحديث. راجعي النص الأصلي.';
    }
    return Directionality(textDirection: TextDirection.rtl,
      child: Scaffold(backgroundColor: cinematicDeep,
        body: Stack(children: [
          Positioned.fill(child: AnimatedBuilder(
            animation: _breath,
            builder: (context, _) => Transform.scale(
              scale: MediaQuery.of(context).disableAnimations
                ? 1 : 1.05 + _breath.value * .05,
              child: CinematicImage(story.cover)),
          )),
          const Positioned.fill(child: IgnorePointer(child: DecoratedBox(
            decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0x99041710), Color(0xB3041710), cinematicDeep]))))),
          SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
            child: Column(children: [
              Row(children: [
                IconButton.filledTonal(
                  style: IconButton.styleFrom(backgroundColor: cinematicGreen),
                  icon: const Icon(Icons.arrow_forward_ios_rounded,
                    color: cinematicCream),
                  onPressed: () => Navigator.pop(context)),
                const Spacer(),
                const CinematicPill(text: 'معرض السيرة'),
                const Spacer(),
                StreamBuilder<PlayerState>(
                  stream: _player.playerStateStream,
                  builder: (context, snapshot) => IconButton.filledTonal(
                    style: IconButton.styleFrom(backgroundColor: cinematicGreen),
                    tooltip: _recordingAvailable
                      ? 'الاستماع إلى تسجيل الراوية البشرية'
                      : 'التسجيل البشري غير متوفر',
                    onPressed: _recordingAvailable ? _toggleRecording : null,
                    icon: Icon(snapshot.data?.playing == true
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                      color: _recordingAvailable ? cinematicGold : cinematicMuted),
                  ),
                ),
              ]),
              const Spacer(),
              const Icon(Icons.auto_stories, color: cinematicGold, size: 37),
              const SizedBox(height: 16),
              AnimatedSwitcher(duration: const Duration(milliseconds: 650),
                child: ConstrainedBox(key: ValueKey(_step),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .43),
                  child: SingleChildScrollView(child: Column(children: [
                    CinematicHeading(title, subtitle: desc),
                    if (_step == 2) ...[
                      const SizedBox(height: 20),
                      const Text(cinematicIllustrationNote,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cinematicGold,
                          height: 1.6, fontSize: 12)),
                    ],
                  ])),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cinematicGreen.withOpacity(.82),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cinematicGold.withOpacity(.33))),
                child: Row(children: [
                  Icon(_recordingAvailable ? Icons.graphic_eq_rounded
                    : Icons.mic_off_outlined, color: cinematicGold),
                  const SizedBox(width: 9),
                  Expanded(child: Text(_checking
                    ? 'جاري فحص التسجيل البشري...'
                    : _recordingAvailable
                      ? 'تسجيل راوية بشرية متاح • ${_loadedRecording!.split('/').last}'
                      : 'لا يوجد تسجيل بشري لهذه الحكاية بعد. النص متاح للقراءة دون صوت اصطناعي.',
                    style: const TextStyle(color: cinematicCream,
                      fontSize: 11, height: 1.5))),
                ]),
              ),
              const SizedBox(height: 17),
              Row(children: List.generate(3, (i) => Expanded(child: AnimatedContainer(
                duration: const Duration(milliseconds: 350), height: 4,
                margin: const EdgeInsets.only(left: 7),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),
                  color: i <= _step ? cinematicGold : cinematicMuted.withOpacity(.5))),
              ))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: CinematicButton(
                  label: _step == 2 ? 'إعادة' : 'التالي',
                  onPressed: () => _move(_step == 2 ? -2 : 1))),
                const SizedBox(width: 10),
                if (_step > 0) IconButton.filledTonal(
                  style: IconButton.styleFrom(backgroundColor: cinematicGreen),
                  icon: const Icon(Icons.arrow_forward_ios_rounded, color: cinematicGold),
                  onPressed: () => _move(-1)),
              ]),
              const SizedBox(height: 8),
              const Text('لا تجسيد للنبي ﷺ ولا محاكاة لصوته',
                style: TextStyle(color: cinematicMuted, fontSize: 10)),
            ]),
          )),
        ]),
      ),
    );
  }
}
