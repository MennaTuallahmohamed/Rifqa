import 'dart:async';



import 'package:flutter/material.dart';

import 'package:flutter_tts/flutter_tts.dart';

import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:url_launcher/url_launcher.dart';



import '../../models/haramain/haramain_map_demo_models.dart';
import '../rawdah/rawdah_screen.dart';



class HaramainMapDemoScreen extends StatefulWidget {

  const HaramainMapDemoScreen({super.key});



  @override

  State<HaramainMapDemoScreen> createState() => _HaramainMapDemoScreenState();

}



class _HaramainMapDemoScreenState extends State<HaramainMapDemoScreen> {

  static const _emerald = Color(0xFF075B4A);

  static const _blue = Color(0xFF1677FF);

  static const _ivory = Color(0xFFF7F4ED);



  HaramainSite? _site;



  @override

  Widget build(BuildContext context) {

    if (_site == null) {

      return _HaramainChooser(

        onSelect: (site) => setState(() => _site = site),

      );

    }



    return _HaramainRealMap(

      key: ValueKey(_site),

      site: _site!,

      onBackToChooser: () => setState(() => _site = null),

      emerald: _emerald,

      blue: _blue,

      ivory: _ivory,

    );

  }

}



class _HaramainChooser extends StatelessWidget {

  const _HaramainChooser({required this.onSelect});



  final ValueChanged<HaramainSite> onSelect;



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF7F4ED),

      body: SafeArea(

        child: Padding(

          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              Row(

                children: [

                  IconButton.filledTonal(

                    onPressed: () => Navigator.maybePop(context),

                    icon: const Icon(Icons.arrow_back_rounded),

                  ),

                  const Spacer(),

                  const Column(

                    crossAxisAlignment: CrossAxisAlignment.end,

                    children: [

                      Text(

                        '\u{62e}\u{631}\u{64a}\u{637}\u{629} \u{627}\u{644}\u{62d}\u{631}\u{645}\u{64a}\u{646}',

                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),

                      ),

                      SizedBox(height: 4),

                      Text(

                        '\u{627}\u{62e}\u{62a}\u{627}\u{631}\u{64a} \u{627}\u{644}\u{645}\u{643}\u{627}\u{646} \u{627}\u{644}\u{630}\u{64a} \u{62a}\u{631}\u{64a}\u{62f}\u{64a}\u{646} \u{627}\u{633}\u{62a}\u{643}\u{634}\u{627}\u{641}\u{647}',

                        style: TextStyle(color: Color(0xFF6F746F), fontSize: 14),

                      ),

                    ],

                  ),

                ],

              ),

              const SizedBox(height: 28),

              Expanded(

                child: Column(

                  children: [

                    Expanded(

                      child: _SiteCard(

                        site: HaramainSite.makkah,

                        gradient: const [Color(0xFF0A6653), Color(0xFF063F35)],

                        icon: Icons.mosque_rounded,

                        onTap: () => onSelect(HaramainSite.makkah),

                      ),

                    ),

                    const SizedBox(height: 16),

                    Expanded(

                      child: _SiteCard(

                        site: HaramainSite.madinah,

                        gradient: const [Color(0xFF146B62), Color(0xFF0A4C46)],

                        icon: Icons.location_city_rounded,

                        onTap: () => onSelect(HaramainSite.madinah),

                      ),

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 18),

              const _SafetyPill(

                text: '\u{627}\u{62e}\u{62a}\u{627}\u{631}\u{64a} \u{645}\u{643}\u{627}\u{646}\u{64b}\u{627} \u{639}\u{644}\u{649} \u{627}\u{644}\u{62e}\u{631}\u{64a}\u{637}\u{629} \u{644}\u{628}\u{62f}\u{621} \u{627}\u{62a}\u{62c}\u{627}\u{647}\u{627}\u{62a} \u{627}\u{644}\u{645}\u{634}\u{64a}.',

              ),

            ],

          ),

        ),

      ),

    );

  }

}



class _SiteCard extends StatelessWidget {

  const _SiteCard({

    required this.site,

    required this.gradient,

    required this.icon,

    required this.onTap,

  });



