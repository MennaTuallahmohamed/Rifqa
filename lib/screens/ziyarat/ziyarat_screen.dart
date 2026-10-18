import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/ziyarat/ziyarat_place.dart';
import '../../services/ziyarat/ziyarat_repository.dart';

// RIFQA ZIYARAT — based on the approved eight-screen reference.
// Local photographs are *illustrative concepts*, not verified documentary
// photographs of the listed sites. Do not label them as site-verified photos.
// No coordinates, journey durations or religious merits are invented.
// There is intentionally NO flutter_tts usage.

const _forest = Color(0xFF063E31);
const _emerald = Color(0xFF0B624C);
const _gold = Color(0xFFD8AD63);
const _ivory = Color(0xFFFBF6EC);
const _white = Color(0xFFFFFDFA);
const _ink = Color(0xFF15392F);
const _secondary = Color(0xFF77857B);
const _line = Color(0xFFECE3D2);

TextStyle _font(double size, {Color color = _ink, FontWeight weight = FontWeight.w500, double height = 1.35}) =>
    GoogleFonts.cairo(fontSize: size, color: color, fontWeight: weight, height: height);

class _ZiyaratImages {
  static const root = 'assets/ziyarat/';
  static const byId = <String, String>{
    'kaaba_haram': 'haram.jpg',
    'safa_marwa': 'safa_marwa.jpg',
    'zamzam': 'kaaba_detail.jpg',
    'hira': 'hira.jpg',
    'maqam_ibrahim': 'haram_courtyard.jpg',
    'black_stone_hijr': 'kaaba_detail.jpg',
    'thawr': 'thawr.jpg',
    'taneem': 'taneem.jpg',
    'arafat': 'hills.jpg',
    'namirah': 'mosque.jpg',
    'muzdalifah': 'makkah_panorama.jpg',
    'mina': 'hills.jpg',
    'jamarat': 'makkah_panorama.jpg',
    'prophets_mosque_rawdah': 'madinah.jpg',
    'quba': 'madinah.jpg',
    'uhud': 'hills.jpg',
    'qiblatain': 'mosque.jpg',
    'baqi': 'maqbara.jpg',
    'bir_rumah': 'maqbara.jpg',
  };
  static String forPlace(ZiyaratPlace place) =>
      place.heroImage ?? '$root${byId[place.id] ?? (place.city == ZiyaratCity.makkah ? 'hero_makkah.jpg' : 'madinah.jpg')}';

  static List<String> gallery(ZiyaratPlace place) {
    final first = forPlace(place);
    if (place.id == 'kaaba_haram') {
      return [first, '${root}kaaba_detail.jpg', '${root}haram_courtyard.jpg', '${root}hero_makkah.jpg'];
    }
    if (place.id == 'safa_marwa') {
      return [first, '${root}haram.jpg'];
    }
    if (place.id == 'hira' || place.id == 'thawr') {
      return [first, '${root}noor.jpg', '${root}hero_mountain.jpg'];
    }
    if (place.city == ZiyaratCity.madinah) {
      return [first, '${root}madinah.jpg'];
    }
    return [first];
  }
  static String heroForFilter(_FilterCity filter) => switch (filter) {
    _FilterCity.madinah => '${root}madinah.jpg',
    _FilterCity.hajj => '${root}hills.jpg',
    _ => '${root}makkah_panorama.jpg',
  };
}

String _displayName(ZiyaratPlace p) => switch (p.id) {
  'kaaba_haram' => 'المسجد الحرام',
  'hira' => 'جبل النور وغار حراء',
  'thawr' => 'جبل ثور',
  'prophets_mosque_rawdah' => 'المسجد النبوي',
  'taneem' => 'مسجد التنعيم',
  _ => p.name,
};

Widget _image(String path, {BoxFit fit = BoxFit.cover, Alignment alignment = Alignment.center}) =>
    Image.asset(
      path, fit: fit, alignment: alignment,
      errorBuilder: (_, __, ___) => Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [_emerald, _forest])),
        child: const Center(child: Icon(Icons.mosque_rounded, color: _gold, size: 49)),
      ),
    );

BoxDecoration _cardDecoration({Color color = _white, double radius = 24, bool shadow = true}) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: _line, width: 1),
  boxShadow: shadow ? const [BoxShadow(color: Color(0x0D42351F), blurRadius: 18, offset: Offset(0, 7))] : null,
);

