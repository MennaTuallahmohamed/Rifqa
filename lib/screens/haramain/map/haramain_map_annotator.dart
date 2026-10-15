import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../haramain_live_models.dart';
import '../haramain_live_store.dart';
import '../haramain_marker_factory.dart';
import '../theme/haramain_ui.dart';
import '../../../models/haramain/haramain_map_demo_models.dart';

class HaramainMapAnnotator {
  HaramainMapAnnotator();

  final Map<String, String> symbolToPoi = {};
  final Set<String> images = {};
  int seq = 0;

  Future<String> _icon(
    MapLibreMapController map,
    String emoji,
    Color color,
    String? label,
    bool selected,
  ) async {
    final name = HaramainMarkers.nameFor(emoji, color, label, selected);
    if (!images.contains(name)) {
      await map.addImage(
        name,
        await HaramainMarkers.badge(
          emoji: emoji,
          color: color,
          label: label,
          selected: selected,
        ),
      );
      images.add(name);
    }
    return name;
  }

  Future<void> sync({
    required MapLibreMapController map,
    required List<HlPoi> pois,
    required HaramainLiveStore store,
    required HaramainSite? site,
    required HlPoi? selected,
    required HlRoute? route,
  }) async {
    if (site == null) return;
    final token = ++seq;
    final opts = <SymbolOptions>[];
    final ids = <String>[];
    for (final p in pois) {
      opts.add(SymbolOptions(
        geometry: p.position,
        iconImage: await _icon(
            map, p.category.emoji, p.category.color, p.gateNumber, selected?.id == p.id),
        iconSize: HmUi.iconSize,
        iconAnchor: 'bottom',
      ));
      ids.add(p.id);
    }
    for (final pin in store.pinsFor(site)) {
      opts.add(SymbolOptions(
        geometry: pin.position,
        iconImage: await _icon(map, pin.kind.emoji, const Color(0xFFD94F4F),
            null, selected?.id == pin.id),
        iconSize: HmUi.iconSize,
        iconAnchor: 'bottom',
      ));
      ids.add(pin.id);
    }
    if (token != seq) return;

    await map.clearSymbols();
    await map.clearLines();
    symbolToPoi.clear();
    final symbols = await map.addSymbols(opts);
    for (var i = 0; i < symbols.length && i < ids.length; i++) {
      symbolToPoi[symbols[i].id] = ids[i];
    }

    final r = route;
    if (r != null) {
      await map.addLine(LineOptions(
          geometry: r.points,
          lineColor: '#FFFFFF',
          lineWidth: 11,
          lineJoin: 'round'));
      await map.addLine(LineOptions(
          geometry: r.points,
          lineColor: '#0B6B54',
          lineWidth: 7,
          lineJoin: 'round'));
    }
  }
}