  final HaramainSite site;

  final List<Color> gradient;

  final IconData icon;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return Material(

      color: Colors.transparent,

      child: InkWell(

        onTap: onTap,

        borderRadius: BorderRadius.circular(30),

        child: Ink(

          decoration: BoxDecoration(

            gradient: LinearGradient(

              colors: gradient,

              begin: Alignment.topRight,

              end: Alignment.bottomLeft,

            ),

            borderRadius: BorderRadius.circular(30),

            boxShadow: const [

              BoxShadow(

                color: Color(0x22000000),

                blurRadius: 24,

                offset: Offset(0, 12),

              ),

            ],

          ),

          child: Stack(

            children: [

              Positioned(

                left: -25,

                bottom: -35,

                child: Icon(

                  icon,

                  size: 190,

                  color: Colors.white.withValues(alpha: .07),

                ),

              ),

              Padding(

                padding: const EdgeInsets.all(24),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.end,

                  children: [

                    Row(

                      children: [

                        Container(

                          width: 54,

                          height: 54,

                          decoration: BoxDecoration(

                            color: Colors.white.withValues(alpha: .14),

                            shape: BoxShape.circle,

                          ),

                          child: const Icon(

                            Icons.arrow_back_rounded,

                            color: Colors.white,

                          ),

                        ),

                        const Spacer(),

                        Text(site.emoji, style: const TextStyle(fontSize: 38)),

                      ],

                    ),

                    const Spacer(),

                    Text(

                      site.title,

                      textAlign: TextAlign.right,

                      style: const TextStyle(

                        color: Colors.white,

                        fontSize: 27,

                        fontWeight: FontWeight.w900,

                      ),

                    ),

                    const SizedBox(height: 6),

                    Text(

                      site.city,

                      style: const TextStyle(

                        color: Color(0xFFD8E9E5),

                        fontSize: 15,

                        fontWeight: FontWeight.w600,

                      ),

                    ),

                    const SizedBox(height: 16),

                    const Row(

                      mainAxisAlignment: MainAxisAlignment.end,

                      children: [

                        Text(

                          '\u{627}\u{641}\u{62a}\u{62d}\u{64a} \u{627}\u{644}\u{62e}\u{631}\u{64a}\u{637}\u{629}',

                          style: TextStyle(

                            color: Colors.white,

                            fontWeight: FontWeight.w800,

                          ),

                        ),

                        SizedBox(width: 8),

                        Icon(Icons.map_rounded, color: Colors.white),

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



class _HaramainRealMap extends StatefulWidget {

  const _HaramainRealMap({

    super.key,

    required this.site,

    required this.onBackToChooser,

    required this.emerald,

    required this.blue,

    required this.ivory,

  });



  final HaramainSite site;

  final VoidCallback onBackToChooser;

  final Color emerald;

  final Color blue;

  final Color ivory;



  @override

  State<_HaramainRealMap> createState() => _HaramainRealMapState();

}



class _HaramainRealMapState extends State<_HaramainRealMap> {

  // Outdoor satellite imagery improves landmark recognition; it is not an

  // indoor floorplan and must not be used as proof of an indoor route.

  static const _imageryStyle = '''{

    "version": 8,

    "sources": {

      "esri-imagery": {

        "type": "raster",

        "tiles": ["https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"],

        "tileSize": 256,

        "attribution": "Esri World Imagery"

      }

    },

    "layers": [{"id": "esri-imagery", "type": "raster", "source": "esri-imagery"}]

  }''';

  static const _streetStyle = 'https://tiles.openfreemap.org/styles/positron';



  final FlutterTts _tts = FlutterTts();

  MapLibreMapController? _controller;



  bool _styleLoaded = false;

  final bool _largeText = false;

  final bool _highContrast = false;

  bool _satellite = false;

  LatLng? _selectedDestination;



  @override

  void initState() {

    super.initState();

    unawaited(_tts.setLanguage('ar-SA'));

    unawaited(_tts.setSpeechRate(.43));

  }



  @override

  void dispose() {

    unawaited(_tts.stop());

    super.dispose();

  }



  Future<void> _onStyleLoaded() async {

    _styleLoaded = true;

    await _drawMapLayers();

    if (mounted) setState(() {});

  }



  Future<void> _drawMapLayers() async {
    final c = _controller;
    if (c == null || !_styleLoaded) return;
    await c.clearLines();
    await c.clearCircles();
    await c.clearSymbols();
    final destination = _selectedDestination;
    if (destination != null) {
      await c.addCircle(CircleOptions(
        geometry: destination,
        circleRadius: 10,
        circleColor: '#1677FF',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 4,
      ));
    }
  }

  void _toggleMapStyle() => setState(() => _satellite = !_satellite);

  Future<void> _selectDestination(LatLng destination) async {
    setState(() => _selectedDestination = destination);
    await _drawMapLayers();
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: destination, zoom: 18, tilt: 0),
      ),
      duration: const Duration(milliseconds: 450),
    );
  }

  Future<void> _openWalkingDirections() async {
    final destination = _selectedDestination;
    if (destination == null) {
      _statusToast('\u{627}\u{62e}\u{62a}\u{627}\u{631}\u{64a} \u{646}\u{642}\u{637}\u{629} \u{648}\u{627}\u{636}\u{62d}\u{629} \u{639}\u{644}\u{649} \u{627}\u{644}\u{62e}\u{631}\u{64a}\u{637}\u{629} \u{644}\u{628}\u{62f}\u{621} \u{627}\u{62a}\u{62c}\u{627}\u{647}\u{627}\u{62a} \u{627}\u{644}\u{645}\u{634}\u{64a}.');
      return;
    }
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${destination.latitude},${destination.longitude}',
      'travelmode': 'walking',
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _statusToast('\u{62a}\u{639}\u{630}\u{651}\u{631} \u{641}\u{62a}\u{62d} \u{62a}\u{637}\u{628}\u{64a}\u{642} \u{627}\u{644}\u{62e}\u{631}\u{627}\u{626}\u{637} \u{639}\u{644}\u{649} \u{647}\u{630}\u{627} \u{627}\u{644}\u{62c}\u{647}\u{627}\u{632}.');
    }
  }

  void _clearDestination() {
    setState(() => _selectedDestination = null);
    unawaited(_drawMapLayers());
  }
  Future<void> _openRawdah() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RawdahScreen()),
    );
  }

  Future<void> _resetCamera() async {

    final c = _controller;

    if (c == null) return;

    await c.animateCamera(

      CameraUpdate.newCameraPosition(

        CameraPosition(

          target: widget.site.center,

          zoom: widget.site.initialZoom,

          tilt: 0,

          bearing: 0,

        ),

      ),

      duration: const Duration(milliseconds: 700),

    );

  }



  void _showSearch() {
    _statusToast('\u{627}\u{636}\u{63a}\u{637}\u{64a} \u{639}\u{644}\u{649} \u{627}\u{633}\u{645} \u{645}\u{643}\u{627}\u{646} \u{638}\u{627}\u{647}\u{631} \u{639}\u{644}\u{649} \u{627}\u{644}\u{62e}\u{631}\u{64a}\u{637}\u{629} \u{644}\u{627}\u{62e}\u{62a}\u{64a}\u{627}\u{631}\u{647}\u{60c} \u{62b}\u{645} \u{627}\u{637}\u{644}\u{628}\u{64a} \u{627}\u{62a}\u{62c}\u{627}\u{647}\u{627}\u{62a} \u{627}\u{644}\u{645}\u{634}\u{64a}.');
  }
  void _statusToast(String message) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(content: Text(message)),

    );

  }



  @override

  Widget build(BuildContext context) {

    final scale = _largeText ? 1.12 : 1.0;



    return MediaQuery(

      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),

      child: Scaffold(

        backgroundColor: widget.ivory,

        body: Stack(

          children: [

            Positioned.fill(

              child: MapLibreMap(

                styleString: _satellite ? _imageryStyle : _streetStyle,

                initialCameraPosition: CameraPosition(

                  target: widget.site.center,

                  zoom: widget.site.initialZoom,

                  tilt: 0,

                  bearing: 0,

                ),

                onMapCreated: (controller) => _controller = controller,

                onStyleLoadedCallback: _onStyleLoaded,

                onMapClick: (point, coordinates) =>

                    unawaited(_selectDestination(coordinates)),

                compassEnabled: false,

                rotateGesturesEnabled: true,

                tiltGesturesEnabled: true,

                zoomGesturesEnabled: true,

                scrollGesturesEnabled: true,

              ),

            ),



            if (_highContrast)

              Positioned.fill(

                child: IgnorePointer(

                  child: Container(color: Colors.white.withValues(alpha: .06)),

                ),

              ),



            SafeArea(

              child: Column(

                children: [

                  _TopMapBar(

                    site: widget.site,

                    onBack: widget.onBackToChooser,

                    onRawdah: widget.site == HaramainSite.madinah ? _openRawdah : null,

                  ),

                  _SearchPill(onTap: _showSearch),

                  const Spacer(),

                  Padding(

                    padding: const EdgeInsets.symmetric(horizontal: 14),

                    child: Row(

                      crossAxisAlignment: CrossAxisAlignment.end,

                      children: [

                        Column(

                          children: [

                            _MapFab(

                              icon: _satellite

                                  ? Icons.satellite_alt_rounded

                                  : Icons.map_outlined,

                              onTap: _toggleMapStyle,

                            ),

                            const SizedBox(height: 10),

                            _MapFab(

                              icon: Icons.center_focus_weak_rounded,

                              onTap: _resetCamera,

                            ),

                          ],

                        ),

                        const Spacer(),

                      ],

                    ),

                  ),

                  const SizedBox(height: 12),

                  _BottomNavigationPanel(

                    site: widget.site,

                    destination: _selectedDestination,

                    onStart: _openWalkingDirections,

                    onClear: _clearDestination,

                  ),

                ],

              ),

            ),



            if (!_styleLoaded)

              const Positioned.fill(

                child: ColoredBox(

                  color: Color(0xFFF7F4ED),

                  child: Center(child: CircularProgressIndicator()),

                ),

              ),

          ],

        ),

      ),

    );

  }

}



