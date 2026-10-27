import 'package:flutter/material.dart';

import '../../services/markets/market_community_service.dart';
import 'market_contribute_screen.dart';
import 'widgets/rifqa_market_style.dart';

/// User-supplied listings for Makkah and Madinah; not a social post/chat feed.
class MarketCommunityScreen extends StatefulWidget {
  const MarketCommunityScreen({super.key, this.initialCity = 'makkah'});
  final String initialCity;

  @override
  State<MarketCommunityScreen> createState() => _MarketCommunityScreenState();
}

class _MarketCommunityScreenState extends State<MarketCommunityScreen> {
  final _search = TextEditingController();
  late String _city = widget.initialCity;
  String _category = 'الكل';
  bool _towerOnly = false;

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  String _normalize(String s) => s.toLowerCase()
    .replaceAll(RegExp(r'[\u064b-\u065f]'), '')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ة', 'ه').replaceAll('ى', 'ي').trim();

  Future<void> _add() async {
    final added = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => MarketContributeScreen(
        initialCity: _city,
        initialTower: _towerOnly && _city == 'makkah')));
    if (added == true && mounted) _show('تم نشر إضافتك في الدليل مباشرةً.');
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _vote(RefqaMarketContribution item, bool wrong) async {
    if (wrong) {
      final okay = await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('الإبلاغ عن معلومة خاطئة'),
          content: const Text('لو 3 مستخدمين بحسابات مختلفة أبلغوا عن هذه الإضافة، '
              'هتختفي تلقائيًا من الدليل. البلاغ مرة واحدة لكل شخص.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true),
                child: const Text('إرسال بلاغ')),
          ],
        ));
      if (okay != true) return;
    }
    try {
      final value = wrong
          ? await RefqaMarketsCommunityService.instance.reportWrong(item)
          : await RefqaMarketsCommunityService.instance.markHelpful(item);
      if (!mounted) return;
      _show(wrong
          ? (value >= 3 ? 'وصلت 3 بلاغات مختلفة، وتم إخفاء المكان.'
              : 'تم تسجيل بلاغك ($value/3).')
          : 'شكرًا! تم تسجيل أن المعلومة مفيدة.');
    } catch (e) {
      if (mounted) _show(refqaMarketErrorMessage(e));
    }
  }

  Widget _itemCard(RefqaMarketContribution item) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: MarketSoftCard(padding: const EdgeInsets.all(13), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 47, height: 47,
            decoration: BoxDecoration(color: MarketPalette.pale,
                borderRadius: BorderRadius.circular(13)),
            child: Icon(item.placeType == 'market'
                ? Icons.store_mall_directory_outlined
                : Icons.storefront_outlined, color: MarketPalette.emerald)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15,
                    color: MarketPalette.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(item.category, style: const TextStyle(fontSize: 11,
                color: MarketPalette.muted)),
          ])),
          const Icon(Icons.people_alt_outlined, size: 19,
              color: MarketPalette.emerald),
        ]),
        const SizedBox(height: 9),
        Wrap(spacing: 7, runSpacing: 7, children: [
          MarketPill(label: item.cityLabel, icon: Icons.place_outlined),
          MarketPill(label: item.typeLabel),
          if (item.clockTower) MarketPill(label: item.floorLabel,
              icon: Icons.layers_outlined),
          if (item.marketName.isNotEmpty) MarketPill(label: item.marketName),
        ]),
        const SizedBox(height: 10),
        Text(item.area, style: const TextStyle(fontSize: 12,
            color: MarketPalette.ink)),
        if (item.note.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(item.note, maxLines: 3, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, height: 1.5,
                  color: MarketPalette.muted)),
        ],
        const SizedBox(height: 11),
        const Text('معلومة من مستخدم • لم يتم التحقق منها ميدانيًا',
            style: TextStyle(fontSize: 10.5, color: MarketPalette.muted)),
        const Divider(height: 22, color: MarketPalette.line),
        Wrap(alignment: WrapAlignment.spaceBetween, spacing: 6,
          runSpacing: 4, children: [
            TextButton.icon(
              onPressed: () => _vote(item, false),
              icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
              label: Text('مفيدة (${item.helpfulCount})'),
              style: TextButton.styleFrom(foregroundColor: MarketPalette.emerald)),
            TextButton.icon(
              onPressed: () => _vote(item, true),
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: Text('معلومة خاطئة (${item.reportCount}/3)'),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFA05035)),
            ),
          ]),
      ],
    )),
  );

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: MarketPalette.cream,
      appBar: AppBar(backgroundColor: MarketPalette.evergreen,
          foregroundColor: Colors.white, title: const Text('عرّف غيرك')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_market_community',
        onPressed: _add,
        backgroundColor: MarketPalette.emerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('أضف مكان'),
      ),
      body: StreamBuilder<List<RefqaMarketContribution>>(
        stream: RefqaMarketsCommunityService.instance.visiblePlaces(),
        builder: (context, snapshot) {
          final q = _normalize(_search.text);
          final records = (snapshot.data ?? const <RefqaMarketContribution>[])
              .where((item) => item.city == _city
                  && (!_towerOnly || item.clockTower)
                  && (_category == 'الكل' || item.category == _category)
                  && (q.isEmpty || _normalize([
                    item.name, item.category, item.marketName, item.area,
                    item.note, item.floorLabel,
                  ].join(' ')).contains(q)))
              .toList();
          return CustomScrollView(slivers: [
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 16, 15, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MarketSoftCard(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Row(children: [Icon(Icons.volunteer_activism_outlined,
                          color: MarketPalette.emerald), SizedBox(width: 8),
                        Expanded(child: Text('ساعد غيرك يعرف المكان الصحيح',
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: MarketPalette.ink)))]),
                      SizedBox(height: 7),
                      Text('أي شخص يضيف سوق أو محل ويظهر فورًا. '
                          'في حالة 3 بلاغات مختلفة عن معلومة خاطئة، '
                          'الإضافة تختفي تلقائيًا. نعرض مساهمات الناس '
                          'بوضوح بعيدًا عن المعلومات الرسمية.',
                          style: TextStyle(fontSize: 11.5,
                              height: 1.7, color: MarketPalette.muted)),
                    ])),
                  const SizedBox(height: 15),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'makkah', label: Text('مكة')),
                      ButtonSegment(value: 'madinah', label: Text('المدينة')),
                    ],
                    selected: {_city},
                    onSelectionChanged: (x) => setState(() {
                      _city = x.first;
                      if (_city == 'madinah') _towerOnly = false;
                    }),
                  ),
                  const SizedBox(height: 13),
                  TextField(controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن سوق أو محل أو تجميل أو الدور...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: MarketPalette.line)),
                    )),
                  if (_city == 'makkah') SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('محلات برج الساعة فقط',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    value: _towerOnly,
                    onChanged: (v) => setState(() => _towerOnly = v),
                  ),
                  SizedBox(height: 43,
                    child: ListView(scrollDirection: Axis.horizontal,
                      children: [for (final category in [
                        'الكل', ...RefqaMarketsCommunityService.categories,
                      ]) Padding(padding: const EdgeInsets.only(left: 7),
                        child: MarketPill(label: category,
                          filled: _category == category,
                          onTap: () => setState(() => _category = category))),
                      ])),
                  const SizedBox(height: 13),
                  Text('${records.length} إضافة ظاهرة من المستخدمين',
                    style: const TextStyle(color: MarketPalette.muted,
                        fontSize: 12)),
                  if (snapshot.hasError) const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text('تعذّر تحميل إضافات المستخدمين. '
                        'راجعي اتصال الإنترنت وقواعد Firestore.',
                        style: TextStyle(color: Color(0xFFA05035)))),
                ]),
            )),
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData)
              const SliverFillRemaining(hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()))
            else if (records.isEmpty)
              const SliverFillRemaining(hasScrollBody: false,
                child: Center(child: Padding(padding: EdgeInsets.all(25),
                  child: Text('لسه مفيش إضافات مطابقة. اضغطي «أضف مكان» '
                      'وساعدي غيرك.', textAlign: TextAlign.center))))
            else SliverPadding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 110),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (context, index) => _itemCard(records[index]),
                childCount: records.length)),
            ),
          ]);
        },
      ),
    ),
  );
}
