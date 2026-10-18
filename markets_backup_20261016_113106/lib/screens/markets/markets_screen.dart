import 'package:flutter/material.dart';

import '../../models/markets/market_place.dart';
import '../../services/markets/markets_location_service.dart';
import '../../services/markets/markets_repository.dart';

import 'market_details_screen.dart';
import 'markets_map_screen.dart';
import 'shopping_list_screen.dart';

import 'widgets/city_selector.dart';
import 'widgets/market_card.dart';
import 'widgets/market_category_chip.dart';
import 'widgets/market_filters.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  static const Color _green = Color(0xFF176B52);
  static const Color _greenDark = Color(0xFF0D4D3B);
  static const Color _gold = Color(0xFFD5AE5B);
  static const Color _background = Color(0xFFFAF7F0);
  static const Color _ink = Color(0xFF17322A);
  static const Color _muted = Color(0xFF6B7B74);
  static const Color _border = Color(0xFFEDE7D6);

  final MarketsRepository _repository = const MarketsRepository();

  final MarketsLocationService _locationService =
      MarketsLocationService();

  final TextEditingController _searchController =
      TextEditingController();

  MarketCity _selectedCity = MarketCity.makkah;
  MarketCategory? _selectedCategory;

  bool _nearMe = false;
  bool _openNow = false;
  bool _accessibleOnly = false;
  bool _gettingLocation = false;

  final Set<String> _favorites = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    _locationService.dispose();
    super.dispose();
  }

  List<MarketPlace> get _filteredMarkets {
    List<MarketPlace> result =
        _repository.byCity(_selectedCity);

    final query =
        _searchController.text.trim();

    if (query.isNotEmpty) {
      result = _repository.search(
        city: _selectedCity,
        query: query,
      );
    }

    if (_selectedCategory != null) {
      result = result
          .where(
            (market) =>
                market.category ==
                _selectedCategory,
          )
          .toList();
    }

    if (_accessibleOnly) {
      result = result
          .where(
            (market) =>
                market.accessibilityVerified &&
                market.hasWheelchairAccess,
          )
          .toList();
    }

    if (_nearMe &&
        _locationService.hasLocation) {
      result =
          _locationService.sortNearest(
        result,
      );
    }

    // "Open now" is intentionally not applied yet.
    //
    // openingHours is currently display text only.
    // We should not infer whether a market is open
    // until verified structured opening-hours data
    // is available.

    return result;
  }

  void _changeCity(MarketCity city) {
    setState(() {
      _selectedCity = city;
      _selectedCategory = null;
      _nearMe = false;
      _openNow = false;
      _accessibleOnly = false;
      _searchController.clear();
    });
  }

  void _toggleFavorite(
    MarketPlace market,
  ) {
    setState(() {
      if (_favorites.contains(market.id)) {
        _favorites.remove(market.id);
      } else {
        _favorites.add(market.id);
      }
    });
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _changeNearMe(
    bool value,
  ) async {
    if (!value) {
      setState(() {
        _nearMe = false;
      });

      return;
    }

    if (_gettingLocation) {
      return;
    }

    setState(() {
      _gettingLocation = true;
    });

    final success =
        await _locationService
            .requestCurrentLocation();

    if (!mounted) {
      return;
    }

    if (!success) {
      setState(() {
        _gettingLocation = false;
        _nearMe = false;
      });

      _showMessage(
        'تعذّر تحديد موقعك. تأكدي من تشغيل GPS ومنح التطبيق إذن الموقع.',
      );

      return;
    }

    final marketsWithCoordinates =
        _repository
            .byCity(_selectedCity)
            .where(
              (market) =>
                  market.hasCoordinates,
            )
            .length;

    setState(() {
      _gettingLocation = false;
      _nearMe = true;
    });

    if (marketsWithCoordinates == 0) {
      _showMessage(
        'تم تحديد موقعك، لكن لا توجد أسواق بإحداثيات موثقة في هذه المدينة حتى الآن.',
      );

      return;
    }

    final current =
        _locationService.location.value;

    final accuracy =
        current?.accuracy.round();

    if (accuracy == null) {
      _showMessage(
        'تم ترتيب الأسواق من الأقرب إلى الأبعد حسب موقعك الحالي.',
      );
    } else {
      _showMessage(
        'تم ترتيب الأسواق من الأقرب إلى الأبعد • دقة GPS تقريبًا ±$accuracy م',
      );
    }
  }

  void _changeOpenNow(
    bool value,
  ) {
    if (value) {
      _showMessage(
        'ميزة مفتوح الآن ستعمل بعد إضافة مواعيد عمل موثقة ومنظمة.',
      );
    }

    setState(() {
      _openNow = false;
    });
  }

  void _openDetails(
    MarketPlace market,
  ) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) =>
            MarketDetailsScreen(
          market: market,
          isFavorite:
              _favorites.contains(
            market.id,
          ),
          onFavorite: () {
            _toggleFavorite(market);
          },
          onDirections:
              market.hasCoordinates
                  ? () {
                      _openDirections(
                        market,
                      );
                    }
                  : null,
        ),
      ),
    )
        .then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _openDirections(
    MarketPlace market,
  ) {
    if (!market.hasCoordinates) {
      _showMessage(
        'الاتجاهات غير متاحة قبل التحقق من موقع هذا المكان.',
      );

      return;
    }

    _showMessage(
      'تم تجهيز موقع ${market.name}. ربط تطبيق الخرائط الخارجي سيتم في خطوة الربط.',
    );
  }

  void _openMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MarketsMapScreen(
          city: _selectedCity,
          markets: _repository
              .byCity(
            _selectedCity,
          ),
          onMarketTap: _openDetails,
        ),
      ),
    );
  }

  void _openShoppingList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const ShoppingListScreen(),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final markets =
        _filteredMarkets;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: _background,
        elevation: 0,
        foregroundColor: _greenDark,
        centerTitle: true,
        title: const Text(
          'الأسواق',
          style: TextStyle(
            color: _ink,
            fontSize: 21,
            fontWeight:
                FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'قائمة التسوق',
            onPressed:
                _openShoppingList,
            icon: const Icon(
              Icons
                  .shopping_bag_outlined,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: _green,
          onRefresh: () async {
            setState(() {});
          },
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(
              parent:
                  BouncingScrollPhysics(),
            ),
            padding:
                const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              36,
            ),
            children: [
              _buildHero(),

              const SizedBox(
                height: 22,
              ),

              MarketCitySelector(
                selectedCity:
                    _selectedCity,
                onChanged:
                    _changeCity,
              ),

              const SizedBox(
                height: 24,
              ),

              _buildSearch(),

              const SizedBox(
                height: 16,
              ),

              _buildQuickActions(),

              const SizedBox(
                height: 24,
              ),

              _sectionTitle(
                icon: Icons
                    .category_outlined,
                title:
                    'ماذا تريدين شراءه؟',
                subtitle:
                    'اختاري التصنيف المناسب',
              ),

              const SizedBox(
                height: 12,
              ),

              MarketCategoriesBar(
                selectedCategory:
                    _selectedCategory,
                onChanged:
                    (category) {
                  setState(() {
                    _selectedCategory =
                        category;
                  });
                },
              ),

              const SizedBox(
                height: 22,
              ),

              _sectionTitle(
                icon:
                    Icons.tune_rounded,
                title:
                    'فلترة النتائج',
                subtitle:
                    'وصلي للمكان الأنسب بسهولة',
              ),

              const SizedBox(
                height: 12,
              ),

              MarketFilters(
                nearMe: _nearMe,
                openNow: _openNow,
                accessibleOnly:
                    _accessibleOnly,
                onNearMeChanged:
                    _changeNearMe,
                onOpenNowChanged:
                    _changeOpenNow,
                onAccessibleChanged:
                    (value) {
                  setState(() {
                    _accessibleOnly =
                        value;
                  });
                },
              ),

              if (_gettingLocation) ...[
                const SizedBox(
                  height: 12,
                ),
                _buildLocationLoading(),
              ],

              if (_nearMe &&
                  _locationService
                      .hasLocation) ...[
                const SizedBox(
                  height: 12,
                ),
                _buildLocationActive(),
              ],

              const SizedBox(
                height: 24,
              ),

              _buildResultsHeader(
                markets.length,
              ),

              const SizedBox(
                height: 13,
              ),

              if (markets.isEmpty)
                _buildEmptyState()
              else
                ...markets.map(
                  (market) {
                    final distance =
                        _nearMe
                            ? _locationService
                                .distanceToMarket(
                                market,
                              )
                            : null;

                    return Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        bottom: 14,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .stretch,
                        children: [
                          if (distance !=
                              null) ...[
                            _buildDistanceBadge(
                              distance,
                            ),
                            const SizedBox(
                              height: 7,
                            ),
                          ],
                          MarketCard(
                            market: market,
                            isFavorite:
                                _favorites
                                    .contains(
                              market.id,
                            ),
                            onFavorite:
                                () {
                              _toggleFavorite(
                                market,
                              );
                            },
                            onDetails:
                                () {
                              _openDetails(
                                market,
                              );
                            },
                            onDirections:
                                () {
                              _openDirections(
                                market,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationLoading() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
      ),
      child: const Row(
        mainAxisAlignment:
            MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              'جارٍ تحديد موقعك الحالي...',
              textAlign:
                  TextAlign.right,
              style: TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 12),
          SizedBox(
            width: 18,
            height: 18,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
              color: _green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationActive() {
    final accuracy =
        _locationService
            .location
            .value
            ?.accuracy
            .round();

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color:
            _green.withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              _green.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip:
                'إلغاء الأقرب لي',
            visualDensity:
                VisualDensity.compact,
            onPressed: () {
              _changeNearMe(false);
            },
            icon: const Icon(
              Icons.close_rounded,
              color: _muted,
              size: 19,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              const Text(
                'الترتيب حسب موقعك الحالي',
                textAlign:
                    TextAlign.right,
                style: TextStyle(
                  color: _greenDark,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              if (accuracy != null)
                Text(
                  'دقة الموقع تقريبًا ±$accuracy م',
                  textAlign:
                      TextAlign.right,
                  style:
                      const TextStyle(
                    color: _muted,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 9),
          const Icon(
            Icons
                .my_location_rounded,
            color: _green,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceBadge(
    double distance,
  ) {
    final formatted =
        _locationService
            .formatDistance(
      distance,
    );

    return Align(
      alignment:
          Alignment.centerRight,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color:
              _green.withValues(
            alpha: 0.08,
          ),
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          border: Border.all(
            color:
                _green.withValues(
              alpha: 0.15,
            ),
          ),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Text(
              formatted,
              style:
                  const TextStyle(
                color: _greenDark,
                fontSize: 11,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            const Icon(
              Icons
                  .near_me_rounded,
              color: _green,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.topRight,
          end:
              Alignment.bottomLeft,
          colors: [
            _green,
            _greenDark,
          ],
        ),
        borderRadius:
            BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color:
                _greenDark.withValues(
              alpha: 0.18,
            ),
            blurRadius: 20,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration:
                BoxDecoration(
              color:
                  Colors.white.withValues(
                alpha: 0.12,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    _gold.withValues(
                  alpha: 0.65,
                ),
              ),
            ),
            alignment:
                Alignment.center,
            child: const Text(
              '🛍️',
              style: TextStyle(
                fontSize: 36,
              ),
            ),
          ),
          const SizedBox(
            width: 15,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  'دليل التسوق',
                  textAlign:
                      TextAlign.right,
                  style: TextStyle(
                    color:
                        Colors.white,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'اكتشفي الأسواق وما تحتاجينه في مكة والمدينة بطريقة منظمة.',
                  textAlign:
                      TextAlign.right,
                  style: TextStyle(
                    color:
                        Color(
                      0xFFE7F1ED,
                    ),
                    fontSize: 12.5,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(19),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller:
            _searchController,
        textAlign:
            TextAlign.right,
        textInputAction:
            TextInputAction.search,
        onChanged: (_) {
          setState(() {});
        },
        decoration:
            InputDecoration(
          hintText:
              'ابحثي عن سوق، متجر أو منتج...',
          hintStyle:
              const TextStyle(
            color: _muted,
            fontSize: 12.5,
          ),
          prefixIcon:
              _searchController
                      .text
                      .isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController
                            .clear();

                        setState(
                          () {},
                        );
                      },
                      icon:
                          const Icon(
                        Icons
                            .close_rounded,
                        color: _muted,
                      ),
                    ),
          suffixIcon:
              const Icon(
            Icons.search_rounded,
            color: _green,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets
                  .symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons
                .checklist_rounded,
            title:
                'قائمة مشترياتي',
            subtitle:
                'رتّبي احتياجاتك',
            onTap:
                _openShoppingList,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _ActionCard(
            icon:
                Icons.map_rounded,
            title: 'الخريطة',
            subtitle:
                'شاهدي المواقع',
            onTap: _openMap,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                title,
                textAlign:
                    TextAlign.right,
                style:
                    const TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                subtitle,
                textAlign:
                    TextAlign.right,
                style:
                    const TextStyle(
                  color: _muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: 9,
        ),
        Container(
          width: 38,
          height: 38,
          decoration:
              BoxDecoration(
            color:
                _green.withValues(
              alpha: 0.08,
            ),
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
          child: Icon(
            icon,
            color: _green,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader(
    int count,
  ) {
    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration:
              BoxDecoration(
            color:
                _green.withValues(
              alpha: 0.08,
            ),
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
          child: Text(
            '$count',
            style:
                const TextStyle(
              color: _green,
              fontSize: 12,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ),
        const Spacer(),
        Text(
          _nearMe
              ? 'الأقرب إليك'
              : 'أماكن التسوق',
          style:
              const TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final hasFilters =
        _searchController.text
                .trim()
                .isNotEmpty ||
            _selectedCategory !=
                null ||
            _accessibleOnly;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 36,
        horizontal: 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        children: [
          Text(
            hasFilters
                ? '🔎'
                : '🛍️',
            style:
                const TextStyle(
              fontSize: 44,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            hasFilters
                ? 'لا توجد نتائج بهذه الاختيارات'
                : 'بيانات الأسواق قيد التجهيز',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            hasFilters
                ? 'جرّبي إزالة بعض الفلاتر أو البحث بكلمة مختلفة.'
                : 'الواجهة جاهزة، وسنضيف أماكن حقيقية وموثقة لمكة والمدينة بدل استخدام بيانات تجريبية.',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color: _muted,
              fontSize: 12.5,
              height: 1.7,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(
              height: 16,
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController
                      .clear();

                  _selectedCategory =
                      null;

                  _accessibleOnly =
                      false;
                });
              },
              icon: const Icon(
                Icons
                    .restart_alt_rounded,
              ),
              label:
                  const Text(
                'إلغاء الفلاتر',
              ),
              style:
                  OutlinedButton
                      .styleFrom(
                foregroundColor:
                    _green,
                side: BorderSide(
                  color:
                      _green.withValues(
                    alpha: 0.35,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionCard
    extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const Color _green =
      Color(0xFF176B52);

  static const Color _ink =
      Color(0xFF17322A);

  static const Color _muted =
      Color(0xFF6B7B74);

  static const Color _border =
      Color(0xFFEDE7D6);

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(19),
        child: Container(
          padding:
              const EdgeInsets.all(
            14,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              19,
            ),
            border: Border.all(
              color: _border,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(
                  color:
                      _green.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color: _green,
                  size: 22,
                ),
              ),
              const SizedBox(
                height: 9,
              ),
              Text(
                title,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                subtitle,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color: _muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}