class _TopMapBar extends StatelessWidget {

  const _TopMapBar({

    required this.site,

    required this.onBack,

    required this.onRawdah,

  });



  final HaramainSite site;

  final VoidCallback onBack;

  final VoidCallback? onRawdah;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),

      child: Row(

        children: [

          _MapFab(icon: Icons.arrow_back_rounded, onTap: onBack, size: 46),

          if (onRawdah != null) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.white.withValues(alpha: .96),
              borderRadius: BorderRadius.circular(18),
              elevation: 5,
              child: InkWell(
                onTap: onRawdah,
                borderRadius: BorderRadius.circular(18),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_florist_rounded, color: Color(0xFF075B4A), size: 19),
                      SizedBox(width: 6),
                      Text('الروضة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const Spacer(),

          Container(

            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),

            decoration: BoxDecoration(

              color: Colors.white.withValues(alpha: .95),

              borderRadius: BorderRadius.circular(18),

              boxShadow: const [

                BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, 6)),

              ],

            ),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.end,

              children: [

                Text(

                  '${site.emoji} ${site.title}',

                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),

                ),

                Text(

                  site.city,

                  style: const TextStyle(color: Color(0xFF717873), fontSize: 11),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }

}



class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Material(
        elevation: 7,
        shadowColor: Colors.black12,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 17, vertical: 15),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: Color(0xFF075B4A)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '\u{627}\u{636}\u{63a}\u{637}\u{64a} \u{639}\u{644}\u{649} \u{627}\u{633}\u{645} \u{645}\u{643}\u{627}\u{646} \u{641}\u{64a} \u{627}\u{644}\u{62e}\u{631}\u{64a}\u{637}\u{629}',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Color(0xFF5F6762), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _BottomNavigationPanel extends StatelessWidget {
  const _BottomNavigationPanel({
    required this.site,
    required this.destination,
    required this.onStart,
    required this.onClear,
  });

  final HaramainSite site;
  final LatLng? destination;
  final VoidCallback onStart;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasDestination = destination != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 42, height: 5, decoration: const BoxDecoration(color: Color(0xFFD7DAD8), borderRadius: BorderRadius.all(Radius.circular(99)))),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hasDestination ? '\u{648}\u{62c}\u{647}\u{629} \u{645}\u{62d}\u{62f}\u{62f}\u{629}' : site.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasDestination ? '\u{627}\u{636}\u{63a}\u{637}\u{64a} \u{644}\u{641}\u{62a}\u{62d} \u{627}\u{644}\u{645}\u{633}\u{627}\u{631} \u{627}\u{644}\u{62e}\u{627}\u{631}\u{62c}\u{64a} \u{644}\u{644}\u{645}\u{634}\u{64a}' : '\u{627}\u{62e}\u{62a}\u{627}\u{631}\u{64a} \u{645}\u{643}\u{627}\u{646}\u{64b}\u{627} \u{645}\u{643}\u{62a}\u{648}\u{628}\u{64b}\u{627} \u{639}\u{644}\u{649} \u{627}\u{644}\u{62e}\u{631}\u{64a}\u{637}\u{629}',
                    style: const TextStyle(color: Color(0xFF747A76), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: hasDestination ? onStart : null,
              icon: const Icon(Icons.directions_walk_rounded),
              label: Text(hasDestination ? '\u{627}\u{628}\u{62f}\u{626}\u{64a} \u{627}\u{62a}\u{62c}\u{627}\u{647}\u{627}\u{62a} \u{627}\u{644}\u{645}\u{634}\u{64a}' : '\u{627}\u{62e}\u{62a}\u{627}\u{631}\u{64a} \u{648}\u{62c}\u{647}\u{629} \u{639}\u{644}\u{649} \u{627}\u{644}\u{62e}\u{631}\u{64a}\u{637}\u{629}'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF075B4A),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(17))),
              ),
            ),
          ),
          if (hasDestination)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('\u{645}\u{633}\u{62d} \u{627}\u{644}\u{648}\u{62c}\u{647}\u{629}'),
            ),
          const _SafetyPill(text: '\u{627}\u{644}\u{627}\u{62a}\u{62c}\u{627}\u{647}\u{627}\u{62a} \u{627}\u{644}\u{62e}\u{627}\u{631}\u{62c}\u{64a}\u{629} \u{644}\u{627} \u{62a}\u{62d}\u{62f}\u{62f} \u{627}\u{644}\u{645}\u{645}\u{631}\u{627}\u{62a} \u{62f}\u{627}\u{62e}\u{644} \u{627}\u{644}\u{62d}\u{631}\u{645}.'),
        ],
      ),
    );
  }
}
class _MapFab extends StatelessWidget {

