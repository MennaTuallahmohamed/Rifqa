import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../services/haramain/haramain_connectivity_service.dart';
import '../controllers/haramain_controller.dart';
import '../haramain_live_models.dart';
import '../haramain_marker_factory.dart';

/// Owns every call into [MapLibreMapController].
///
/// This exists for three concrete reasons:
///
///  1. **No rebuild storms.** The MapLibre canvas widget is built once and
///     reads imperative commands from here. Changing a filter or a preference
///     never rebuilds the platform view; it only re-syncs annotations.
///  2. **Bounded concurrency.** Every asynchronous MapLibre operation goes
///     through a monotonic token, so a burst of taps cannot interleave two
///     `clearSymbols`/`addSymbols` sequences and leave orphaned symbols.
///  3. **Connectivity evidence.** Tile successes/failures feed the
///     connectivity service, which is the honest source for the offline
///     banner. We never guess.
class HaramainMapCoordinator {
  HaramainMapCoordinator({
    required this.connectivity,
    required this.highContrast,
  });

  final HaramainConnectivityService connectivity;
  final bool Function() highContrast;

  MapLibreMapController? _map;
  bool _styleReady = false;

  /// Images already uploaded for the current style.
  final Set<String> _images = {};

  /// symbol id -> POI / pin id, so a marker tap resolves to real data.
  final Map<String, String> _symbolToId = {};

  /// Guards against overlapping syncs. Only the newest token may commit.
  int _syncToken = 0;

  /// Last applied snapshot, so identical snapshots are free.
  HmMapSnapshot _applied = HmMapSnapshot.empty;

  /// Throttles "follow me" camera moves; GPS can fire several times a second.
  DateTime _lastCameraMove = DateTime.fromMillisecondsSinceEpoch(0);
  bool _cameraMoveScheduled = false;

  bool get styleReady => _styleReady;

  MapLibreMapController? get controller => _map;

  void attach(MapLibreMapController controller) {
    _map = controller;
  }

  void detach() {
    _map = null;
  }

  /// Called on style load. Images are style-scoped, so the cache resets.
  Future<void> onStyleLoaded() async {
    _styleReady = true;
    _images.clear();
    _symbolToId.clear();
    connectivity.reportStyleLoaded();
    try {
      // Gate POIs are dense; let MapLibre place them without dropping them.
      await _map?.setSymbolIconAllowOverlap(true);
      await _map?.setSymbolIconIgnorePlacement(false);
    } catch (_) {
      // Older platform versions may not expose these; harmless.
    }
    // Force a full re-apply because the previous symbols died with the style.
    _applied = HmMapSnapshot.empty;
  }

  void onStyleFailed() {
    _styleReady = false;
    connectivity.reportStyleFailure();
  }

  /// The tile host changed, so previous connectivity evidence is stale.
  void onStyleHostChanged() {
    _images.clear();
    _symbolToId.clear();
    _applied = HmMapSnapshot.empty;
    connectivity.onStyleHostChanged();
  }

  /// Re-applies annotations only when the snapshot actually changed.
  Future<void> apply(HmMapSnapshot snapshot) async {
    if (!_styleReady || _map == null) return;
    if (snapshot == _applied) return;
    _applied = snapshot;
    final token = ++_syncToken;

    final symbols = <SymbolOptions>[];
    final ids = <String>[];

    for (final poi in snapshot.pois) {
      symbols.add(SymbolOptions(
        geometry: poi.position,
        iconImage: await _icon(
          emoji: poi.emoji,
          color: poi.category.color,
          label: poi.gateNumber,
          selected: snapshot.selected?.id == poi.id,
        ),
        iconAnchor: 'bottom',
      ));
      ids.add(poi.id);
    }

    for (final pin in snapshot.pins) {
      symbols.add(SymbolOptions(
        geometry: pin.position,
        iconImage: await _icon(
          emoji: pin.kind.emoji,
          color: _pinColor,
          label: null,
          selected: snapshot.selected?.id == pin.id,
        ),
        iconAnchor: 'bottom',
      ));
      ids.add(pin.id);
    }

    // A newer sync started while we awaited icon rasterisation: abandon.
    if (token != _syncToken) return;

    final map = _map;
    if (map == null) return;

    try {
      await map.clearSymbols();
      await map.clearLines();
      _symbolToId.clear();

      if (symbols.isNotEmpty) {
        final added = await map.addSymbols(symbols);
        for (var i = 0; i < added.length && i < ids.length; i++) {
          _symbolToId[added[i].id] = ids[i];
        }
      }

      await _drawRoute(map, snapshot.route);

      } catch (e) {
      // Never let a MapLibre error crash the screen.
      debugPrint('HaramainMapCoordinator.sync failed: $e');
    }
  }

