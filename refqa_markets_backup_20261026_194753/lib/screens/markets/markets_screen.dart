import 'package:flutter/material.dart';

import '../../services/markets/rifqa_markets_catalog.dart';
import 'market_details_premium_screen.dart';
import 'markets_directory_map_screen.dart';
import 'shopping_list_screen.dart';
import 'widgets/rifqa_market_style.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});
  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  final TextEditingController _search = TextEditingController();
  List<RifqaMarket> _all = const [];
  bool _loading = true;
  String? _error;
  RifqaCity _city = RifqaCity.makkah;
  String _interest = 'الكل';
  bool _onlyFavorites = false;
  bool _onlyOfficial = false;
  static const _interests = <(String, IconData)>[
    ('الكل', Icons.grid_view_rounded),
    ('هدايا', Icons.card_giftcard_rounded),
    ('تمور', Icons.spa_outlined),
    ('عطور', Icons.local_florist_outlined),
    ('ملابس', Icons.checkroom_rounded),
    ('مولات', Icons.store_mall_directory_outlined),
    ('أسواق شعبية', Icons.storefront_rounded),
    ('جملة', Icons.local_offer_outlined),
    ('مطاعم', Icons.restaurant_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await Future.wait<dynamic>([
        RifqaMarketsCatalog.instance.load(),
        RifqaMarketSaved.instance.load(),
      ]);
      if (!mounted) return;
      setState(() { _all = result[0] as List<RifqaMarket>; _loading = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<RifqaMarket> get _visible {
    final needle = _search.text.trim().toLowerCase();
    final output = _all.where((m) {
      if (m.city != _city) return false;
      if (_onlyFavorites && !RifqaMarketSaved.instance.contains(m.id)) return false;
      if (_onlyOfficial && !m.officialSource) return false;
      if (!_matches(m, _interest)) return false;
      if (needle.isEmpty) return true;
      return '${m.name} ${m.area} ${m.description} ${m.tags.join(' ')} ${m.category}'
          .toLowerCase().contains(needle);
    }).toList();
    // Group entrances and their child zones together without inventing unique venues.
    final weight = <String, int>{};
    for (var i = 0; i < _all.length; i++) { weight[_all[i].id] = i; }
    output.sort((a, b) {
      final aa = weight[a.parentId ?? a.id] ?? 999;
      final bb = weight[b.parentId ?? b.id] ?? 999;
      return aa.compareTo(bb);
    });
    return output;
  }

  bool _matches(RifqaMarket m, String interest) {
    final tags = m.tags.join(' ');
    switch (interest) {
      case 'هدايا': return tags.contains('هدايا');
      case 'تمور': return tags.contains('تمور');
      case 'عطور': return tags.contains('عطور');
      case 'ملابس': return tags.contains('ملابس') || tags.contains('عبايات');
      case 'مولات': return const ['mall', 'shopping_complex', 'market_inside_mall', 'retail_zone'].contains(m.type);
      case 'أسواق شعبية': return m.type == 'traditional_market' || m.type == 'market_promenade';
      case 'جملة': return m.type == 'wholesale_market' || tags.contains('جملة');
      case 'مطاعم': return tags.contains('مطاعم') || m.type == 'food_market';
      default: return true;
    }
  }

  void _toggle(RifqaMarket m) async {
    await RifqaMarketSaved.instance.toggle(m.id);
    if (mounted) setState(() {});
  }

  void _details(RifqaMarket m) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
      MarketPremiumDetailsScreen(market: m, allMarkets: _all, onFavoriteToggle: () => _toggle(m))));
    if (mounted) setState(() {});
  }

  void _map() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
      MarketsDirectoryMapScreen(city: _city, markets: _all.where((m) => m.city == _city).toList(), onOpenMarket: _details)));
  void _list() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ShoppingListScreen()));

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: MarketPalette.cream,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MarketPalette.emerald))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [const Icon(Icons.error_outline, color: MarketPalette.emerald, size: 40),
                    const SizedBox(height: 10), const Text('تعذّر تحميل دليل الأسواق'),
                    const SizedBox(height: 8), Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                    TextButton(onPressed: () { setState(() => _loading = true); _load(); }, child: const Text('إعادة المحاولة'))],
                )))
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 265,
                      pinned: false,
                      stretch: true,
                      backgroundColor: MarketPalette.evergreen,
                      automaticallyImplyLeading: false,
                      flexibleSpace: FlexibleSpaceBar(
                        stretchModes: const [StretchMode.zoomBackground],
                        background: _hero(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Transform.translate(
                        offset: const Offset(0, -22),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 17, 16, 32),
                          decoration: const BoxDecoration(color: MarketPalette.cream,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _citySelector(),
                            const SizedBox(height: 15),
                            _searchField(),
                            const SizedBox(height: 20),
                            _heading('بتدوري على إيه؟', 'اختاري اللي محتاجاه من الأسواق', Icons.shopping_bag_outlined),
                            const SizedBox(height: 11),
                            _categories(),
                            const SizedBox(height: 22),
                            _quickLinks(),
                            const SizedBox(height: 23),
                            if (_search.text.trim().isEmpty && !_onlyFavorites && !_onlyOfficial && _interest == 'الكل') ...[
                              _heading('وجهات مميزة', 'مجمعات معروفة وأماكن للتسوق', Icons.auto_awesome_outlined),
                              const SizedBox(height: 11),
                              _featured(),
                              const SizedBox(height: 23),
                            ],
                            _heading(_onlyFavorites ? 'أسواقي المحفوظة' : 'الأسواق في ${_city.title}',
                              '${_visible.length} سجلًا في الدليل • بيانات أولية', Icons.store_mall_directory_outlined),
                            const SizedBox(height: 11),
                            _secondaryFilters(),
                            const SizedBox(height: 14),
                            if (_visible.isEmpty) _empty() else
                              ..._visible.map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 11),
                                child: _marketTile(m),
                              )),
                            const SizedBox(height: 5),
                            _footnote(),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
    ),
  );

  Widget _hero() {
    final image = _city == RifqaCity.makkah
        ? 'assets/markets/images/hero_makkah.jpg' : 'assets/markets/images/hero_madinah.jpg';
    return Stack(fit: StackFit.expand, children: [
      MarketPhoto(image: image, radius: 0),
      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0x34041C17), Color(0xB70A3027), Color(0xE70B3C31)],
      ))),
      SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 13, 20, 32), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton.filledTonal(
              style: IconButton.styleFrom(backgroundColor: const Color(0xB80F4B3C), foregroundColor: MarketPalette.gold),
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_forward_rounded)),
            const Spacer(),
            const Icon(Icons.shopping_bag_outlined, color: MarketPalette.gold, size: 29),
            const Spacer(),
            IconButton.filledTonal(
              tooltip: 'قائمة مشترياتي',
              style: IconButton.styleFrom(backgroundColor: const Color(0xB80F4B3C), foregroundColor: MarketPalette.gold),
              onPressed: _list, icon: const Icon(Icons.checklist_rounded)),
          ]),
          const Spacer(),
          const Text('دليل الأسواق', style: TextStyle(color: Colors.white, fontSize: 31, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          const Text('تسوّق أجمل في مكة والمدينة، وهدايا تفرّح أحبابك',
              style: TextStyle(color: Color(0xFFFAE7BF), fontSize: 12.5, height: 1.5)),
          const SizedBox(height: 8),
        ],
      ))),
    ]);
  }

  Widget _citySelector() => MarketSoftCard(
    padding: const EdgeInsets.all(5),
    child: Row(children: [
      Expanded(child: _cityChoice(RifqaCity.makkah, 'مكة المكرمة', Icons.mosque_outlined)),
      const SizedBox(width: 5),
      Expanded(child: _cityChoice(RifqaCity.madinah, 'المدينة المنورة', Icons.location_city_outlined)),
    ]),
  );

  Widget _cityChoice(RifqaCity city, String name, IconData icon) {
    final selected = _city == city;
    return Material(color: selected ? MarketPalette.evergreen : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () {
        setState(() { _city = city; _interest = 'الكل'; _onlyOfficial = false; _onlyFavorites = false; _search.clear(); });
      }, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: selected ? MarketPalette.gold : MarketPalette.emerald),
          const SizedBox(width: 5), Flexible(child: Text(name, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: selected ? Colors.white : MarketPalette.ink, fontSize: 11.3, fontWeight: FontWeight.w800))),
        ]),
      )),
    );
  }

  Widget _searchField() => MarketSoftCard(
    padding: EdgeInsets.zero,
    child: TextField(
      controller: _search, onChanged: (_) => setState(() {}), textAlign: TextAlign.start,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'ابحثي عن برج الساعة، الصفوة، سوق أو هدية...',
        hintStyle: const TextStyle(color: MarketPalette.muted, fontSize: 11.5),
        prefixIcon: const Icon(Icons.search_rounded, color: MarketPalette.emerald),
        suffixIcon: _search.text.isNotEmpty ? IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded)) : null,
        border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
  );

  Widget _heading(String title, String caption, IconData icon) => Row(children: [
    Icon(icon, color: MarketPalette.gold, size: 23), const SizedBox(width: 8),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: MarketPalette.ink, fontSize: 19, fontWeight: FontWeight.w900)),
      Text(caption, style: const TextStyle(color: MarketPalette.muted, fontSize: 11.5)),
    ])),
  ]);

  Widget _categories() => SizedBox(height: 78, child: ListView.separated(
    scrollDirection: Axis.horizontal, itemCount: _interests.length,
    separatorBuilder: (_, __) => const SizedBox(width: 8),
    itemBuilder: (_, index) {
      final entry = _interests[index];
      final selected = _interest == entry.$1;
      return InkWell(onTap: () => setState(() => _interest = entry.$1),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          width: 73, padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? MarketPalette.evergreen : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? MarketPalette.gold : MarketPalette.line),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(entry.$2, color: selected ? MarketPalette.gold : MarketPalette.emerald, size: 23),
            const SizedBox(height: 6), Text(entry.$1, textAlign: TextAlign.center, maxLines: 1,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: selected ? Colors.white : MarketPalette.ink)),
          ]),
        ),
      );
    },
  ));

  Widget _quickLinks() => Row(children: [
    Expanded(child: _actionLink('خريطة الأسواق', 'بحث ومواقع', Icons.map_outlined, _map)),
    const SizedBox(width: 10),
    Expanded(child: _actionLink('قائمة مشترياتي', 'هداياك في مكان', Icons.checklist_rounded, _list)),
  ]);

  Widget _actionLink(String title, String caption, IconData icon, VoidCallback action) =>
      InkWell(onTap: action, borderRadius: BorderRadius.circular(20), child: MarketSoftCard(
        padding: const EdgeInsets.all(13),
        child: Row(children: [
          Container(width: 43, height: 43,
            decoration: BoxDecoration(color: MarketPalette.pale, borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: MarketPalette.emerald)),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: MarketPalette.ink, fontWeight: FontWeight.w900)),
            Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: MarketPalette.muted)),
          ])),
        ]),
      ));

  Widget _featured() {
    final parent = _all.where((m) => m.city == _city && !m.isSubMarket).toList();
    parent.sort((a, b) {
      if (a.officialSource == b.officialSource) return a.name.compareTo(b.name);
      return a.officialSource ? -1 : 1;
    });
    final list = parent.take(7).toList();
    return SizedBox(height: 204, child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: list.length, separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, i) {
        final m = list[i];
        return InkWell(onTap: () => _details(m), borderRadius: BorderRadius.circular(20),
          child: SizedBox(width: 161, child: MarketSoftCard(padding: const EdgeInsets.all(7), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 115, child: Stack(children: [
                MarketPhoto(image: m.assetImage, radius: 13),
                Positioned(top: 4, left: 4, child: MarketFavoritesButton(
                  selected: RifqaMarketSaved.instance.contains(m.id), onTap: () => _toggle(m))),
              ])),
              const SizedBox(height: 10),
              Text(m.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900, color: MarketPalette.ink, fontSize: 12)),
              const Spacer(),
              Text(m.area, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: MarketPalette.muted)),
              const SizedBox(height: 3),
            ],
          ))),
        );
      },
    ));
  }

  Widget _secondaryFilters() => SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
    MarketPill(label: 'جميع النتائج', icon: Icons.list_rounded,
      filled: !_onlyFavorites && !_onlyOfficial,
      onTap: () => setState(() { _onlyFavorites = false; _onlyOfficial = false; })),
    const SizedBox(width: 7),
    MarketPill(label: 'المفضلة', icon: Icons.favorite_border_rounded, filled: _onlyFavorites,
      onTap: () => setState(() { _onlyFavorites = !_onlyFavorites; _onlyOfficial = false; })),
    const SizedBox(width: 7),
    MarketPill(label: 'مصادر رسمية', icon: Icons.fact_check_outlined, filled: _onlyOfficial,
      onTap: () => setState(() { _onlyOfficial = !_onlyOfficial; _onlyFavorites = false; })),
  ]));

  Widget _marketTile(RifqaMarket m) => InkWell(onTap: () => _details(m),
    borderRadius: BorderRadius.circular(20), child: MarketSoftCard(
      padding: const EdgeInsets.all(10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 106, height: 107, child: Stack(children: [
          MarketPhoto(image: m.assetImage, radius: 14),
          Positioned(top: 3, left: 3, child: MarketFavoritesButton(
            selected: RifqaMarketSaved.instance.contains(m.id), onTap: () => _toggle(m))),
        ])),
        const SizedBox(width: 12),
        Expanded(child: SizedBox(height: 107, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.name, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: MarketPalette.ink)),
          const SizedBox(height: 3),
          Text(m.area, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: MarketPalette.emerald, fontSize: 10.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(m.description, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: MarketPalette.muted, fontSize: 10.5, height: 1.45)),
          const Spacer(),
          Row(children: [
            Flexible(child: Text(m.isSubMarket ? 'داخل مجمع آخر' : m.category,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: MarketPalette.ink, fontWeight: FontWeight.w700))),
            const Spacer(),
            const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: MarketPalette.emerald),
          ]),
        ]))),
      ]),
    ));

  Widget _empty() => MarketSoftCard(child: Column(children: [
    const Icon(Icons.travel_explore_rounded, color: MarketPalette.emerald, size: 44),
    const SizedBox(height: 7), const Text('مفيش أسواق مطابقة للاختيارات دي'),
    const SizedBox(height: 8),
    TextButton(onPressed: () => setState(() {
      _interest = 'الكل'; _search.clear(); _onlyFavorites = false; _onlyOfficial = false;
    }), child: const Text('عرض الكل')),
  ]));

  Widget _footnote() => const Padding(padding: EdgeInsets.all(10), child: Text(
    'دليل تأسيسي • الصور تصميمية توضيحية وليست صورًا مؤكدة للمحلات. '
    'المواعيد والأسعار والإحداثيات غير المؤكدة لا نعرضها كحقائق. '
    'تحققي من التفاصيل قبل التحرك.',
    textAlign: TextAlign.center,
    style: TextStyle(color: MarketPalette.muted, fontSize: 11, height: 1.7),
  ));
}