enum _FilterCity { all, makkah, madinah, hajj }

// ---------------------------------------------------------------------------
// Screen 1 + 5 — home and city discovery, same layout as approved mock-up
// ---------------------------------------------------------------------------
class ZiyaratScreen extends StatefulWidget {
  const ZiyaratScreen({super.key});
  @override
  State<ZiyaratScreen> createState() => _ZiyaratScreenState();
}

class _ZiyaratScreenState extends State<ZiyaratScreen> {
  final ZiyaratRepository _repo = const ZiyaratRepository();
  final TextEditingController _search = TextEditingController();
  final Set<String> _favorites = {};
  final Set<String> _visited = {};
  _FilterCity _filter = _FilterCity.all;
  ZiyaratCategory? _category;
  bool _favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favorites.addAll(prefs.getStringList('rifqa_ziyarat_favorites_v1') ?? []);
      _visited.addAll(prefs.getStringList('rifqa_ziyarat_visited_v1') ?? []);
    });
  }

  Future<void> _changeFavorite(String id, bool value) async {
    setState(() { if (value) { _favorites.add(id); } else { _favorites.remove(id); } });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('rifqa_ziyarat_favorites_v1', _favorites.toList());
  }

  Future<void> _changeVisited(String id, bool value) async {
    setState(() { if (value) { _visited.add(id); } else { _visited.remove(id); } });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('rifqa_ziyarat_visited_v1', _visited.toList());
  }

  List<ZiyaratPlace> get _results {
    final city = _filter == _FilterCity.makkah ? ZiyaratCity.makkah
        : _filter == _FilterCity.madinah ? ZiyaratCity.madinah : null;
    final category = _filter == _FilterCity.hajj ? ZiyaratCategory.hajjSite : _category;
    final items = _repo.search(_search.text, city: city, category: category);
    return _favoritesOnly ? items.where((p) => _favorites.contains(p.id)).toList() : items;
  }

  Future<void> _open(ZiyaratPlace place) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ZiyaratDetailsScreen(
        place: place,
        initialFavorite: _favorites.contains(place.id),
        initialVisited: _visited.contains(place.id),
        onFavoriteChanged: (value) => _changeFavorite(place.id, value),
        onVisitedChanged: (value) => _changeVisited(place.id, value),
      ),
    ));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _ivory,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _hero()),
              SliverToBoxAdapter(child: Transform.translate(
                offset: const Offset(0, -20),
                child: _filterPanel(),
              )),
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Row(children: [
                  Text(_favoritesOnly ? 'المزارات المحفوظة' : _filter == _FilterCity.madinah ? 'مزارات المدينة المنورة' : 'اكتشفي المزارات',
                    style: _font(19, weight: FontWeight.w800)),
                  const Spacer(),
                  Text('${results.length} مزار', style: _font(12, color: _secondary)),
                ]),
              )),
              if (results.isEmpty)
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.all(36),
                  child: Column(children: [
                    const Icon(Icons.travel_explore_rounded, color: _emerald, size: 55),
                    const SizedBox(height: 13),
                    Text('مفيش مزارات مطابقة للبحث', style: _font(16, weight: FontWeight.w700)),
                    const SizedBox(height: 9),
                    TextButton(onPressed: () => setState(() {
                      _search.clear(); _category = null; _filter = _FilterCity.all; _favoritesOnly = false;
                    }), child: const Text('عرض كل المزارات')),
                  ]),
                )),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(17, 0, 17, 85),
                sliver: SliverList.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _placeCard(results[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    final safe = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: safe + 235,
      child: Stack(fit: StackFit.expand, children: [
        _image(_ZiyaratImages.heroForFilter(_filter)),
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          stops: [0, .35, 1],
          colors: [Color(0x8D062B29), Color(0x25062B29), Color(0xE403382E)],
        ))),
        Positioned(
          top: safe + 13, right: 18, left: 18,
          child: Row(children: [
            _roundTopButton(Icons.arrow_forward_rounded, () => Navigator.maybePop(context)),
            const Spacer(),
            _roundTopButton(_favoritesOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded, () {
              setState(() => _favoritesOnly = !_favoritesOnly);
            }),
          ]),
        ),
        Positioned(
          bottom: 44, left: 20, right: 20,
          child: Column(children: [
            Text('المزارات', textAlign: TextAlign.center, style: _font(35, color: _white, weight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text('أماكن مباركة ذات قيمة إيمانية وتاريخية', textAlign: TextAlign.center,
              style: _font(12.5, color: const Color(0xFFFFF1D9), weight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  Widget _filterPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.fromLTRB(15, 17, 15, 6),
      decoration: const BoxDecoration(
        color: _ivory, borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(children: [
        SizedBox(height: 47, child: ListView(scrollDirection: Axis.horizontal, children: [
          _filterChip('الكل', _FilterCity.all),
          _filterChip('مكة المكرمة', _FilterCity.makkah),
          _filterChip('المدينة المنورة', _FilterCity.madinah),
          _filterChip('مشاعر الحج', _FilterCity.hajj),
        ])),
        const SizedBox(height: 11),
        Container(
          height: 49,
          decoration: _cardDecoration(radius: 17, shadow: false),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: _font(13),
            decoration: InputDecoration(
              hintText: 'ابحثي عن مزار أو مكان تاريخي...',
              hintStyle: _font(12, color: _secondary),
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: _emerald),
              suffixIcon: _search.text.isEmpty ? null : IconButton(
                icon: const Icon(Icons.close_rounded, size: 17),
                onPressed: () => setState(() => _search.clear()),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(height: 37, child: ListView(scrollDirection: Axis.horizontal, children: [
          _categoryChip('كل الأنواع', null),
          _categoryChip('مساجد', ZiyaratCategory.mosque),
          _categoryChip('معالم', ZiyaratCategory.landmark),
          _categoryChip('جبال', ZiyaratCategory.mountain),
          _categoryChip('مواقع تاريخية', ZiyaratCategory.historical),
          _categoryChip('آبار', ZiyaratCategory.well),
        ])),
      ]),
    );
  }

  Widget _filterChip(String text, _FilterCity value) {
    final selected = _filter == value;
    return Padding(padding: const EdgeInsetsDirectional.only(end: 7), child: InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => setState(() { _filter = value; _category = null; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: selected ? _forest : const Color(0xFFFAF2E5),
          border: Border.all(color: selected ? _gold : _line),
          boxShadow: selected ? const [BoxShadow(color: Color(0x220B624C), blurRadius: 8, offset: Offset(0, 3))] : null,
        ),
        child: Center(child: Text(text, style: _font(11.5, color: selected ? Colors.white : _ink,
          weight: selected ? FontWeight.w800 : FontWeight.w600))),
      ),
    ));
  }

  Widget _categoryChip(String label, ZiyaratCategory? category) {
    final selected = _category == category;
    return Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: () => setState(() { _category = category; if (_filter == _FilterCity.hajj && category != null) _filter = _FilterCity.all; }),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6), decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: selected ? const Color(0xFFE3EFE6) : Colors.transparent,
        border: Border.all(color: selected ? _emerald : _line),
      ), child: Text(label, style: _font(10.2, weight: FontWeight.w700, color: selected ? _emerald : _secondary))),
    ));
  }

  Widget _placeCard(ZiyaratPlace place) {
    final fav = _favorites.contains(place.id);
    return Material(color: _white, borderRadius: BorderRadius.circular(22), child: InkWell(
      onTap: () => _open(place),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(10), decoration: _cardDecoration(radius: 22),
        child: Row(children: [
          Expanded(child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 5),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(_displayName(place), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: _font(14.5, weight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(place.cityName, style: _font(10.5, color: _emerald, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(place.shortDescription, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: _font(10.4, color: _secondary, height: 1.5)),
              if (_visited.contains(place.id))
                Padding(padding: const EdgeInsets.only(top: 5), child: Text('✓ تمت الزيارة',
                  style: _font(10, color: _emerald, weight: FontWeight.w800))),
            ]),
          )),
          IconButton(
            onPressed: () => _changeFavorite(place.id, !fav),
            icon: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: fav ? const Color(0xFFC08941) : _emerald, size: 20),
            tooltip: fav ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
            padding: EdgeInsets.zero, constraints: const BoxConstraints(minHeight: 37, minWidth: 37),
          ),
          const SizedBox(width: 3),
          ClipRRect(borderRadius: BorderRadius.circular(15), child: SizedBox(
            width: 89, height: 94, child: _image(_ZiyaratImages.forPlace(place)),
          )),
        ]),
      ),
    ));
  }
}

