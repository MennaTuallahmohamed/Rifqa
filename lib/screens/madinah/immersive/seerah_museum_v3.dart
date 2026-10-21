import 'package:flutter/material.dart';
import 'cinematic_theme.dart';
import 'seerah_museum.dart';

/// Cream / gold redesign of the 50-story index. Reads the exact same offline
/// catalog and opens the existing story experience, preserving narration,
/// historic-source display and the user's previous assets.
class SeerahMuseumV3 extends StatefulWidget {
  const SeerahMuseumV3({super.key});
  @override
  State<SeerahMuseumV3> createState() => _SeerahMuseumV3State();
}

class _SeerahMuseumV3State extends State<SeerahMuseumV3> {
  late final Future<List<SeerahStory>> _future = SeerahStory.load();
  final TextEditingController _search = TextEditingController();
  String _category = 'الكل';

  static const _categories = <String>[
    'الكل', 'محبته لأمته', 'مواقف الرحمة', 'المواساة والوفاء',
    'التوبة والعدل', 'رحلة الرسالة',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(SeerahStory story) => Navigator.of(context).push(
    cinematicRoute(SeerahStoryExperience(story: story)),
  );

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: const Color(0xFFFCF8F1),
      body: FutureBuilder<List<SeerahStory>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(18),
              child: Text('تعذر فتح مكتبة الحكايات: ${snapshot.error}',
                textAlign: TextAlign.center)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(
              color: cinematicGreen));
          }
          final text = _search.text.trim();
          final visible = snapshot.data!.where((story) =>
            (_category == 'الكل' || story.category == _category) &&
            (text.isEmpty || story.title.contains(text) ||
              story.summary.contains(text) || story.source.contains(text))).toList();
          return CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
            SliverToBoxAdapter(child: _SeerahHero(
              onBack: () => Navigator.of(context).pop())),
            SliverPadding(padding: const EdgeInsets.fromLTRB(15, 0, 15, 5),
              sliver: SliverList(delegate: SliverChildListDelegate([
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'ابحثي عن قصة أو موقف ...',
                    prefixIcon: const Icon(Icons.search, color: cinematicGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none),
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 17,
                      horizontal: 16),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(height: 44, child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (context, i) {
                    final label = _categories[i];
                    final active = label == _category;
                    return ChoiceChip(
                      showCheckmark: false,
                      label: Text(label, style: TextStyle(
                        color: active ? Colors.white : cinematicGreen,
                        fontWeight: FontWeight.w700)),
                      selected: active,
                      selectedColor: cinematicGreen,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: active ? cinematicGreen :
                        const Color(0xFFF0E6D4)),
                      onSelected: (_) => setState(() => _category = label),
                    );
                  },
                )),
                const SizedBox(height: 19),
                Text('${visible.length} حكاية من السيرة',
                  style: const TextStyle(color: cinematicGreen,
                    fontWeight: FontWeight.w900, fontSize: 23)),
                const SizedBox(height: 6),
                const Text('حكايات بمراجعها وصور توضيحية، والصوت البشري عند توفر تسجيله.',
                  style: TextStyle(color: Color(0xFF7B847C), fontSize: 12)),
                const SizedBox(height: 13),
              ]))),
            if (visible.isEmpty)
              const SliverToBoxAdapter(child: Padding(
                padding: EdgeInsets.all(25), child: Center(child: Text('لا توجد نتائج')))),
            SliverPadding(padding: const EdgeInsets.fromLTRB(15, 0, 15, 18),
              sliver: SliverList.builder(
                itemCount: visible.length,
                itemBuilder: (context, i) {
                  final story = visible[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: i < 3
                      ? _FeaturedStory(story: story, onTap: () => _open(story))
                      : _StoryItem(story: story, onTap: () => _open(story)),
                  );
                },
              )),
            const SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 26),
              child: Text('غلاف كل حكاية مشهد توضيحي، وليس تصويرًا تاريخيًا للشخصيات أو الأحداث. يُرجى مراجعة المصادر قبل النشر العام.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF777D75),
                  fontSize: 11, height: 1.7)),
            )),
          ]);
        },
      ),
    ),
  );
}

class _SeerahHero extends StatelessWidget {
  const _SeerahHero({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 325,
    child: Stack(fit: StackFit.expand, children: [
      const CinematicImage('$cinematicAssets/scenes/exterior_sunset_wide.jpg',
        alignment: Alignment.centerLeft),
      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.centerLeft, end: Alignment.centerRight,
        colors: [Color(0x10000000), Color(0xCBFFF9EC), Color(0xFFFDF8ED)],
        stops: [0, .55, 1],
      ))),
      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.transparent, Color(0xFFFCF8F1)],
      ))),
      SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('رِفقة', style: TextStyle(color: cinematicGreen,
              fontWeight: FontWeight.w900, fontSize: 31)),
            CircleAvatar(backgroundColor: const Color(0xFFFFF8EC),
              child: IconButton(icon: const Icon(Icons.arrow_forward_ios,
                color: cinematicGreen, size: 18), onPressed: onBack)),
          ]),
          const Spacer(),
          const Text('حكايات عن رسول الله ﷺ', style: TextStyle(
            color: cinematicGreen, fontSize: 28, fontWeight: FontWeight.w900,
            height: 1.4)),
          const SizedBox(height: 7),
          const Text('قدوة ورحمة .. وقصص تلامس القلب', style: TextStyle(
            color: cinematicGreen, fontSize: 14)),
          const SizedBox(height: 11),
          DecoratedBox(decoration: BoxDecoration(color: cinematicGreen,
            borderRadius: BorderRadius.circular(30)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Text('50 قصة وموقفًا', style: TextStyle(
                color: cinematicGold, fontWeight: FontWeight.w800)),
            )),
          const SizedBox(height: 16),
        ])),
      ),
    ]),
  );
}

class _FeaturedStory extends StatelessWidget {
  const _FeaturedStory({required this.story, required this.onTap});
  final SeerahStory story;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 2.06,
    child: Material(color: cinematicGreen, borderRadius: BorderRadius.circular(23),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Stack(fit: StackFit.expand, children: [
        CinematicImage(story.cover),
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.centerRight, end: Alignment.centerLeft,
          colors: [Color(0xF1033628), Color(0xC605392A), Color(0x2005392A)]))),
        Padding(padding: const EdgeInsets.all(15),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('الحكاية ${story.id}  •  ${story.category}', style: const TextStyle(
              color: cinematicGold, fontWeight: FontWeight.w700, fontSize: 12)),
            const Spacer(),
            Text(story.title, maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 19,
                fontWeight: FontWeight.w900, height: 1.3)),
            const SizedBox(height: 6),
            const Row(children: [
              Text('اقرئي واستمعي', style: TextStyle(color: Color(0xFFEBD8B0),
                fontSize: 12)),
              SizedBox(width: 5),
              Icon(Icons.play_circle_outline, color: cinematicGold, size: 18),
            ]),
          ])),
      ])),
    ),
  );
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({required this.story, required this.onTap});
  final SeerahStory story;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white, borderRadius: BorderRadius.circular(20),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20),
      child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(14),
          child: SizedBox(width: 89, height: 83,
            child: CinematicImage(story.cover))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(story.title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: cinematicGreen,
              fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Text(story.source, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF987441), fontSize: 11)),
        ])),
        const Icon(Icons.chevron_left, color: cinematicGreen),
      ])),
    ),
  );
}
