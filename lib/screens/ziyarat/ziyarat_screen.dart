import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../models/ziyarat/ziyarat_place.dart';
import '../../services/ziyarat/ziyarat_repository.dart';

const Color _green = Color(0xFF12372C);
const Color _greenLight = Color(0xFF1F5A46);
const Color _gold = Color(0xFFC69B43);
const Color _cream = Color(0xFFF8F4E8);
const Color _surface = Color(0xFFFFFCF5);
const Color _text = Color(0xFF17251F);
const Color _muted = Color(0xFF6B7872);
const Color _border = Color(0xFFE8E0CC);

class ZiyaratScreen extends StatefulWidget {
  const ZiyaratScreen({super.key});

  @override
  State<ZiyaratScreen> createState() => _ZiyaratScreenState();
}

class _ZiyaratScreenState extends State<ZiyaratScreen> {
  final ZiyaratRepository _repository = const ZiyaratRepository();

  ZiyaratCity _selectedCity = ZiyaratCity.makkah;
  ZiyaratCategory? _selectedCategory;

  String _searchQuery = '';

  final Set<String> _favorites = <String>{};
  final Set<String> _visited = <String>{};

  List<ZiyaratPlace> get _places {
    return _repository.search(
      _searchQuery,
      city: _selectedCity,
      category: _selectedCategory,
    );
  }

  int get _cityPlacesCount {
    return _repository.all
        .where((place) => place.city == _selectedCity)
        .length;
  }