// ---------------------------------------------------------------------------
// Screens 2,3,6,7 — details with tabs, history, photo grids and evidence
// ---------------------------------------------------------------------------
class ZiyaratDetailsScreen extends StatefulWidget {
  const ZiyaratDetailsScreen({super.key, required this.place,
    required this.initialFavorite, required this.initialVisited,
    required this.onFavoriteChanged, required this.onVisitedChanged});
  final ZiyaratPlace place;
  final bool initialFavorite;
  final bool initialVisited;
  final ValueChanged<bool> onFavoriteChanged;
  final ValueChanged<bool> onVisitedChanged;
  @override
  State<ZiyaratDetailsScreen> createState() => _ZiyaratDetailsScreenState();
}

class _ZiyaratDetailsScreenState extends State<ZiyaratDetailsScreen> {
  late bool _fav;
  late bool _visited;
  int _tab = 0;
  AudioPlayer? _player;
  bool _playing = false;

  ZiyaratPlace get p => widget.place;

  @override
  void initState() {
    super.initState();
    _fav = widget.initialFavorite;
    _visited = widget.initialVisited;
  }

  Future<void> _toggleAudio() async {
    if (p.audioAsset == null) return;
    try {
      _player ??= AudioPlayer();
      if (_playing) {
        await _player!.stop();
        if (mounted) setState(() => _playing = false);
        return;
      }
      final asset = p.audioAsset!.replaceFirst(RegExp(r'^assets/'), '');
      await _player!.play(AssetSource(asset));
      if (mounted) setState(() => _playing = true);
      _player!.onPlayerComplete.first.then((_) {
        if (mounted) setState(() => _playing = false);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _playing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر تشغيل التسجيل. تأكدي من وجود ملف الصوت.')));
      }
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  void _openMap() => Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => ZiyaratMapScreen(place: p),
  ));

  void _openGallery([int index = 0]) => Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => ZiyaratGalleryScreen(place: p, initialIndex: index),
  ));

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _ivory,
        body: Column(children: [
          _hero(),
          _tabs(),
          Expanded(child: IndexedStack(index: _tab, children: [
            _overview(), _galleryTab(), _locationTab(), _moreTab(),
          ])),
        ]),
        bottomNavigationBar: SafeArea(top: false, child: Container(
          color: _ivory,
          padding: const EdgeInsets.fromLTRB(18, 9, 18, 11),
          child: ElevatedButton.icon(
            onPressed: _openMap,
            icon: const Icon(Icons.location_on_rounded, color: _white),
            label: Text(p.hasVerifiedCoordinates ? 'عرض الموقع على الخريطة' : 'استكشفي الموقع على الخريطة',
              style: _font(13, color: _white, weight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _forest,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
              elevation: 4,
            ),
          ),
        )),
      ),
    ));
  }

  Widget _hero() {
    final safe = MediaQuery.paddingOf(context).top;
    return SizedBox(height: safe + 258, child: Stack(fit: StackFit.expand, children: [
      _image(_ZiyaratImages.forPlace(p)),
      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0x88051D1B), Color(0x11071B18), Color(0xE0023028)],
        stops: [0, .38, 1],
      ))),
      Positioned(top: safe + 10, left: 18, right: 18, child: Row(children: [
        _roundTopButton(Icons.arrow_forward_rounded, () => Navigator.pop(context)),
        const Spacer(),
        _roundTopButton(_fav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, () {
          setState(() => _fav = !_fav);
          widget.onFavoriteChanged(_fav);
        }),
      ])),
      Positioned(bottom: 24, left: 20, right: 20, child: Column(children: [
        Text(_displayName(p), maxLines: 2, textAlign: TextAlign.center,
          style: _font(25.5, color: _white, weight: FontWeight.w900)),
        const SizedBox(height: 5),
        Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_on_outlined, color: Color(0xFFFFE0AA), size: 15),
          const SizedBox(width: 4),
          Text(p.cityName, style: _font(11.5, color: const Color(0xFFFFE0AA))),
        ]),
      ])),
    ]));
  }

  Widget _tabs() => Container(
    padding: const EdgeInsets.fromLTRB(15, 13, 15, 10),
    decoration: const BoxDecoration(color: _ivory, borderRadius: BorderRadius.vertical(top: Radius.circular(29))),
    child: Row(children: [
      _tabButton('نبذة', 0),
      _tabButton('الصور', 1),
      _tabButton('الموقع', 2),
      _tabButton('المزيد', 3),
    ]),
  );

  Widget _tabButton(String text, int index) {
    final selected = _tab == index;
    return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: InkWell(
      onTap: () => setState(() => _tab = index),
      borderRadius: BorderRadius.circular(27),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        height: 39, alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(27),
          color: selected ? _forest : const Color(0xFFF5EFE4),
          border: Border.all(color: selected ? _gold : Colors.transparent)),
        child: Text(text, style: _font(11.2, color: selected ? Colors.white : _secondary,
          weight: selected ? FontWeight.w800 : FontWeight.w600)),
      ),
    )));
  }

  Widget _overview() => ListView(padding: const EdgeInsets.fromLTRB(19, 5, 19, 35), children: [
    Text(p.shortDescription, textAlign: TextAlign.center, style: _font(14, color: _ink, height: 1.85)),
    const SizedBox(height: 17),
    Row(children: [
      _stat('المدينة', p.cityName, Icons.location_city_rounded),
      const SizedBox(width: 9),
      _stat('التصنيف', p.categoryName, Icons.auto_stories_rounded),
      if (p.estimatedVisitMinutes != null) ...[
        const SizedBox(width: 9),
        _stat('مدة الزيارة', '${p.estimatedVisitMinutes} دقيقة', Icons.timer_outlined),
      ],
    ]),
    const SizedBox(height: 20),
    Row(children: [
      Text('قصة المكان', style: _font(17, weight: FontWeight.w900)),
      const Spacer(),
      InkWell(onTap: () => setState(() => _tab = 3), child: Text('اقرئي المزيد', style: _font(11, color: _emerald, weight: FontWeight.w800))),
    ]),
    const SizedBox(height: 9),
    Text(p.story, maxLines: 5, overflow: TextOverflow.ellipsis, style: _font(12.5, color: _secondary, height: 1.9)),
    const SizedBox(height: 18),
    Text('أهمية المكان', style: _font(17, weight: FontWeight.w900)),
    const SizedBox(height: 8),
    _panel(child: Text(p.significance, style: _font(12.3, height: 1.85))),
    if (p.evidence.isNotEmpty) ...[
      const SizedBox(height: 17),
      Text('الدليل والمصادر', style: _font(17, weight: FontWeight.w900)),
      const SizedBox(height: 9),
      _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.evidence.first.text, maxLines: 3, overflow: TextOverflow.ellipsis,
          style: _font(12.6, height: 1.9, weight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(p.evidence.first.source, style: _font(10.5, color: _secondary)),
      ])),
    ],
    const SizedBox(height: 17),
    if (p.audioAsset != null) OutlinedButton.icon(
      onPressed: _toggleAudio, icon: Icon(_playing ? Icons.stop_circle_rounded : Icons.headphones_rounded),
      label: Text(_playing ? 'إيقاف الاستماع' : 'استمعي للقصة'),
      style: OutlinedButton.styleFrom(foregroundColor: _forest),
    ),
    if (p.needsReview) Padding(padding: const EdgeInsets.only(top: 6),
      child: Text('ملاحظة: هذا المحتوى ما زال قيد المراجعة العلمية قبل النشر.', style: _font(10.5, color: _secondary))),
  ]);

  Widget _stat(String title, String value, IconData icon) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 7),
    decoration: _cardDecoration(radius: 17, shadow: false),
    child: Column(children: [
      Icon(icon, size: 21, color: _emerald),
      const SizedBox(height: 5),
      Text(title, style: _font(10, color: _secondary), textAlign: TextAlign.center),
      const SizedBox(height: 2),
      Text(value, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
        style: _font(10.5, weight: FontWeight.w800)),
    ]),
  ));

  Widget _galleryTab() {
    final photos = _ZiyaratImages.gallery(p);
    return ListView(padding: const EdgeInsets.fromLTRB(17, 4, 17, 30), children: [
      InkWell(onTap: () => _openGallery(0), borderRadius: BorderRadius.circular(17),
        child: ClipRRect(borderRadius: BorderRadius.circular(17), child: SizedBox(
          height: 195, width: double.infinity, child: _image(photos.first),
        ))),
      const SizedBox(height: 10),
      if (photos.length > 1)
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 9, crossAxisSpacing: 9, childAspectRatio: 1.4),
          itemCount: photos.length - 1,
          itemBuilder: (_, i) => InkWell(onTap: () => _openGallery(i+1), borderRadius: BorderRadius.circular(15),
            child: ClipRRect(borderRadius: BorderRadius.circular(15), child: _image(photos[i+1]))),
        ),
      const SizedBox(height: 10),
      Row(children: [const Icon(Icons.info_outline_rounded, color: _secondary, size: 16),
        const SizedBox(width: 7),
        Expanded(child: Text('صور توضيحية للتصميم وليست توثيقًا فوتوغرافيًا للمزار. ستُستبدل بصور معتمدة.',
          style: _font(10.5, color: _secondary, height: 1.65))),
      ]),
    ]);
  }

  Widget _locationTab() => ListView(padding: const EdgeInsets.fromLTRB(17, 5, 17, 25), children: [
    ClipRRect(borderRadius: BorderRadius.circular(20), child: SizedBox(height: 210,
      child: p.hasVerifiedCoordinates
          ? FlutterMap(
              options: MapOptions(initialCenter: LatLng(p.latitude!, p.longitude!), initialZoom: 15),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.rafeek'),
                MarkerLayer(markers: [Marker(point: LatLng(p.latitude!, p.longitude!), width: 65, height: 65,
                  child: const Icon(Icons.place_rounded, color: _forest, size: 49))]),
                RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
              ],
            )
          : _unverifiedMapTile(),
    )),
    const SizedBox(height: 17),
    Text('الموقع الجغرافي', style: _font(17, weight: FontWeight.w900)),
    const SizedBox(height: 6),
    Text(p.hasVerifiedCoordinates
        ? 'الموقع معتمد في بيانات المزار. يمكنك استعراضه أو فتح الاتجاهات.'
        : 'لم تُعتمد إحداثيات دقيقة لهذا المزار بعد؛ لا نعرض دبوسًا تقديريًا.',
      style: _font(12, height: 1.85, color: _secondary)),
    const SizedBox(height: 14),
    OutlinedButton.icon(onPressed: _openMap,
      icon: const Icon(Icons.open_in_new_rounded), label: const Text('فتح صفحة الموقع والاتجاهات'),
      style: OutlinedButton.styleFrom(foregroundColor: _forest)),
  ]);

  Widget _moreTab() => ListView(padding: const EdgeInsets.fromLTRB(17, 5, 17, 30), children: [
    _expansion('أهمية الزيارة', Icons.favorite_outline_rounded,
      Text(p.significance, style: _font(12.5, height: 1.85))),
    _expansion('القصة والمعلومات التاريخية', Icons.auto_stories_rounded,
      Text(p.story, style: _font(12.5, height: 1.9))),
    _expansion('نصائح الزائر', Icons.lightbulb_outline_rounded,
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final g in p.visitorGuidance) _bullet('${g.title}: ${g.description}', Icons.check_circle_outline_rounded),
        if (p.visitorGuidance.isEmpty) Text('لا تتوفر نصائح معتمدة لهذا المزار.', style: _font(12, color: _secondary)),
      ])),
    _expansion('أوقات الزيارة المناسبة', Icons.schedule_rounded,
      Text('لا تتوفر مواعيد زيارة معتمدة في البيانات الحالية. تحققي من تعليمات الموقع والجهات الرسمية قبل الزيارة.',
        style: _font(12.5, height: 1.85))),
    _expansion('تنبيهات مهمة', Icons.health_and_safety_outlined,
      Column(children: [for (final warning in p.warnings) _bullet(warning, Icons.info_outline_rounded)])),
    _expansion('المصادر والمراجع', Icons.menu_book_outlined,
      Column(children: [for (final evidence in p.evidence) Padding(padding: const EdgeInsets.only(bottom: 11), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(evidence.text, style: _font(12.3, height: 1.9)),
          const SizedBox(height: 4),
          Text('${evidence.source}${evidence.reference == null ? '' : ' • ${evidence.reference}'}',
            style: _font(10, color: _emerald, weight: FontWeight.w800)),
          if (evidence.authenticity != null) Text('الدرجة: ${evidence.authenticity}', style: _font(10.5, color: _secondary)),
          if (evidence.note != null) Text(evidence.note!, style: _font(10, color: _secondary)),
        ],
      ))]),
    ),
    _expansion('حالة التوثيق', Icons.verified_user_outlined,
      Text(p.needsReview ? 'المعلومات الدينية والتاريخية لهذا المزار ما زالت قيد المراجعة قبل النشر.'
          : 'تم اعتماد المحتوى داخل قاعدة بيانات رِفقة.', style: _font(12, height: 1.85))),
    const SizedBox(height: 8),
    _panel(child: Row(children: [
      const Icon(Icons.check_circle_outline_rounded, color: _emerald),
      const SizedBox(width: 10),
      Expanded(child: Text(_visited ? 'تم تسجيل زيارتك لهذا المكان' : 'هل زرتِ هذا المكان؟',
        style: _font(12, weight: FontWeight.w700))),
      Switch(value: _visited, activeColor: _forest, onChanged: (v) {
        setState(() => _visited = v);
        widget.onVisitedChanged(v);
      }),
    ])),
  ]);

  Widget _bullet(String text, IconData icon) => Padding(padding: const EdgeInsets.only(bottom: 9),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 4), child: Icon(icon, color: _emerald, size: 18)),
      const SizedBox(width: 9),
      Expanded(child: Text(text, style: _font(12.2, height: 1.8))),
    ]));

  Widget _expansion(String title, IconData icon, Widget content) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: _cardDecoration(radius: 18),
    child: ExpansionTile(
      shape: const RoundedRectangleBorder(side: BorderSide.none),
      collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
      leading: CircleAvatar(backgroundColor: const Color(0xFFE8EEE8), child: Icon(icon, color: _forest, size: 21)),
      title: Text(title, style: _font(12, weight: FontWeight.w800)),
      iconColor: _forest,
      children: [Padding(padding: const EdgeInsets.fromLTRB(17, 0, 17, 17), child: Align(
        alignment: Alignment.centerRight, child: content,
      ))],
    ),
  );
}

