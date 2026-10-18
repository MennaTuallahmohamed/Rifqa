import 'package:flutter/material.dart';
import '../../models/dua_model.dart';
import '../../services/duas/duas_repository.dart';
import 'dua_premium_theme.dart';
import 'dua_details_screen.dart';
import 'dua_audio_screen.dart';

class DuaCategoryScreen extends StatefulWidget {
  const DuaCategoryScreen(
      {super.key, required this.repository, required this.category});
  final DuasRepository repository;
  final DuaCategory category;
  @override
  State<DuaCategoryScreen> createState() => _DuaCategoryScreenState();
}

class _DuaCategoryScreenState extends State<DuaCategoryScreen> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: DuaPremium.cream,
          body: ListenableBuilder(
              listenable: widget.repository,
              builder: (context, _) {
                final repo = widget.repository;
                final items =
                    repo.search(query: _search.text, category: widget.category);
                return CustomScrollView(slivers: [
                  SliverToBoxAdapter(
                      child: DuaPhotoHero(
                          title: 'أدعية ${widget.category.label}',
                          subtitle: 'مجموعة الأدعية المناسبة لهذه المرحلة',
                          image: DuaPremium.imageFor(widget.category),
                          height: 262,
                          onBack: () => Navigator.pop(context))),
                  SliverToBoxAdapter(
                      child: Transform.translate(
                          offset: const Offset(0, -15),
                          child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(13),
                              decoration: DuaPremium.card(),
                              child: TextField(
                                  controller: _search,
                                  onChanged: (_) => setState(() {}),
                                  style: DuaPremium.type(12),
                                  decoration: InputDecoration(
                                      hintText: 'ابحثي داخل المجموعة...',
                                      hintStyle: DuaPremium.type(11,
                                          color: DuaPremium.muted),
                                      prefixIcon: const Icon(
                                          Icons.search_rounded,
                                          color: DuaPremium.green),
                                      filled: true,
                                      fillColor: DuaPremium.cream,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          borderSide: BorderSide.none)))))),
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                          child: Row(children: [
                            Text('${items.length} دعاء',
                                style: DuaPremium.type(14,
                                    weight: FontWeight.w900)),
                            const Spacer(),
                            Text('اضغطي لقراءة الدعاء',
                                style: DuaPremium.type(11,
                                    color: DuaPremium.muted)),
                          ]))),
                  if (items.isEmpty)
                    const SliverFillRemaining(
                        hasScrollBody: false,
                        child:
                            Center(child: Text('لا توجد أدعية مطابقة للبحث')))
                  else
                    SliverList.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final d = items[i];
                          return Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              decoration: DuaPremium.card(radius: 20),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                            builder: (_) => DuaDetailsScreen(
                                                repository: repo,
                                                duaId: d.id))),
                                    child: Padding(
                                        padding: const EdgeInsets.all(13),
                                        child: Row(children: [
                                          Container(
                                              width: 38,
                                              height: 38,
                                              alignment: Alignment.center,
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFFE8EEE4)),
                                              child: Text('${i + 1}',
                                                  style: DuaPremium.type(13,
                                                      weight:
                                                          FontWeight.w900))),
                                          const SizedBox(width: 10),
                                          Expanded(
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                Text(d.title,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: DuaPremium.type(12.5,
                                                        weight:
                                                            FontWeight.w900)),
                                                Text(d.arabicText,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: DuaPremium.type(11,
                                                        color:
                                                            DuaPremium.muted)),
                                                Text(d.sourceType.label,
                                                    style: DuaPremium.type(9.5,
                                                        color:
                                                            DuaPremium.green)),
                                              ])),
                                          Column(children: [
                                            IconButton(
                                                tooltip: 'مفضلة',
                                                onPressed: () =>
                                                    repo.toggleFavorite(d.id),
                                                icon: Icon(
                                                    repo.isFavorite(d.id)
                                                        ? Icons.bookmark_rounded
                                                        : Icons
                                                            .bookmark_border_rounded,
                                                    color: DuaPremium.green)),
                                            IconButton(
                                                tooltip: 'استمعي',
                                                onPressed: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute<void>(
                                                        builder: (_) =>
                                                            DuaAudioScreen(
                                                                dua: d))),
                                                icon: const Icon(
                                                    Icons
                                                        .play_circle_fill_rounded,
                                                    color: DuaPremium.green)),
                                          ]),
                                        ]))),
                              ));
                        }),
                  const SliverToBoxAdapter(child: SizedBox(height: 45)),
                ]);
              }),
        ),
      );
}
