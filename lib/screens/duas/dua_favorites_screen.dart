import 'package:flutter/material.dart';
import '../../models/dua_model.dart';
import '../../services/duas/duas_repository.dart';
import 'dua_premium_theme.dart';
import 'dua_details_screen.dart';
import 'dua_audio_screen.dart';

class DuaFavoritesScreen extends StatefulWidget {
  const DuaFavoritesScreen({super.key, required this.repository});
  final DuasRepository repository;
  @override
  State<DuaFavoritesScreen> createState() => _DuaFavoritesScreenState();
}

class _DuaFavoritesScreenState extends State<DuaFavoritesScreen> {
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
                final items = widget.repository
                    .search(query: _search.text, favoritesOnly: true);
                return CustomScrollView(slivers: [
                  SliverToBoxAdapter(
                      child: DuaPhotoHero(
                          title: 'مفضّلتي',
                          subtitle: 'أدعيتك المحفوظة في مكان واحد',
                          height: 243,
                          image: 'assets/duas/hero_detail.jpg',
                          onBack: () => Navigator.pop(context))),
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
                          child: TextField(
                              controller: _search,
                              onChanged: (_) => setState(() {}),
                              style: DuaPremium.type(12),
                              decoration: InputDecoration(
                                  hintText: 'ابحثي في المفضلة...',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  filled: true,
                                  fillColor: DuaPremium.paper,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(19),
                                      borderSide: BorderSide.none))))),
                  if (items.isEmpty)
                    SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                            child: Padding(
                                padding: const EdgeInsets.all(30),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.favorite_border_rounded,
                                          color: DuaPremium.gold, size: 56),
                                      const SizedBox(height: 13),
                                      Text('مافيش أدعية محفوظة مطابقة حاليًا',
                                          textAlign: TextAlign.center,
                                          style: DuaPremium.type(14,
                                              weight: FontWeight.w800)),
                                    ]))))
                  else
                    SliverList.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final d = items[i];
                          return Container(
                            margin: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                            decoration: DuaPremium.card(),
                            child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                        builder: (_) => DuaDetailsScreen(
                                            repository: widget.repository,
                                            duaId: d.id))),
                                child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(children: [
                                      ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(13),
                                          child: Image.asset(
                                              DuaPremium.imageFor(d.category),
                                              width: 65,
                                              height: 70,
                                              fit: BoxFit.cover)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(d.title,
                                                style: DuaPremium.type(12.5,
                                                    weight: FontWeight.w900)),
                                            Text(d.arabicText,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: DuaPremium.type(10,
                                                    color: DuaPremium.muted)),
                                          ])),
                                      Column(children: [
                                        IconButton(
                                            onPressed: () => widget.repository
                                                .toggleFavorite(d.id),
                                            tooltip: 'إزالة من المفضلة',
                                            icon: const Icon(
                                                Icons.bookmark_rounded,
                                                color: DuaPremium.gold)),
                                        IconButton(
                                            onPressed: () => Navigator.push(
                                                context,
                                                MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        DuaAudioScreen(
                                                            dua: d))),
                                            icon: const Icon(
                                                Icons.play_circle_rounded,
                                                color: DuaPremium.green)),
                                      ]),
                                    ]))),
                          );
                        }),
                  const SliverToBoxAdapter(child: SizedBox(height: 36)),
                ]);
              }),
        ),
      );
}