Widget _panel({required Widget child}) => Container(
  width: double.infinity, padding: const EdgeInsets.all(15),
  decoration: _cardDecoration(radius: 17, shadow: false), child: child,
);

Widget _unverifiedMapTile() => Container(
  decoration: const BoxDecoration(gradient: LinearGradient(
    begin: Alignment.topRight, end: Alignment.bottomLeft,
    colors: [Color(0xFFE8EEE6), Color(0xFFD9E8DB), Color(0xFFEDE7D8)],
  )),
  child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.map_outlined, color: _emerald, size: 54),
    const SizedBox(height: 8),
    Text('الموقع الدقيق قيد التوثيق', style: _font(14, weight: FontWeight.w800)),
    const SizedBox(height: 3),
    Text('لن نعرض دبوسًا غير مؤكد', style: _font(11, color: _secondary)),
  ])),
);

Widget _roundTopButton(IconData icon, VoidCallback callback) => Material(
  color: const Color(0xE0064437),
  shape: const CircleBorder(side: BorderSide(color: _gold, width: 1)),
  child: IconButton(onPressed: callback, icon: Icon(icon, color: _white, size: 23), tooltip: 'فتح'),
);

// ---------------------------------------------------------------------------
// Screen 4 — map / location, only verified coordinates receive a map pin.
// ---------------------------------------------------------------------------
class ZiyaratMapScreen extends StatelessWidget {
  const ZiyaratMapScreen({super.key, required this.place});
  final ZiyaratPlace place;

