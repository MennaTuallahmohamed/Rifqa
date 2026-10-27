import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/markets/clock_tower_directory_service.dart';
import '../../services/markets/market_community_service.dart';
import 'market_contribute_screen.dart';
import 'market_clock_artwork.dart';
import 'widgets/rifqa_market_style.dart';

class ClockTowerDirectoryScreen extends StatefulWidget {
  const ClockTowerDirectoryScreen({super.key});

  @override
  State<ClockTowerDirectoryScreen> createState() =>
      _ClockTowerDirectoryScreenState();
}

class _ClockTowerDirectoryScreenState extends State<ClockTowerDirectoryScreen> {
  final TextEditingController _search = TextEditingController();
  late final Future<List<ClockTowerStore>> _seedFuture =
      ClockTowerDirectoryService.instance.loadSeed();
  int _floor = 0; // 0: all, -1: floor unknown
  String _category = 'الكل';
  bool _communityOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _normal(String input) => input
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064b-\u065f]'), '')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .trim();

  bool _categoryMatches(String actual, String requested) {
    if (requested == 'الكل') return true;
    final n = _normal(actual);
    return switch (requested) {
      'تجميل' => n.contains('تجميل') || n.contains('عنايه'),
      'عطور' => n.contains('عطور') || n.contains('بخور'),
      'مطاعم' => n.contains('مطاعم') || n.contains('طعام'),
      'كافيهات وحلويات' => n.contains('كافيه') || n.contains('حلويات'),
      'ملابس' => n.contains('ملابس') || n.contains('ازياء') || n.contains('احذيه'),
      'هدايا' => n.contains('هدايا') || n.contains('تمور') || n.contains('عمره'),
      'ذهب وساعات' => n.contains('مجوهرات') || n.contains('ساعات') || n.contains('ذهب'),
      'صيدليات وخدمات' => n.contains('خدمات') || n.contains('صيدليات') || n.contains('سوبرماركت'),
      'أخرى' => n.contains('اخرى') || n.contains('متاجر اخرى') || n.contains('اقسام'),
      _ => n == _normal(requested),
    };
  }

  List<ClockTowerStore> _filter(List<ClockTowerStore> all) {
    final query = _normal(_search.text);
    final result = all.where((p) {
      if (_communityOnly && !p.community) return false;
      if (_floor == -1 && p.floor != null) return false;
      if (_floor > 0 && p.floor != _floor) return false;
      if (!_categoryMatches(p.category, _category)) return false;
      if (query.isEmpty) return true;
      final haystack = _normal([
        p.name, p.englishName, p.category, p.note, p.unit, p.floorLabel,
      ].join(' '));
      return haystack.contains(query);
    }).toList();
    result.sort((a, b) {
      // Known floor first, then user-contributed places, then names.
      final ai = a.floor ?? 99;
      final bi = b.floor ?? 99;
      if (ai != bi) return ai.compareTo(bi);
      if (a.community != b.community) return a.community ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return result;
  }

  Future<void> _addStore() async {
    final added = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => const MarketContributeScreen(initialTower: true)));
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم نشر المحل في الدليل مباشرةً.'),
      ));
    }
  }

  Future<void> _report(ClockTowerStore place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('معلومة خاطئة؟'),
        content: Text('هل أنتِ متأكدة أن معلومات «${place.name}» غير صحيحة؟ '
            'البلاغ يُحسب مرة واحدة لكل حساب، وعند 3 بلاغات من حسابات مختلفة '
            'هيتم إخفاء المحل تلقائيًا.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('إرسال البلاغ')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final total = place.contribution != null
          ? await RefqaMarketsCommunityService.instance
              .reportWrong(place.contribution!)
          : await ClockTowerDirectoryService.instance.reportWrongInfo(place.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        total >= 3
            ? 'وصلت 3 بلاغات مختلفة، وتم إخفاء المحل من الدليل.'
            : 'تم تسجيل البلاغ ($total/3). شكرًا على مساعدتك.',
      )));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Bad state: ', '')),
      ));
    }
  }

  Future<void> _showDetails(ClockTowerStore p) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: MarketPalette.cream,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(top: false, child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(p.name, style: const TextStyle(fontSize: 20,
                  fontWeight: FontWeight.w900, color: MarketPalette.ink)),
              if (p.englishName.isNotEmpty) Text(p.englishName,
                  style: const TextStyle(color: MarketPalette.muted)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                MarketPill(label: p.category, icon: Icons.storefront_rounded),
                MarketPill(label: p.floorLabel, icon: Icons.layers_rounded),
                if (p.unit.isNotEmpty) MarketPill(
                    label: 'محل ${p.unit}', icon: Icons.numbers_rounded),
              ]),
              const SizedBox(height: 14),
              Text(p.confidenceLabel, style: const TextStyle(
                  color: MarketPalette.emerald, fontSize: 12,
                  fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (p.note.isNotEmpty) Text(p.note,
                  style: const TextStyle(fontSize: 13, height: 1.7)),
              if (p.community) ...[
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (p.contribution != null) OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      try {
                        await RefqaMarketsCommunityService.instance
                          .markHelpful(p.contribution!);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('شكرًا لتأكيد المعلومة.')));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))));
                      }
                    },
                    icon: const Icon(Icons.thumb_up_alt_outlined),
                    label: Text('مفيدة (${p.helpful})'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _report(p);
                    },
                    icon: const Icon(Icons.report_gmailerrorred_outlined),
                    label: Text('معلومة خاطئة · ${p.reports}/3'),
                  ),
                ]),
              ] else if (p.sourceUrl.startsWith('https://')) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(p.sourceUrl),
                      mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('عرض مصدر المعلومة'),
                ),
              ],
            ],
          ),
        )),
      ),
    );
  }

  Widget _floorPicker() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: [
      _floorPill(0, 'الكل'),
      for (var f = 1; f <= 7; f++) _floorPill(f, 'الدور $f'),
      _floorPill(-1, 'غير محدد'),
    ]),
  );

  Widget _floorPill(int floor, String label) => Padding(
    padding: const EdgeInsets.only(left: 7),
    child: MarketPill(label: label, filled: _floor == floor,
        icon: floor == 0 ? Icons.apps_rounded : Icons.layers_outlined,
        onTap: () => setState(() => _floor = floor)),
  );

  Widget _categoryPicker() => SizedBox(height: 43,
    child: ListView(scrollDirection: Axis.horizontal, children: [
      for (final c in ['الكل', ...ClockTowerDirectoryService.categories])
        Padding(padding: const EdgeInsets.only(left: 6), child: MarketPill(
          label: c,
          filled: _category == c,
          onTap: () => setState(() => _category = c),
        )),
    ]),
  );

  Widget _storeCard(ClockTowerStore p) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      onTap: () => _showDetails(p),
      borderRadius: BorderRadius.circular(20),
      child: MarketSoftCard(padding: const EdgeInsets.all(12), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(width: 46, height: 48,
              decoration: BoxDecoration(color: MarketPalette.pale,
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(p.category.contains('مطاعم')
                  ? Icons.restaurant_rounded
                  : p.category.contains('تجميل')
                      ? Icons.face_retouching_natural_outlined
                      : Icons.storefront_rounded,
                  color: MarketPalette.emerald, size: 25)),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: MarketPalette.ink)),
                const SizedBox(height: 3),
                Text('${p.category}  •  ${p.floorLabel}',
                    style: const TextStyle(fontSize: 11,
                        color: MarketPalette.muted)),
              ],
            )),
            Icon(p.community ? Icons.people_alt_outlined
                : Icons.fact_check_outlined,
                color: p.community ? MarketPalette.gold
                    : MarketPalette.emerald, size: 20),
          ]),
          const SizedBox(height: 9),
          Text(p.confidenceLabel, style: const TextStyle(
              fontSize: 11, color: MarketPalette.emerald,
              fontWeight: FontWeight.w700)),
          if (p.note.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(p.note, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11,
                    color: MarketPalette.muted, height: 1.5)),
          ],
          if (p.community) ...[
            const Divider(height: 18, color: MarketPalette.line),
            Wrap(alignment: WrapAlignment.spaceBetween, spacing: 5,
              runSpacing: 4, children: [
              const Text('إضافة من مستخدم رفقة',
                  style: TextStyle(color: MarketPalette.muted, fontSize: 11)),
              TextButton.icon(
                onPressed: () => _report(p),
                icon: const Icon(Icons.flag_outlined, size: 17),
                label: Text('معلومة خاطئة (${p.reports}/3)'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFAB5A35)),
              ),
            ]),
          ],
        ],
      )),
    ),
  );

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: MarketPalette.cream,
      appBar: AppBar(
        backgroundColor: MarketPalette.evergreen,
        foregroundColor: Colors.white,
        title: const Text('دليل محلات برج الساعة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStore,
        backgroundColor: MarketPalette.emerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('ساعد غيرك'),
      ),
      body: FutureBuilder<List<ClockTowerStore>>(
        future: _seedFuture,
        builder: (context, seedSnapshot) {
          if (seedSnapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (seedSnapshot.hasError) {
            return const Center(child: Text('تعذر فتح بيانات برج الساعة'));
          }
          final seed = seedSnapshot.data ?? const <ClockTowerStore>[];
          return StreamBuilder<List<RefqaMarketContribution>>(
            stream: RefqaMarketsCommunityService.instance.visiblePlaces(),
            builder: (context, newSnapshot) => StreamBuilder<List<ClockTowerStore>>(
            stream: ClockTowerDirectoryService.instance.livePlaces(),
            builder: (context, liveSnapshot) {
              final live = liveSnapshot.data ?? const <ClockTowerStore>[];
              final contributed = (newSnapshot.data ?? const <RefqaMarketContribution>[])
                  .where((p) => p.clockTower && p.placeType == 'shop')
                  .map(ClockTowerStore.fromContribution).toList();
              final filtered = _filter([...seed, ...live, ...contributed]);
              return CustomScrollView(slivers: [
                SliverToBoxAdapter(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 158, child: Stack(fit: StackFit.expand,
                      children: [
                        const MarketClockArtwork(),
                        Container(decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x75063830), Color(0xEE063E32)],
                          ),
                        )),
                        const Padding(
                          padding: EdgeInsets.all(18),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('برج الساعة • مكة المكرمة',
                                  style: TextStyle(color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900)),
                              SizedBox(height: 5),
                              Text('ابحث عن محل بالدور أو النشاط، وشارك بمعلومة تفيد غيرك',
                                  style: TextStyle(color: Color(0xFFFBE3B1),
                                      fontSize: 11.5)),
                            ],
                          ),
                        ),
                      ],
                    )),
                    Padding(padding: const EdgeInsets.fromLTRB(15, 14, 15, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'مثال: تجميل، سيفورا، البيك، الدور الأول',
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: MarketPalette.emerald),
                              filled: true, fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                    color: MarketPalette.line),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Text('اختاري الدور', style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: MarketPalette.ink, fontSize: 16)),
                          const SizedBox(height: 9),
                          _floorPicker(),
                          const SizedBox(height: 16),
                          const Text('نوع النشاط', style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: MarketPalette.ink, fontSize: 16)),
                          const SizedBox(height: 8),
                          _categoryPicker(),
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('إضافات المستخدمين فقط',
                                style: TextStyle(fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                            value: _communityOnly,
                            activeColor: MarketPalette.emerald,
                            onChanged: (v) => setState(() => _communityOnly = v),
                          ),
                          const SizedBox(height: 3),
                          MarketSoftCard(padding: const EdgeInsets.all(12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('كيف يعمل الدليل؟', style: TextStyle(
                                  fontWeight: FontWeight.w900, color: MarketPalette.ink)),
                                SizedBox(height: 4),
                                Text('أسماء من الدليل المنشور + إضافات من الناس. '
                                  'الأدوار غير المؤكدة لا نعرضها كأنها مؤكدة. '
                                  'إضافة المستخدم تظهر فورًا، وبعد 3 بلاغات '
                                  '«معلومة خاطئة» من حسابات مختلفة تختفي تلقائيًا.',
                                  style: TextStyle(fontSize: 11.5,
                                    height: 1.6, color: MarketPalette.muted)),
                              ])),
                          const SizedBox(height: 12),
                          Text('${filtered.length} نتيجة • دليل أولي غير شامل',
                              style: const TextStyle(color: MarketPalette.muted,
                                  fontSize: 11)),
                          if (liveSnapshot.hasError || newSnapshot.hasError) ...[
                            const SizedBox(height: 8),
                            const Text('الإضافات المجتمعية غير متاحة الآن. '
                                'تأكدي من نشر قواعد Firestore والاتصال بالشبكة.',
                                style: TextStyle(color: Color(0xFF9D4D35),
                                    fontSize: 11)),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                )),
                if (filtered.isEmpty)
                  const SliverFillRemaining(hasScrollBody: false,
                      child: Center(child: Text('لا توجد نتائج في هذا القسم بعد')))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 90),
                    sliver: SliverList(delegate: SliverChildBuilderDelegate(
                      (context, index) => _storeCard(filtered[index]),
                      childCount: filtered.length,
                    )),
                  ),
              ]);
            },
          ));
        },
      ),
    ),
  );
}
