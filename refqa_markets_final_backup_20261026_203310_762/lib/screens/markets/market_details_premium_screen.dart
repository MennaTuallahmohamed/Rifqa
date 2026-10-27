import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/markets/rifqa_markets_catalog.dart';
import 'widgets/rifqa_market_style.dart';

class MarketPremiumDetailsScreen extends StatefulWidget {
  const MarketPremiumDetailsScreen({
    super.key,
    required this.market,
    required this.allMarkets,
    required this.onFavoriteToggle,
  });
  final RifqaMarket market;
  final List<RifqaMarket> allMarkets;
  final VoidCallback onFavoriteToggle;

  @override
  State<MarketPremiumDetailsScreen> createState() => _MarketPremiumDetailsScreenState();
}

class _MarketPremiumDetailsScreenState extends State<MarketPremiumDetailsScreen> {
  int _tab = 0;
  late bool _favorite;
  RifqaMarket get market => widget.market;
  @override
  void initState() {
    super.initState();
    _favorite = RifqaMarketSaved.instance.contains(market.id);
  }

  void _save() {
    setState(() => _favorite = !_favorite);
    widget.onFavoriteToggle();
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _source() async {
    try { if (!await RifqaMarketsLinks.source(market)) _notice('تعذّر فتح المصدر حاليًا'); }
    catch (_) { _notice('تعذّر فتح المصدر حاليًا'); }
  }

  Future<void> _map() async {
    try {
      final ok = await RifqaMarketsLinks.mapSearch(market);
      if (!ok) _notice('تعذّر فتح تطبيق الخرائط');
    } catch (_) { _notice('تعذّر فتح تطبيق الخرائط'); }
  }

  void _share() {
    Share.share('${market.name}\n${market.area} — ${market.city.title}\n${market.description}\n${market.sourceUrl}\nمن دليل الأسواق في رِفقة');
  }

  void _openSub(RifqaMarket m) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
      MarketPremiumDetailsScreen(market: m, allMarkets: widget.allMarkets,
          onFavoriteToggle: () { RifqaMarketSaved.instance.toggle(m.id); })));

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    backgroundColor: MarketPalette.cream,
    body: CustomScrollView(slivers: [
      SliverAppBar(
        pinned: true,
        stretch: true,
        expandedHeight: 305,
        backgroundColor: MarketPalette.evergreen,
        foregroundColor: Colors.white,
        leading: Padding(padding: const EdgeInsets.all(8), child: IconButton.filledTonal(
            style: IconButton.styleFrom(backgroundColor: const Color(0xBB083C30), foregroundColor: Colors.white),
            onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_forward_rounded))),
        actions: [
          IconButton.filledTonal(
            style: IconButton.styleFrom(backgroundColor: const Color(0xBB083C30), foregroundColor: Colors.white),
            onPressed: _share, icon: const Icon(Icons.share_outlined)),
          IconButton.filledTonal(
            style: IconButton.styleFrom(backgroundColor: const Color(0xBB083C30), foregroundColor: MarketPalette.gold),
            onPressed: _save, icon: Icon(_favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded)),
          const SizedBox(width: 9),
        ],
        flexibleSpace: FlexibleSpaceBar(background: Stack(fit: StackFit.expand, children: [
          MarketPhoto(image: market.assetImage, radius: 0),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0x45000000), Color(0x06000000), Color(0xD9063025)],
          ))),
          Positioned(right: 17, left: 17, bottom: 40, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(market.city.title, style: const TextStyle(fontSize: 12, color: Color(0xFFFCE1A6), fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              Text(market.name, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Row(children: [const Icon(Icons.location_on_outlined, size: 16, color: MarketPalette.gold),
                const SizedBox(width: 4), Expanded(child: Text(market.area, maxLines: 1,
                  overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFFFEDD1), fontSize: 12)))],
              ),
            ],
          )),
        ])),
      ),
      SliverToBoxAdapter(child: Container(
        decoration: const BoxDecoration(color: MarketPalette.cream, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: _smallAction('الموقع', Icons.map_outlined, _map)),
            const SizedBox(width: 8),
            Expanded(child: _smallAction('حفظ', _favorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, _save)),
            const SizedBox(width: 8),
            Expanded(child: _smallAction('مشاركة', Icons.ios_share_rounded, _share)),
          ]),
          const SizedBox(height: 15),
          _tabs(),
          const SizedBox(height: 18),
          IndexedStack(index: _tab, children: [
            _about(), _shopping(), _where(), _info(),
          ]),
          const SizedBox(height: 15),
          MarketSoftCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.image_outlined, size: 22, color: MarketPalette.gold),
            const SizedBox(width: 8),
            const Expanded(child: Text(
              'الصورة تصميمية للتوضيح وليست صورة معتمدة للمكان نفسه. '
              'لم نضف تقييمات أو مواعيد عمل أو مسافات غير موثّقة.',
              style: TextStyle(color: MarketPalette.muted, fontSize: 11.5, height: 1.7),
            )),
          ])),
        ]),
      )),
    ]),
  ));

  Widget _smallAction(String text, IconData icon, VoidCallback onTap) =>
      InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15),
        child: MarketSoftCard(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
          child: Column(children: [Icon(icon, size: 22, color: MarketPalette.emerald),
            const SizedBox(height: 5), Text(text, style: const TextStyle(color: MarketPalette.ink, fontSize: 11, fontWeight: FontWeight.w800))])));

  Widget _tabs() {
    const labels = ['نبذة', 'ماذا أشتري؟', 'الموقع', 'المعلومات'];
    return Container(padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: const Color(0xFFEEE9DD), borderRadius: BorderRadius.circular(16)),
      child: Row(children: List.generate(labels.length, (i) {
        final selected = _tab == i;
        return Expanded(child: InkWell(onTap: () => setState(() => _tab = i),
          borderRadius: BorderRadius.circular(12), child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 3),
            decoration: BoxDecoration(color: selected ? MarketPalette.evergreen : Colors.transparent,
              borderRadius: BorderRadius.circular(12)),
            child: Text(labels[i], textAlign: TextAlign.center,
              style: TextStyle(color: selected ? Colors.white : MarketPalette.ink, fontSize: 10.5, fontWeight: FontWeight.w800)),
          )));
      })),
    );
  }

  Widget _section(String title, IconData icon, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: MarketSoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: MarketPalette.emerald, size: 21), const SizedBox(width: 8),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: MarketPalette.ink)))]),
      const SizedBox(height: 12), child,
    ])),
  );

  Widget _about() {
    final children = RifqaMarketsCatalog.instance.childrenOf(widget.allMarkets, market);
    final parent = RifqaMarketsCatalog.instance.parentOf(widget.allMarkets, market);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _section('عن السوق', Icons.storefront_outlined, Text(market.description,
        style: const TextStyle(fontSize: 13.5, height: 1.85, color: MarketPalette.ink))),
      if (parent != null) _section('داخل المجمع', Icons.apartment_rounded,
        ListTile(contentPadding: EdgeInsets.zero, title: Text(parent.name), subtitle: const Text('المجمع الرئيسي'),
          trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 15), onTap: () => _openSub(parent))),
      if (children.isNotEmpty) _section('أسواق داخل هذا المجمع', Icons.store_mall_directory_outlined,
        Column(children: children.map((m) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: const Icon(Icons.shopping_bag_outlined, color: MarketPalette.emerald),
          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          subtitle: Text(m.area, style: const TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
          onTap: () => _openSub(m),
        )).toList())),
      _section('معلومات الدليل', Icons.fact_check_outlined, Column(children: [
        _infoRow('التصنيف', market.category),
        _infoRow('المدينة', market.cityName),
        _infoRow('المنطقة', market.area),
      ])),
    ]);
  }

  Widget _shopping() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _section('أصناف يمكنكِ البحث عنها', Icons.shopping_bag_outlined,
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (market.tags.isEmpty)
          const Text('لا توجد أصناف موثّقة أو مقترحة لهذا السوق حتى الآن.')
        else Wrap(spacing: 7, runSpacing: 8, children: market.tags.map((t) => MarketPill(label: t, icon: Icons.check_circle_outline_rounded)).toList()),
        const SizedBox(height: 13),
        const Text('دي تصنيفات بحث مقترحة، مش ضمان إن كل المنتجات أو المتاجر متاحة حاليًا.',
          style: TextStyle(color: MarketPalette.muted, fontSize: 11, height: 1.7)),
      ])),
    _section('دليل المحلات', Icons.view_list_rounded,
      const Text('أسماء المحلات وأرقام الأدوار لسه محتاجة مصادر معتمدة من إدارة المجمع. '
        'هنضيفها عند التحقق بدل ما نعرض أسماء وأماكن مش مؤكدة.',
        style: TextStyle(color: MarketPalette.muted, fontSize: 12.5, height: 1.8))),
  ]);

  Widget _where() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _section('أين يوجد السوق؟', Icons.place_outlined,
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${market.area}\n${market.city.title}، المملكة العربية السعودية',
          style: const TextStyle(color: MarketPalette.ink, fontSize: 14, height: 1.8)),
        const SizedBox(height: 11),
        Text(market.hasCoordinates
          ? 'إحداثيات هذا السوق متاحة في قاعدة البيانات.'
          : 'لا توجد إحداثيات موثوقة محفوظة لهذا السوق. الزر التالي يفتح بحثًا باسمه في خرائط Google وليس دبوسًا مؤكدًا.',
          style: const TextStyle(color: MarketPalette.muted, fontSize: 11.5, height: 1.65)),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: _map,
          icon: const Icon(Icons.map_outlined), label: const Text('البحث عن السوق في الخرائط'),
          style: FilledButton.styleFrom(backgroundColor: MarketPalette.evergreen,
            foregroundColor: Colors.white, minimumSize: const Size.fromHeight(49))),
      ])),
  ]);

  Widget _info() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _section('المصدر والمراجعة', Icons.verified_user_outlined, Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(market.officialSource
        ? 'اسم السوق ومعلوماته الأساسية مذكورة في مصدر تابع للمشغّل أو جهة رسمية.'
        : 'السوق مذكور في دليل مستقل؛ تفاصيله تحتاج مراجعة إضافية قبل الاعتماد النهائي.',
        style: const TextStyle(fontSize: 12.5, height: 1.8, color: MarketPalette.ink)),
      const SizedBox(height: 9),
      _infoRow('آخر مراجعة للبحث', '16 أكتوبر 2026'),
      _infoRow('ساعات العمل', market.openingHours?.trim().isNotEmpty == true ? market.openingHours! : 'غير معتمدة'),
      _infoRow('التقييمات والأسعار', 'غير متاحة ببيانات موثقة'),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: _source, icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('افتحي المصدر الأصلي'),
        style: OutlinedButton.styleFrom(foregroundColor: MarketPalette.emerald)),
    ])),
    _section('نصيحة قبل الزيارة', Icons.lightbulb_outline_rounded,
      const Text('اتأكدي من مواعيد المحلات وساعات تشغيل السوق ومن المدخل الصحيح، '
          'خصوصًا في مواسم الحج والعمرة أو وقت الصلوات.',
        style: TextStyle(fontSize: 12.5, height: 1.8, color: MarketPalette.ink))),
  ]);

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 9), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(color: MarketPalette.muted, fontSize: 11.5))),
      Expanded(child: Text(value, textAlign: TextAlign.start,
        style: const TextStyle(color: MarketPalette.ink, fontWeight: FontWeight.w800, fontSize: 11.5))),
    ]),
  );
}
