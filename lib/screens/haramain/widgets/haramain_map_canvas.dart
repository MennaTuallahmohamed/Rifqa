import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../models/haramain/haramain_map_demo_models.dart';
import '../map/haramain_map_coordinator.dart';
import '../map/haramain_map_style.dart';

/// The real, interactive MapLibre canvas.
///
/// This widget is intentionally dumb: it renders the map and forwards raw
/// events. All logic lives in [HaramainMapCoordinator], which means changing a
/// filter, opening a sheet, or toggling accessibility never rebuilds the
/// platform view — it only re-syncs annotations imperatively.
class HmMapCanvas extends StatefulWidget {
  const HmMapCanvas({
    super.key,
    required this.site,
    required this.satellite,
    required this.locationEnabled,
    required this.followMode,
    required this.coordinator,
    required this.onSymbolTap,
    required this.onMapTap,
    required this.onLongPress,
  });

  final HaramainSite site;
  final bool satellite;
  final bool locationEnabled;

  /// True while the map is actively following the pilgrim's position.
  final bool followMode;

  final HaramainMapCoordinator coordinator;
  final void Function(Symbol symbol) onSymbolTap;
  final VoidCallback onMapTap;
  final void Function(LatLng point) onLongPress;

  @override
  State<HmMapCanvas> createState() => _HmMapCanvasState();
}

class _HmMapCanvasState extends State<HmMapCanvas> {
  MapLibreMapController? _controller;

  @override
  void didUpdateWidget(HmMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The style is style-scoped: when the layer changes we must forget the
    // cached images and re-upload them once the new style finishes loading.
    if (oldWidget.satellite != widget.satellite) {
      widget.coordinator.forgetSymbols();
    }
  }

  @override
  void dispose() {
    widget.coordinator.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      key: ValueKey('hm_map_${widget.site.name}_${widget.satellite}'),
      styleString:
          widget.satellite ? haramainSatelliteStyle : haramainStreetStyle,
      initialCameraPosition: CameraPosition(
        target: widget.site.center,
        zoom: widget.site.initialZoom + 0.6,
      ),
      minMaxZoomPreference: const MinMaxZoomPreference(13, 20.5),
      compassEnabled: false,
      // Full gesture set: pan, zoom, rotate, pitch, double-tap zoom.
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      doubleClickZoomEnabled: true,
      dragEnabled: true,
      myLocationEnabled: widget.locationEnabled,
      myLocationRenderMode: widget.followMode
          ? MyLocationRenderMode.compass
          : MyLocationRenderMode.normal,
      trackCameraPosition: true,
      onMapCreated: (controller) {
        _controller = controller;
        widget.coordinator.attach(controller);
        controller.onSymbolTapped.add(_handleSymbolTap);
      },
      onStyleLoadedCallback: widget.coordinator.onStyleLoaded,
      onMapClick: (_, __) => widget.onMapTap(),
      onMapLongClick: (_, point) => widget.onLongPress(point),
    );
  }

  void _handleSymbolTap(Symbol symbol) => widget.onSymbolTap(symbol);
}