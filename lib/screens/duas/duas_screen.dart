import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/dua_model.dart';
import '../../services/duas/duas_repository.dart';
import 'dua_premium_theme.dart';
import 'dua_details_screen.dart';
import 'dua_category_screen.dart';
import 'dua_audio_screen.dart';
import 'dua_favorites_screen.dart';
import 'my_duas_screen.dart';
import 'add_dua_screen.dart';
import 'amanat_screen.dart';

/// Premium, RTL, repository-backed dua library. Safe with the existing AppShell.
class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key, required this.repository});
  final DuasRepository repository;
  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen> {
  final TextEditingController _query = TextEditingController();
  DuaCategory? _selected;
  bool _favorites = false;
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  void _details(Dua d) =>
      _open(DuaDetailsScreen(repository: widget.repository, duaId: d.id));
  void _category(DuaCategory c) =>
      _open(DuaCategoryScreen(repository: widget.repository, category: c));

  List<Dua> _matched(DuasRepository repo) => repo.search(
      query: _query.text, category: _selected, favoritesOnly: _favorites);

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: DuaPremium.cream,
          floatingActionButton: FloatingActionButton.small(
              heroTag: 'dua-add',
              backgroundColor: DuaPremium.deep,
              tooltip: 'أضيفي دعاءك الخاص',
              onPressed: () =>
                  _open(AddDuaScreen(repository: widget.repository)),
              child: const Icon(Icons.add_rounded, color: DuaPremium.gold)),
          body: ListenableBuilder(
              listenable: widget.repository,
              builder: (context, _) {
                final repo = widget.repository;
                if (!repo.isReady)
                  return const Center(
                      child:
                          CircularProgressIndicator(color: DuaPremium.green));
                final filtering = _query.text.trim().isNotEmpty ||
                    _selected != null ||
                    _favorites;
                final items =
                    filtering ? _matched(repo) : repo.search(query: '');
                final featured = items.take(2).toList();
                return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                          child: Stack(children: [
                        const DuaPhotoHero(
                            title: 'الأدعية',
                            subtitle: 'أدعية مأثورة ترافق قلبك في رحلتك',
                            height: 279),
                        Positioned(
                            top: MediaQuery.paddingOf(context).top + 8,
                            right: 16,
                            child: DuaCircleAction(
                                icon: Icons.menu_book_outlined,
                                onTap: () =>
                                    _open(MyDuasScreen(repository: repo)))),
                        Positioned(
                            top: MediaQuery.paddingOf(context).top + 8,
                            left: 16,
                            child: DuaCircleAction(
                                icon: Icons.favorite_border_rounded,
                                onTap: () => _open(
                                    DuaFavoritesScreen(repository: repo)))),
                      ])),
                      SliverToBoxAdapter(
                          child: Transform.translate(
                              offset: const Offset(0, -16),
                              child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 17, 14, 18),
                                  decoration: DuaPremium.card(radius: 27),
                                  child: Column(children: [
                                    Container(
                                      height: 46,
                                      decoration: BoxDecoration(
                                          color: DuaPremium.cream,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          border: Border.all(
                                              color: DuaPremium.line)),
                                      child: TextField(
                                          controller: _query,
                                          textInputAction:
                                              TextInputAction.search,
                                          onChanged: (_) => setState(() {}),
                                          style: DuaPremium.type(12.5),
                                          decoration: InputDecoration(
                                              hintText:
                                                  'ابحثي عن دعاء، مرحلة، أو كلمة...',
                                              hintStyle: DuaPremium.type(11,
                                                  color: DuaPremium.muted),
                                              prefixIcon: const Icon(
                                                  Icons.search_rounded,
                                                  size: 21,
                                                  color: DuaPremium.green),
                                              suffixIcon: _query.text.isEmpty
                                                  ? null
                                                  : IconButton(
                                                      onPressed: () => setState(
                                                          _query.clear),
                                                      icon: const Icon(
                                                          Icons.close_rounded,
                                                          size: 18)),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10))),
                                    ),
                                    const SizedBox(height: 13),
                                    SizedBox(
                                        height: 41,
                                        child: ListView(
                                            scrollDirection: Axis.horizontal,
                                            children: [
                                              DuaPill(
                                                  label: 'الكل',
                                                  selected: _selected == null &&
                                                      !_favorites,
                                                  onTap: () => setState(() {
                                                        _selected = null;
                                                        _favorites = false;
                                                      })),
                                              const SizedBox(width: 7),
                                              DuaPill(
                                                  label: 'المفضلة',
                                                  icon: Icons.favorite_rounded,
                                                  selected: _favorites,
                                                  onTap: () => setState(() {
                                                        _favorites = true;
                                                        _selected = null;
                                                      })),
                                              for (final category
                                                  in DuaCategory.values) ...[
                                                const SizedBox(width: 7),
                                                DuaPill(
                                                    label: category.label,
                                                    selected:
                                                        _selected == category,
                                                    onTap: () => setState(() {
                                                          _selected = category;
                                                          _favorites = false;
                                                        })),
                                              ],
                                            ])),
                                  ])))),
                      if (!filtering) ...[
                        SliverToBoxAdapter(
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(17, 1, 17, 10),
                                child: DuaSectionHeading(
                                    title: 'أدعية مختارة',
                                    subtitle: 'دعاء يرافقك في رحلتك',
                                    action: 'عرض الكل',
                                    onTap: () =>
                                        _category(DuaCategory.general)))),
                        SliverToBoxAdapter(
                            child: SizedBox(
                                height: 232,
                                child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15),
                                    itemCount: featured.length,
                                    itemBuilder: (context, i) =>
                                        _FeaturedDuaCard(
                                            dua: featured[i],
                                            favorite:
                                                repo.isFavorite(featured[i].id),
                                            onTap: () => _details(featured[i]),
                                            onFavorite: () => repo
                                                .toggleFavorite(featured[i].id),
                                            onAudio: () => _open(DuaAudioScreen(
                                                dua: featured[i])))))),
                        SliverToBoxAdapter(
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(17, 23, 17, 10),
                                child: const DuaSectionHeading(
                                    title: 'مجموعات الأدعية',
                                    subtitle: 'اختاري ما يناسب المرحلة'))),
                        SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 1.36,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12),
                                itemCount: DuaCategory.values.length,
                                itemBuilder: (context, i) {
                                  final c = DuaCategory.values[i];
                                  return _GroupTile(
                                      category: c,
                                      count: repo.countIn(c),
                                      onTap: () => _category(c));
                                })),
                        SliverToBoxAdapter(
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(17, 21, 17, 9),
                                child: const DuaSectionHeading(
                                    title: 'رفقة معك',
                                    subtitle:
                                        'أدعية شخصية وأمانات في الرحلة'))),
                        SliverToBoxAdapter(
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(children: [
                                  Expanded(
                                      child: _LinkTile(
                                          icon: Icons.auto_stories_rounded,
                                          label: 'أدعيتي',
                                          subtitle: 'اكتبي واحتفظي بدعائك',
                                          onTap: () => _open(
                                              MyDuasScreen(repository: repo)))),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: _LinkTile(
                                          icon:
                                              Icons.volunteer_activism_outlined,
                                          label: 'أمانة الدعاء',
                                          subtitle:
                                              '${repo.pendingAmanatCount} أمانة بانتظارك',
                                          onTap: () => _open(
                                              AmanatScreen(repository: repo)))),
                                ]))),
                      ] else ...[
                        SliverToBoxAdapter(
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(17, 6, 17, 12),
                                child: DuaSectionHeading(
                                    title: 'نتائج الأدعية',
                                    subtitle: '${items.length} دعاء'))),
                        if (items.isEmpty)
                          const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                  child: Text(
                                      'مفيش نتائج مطابقة؛ جرّبي بحث تاني.')))
                        else
                          SliverList.builder(
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final d = items[i];
                                return _DuaResultCard(
                                    dua: d,
                                    favorite: repo.isFavorite(d.id),
                                    onTap: () => _details(d),
                                    onFavorite: () =>
                                        repo.toggleFavorite(d.id));
                              }),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 115)),
                    ]);
              }),
        ),
      );
}