  Future<void> _drawRoute(
    MapLibreMapController map,
    HlRoute? route,
  ) async {
    // The route reaching this method is only ever a verified one:
    // HaramainController.planRoute produces it via HaramainNavSafety, which
    // only accepts VERIFIED_ROUTE edges flagged navigationAllowed.
    final points = route?.points;
    if (points == null || points.length < 2) return;

    try {
      // Casing first so the line reads on both satellite and street styles.
      await map.addLine(LineOptions(
        geometry: points,
        lineColor: '#FFFFFF',
        lineWidth: 12,
        lineJoin: 'round',
        lineOpacity: 0.9,
      ));
      await map.addLine(LineOptions(
        geometry: points,
        lineColor: _routeColor,
        lineWidth: 7,
        lineJoin: 'round',
      ));
    } catch (e) {
      debugPrint('HaramainMapCoordinator.route draw failed: $e');
    }
  }

  String get _routeColor => highContrast() ? '#000000' : '#0B6B54';

  Color get _pinColor => const Color(0xFFD94F4F);

  Future<String> _icon({
    required String emoji,
    required Color color,
    required String? label,
    required bool selected,
  }) async {
    final name = HaramainMarkers.nameFor(emoji, color, label, selected);
    if (_images.contains(name)) return name;
    final map = _map;
    if (map == null) return name;
    try {
      await map.addImage(
        name,
        await HaramainMarkers.badge(
          emoji: emoji,
          color: color,
          label: label,
          selected: selected,
        ),
      );
      _images.add(name);
    } catch (e) {
      debugPrint('HaramainMapCoordinator.icon($name) failed: $e');
    }
    return name;
  }

  /// Resolves a tapped symbol to a POI / pin id, or null.
  String? idForSymbol(Symbol symbol) => _symbolToId[symbol.id];

  void forgetSymbols() {
    _symbolToId.clear();
    _images.clear();
    _applied = HmMapSnapshot.empty;
  }

  // ─────────────────────── camera ───────────────────────

  Future<void> focusOn(LatLng target, {double zoom = 18.4}) async {
    final map = _map;
    if (map == null) return;
    try {
      await map.animateCamera(
        CameraUpdate.newLatLngZoom(target, zoom),
        duration: const Duration(milliseconds: 650),
      );
    } catch (e) {
      debugPrint('HaramainMapCoordinator.focusOn failed: $e');
    }
  }

  /// Fits a route (or a pair of points) into the viewport.
  Future<void> fitPoints(
    List<LatLng> points, {
    double paddingTop = 220,
    double paddingBottom = 380,
  }) async {
    final map = _map;
    if (map == null || points.length < 2) return;
    try {
      final lats = points.map((e) => e.latitude);
      final lngs = points.map((e) => e.longitude);
      await map.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
            northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
          ),
          left: 64,
          right: 64,
          top: paddingTop,
          bottom: paddingBottom,
        ),
        duration: const Duration(milliseconds: 700),
      );
    } catch (e) {
      debugPrint('HaramainMapCoordinator.fitPoints failed: $e');
    }
  }

  /// Smooth "follow me" camera, throttled and heading-aware.
  void followUser(LatLng position, double? heading) {
    final map = _map;
    if (map == null) return;
    final now = DateTime.now();
    if (now.difference(_lastCameraMove).inMilliseconds < 1400) return;
    if (_cameraMoveScheduled) return;
    _lastCameraMove = now;
    _cameraMoveScheduled = true;

    final zoom = math.max(map.cameraPosition?.zoom ?? 18, 18.4);
    try {
      map
          .animateCamera(
            CameraUpdate.newCameraPosition(CameraPosition(
              target: position,
              zoom: zoom,
              tilt: 55,
              bearing: heading ?? 0,
            )),
            duration: const Duration(milliseconds: 1000),
          )
          .then((_) => _cameraMoveScheduled = false)
          .catchError((Object _) {
        _cameraMoveScheduled = false;
      });
    } catch (_) {
      _cameraMoveScheduled = false;
    }
  }

  /// Flattens the camera (used when leaving navigation).
  Future<void> flatten() async {
    final map = _map;
    final cam = map?.cameraPosition;
    if (map == null || cam == null) return;
    try {
      await map.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: cam.target, zoom: cam.zoom, bearing: 0),
        ),
        duration: const Duration(milliseconds: 600),
      );
    } catch (_) {
      // ignore
    }
  }

  Future<void> setTilt(double tilt) async {
    final map = _map;
    final cam = map?.cameraPosition;
    if (map == null || cam == null) return;
    try {
      await map.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
          target: cam.target,
          zoom: cam.zoom,
          bearing: cam.bearing,
          tilt: tilt,
        )),
        duration: const Duration(milliseconds: 500),
      );
    } catch (_) {
      // ignore
    }
  }

  Future<void> recenterOn(LatLng target) =>
      focusOn(target, zoom: math.max(18.2, (_map?.cameraPosition?.zoom ?? 18)));

  void dispose() {
    _symbolToId.clear();
    _images.clear();
    _map = null;
    _styleReady = false;
  }
}