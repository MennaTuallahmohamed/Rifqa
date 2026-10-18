import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/markets/rifqa_markets_catalog.dart';
import 'widgets/rifqa_market_style.dart';

/// Only independently verified coordinates can appear as pins.
/// The city center is a map viewport, NOT a location assigned to a market.
class MarketsDirectoryMapScreen extends StatefulWidget {
  const MarketsDirectoryMapScreen({super.key, required this.city, required this.markets, required this.onOpenMarket});
  final RifqaCity city;
  final List<RifqaMarket> markets;
  final ValueChanged<RifqaMarket> onOpenMarket;

  @override
  State<MarketsDirectoryMapScreen> createState() => _MarketsDirectoryMapScreenState();
}

class _MarketsDirectoryMapScreenState extends State<MarketsDirectoryMapScreen> {
  final MapController _controller = MapController();
  late final List<RifqaMarket> _pinned = widget.markets.where((m) => m.hasCoordinates).toList();
  LatLng get _cityCenter => widget.city == RifqaCity.makkah
      ? const LatLng(21.4225, 39.8262) : const LatLng(24.4672, 39.6112);

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _showMarket(RifqaMarket m) {
    showModalBottomSheet<void>(context: context, showDragHandle: true,
      backgroundColor: MarketPalette.cream,
      builder: (c) => Directionality(textDirection: TextDirection.rtl, child: SafeArea(top: false,
        child: Padding(padding: const EdgeInsets.fromLTRB(18, 6, 18, 24), child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.shopping_bag_outlined, color: MarketPalette.emerald),
              const SizedBox(width: 8), Expanded(child: Text(m.name,
                style: const TextStyle(color: MarketPalette.ink, fontWeight: FontWeight.w900, fontSize: 17)))]),
            const SizedBox(height: 6), Text(m.area,
              style: const TextStyle(color: MarketPalette.muted, fontSize: 12)),
            const SizedBox(height: 12), Text(m.description,
              style: const TextStyle(color: MarketPalette.ink, height: 1.6)),
            const SizedBox(height: 17),
            Row(children: [Expanded(child: FilledButton.icon(
              onPressed: () { Navigator.pop(c); widget.onOpenMarket(m); },
              icon: const Icon(Icons.info_outline_rounded), label: const Text('التفاصيل'),
              style: FilledButton.styleFrom(backgroundColor: MarketPalette.evergreen,
                foregroundColor: Colors.white))), const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                onPressed: () async { await RifqaMarketsLinks.mapSearch(m); },
                icon: const Icon(Icons.search_rounded), label: const Text('بحث الخرائط')))],
            ),
          ],
        )))),
    );
  }

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    body: Stack(children: [
      Positioned.fill(child: FlutterMap(
        mapController: _controller,
        options: MapOptions(initialCenter: _cityCenter, initialZoom: 12),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.rafeek', maxZoom: 19),
          MarkerLayer(markers: _pinned.map((m) => Marker(
            point: LatLng(m.latitude!, m.longitude!), width: 56, height: 61,
            child: InkWell(onTap: () => _showMarket(m),
              child: Container(alignment: Alignment.center,
                decoration: const BoxDecoration(color: MarketPalette.evergreen, shape: BoxShape.circle),
                child: const Icon(Icons.shopping_bag_rounded, color: MarketPalette.gold, size: 23))),
          )).toList()),
          const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
        ],
      )),
      Positioned(top: 0, right: 0, left: 0, child: SafeArea(bottom: false,
        child: Padding(padding: const EdgeInsets.all(14), child: MarketSoftCard(
          child: Row(children: [
            IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_forward_rounded)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('خريطة الأسواق', style: TextStyle(color: MarketPalette.ink, fontWeight: FontWeight.w900, fontSize: 17)),
              Text(widget.city.title, style: const TextStyle(fontSize: 11.5, color: MarketPalette.muted)),
            ])),
            MarketPill(label: '${_pinned.length} موقع مؤكد', icon: Icons.pin_drop_outlined),
          ]),
        )),
      )),
      Positioned(top: 130, left: 15, child: Column(children: [
        FloatingActionButton.small(heroTag: 'marketCity', backgroundColor: Colors.white,
          onPressed: () => _controller.move(_cityCenter, 12),
          child: const Icon(Icons.center_focus_strong_rounded, color: MarketPalette.evergreen)),
      ])),
      Positioned(left: 12, right: 12, bottom: 22, child: MarketSoftCard(child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_pinned.isEmpty ? 'لسه مفيش إحداثيات أسواق معتمدة' : 'الأسواق على الخريطة',
            style: const TextStyle(color: MarketPalette.ink, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(_pinned.isEmpty
              ? 'الخريطة تعرض المدينة فقط. اختاري سوقًا لفتح بحث باسمه في Google Maps؛ مش هنحط دبوس تقريبي.'
              : 'اضغطي على أي علامة مؤكدة لفتح تفاصيل السوق.',
            style: const TextStyle(color: MarketPalette.muted, fontSize: 11.5, height: 1.5)),
          const SizedBox(height: 12),
          SizedBox(height: 54, child: ListView.separated(
            scrollDirection: Axis.horizontal, itemCount: widget.markets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (_, i) {
              final m = widget.markets[i];
              return ActionChip(label: Text(m.name, style: const TextStyle(fontSize: 11)),
                avatar: const Icon(Icons.storefront_outlined, size: 17, color: MarketPalette.emerald),
                onPressed: () => _showMarket(m));
            },
          )),
        ],
      ))),
    ]),
  ));
}