  Future<void> _openExternal(BuildContext context) async {
    final query = place.hasVerifiedCoordinates
        ? '${place.latitude},${place.longitude}'
        : '${place.name} ${place.cityName}';
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر فتح تطبيق الخرائط.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final has = place.hasVerifiedCoordinates;
    return Directionality(textDirection: TextDirection.rtl, child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _ivory,
        appBar: AppBar(backgroundColor: _forest, foregroundColor: _white,
          title: Text('الموقع على الخريطة', style: _font(17, color: _white, weight: FontWeight.w800))),
        body: Column(children: [
          Expanded(child: has
              ? FlutterMap(
                  options: MapOptions(initialCenter: LatLng(place.latitude!, place.longitude!), initialZoom: 15),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.rafeek'),
                    MarkerLayer(markers: [Marker(
                      point: LatLng(place.latitude!, place.longitude!), width: 72, height: 72,
                      child: const Icon(Icons.location_on_rounded, color: _forest, size: 64),
                    )]),
                    RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
                  ],
                )
              : _unverifiedMapTile()),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 25),
            decoration: const BoxDecoration(color: _ivory, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(children: [
              Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(
                  width: 74, height: 71, child: _image(_ZiyaratImages.forPlace(place)),
                )),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_displayName(place), style: _font(16, weight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(place.cityName, style: _font(11, color: _emerald)),
                  const SizedBox(height: 3),
                  Text(has ? 'موقع معتمد' : 'بحث بالاسم فقط — ليس دبوسًا موثقًا',
                    style: _font(10, color: _secondary)),
                ])),
              ]),
              const SizedBox(height: 15),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: () => _openExternal(context),
                icon: const Icon(Icons.directions_rounded),
                label: Text(has ? 'الاتجاهات إلى الموقع المعتمد' : 'البحث عن المكان في خرائط Google',
                  style: _font(12.5, color: Colors.white, weight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(backgroundColor: _forest, foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(51),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
              )),
            ]),
          ),
        ]),
      ),
    ));
  }
}

