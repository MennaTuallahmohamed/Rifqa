import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../models/haramain/haramain_map_demo_models.dart';
import 'haramain_map_style.dart';

class HaramainMapCanvas extends StatefulWidget {
  const HaramainMapCanvas({
    super.key,
    required this.site,
    required this.satellite,
    required this.locationEnabled,
    required this.onCreated,
    required this.onStyleLoaded,
    required this.onMapClick,
    required this.onLongPress,
    required this.onSymbolTap,
  });

  final HaramainSite site;
  final bool satellite;
  final bool locationEnabled;
  final void Function(MapLibreMapController controller) onCreated;
  final VoidCallback onStyleLoaded;
  final VoidCallback onMapClick;
  final void Function(LatLng point) onLongPress;
  final void Function(Symbol symbol) onSymbolTap;

  @override
  State<HaramainMapCanvas> createState() => _HaramainMapCanvasState();
}

class _HaramainMapCanvasState extends State<HaramainMapCanvas> {
  MapLibreMapController? _controller;

  @override
  void dispose() {
    final c = _controller;
    if (c != null) {
      c.onSymbolTapped.remove(_handleSymbol);
    }
    super.dispose();
  }

  void _handleSymbol(Symbol s) => widget.onSymbolTap(s);

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString:
          widget.satellite ? haramainSatelliteStyle : haramainStreetStyle,
      initialCameraPosition: CameraPosition(
        target: widget.site.center,
        zoom: widget.site.initialZoom + .6,
      ),
      minMaxZoomPreference: const MinMaxZoomPreference(13, 20.5),
      compassEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      myLocationEnabled: widget.locationEnabled,
      myLocationRenderMode: widget.locationEnabled
          ? MyLocationRenderMode.compass
          : MyLocationRenderMode.normal,
      trackCameraPosition: true,
      onMapCreated: (c) {
        _controller = c;
        c.onSymbolTapped.add(_handleSymbol);
        widget.onCreated(c);
      },
      onStyleLoadedCallback: widget.onStyleLoaded,
      onMapClick: (_, __) => widget.onMapClick(),
      onMapLongClick: (_, ll) => widget.onLongPress(ll),
    );
  }
}