class _FeaturedDuaCard extends StatelessWidget {
  const _FeaturedDuaCard(
      {required this.dua,
      required this.favorite,
      required this.onTap,
      required this.onFavorite,
      required this.onAudio});
  final Dua dua;
  final bool favorite;
  final VoidCallback onTap, onFavorite, onAudio;
  @override
  Widget build(BuildContext context) => Container(
        width: 230,
        margin: const EdgeInsetsDirectional.only(end: 11),
        decoration: DuaPremium.card(radius: 23),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
              child: Stack(fit: StackFit.expand, children: [
            ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                child: Image.asset(DuaPremium.imageFor(dua.category),
                    fit: BoxFit.cover)),
            Positioned(
                top: 6,
                left: 6,
                child: IconButton(
                    onPressed: onFavorite,
                    icon: Icon(
                        favorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: favorite ? DuaPremium.gold : Colors.white),
                    style: IconButton.styleFrom(
                        backgroundColor: const Color(0x7701231C)))),
          ])),
          InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 11, 10),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(dua.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  DuaPremium.type(12, weight: FontWeight.w900)),
                          Text(dua.sourceType.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DuaPremium.type(9.5,
                                  color: DuaPremium.muted)),
                        ])),
                    const SizedBox(width: 5),
                    Material(
                        color: DuaPremium.deep,
                        shape: const CircleBorder(),
                        child: InkWell(
                            onTap: onAudio,
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                                width: 34,
                                height: 34,
                                child: Icon(Icons.play_arrow_rounded,
                                    color: DuaPremium.gold, size: 21)))),
                  ]))),
        ]),
      );
}

