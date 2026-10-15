import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../models/markets/market_place.dart';

const _emerald = Color(0xFF075B4A);
const _ivory = Color(0xFFF7F4ED);

const _streetStyle =
    'https://tiles.openfreemap.org/styles/positron';

const _satelliteStyle =
    '{"version":8,"sources":{"img":{"type":"raster","tiles":["https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"],"tileSize":256,"maxzoom":19,"attribution":"Esri World Imagery"}},"layers":[{"id":"img","type":"raster","source":"img"}]}';

class MarketsMapScreen extends StatefulWidget {
  const MarketsMapScreen({
    super.key,
    required this.city,
    required this.markets,
    this.onMarketTap,
  });

  final MarketCity city;
  final List<MarketPlace> markets;
  final ValueChanged<MarketPlace>? onMarketTap;

  @override
  State<MarketsMapScreen> createState() =>
      _MarketsMapScreenState();
}

class _MarketsMapScreenState
    extends State<MarketsMapScreen> {
  MapLibreMapController? _map;

  bool _satellite = false;
  bool _styleReady = false;

  final Map<String, MarketPlace> _symbolMarkets = {};

  List<MarketPlace> get _marketsWithCoordinates {
    return widget.markets
        .where(
          (market) =>
              market.verificationStatus ==
                  MarketVerificationStatus.verified &&
              market.hasCoordinates,
        )
        .toList();
  }

  LatLng get _cityCenter {
    switch (widget.city) {
      case MarketCity.makkah:
        return const LatLng(
          21.4225,
          39.8262,
        );

      case MarketCity.madinah:
        return const LatLng(
          24.4672,
          39.6112,
        );
    }
  }

  double get _initialZoom {
    return 11.5;
  }

  String get _cityName {
    switch (widget.city) {
      case MarketCity.makkah:
        return 'مكة المكرمة';

      case MarketCity.madinah:
        return 'المدينة المنورة';
    }
  }

  @override
  void dispose() {
    _map = null;
    super.dispose();
  }

  Future<void> _onStyleLoaded() async {
    _styleReady = true;

    await _addMarketMarkers();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addMarketMarkers() async {
    final controller = _map;

    if (controller == null || !_styleReady) {
      return;
    }

    _symbolMarkets.clear();

    await controller.clearSymbols();

    final markets = _marketsWithCoordinates;

    if (markets.isEmpty) {
      return;
    }

    for (final market in markets) {
      final symbol = await controller.addSymbol(
        SymbolOptions(
          geometry: LatLng(
            market.latitude!,
            market.longitude!,
          ),
          iconImage: 'marker-15',
          iconSize: 1.8,
          iconAnchor: 'bottom',
          textField: market.name,
          textSize: 12,
          textOffset: const Offset(0, 1.8),
          textColor: '#17322A',
          textHaloColor: '#FFFFFF',
          textHaloWidth: 2,
        ),
      );

      _symbolMarkets[symbol.id] = market;
    }
  }

  void _onSymbolTapped(Symbol symbol) {
    final market = _symbolMarkets[symbol.id];

    if (market == null) {
      return;
    }

    _showMarketSheet(market);
  }

  Future<void> _focusMarket(
    MarketPlace market,
  ) async {
    if (!market.hasCoordinates) {
      return;
    }

    await _map?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(
          market.latitude!,
          market.longitude!,
        ),
        16,
      ),
      duration: const Duration(
        milliseconds: 600,
      ),
    );
  }

  void _showMarketSheet(
    MarketPlace market,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                4,
                18,
                18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFE3F1EC,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                        child: Text(
                          market.categoryEmoji,
                          style: const TextStyle(
                            fontSize: 25,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              market.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              market.categoryName,
                              style: const TextStyle(
                                color:
                                    Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  Text(
                    market.shortDescription,
                    style: const TextStyle(
                      height: 1.5,
                      fontSize: 13,
                    ),
                  ),
                  if (market.address != null &&
                      market.address!
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(
                      height: 12,
                    ),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: _emerald,
                          size: 20,
                        ),
                        const SizedBox(
                          width: 7,
                        ),
                        Expanded(
                          child: Text(
                            market.address!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (market.openingHours != null &&
                      market.openingHours!
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: _emerald,
                          size: 19,
                        ),
                        const SizedBox(
                          width: 7,
                        ),
                        Expanded(
                          child: Text(
                            market.openingHours!,
                            style: const TextStyle(
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style:
                              FilledButton.styleFrom(
                            backgroundColor:
                                _emerald,
                            minimumSize:
                                const Size.fromHeight(
                              48,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                            );

                            widget.onMarketTap?.call(
                              market,
                            );
                          },
                          icon: const Icon(
                            Icons.info_outline_rounded,
                          ),
                          label: const Text(
                            'التفاصيل',
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      IconButton.filledTonal(
                        tooltip:
                            'إظهار على الخريطة',
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                          );

                          _focusMarket(
                            market,
                          );
                        },
                        icon: const Icon(
                          Icons.center_focus_strong_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleMapStyle() async {
    setState(() {
      _satellite = !_satellite;
      _styleReady = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final markets = _marketsWithCoordinates;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _ivory,
        body: Stack(
          children: [
            Positioned.fill(
              child: MapLibreMap(
                styleString: _satellite
                    ? _satelliteStyle
                    : _streetStyle,
                initialCameraPosition:
                    CameraPosition(
                  target: _cityCenter,
                  zoom: _initialZoom,
                ),
                minMaxZoomPreference:
                    const MinMaxZoomPreference(
                  8,
                  20,
                ),
                compassEnabled: false,
                trackCameraPosition: true,
                onMapCreated: (
                  controller,
                ) {
                  _map = controller;

                  controller.onSymbolTapped.add(
                    _onSymbolTapped,
                  );
                },
                onStyleLoadedCallback:
                    _onStyleLoaded,
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(),
            ),

            Positioned(
              left: 14,
              top:
                  MediaQuery.of(context)
                          .padding
                          .top +
                      105,
              child: Column(
                children: [
                  _mapButton(
                    icon: _satellite
                        ? Icons.map_outlined
                        : Icons
                            .satellite_alt_rounded,
                    tooltip: _satellite
                        ? 'الخريطة العادية'
                        : 'القمر الصناعي',
                    onTap: _toggleMapStyle,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _mapButton(
                    icon:
                        Icons.location_city_rounded,
                    tooltip:
                        'عرض المدينة',
                    onTap: () {
                      _map?.animateCamera(
                        CameraUpdate
                            .newLatLngZoom(
                          _cityCenter,
                          _initialZoom,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            if (!_styleReady)
              const Positioned.fill(
                child: ColoredBox(
                  color: _ivory,
                  child: Center(
                    child:
                        CircularProgressIndicator(
                      color: _emerald,
                    ),
                  ),
                ),
              ),

            if (_styleReady &&
                markets.isEmpty)
              Positioned(
                left: 18,
                right: 18,
                bottom: 28,
                child: _emptyCoordinatesCard(),
              ),

            if (_styleReady &&
                markets.isNotEmpty)
              Positioned(
                left: 12,
                right: 12,
                bottom: 14,
                child: _marketsBar(
                  markets,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final top =
        MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        top + 8,
        12,
        14,
      ),
      decoration: const BoxDecoration(
        color: _emerald,
        borderRadius:
            BorderRadius.vertical(
          bottom: Radius.circular(
            24,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.maybePop(
                context,
              );
            },
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(
            width: 4,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'خريطة الأسواق',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                Text(
                  _cityName,
                  style: const TextStyle(
                    color:
                        Color(0xFFD8E9E5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(
                alpha: 0.15,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Text(
              '${_marketsWithCoordinates.length} موقع',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 5,
      shape: const CircleBorder(),
      color: Colors.white,
      child: InkWell(
        customBorder:
            const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              icon,
              color: _emerald,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyCoordinatesCard() {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x22000000,
            ),
            blurRadius: 18,
            offset: Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.verified_outlined,
            color: _emerald,
          ),
          SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              'لا توجد مواقع موثقة بإحداثيات في هذه المدينة حتى الآن.',
              style: TextStyle(
                fontWeight:
                    FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _marketsBar(
    List<MarketPlace> markets,
  ) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        itemCount: markets.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          width: 8,
        ),
        itemBuilder: (
          context,
          index,
        ) {
          final market =
              markets[index];

          return InkWell(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            onTap: () async {
              await _focusMarket(
                market,
              );

              if (mounted) {
                _showMarketSheet(
                  market,
                );
              }
            },
            child: Container(
              width: 220,
              padding:
                  const EdgeInsets.all(
                12,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                boxShadow: const [
                  BoxShadow(
                    color:
                        Color(
                      0x22000000,
                    ),
                    blurRadius: 12,
                    offset:
                        Offset(
                      0,
                      5,
                    ),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment:
                        Alignment.center,
                    decoration:
                        BoxDecoration(
                      color: const Color(
                        0xFFE3F1EC,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                    child: Text(
                      market
                          .categoryEmoji,
                      style:
                          const TextStyle(
                        fontSize: 23,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          market.name,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight
                                    .w900,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          market
                              .categoryName,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color: Colors
                                .black54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}