  const _MapFab({

    required this.icon,

    required this.onTap,

    this.size = 50,

  });



  final IconData icon;

  final VoidCallback onTap;

  final double size;



  @override

  Widget build(BuildContext context) {

    return Material(

      elevation: 8,

      shadowColor: Colors.black12,

      color: Colors.white,

      shape: const CircleBorder(),

      child: InkWell(

        onTap: onTap,

        customBorder: const CircleBorder(),

        child: SizedBox(

          width: size,

          height: size,

          child: Icon(icon, color: const Color(0xFF26312D), size: size * .48),

        ),

      ),

    );

  }

}



class _SafetyPill extends StatelessWidget {

  const _SafetyPill({required this.text});



  final String text;



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),

      decoration: BoxDecoration(

        color: const Color(0xFFF0F2F0),

        borderRadius: BorderRadius.circular(14),

      ),

      child: Row(

        mainAxisSize: MainAxisSize.min,

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF6B736E)),

          const SizedBox(width: 6),

          Flexible(

            child: Text(

              text,

              textAlign: TextAlign.center,

              style: const TextStyle(

                fontSize: 10.5,

                color: Color(0xFF6B736E),

                fontWeight: FontWeight.w600,

              ),

            ),

          ),

        ],

      ),

    );

  }

}