class _GroupTile extends StatelessWidget {
  const _GroupTile(
      {required this.category, required this.count, required this.onTap});
  final DuaCategory category;
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: DuaPremium.paper,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(19),
            child: Container(
                decoration: DuaPremium.card(radius: 19),
                child: Row(children: [
                  Expanded(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(category.label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: DuaPremium.type(12.5,
                                        weight: FontWeight.w900)),
                                Text('$count دعاء',
                                    style: DuaPremium.type(10,
                                        color: DuaPremium.muted)),
                              ]))),
                  SizedBox(
                      width: 66,
                      height: double.infinity,
                      child: ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(18)),
                          child: Image.asset(DuaPremium.imageFor(category),
                              fit: BoxFit.cover))),
                ]))),
      );
}

class _LinkTile extends StatelessWidget {
  const _LinkTile(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: DuaPremium.paper,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
                padding: const EdgeInsets.all(14),
                decoration: DuaPremium.card(radius: 20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 28, color: DuaPremium.green),
                      const SizedBox(height: 5),
                      Text(label,
                          style: DuaPremium.type(13, weight: FontWeight.w900)),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DuaPremium.type(9.5, color: DuaPremium.muted)),
                    ]))),
      );
}

class _DuaResultCard extends StatelessWidget {
  const _DuaResultCard(
      {required this.dua,
      required this.favorite,
      required this.onTap,
      required this.onFavorite});
  final Dua dua;
  final bool favorite;
  final VoidCallback onTap, onFavorite;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: DuaPremium.card(radius: 21),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(21),
            child: Padding(
                padding: const EdgeInsets.all(11),
                child: Row(children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.asset(DuaPremium.imageFor(dua.category),
                          width: 69, height: 76, fit: BoxFit.cover)),
                  const SizedBox(width: 11),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(dua.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                DuaPremium.type(13, weight: FontWeight.w900)),
                        Text(dua.arabicText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                DuaPremium.type(11.5, color: DuaPremium.muted)),
                        Text(dua.sourceType.label,
                            style:
                                DuaPremium.type(9.5, color: DuaPremium.green)),
                      ])),
                  IconButton(
                      onPressed: onFavorite,
                      icon: Icon(
                          favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color:
                              favorite ? DuaPremium.green : DuaPremium.muted)),
                ]))),
      );
}