// ---------------------------------------------------------------------------
// Screen 8 — immersive photo viewer
// ---------------------------------------------------------------------------
class ZiyaratGalleryScreen extends StatefulWidget {
  const ZiyaratGalleryScreen({super.key, required this.place, this.initialIndex = 0});
  final ZiyaratPlace place;
  final int initialIndex;
  @override
  State<ZiyaratGalleryScreen> createState() => _ZiyaratGalleryScreenState();
}

class _ZiyaratGalleryScreenState extends State<ZiyaratGalleryScreen> {
  late final PageController _pager;
  late int _index;
  late final List<String> _photos;
  @override
  void initState() {
    super.initState();
    _photos = _ZiyaratImages.gallery(widget.place);
    _index = widget.initialIndex.clamp(0, _photos.length - 1).toInt();
    _pager = PageController(initialPage: _index);
  }
  @override
  void dispose() { _pager.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl,
    child: AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.light, child: Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(15, 10, 15, 12), child: Row(children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white)),
          const Spacer(),
          Text('${_index + 1} / ${_photos.length}', style: _font(13, color: Colors.white, weight: FontWeight.w800)),
          const Spacer(),
          const Icon(Icons.fullscreen_rounded, color: Colors.white),
        ])),
        Expanded(child: PageView.builder(
          controller: _pager, itemCount: _photos.length,
          onPageChanged: (index) => setState(() => _index = index),
          itemBuilder: (_, index) => InteractiveViewer(minScale: 1, maxScale: 4,
            child: Center(child: _image(_photos[index], fit: BoxFit.contain))),
        )),
        const SizedBox(height: 14),
        SizedBox(height: 71, child: ListView.separated(
          scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 18),
          itemCount: _photos.length, separatorBuilder: (_, __) => const SizedBox(width: 9),
          itemBuilder: (_, index) => GestureDetector(
            onTap: () => _pager.animateToPage(index,
              duration: const Duration(milliseconds: 260), curve: Curves.easeOut),
            child: Container(width: 75, height: 69,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                border: Border.all(color: index == _index ? _gold : Colors.white38, width: index == _index ? 2 : 1)),
              clipBehavior: Clip.antiAlias,
              child: _image(_photos[index])),
          ),
        )),
        Padding(padding: const EdgeInsets.all(14), child: Text(
          'الصور توضيحية لعرض التصميم وليست توثيقًا فوتوغرافيًا معتمدًا للمكان.',
          textAlign: TextAlign.center, style: _font(10, color: Colors.white70, height: 1.55),
        )),
      ])),
    )));
}