  int get _visitedInCurrentCity {
    return _repository.all
        .where(
          (place) =>
              place.city == _selectedCity &&
              _visited.contains(place.id),
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildCitySelector(),
                        if (_selectedCity == ZiyaratCity.madinah) ...[
                          const SizedBox(height: 14),
                          _buildMadinahWelcome(),
                        ],
                        const SizedBox(height: 12),
                        _buildSearch(),
                        const SizedBox(height: 12),
                        _buildJourneyProgress(),
                        const SizedBox(height: 12),
                        _buildCategories(),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                  if (_places.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        30,
                      ),
                      sliver: SliverList.separated(
                        itemCount: _places.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 13),
                        itemBuilder: (context, index) {
                          final place = _places[index];

                          return _PlaceCard(
                            place: place,
                            isFavorite:
                                _favorites.contains(place.id),
                            isVisited:
                                _visited.contains(place.id),
                            onFavorite: () {
                              setState(() {
                                if (_favorites.contains(place.id)) {
                                  _favorites.remove(place.id);
                                } else {
                                  _favorites.add(place.id);
                                }
                              });
                            },
                            onTap: () => _openPlace(place),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: const BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Navigator.canPop(context)
                ? IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  'المزارات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFE5A3),
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'اكتشفي القصة • الدليل • آداب الزيارة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFD8E8E0),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildCitySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _CityButton(
                title: 'مكة المكرمة',
                emoji: '🕋',
                selected:
                    _selectedCity == ZiyaratCity.makkah,
                onTap: () {
                  setState(() {
                    _selectedCity = ZiyaratCity.makkah;
                    _selectedCategory = null;
                  });
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _CityButton(
                title: 'المدينة المنورة',
                emoji: '🕌',
                selected:
                    _selectedCity == ZiyaratCity.madinah,
                onTap: () {
                  setState(() {
                    _selectedCity = ZiyaratCity.madinah;
                    _selectedCategory = null;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMadinahWelcome() {
    final quba = _repository.byId('quba');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [_greenLight, _green],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF4D7966)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.nights_stay_rounded,
                  color: Color(0xFFFFE5A3),
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'حكاية دار الهجرة',
                  style: TextStyle(
                    color: Color(0xFFFFE5A3),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'في المدينة، وجد رسول الله ﷺ وأصحابه دارًا تجمعهم على الإيمان؛ آوى الأنصار المهاجرين وشاركوهم المحبة والدار. ومن هنا بدأت حكايات وطنٍ بُني بالإخاء.',
              style: TextStyle(
                color: Colors.white,
                height: 1.75,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '﴿يُحِبُّونَ مَنْ هَاجَرَ إِلَيْهِمْ﴾  •  الحشر: 9',
              style: TextStyle(
                color: Color(0xFFD8E8E0),
                height: 1.5,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: quba == null ? null : () => _openPlace(quba),
                style: TextButton.styleFrom(
                  foregroundColor: _green,
                  backgroundColor: const Color(0xFFFFE5A3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                ),
                icon: const Icon(Icons.auto_stories_rounded, size: 18),
                label: const Text(
                  'ابدئي الحكاية من قباء',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'ابحثي عن مزار أو قصة...',
          hintStyle: const TextStyle(color: _muted),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _greenLight,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: _greenLight,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyProgress() {
    final progress = _cityPlacesCount == 0
        ? 0.0
        : _visitedInCurrentCity / _cityPlacesCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE5F1EB),
              ),
              child: const Icon(
                Icons.route_rounded,
                color: _green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'رحلة مزاراتي',
                    style: TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'زرتِ $_visitedInCurrentCity من $_cityPlacesCount',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor:
                          const Color(0xFFE8E6DD),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                        _gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: _green,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    const categories = [
      ZiyaratCategory.mosque,
      ZiyaratCategory.landmark,
      ZiyaratCategory.mountain,
      ZiyaratCategory.well,
      ZiyaratCategory.hajjSite,
      ZiyaratCategory.historical,
    ];

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _CategoryChip(
            text: 'الكل',
            selected: _selectedCategory == null,
            onTap: () {
              setState(() => _selectedCategory = null);
            },
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _CategoryChip(
                text: _categoryLabel(category),
                selected:
                    _selectedCategory == category,
                onTap: () {
                  setState(
                    () => _selectedCategory = category,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(ZiyaratCategory category) {
    switch (category) {
      case ZiyaratCategory.mosque:
        return '🕌 مساجد';
      case ZiyaratCategory.landmark:
        return '✨ معالم';
      case ZiyaratCategory.mountain:
        return '🏔 تاريخية';
      case ZiyaratCategory.well:
        return '💧 آبار';
      case ZiyaratCategory.historical:
        return '📖 مواقع تاريخية';
      case ZiyaratCategory.hajjSite:
        return '🕋 مشاعر الحج';
      case ZiyaratCategory.other:
        return '📍 أخرى';
    }
  }

  Future<void> _openPlace(ZiyaratPlace place) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ZiyaratDetailsScreen(
          place: place,
          initialFavorite:
              _favorites.contains(place.id),
          initialVisited:
              _visited.contains(place.id),
          onFavoriteChanged: (value) {
            setState(() {
              if (value) {
                _favorites.add(place.id);
              } else {
                _favorites.remove(place.id);
              }
            });
          },
          onVisitedChanged: (value) {
            setState(() {
              if (value) {
                _visited.add(place.id);
              } else {
                _visited.remove(place.id);
              }
            });
          },
        ),
      ),
    );
  }
}

// ============================================================
// PLACE CARD
// ============================================================

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.isFavorite,
    required this.isVisited,
    required this.onFavorite,
    required this.onTap,
  });

  final ZiyaratPlace place;
  final bool isFavorite;
  final bool isVisited;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 132,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      _greenLight,
                      _green,
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        place.icon,
                        style: const TextStyle(
                          fontSize: 58,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Material(
                        color: const Color(0x33000000),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: onFavorite,
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite
                                ? const Color(0xFFFFD6D6)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (isVisited)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '✓ زرتُه',
                            style: TextStyle(
                              color: _green,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: const TextStyle(
                              color: _text,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _muted,
                          size: 15,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      place.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        height: 1.6,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _SmallTag(
                          icon: Icons.location_city_rounded,
                          text: place.cityName,
                        ),
                        _SmallTag(
                          icon: Icons.auto_stories_rounded,
                          text: place.categoryName,
                        ),
                        if (place.needsReview)
                          const _SmallTag(
                            icon: Icons.fact_check_outlined,
                            text: 'قيد المراجعة',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DETAILS SCREEN
// ============================================================

class ZiyaratDetailsScreen extends StatefulWidget {
  const ZiyaratDetailsScreen({
    super.key,
    required this.place,
    required this.initialFavorite,
    required this.initialVisited,
    required this.onFavoriteChanged,
    required this.onVisitedChanged,
  });

  final ZiyaratPlace place;
  final bool initialFavorite;
  final bool initialVisited;

  final ValueChanged<bool> onFavoriteChanged;
  final ValueChanged<bool> onVisitedChanged;

  @override
  State<ZiyaratDetailsScreen> createState() =>
      _ZiyaratDetailsScreenState();
}

class _ZiyaratDetailsScreenState
    extends State<ZiyaratDetailsScreen> {
  final FlutterTts _tts = FlutterTts();

  late bool _favorite;
  late bool _visited;

  bool _speaking = false;

  ZiyaratPlace get place => widget.place;

  @override
  void initState() {
    super.initState();

    _favorite = widget.initialFavorite;
    _visited = widget.initialVisited;

    _setupTts();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('ar-SA');
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _speaking = false);
      }
    });

    _tts.setCancelHandler(() {
      if (mounted) {
        setState(() => _speaking = false);
      }
    });

    _tts.setErrorHandler((_) {
      if (mounted) {
        setState(() => _speaking = false);
      }
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleStoryAudio() async {
    if (_speaking) {
      await _tts.stop();

      if (mounted) {
        setState(() => _speaking = false);
      }

      return;
    }

    final guidanceText = place.visitorGuidance
        .map(
          (item) =>
              '${item.title}. ${item.description}',
        )
        .join('. ');

    final narration = '''
${place.name}.

${place.shortDescription}

قصة المكان.

${place.story}

أهمية المكان.

${place.significance}

ماذا يفعل الزائر؟

$guidanceText
''';

    setState(() => _speaking = true);

    await _tts.speak(narration);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 275,
            pinned: true,
            backgroundColor: _green,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'المفضلة',
                onPressed: () {
                  setState(
                    () => _favorite = !_favorite,
                  );

                  widget.onFavoriteChanged(_favorite);
                },
                icon: Icon(
                  _favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _PlaceHero(place: place),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                20,
                16,
                38,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 27,
                      height: 1.3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SmallTag(
                        icon: Icons.location_city_rounded,
                        text: place.cityName,
                      ),
                      _SmallTag(
                        icon: Icons.category_outlined,
                        text: place.categoryName,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    place.shortDescription,
                    style: const TextStyle(
                      color: _muted,
                      height: 1.8,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: _speaking
                              ? Icons.stop_circle_outlined
                              : Icons.volume_up_outlined,
                          label: _speaking
                              ? 'إيقاف القصة'
                              : 'اسمعي القصة',
                          onPressed: _toggleStoryAudio,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _ActionButton(
                          icon: _visited
                              ? Icons.check_circle_rounded
                              : Icons
                                  .check_circle_outline_rounded,
                          label: _visited
                              ? 'تمت الزيارة'
                              : 'زرتُ المكان',
                          active: _visited,
                          onPressed: () {
                            setState(
                              () => _visited = !_visited,
                            );

                            widget.onVisitedChanged(
                              _visited,
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _DetailsSection(
                    emoji: '📖',
                    title: 'قصة المكان',
                    child: Text(
                      place.story,
                      style: _bodyStyle,
                    ),
                  ),

                  _DetailsSection(
                    emoji: '✨',
                    title: 'أهمية المكان',
                    child: Text(
                      place.significance,
                      style: _bodyStyle,
                    ),
                  ),

                  if (place.evidence.isNotEmpty)
                    _DetailsSection(
                      emoji: '📜',
                      title: 'الدليل والمصادر',
                      child: Column(
                        children: [
                          for (int index = 0;
                              index <
                                  place.evidence.length;
                              index++) ...[
                            _EvidenceBox(
                              evidence:
                                  place.evidence[index],
                            ),
                            if (index <
                                place.evidence.length - 1)
                              const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),

                  if (place.visitorGuidance.isNotEmpty)
                    _DetailsSection(
                      emoji: '🤲',
                      title: 'ماذا يفعل الزائر؟',
                      child: Column(
                        children: place.visitorGuidance
                            .map(
                              (guidance) =>
                                  _GuidanceItem(
                                guidance: guidance,
                              ),
                            )
                            .toList(),
                      ),
                    ),

                  if (place.warnings.isNotEmpty)
                    _DetailsSection(
                      emoji: '⚠️',
                      title: 'تنبيهات مهمة',
                      background:
                          const Color(0xFFFFF8E7),
                      child: Column(
                        children: place.warnings
                            .map(
                              (warning) => _BulletItem(
                                text: warning,
                                icon:
                                    Icons.info_outline_rounded,
                                iconColor:
                                    const Color(0xFF9C7414),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                  if (place.accessibilityInfo != null)
                    _DetailsSection(
                      emoji: '♿',
                      title: 'سهولة الوصول',
                      child: Text(
                        place.accessibilityInfo!,
                        style: _bodyStyle,
                      ),
                    ),

                  _DetailsSection(
                    emoji: '🗺️',
                    title: 'الموقع على الخريطة',
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.hasVerifiedCoordinates
                              ? 'يتوفر موقع موثق لهذا المزار.'
                              : 'لن تعرض رِفقة موقعًا تقريبيًا لهذا المزار. سيتم تفعيل الخريطة بعد اعتماد الإحداثيات الموثوقة.',
                          style: _bodyStyle,
                        ),
                        const SizedBox(height: 13),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                place.hasVerifiedCoordinates
                                    ? () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'ربط خريطة المزارات سيتم في خطوة الربط.',
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                            icon: const Icon(
                              Icons.map_outlined,
                            ),
                            label: Text(
                              place.hasVerifiedCoordinates
                                  ? 'اعرضي على الخريطة'
                                  : 'الموقع قيد التوثيق',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _DetailsSection(
                    emoji: '📚',
                    title: 'حالة المحتوى',
                    child: Text(
                      place.needsReview
                          ? 'هذا المحتوى موجود حاليًا ضمن قاعدة رِفقة، لكنه ما زال محددًا للمراجعة الدينية والتاريخية النهائية قبل الإصدار العام.'
                          : 'تم اعتماد ومراجعة محتوى هذا المكان.',
                      style: _bodyStyle,
                    ),
                  ),

                  const SizedBox(height: 2),

                  _buildAskRifqaCard(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAskRifqaCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFFFFE5A3),
            size: 32,
          ),
          const SizedBox(height: 9),
          const Text(
            'اسألي رِفقة عن هذا المكان',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'اسألي عن القصة، الدليل أو آداب الزيارة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD8E8E0),
              height: 1.6,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 13),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'هنربط اسألي رِفقة بالـ AI بعد تجهيز شاشة المحادثة.',
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor:
                  const Color(0xFFFFE5A3),
              foregroundColor: _green,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 12,
              ),
            ),
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
            ),
            label: const Text(
              'اسألي رِفقة',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COMPONENTS
// ============================================================

class _PlaceHero extends StatelessWidget {
  const _PlaceHero({
    required this.place,
  });

  final ZiyaratPlace place;

  @override
  Widget build(BuildContext context) {
    if (place.heroImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            place.heroImage!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _fallbackHero(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0xB0000000),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return _fallbackHero();
  }

  Widget _fallbackHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            _greenLight,
            _green,
          ],
        ),
      ),
      child: Center(
        child: Text(
          place.icon,
          style: const TextStyle(
            fontSize: 92,
          ),
        ),
      ),
    );
  }
}

class _CityButton extends StatelessWidget {
  const _CityButton({
    required this.title,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _green : Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 8,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(emoji),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : _text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(text),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _green,
      backgroundColor: Colors.white,
      side: const BorderSide(color: _border),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _text,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFE3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: _greenLight,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor:
            active ? Colors.white : _green,
        backgroundColor:
            active ? _green : Colors.white,
        side: const BorderSide(color: _green),
        padding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.emoji,
    required this.title,
    required this.child,
    this.background = Colors.white,
  });

  final String emoji;
  final String title;
  final Widget child;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _green,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EvidenceBox extends StatelessWidget {
  const _EvidenceBox({
    required this.evidence,
  });

  final ZiyaratEvidence evidence;

  @override
  Widget build(BuildContext context) {
    final bool isQuran =
        evidence.type == ZiyaratEvidenceType.quran;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isQuran
            ? const Color(0xFFF8F2E2)
            : const Color(0xFFF4F8F6),
        borderRadius: BorderRadius.circular(15),
        border: const Border(
          right: BorderSide(
            color: _gold,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            evidence.text,
            style: TextStyle(
              color: _text,
              height: 1.9,
              fontSize: isQuran ? 17 : 14,
              fontWeight: isQuran
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _evidenceSource(evidence),
            style: const TextStyle(
              color: _gold,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (evidence.authenticity != null) ...[
            const SizedBox(height: 4),
            Text(
              'الدرجة: ${evidence.authenticity}',
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
              ),
            ),
          ],
          if (evidence.note != null) ...[
            const SizedBox(height: 7),
            Text(
              evidence.note!,
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _evidenceSource(
    ZiyaratEvidence evidence,
  ) {
    if (evidence.reference == null ||
        evidence.reference!.trim().isEmpty) {
      return evidence.source;
    }

    return '${evidence.source} • ${evidence.reference}';
  }
}

class _GuidanceItem extends StatelessWidget {
  const _GuidanceItem({
    required this.guidance,
  });

  final ZiyaratVisitorGuidance guidance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: _greenLight,
              size: 19,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  guidance.title,
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  guidance.description,
                  style: const TextStyle(
                    color: _muted,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({
    required this.text,
    required this.icon,
    required this.iconColor,
  });

  final String text;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: _bodyStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(35),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.travel_explore_rounded,
              size: 58,
              color: _muted,
            ),
            SizedBox(height: 13),
            Text(
              'لم نجد مزارًا مطابقًا',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _text,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'جرّبي اسمًا آخر أو اختاري تصنيفًا مختلفًا.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const TextStyle _bodyStyle = TextStyle(
  color: _text,
  fontSize: 14,
  height: 1.9,
);