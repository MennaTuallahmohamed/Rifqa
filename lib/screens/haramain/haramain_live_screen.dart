import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'haramain_live_models.dart';
import '../../models/haramain/haramain_map_demo_models.dart';
import 'haramain_data_service.dart';
import 'haramain_geo.dart';
import 'haramain_live_store.dart';
import 'haramain_location_service.dart';
import 'haramain_marker_factory.dart';
import 'haramain_nav_session.dart';
import '../../services/haramain/haramain_voice_service.dart';
import 'haramain_live_sheets.dart';

const _emerald = Color(0xFF075B4A);
const _blue = Color(0xFF1677FF);
const _ivory = Color(0xFFF7F4ED);

/// إذا ظهرت العلامات كبيرة/صغيرة على جهازك عدّل هذا الرقم فقط.
const double _kIconSize = 0.5;

// ───────────── أنماط الخريطة ─────────────
const _glyphs = 'https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf';
const _fontR = ['Noto Sans Regular'];
const _fontB = ['Noto Sans Bold'];
const _nameAr = ['coalesce', ['get', 'name:ar'], ['get', 'name']];
const _streetUrl = 'https://tiles.openfreemap.org/styles/liberty'; // مباني 3D + أسماء كثيرة

/// قمر صناعي + أسماء عربية (شوارع، أحياء، معالم، محلات) فوق الصورة.
String _hybridStyle() => jsonEncode({
      'version': 8,
      'glyphs': _glyphs,
      'sources': {
        'img': {
          'type': 'raster',
          'tiles': [
            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
          ],
          'tileSize': 256,
          'maxzoom': 19,
          'attribution': 'Esri World Imagery'
        },
        'omt': {'type': 'vector', 'url': 'https://tiles.openfreemap.org/planet'},
      },
      'layers': [
        {'id': 'img', 'type': 'raster', 'source': 'img'},
        {
          'id': 'lbl-road',
          'type': 'symbol',
          'source': 'omt',
          'source-layer': 'transportation_name',
          'minzoom': 14,
          'layout': {
            'symbol-placement': 'line',
            'text-field': _nameAr,
            'text-font': _fontR,
            'text-size': 12
          },
          'paint': {
            'text-color': '#FFFFFF',
            'text-halo-color': 'rgba(0,0,0,0.8)',
            'text-halo-width': 1.6
          }
        },
        {
          'id': 'lbl-place',
          'type': 'symbol',
          'source': 'omt',
          'source-layer': 'place',
          'minzoom': 9,
          'filter': [
            'in',
            ['get', 'class'],
            ['literal', ['city', 'town', 'village', 'suburb', 'neighbourhood', 'quarter', 'island']]
          ],
          'layout': {
            'text-field': _nameAr,
            'text-font': _fontB,
            'text-size': ['interpolate', ['linear'], ['zoom'], 9, 12, 17, 20],
            'text-max-width': 8
          },
          'paint': {
            'text-color': '#FFE9A8',
            'text-halo-color': 'rgba(0,0,0,0.85)',
            'text-halo-width': 2
          }
        },
        {
          'id': 'lbl-poi-major',
          'type': 'symbol',
          'source': 'omt',
          'source-layer': 'poi',
          'minzoom': 15,
          'filter': ['<=', ['coalesce', ['get', 'rank'], 99], 12],
          'layout': {
            'text-field': _nameAr,
            'text-font': _fontB,
            'text-size': 12.5,
            'text-anchor': 'top',
            'text-offset': [0, 0.4],
            'text-max-width': 7
          },
          'paint': {
            'text-color': '#B9F6CA',
            'text-halo-color': 'rgba(0,0,0,0.85)',
            'text-halo-width': 1.8
          }
        },
        {
          'id': 'lbl-poi-all',
          'type': 'symbol',
          'source': 'omt',
          'source-layer': 'poi',
          'minzoom': 17,
          'filter': ['>', ['coalesce', ['get', 'rank'], 99], 12],
          'layout': {
            'text-field': _nameAr,
            'text-font': _fontR,
            'text-size': 11,
            'text-anchor': 'top',
            'text-offset': [0, 0.4],
            'text-max-width': 7
          },
          'paint': {
            'text-color': '#FFFFFF',
            'text-halo-color': 'rgba(0,0,0,0.85)',
            'text-halo-width': 1.5
          }
        },
      ],
    });

const _baseLabelIds = ['lbl-road', 'lbl-place', 'lbl-poi-major', 'lbl-poi-all'];

// ───────────── معالم كبرى (إحداثيات تقريبية للتسمية فقط — راجعها قبل الاعتماد) ─────────────
const _landmarks = <(String, double, double)>[
  ('الكعبة المشرفة', 21.4225, 39.8262),
  ('جبل النور (غار حراء)', 21.4590, 39.8582),
  ('جبل ثور', 21.3790, 39.8480),
  ('مسجد التنعيم (عائشة)', 21.4616, 39.7704),
  ('منى', 21.4133, 39.8933),
  ('الجمرات', 21.4224, 39.8731),
  ('مزدلفة', 21.3880, 39.9360),
  ('جبل عرفات', 21.3547, 39.9841),
  ('المسجد النبوي', 24.4672, 39.6111),
  ('مقبرة البقيع', 24.4665, 39.6159),
  ('مسجد قباء', 24.4393, 39.6172),
  ('مسجد القبلتين', 24.4818, 39.5890),
  ('جبل أحد', 24.5049, 39.6118),
];

enum _Panel { idle, poi, preview, nav }

// معرّفات المصادر والطبقات
const _srcPoi = 'src-poi', _srcRoute = 'src-route', _srcOsm = 'src-osm', _srcLand = 'src-land';
const _lyOsm = 'ly-osm', _lyLand = 'ly-land', _lyCase = 'ly-route-case', _lyRoute = 'ly-route';
const _lyMinor = 'ly-poi-minor', _lyMajor = 'ly-poi-major';

class HaramainLiveScreen extends StatefulWidget {
  const HaramainLiveScreen({super.key});
  @override
  State<HaramainLiveScreen> createState() => _HaramainLiveScreenState();
}

class _HaramainLiveScreenState extends State<HaramainLiveScreen> {
  final _data = HaramainDataService();
  final _store = HaramainLiveStore();
  final _loc = HaramainLocationService();
  final _voice = HaramainVoiceService();
  late final HaramainNavSession _nav = HaramainNavSession(_voice);

  HaramainSite? _site;
  List<HlPoi> _pois = const [];
  MapLibreMapController? _map;
  bool _booting = true, _locOk = false, _styleReady = false;
  bool _sat = true, _tilt = false, _labels = true;
  String _streetStyle = _streetUrl;
  final _hybrid = _hybridStyle();

  _Panel _panel = _Panel.idle;
  HlCategory? _filter;
  HlPoi? _sel;
  HlRoute? _route;

  final _imgs = <String>{};
  final _osm = <String, List<Map<String, dynamic>>>{}; // أسماء OSM لكل حرم
  int _syncSeq = 0;
  DateTime _lastCam = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _hc => _store.profile.highContrast;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.wait([_store.load(), _data.load()]);
    _streetStyle = await _loadStreetStyle();
    _locOk = await _loc.start();
    _nav.voiceOn = _store.profile.voiceGuidance;
    _loc.fix.addListener(_onFix);
    _loc.heading.addListener(_onHeading);
    _nav.addListener(_rebuild);
    _store.addListener(_onStore);
    if (mounted) setState(() => _booting = false);
  }

  /// يجلب نمط الشوارع ويحوّل الأسماء للعربية (مع رجوع للاسم الأصلي لو غير متوفر).
  Future<String> _loadStreetStyle() async {
    try {
      final r = await http.get(Uri.parse(_streetUrl)).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return _streetUrl;
      return r.body
          .replaceAll('"name_en"', '"name:ar"')
          .replaceAll('"name:en"', '"name:ar"')
          .replaceAll('"name:latin"', '"name:ar"');
    } catch (_) {
      return _streetUrl;
    }
  }

  @override
  void dispose() {
    _loc.fix.removeListener(_onFix);
    _loc.heading.removeListener(_onHeading);
    _nav.removeListener(_rebuild);
    _store.removeListener(_onStore);
    _nav.dispose();
    _loc.dispose();
    _voice.stop();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onStore() {
    _nav.voiceOn = _store.profile.voiceGuidance;
    _rebuild();
    _sync();
  }

  void _onFix() {
    final f = _loc.fix.value;
    if (f == null) return;
    if (_nav.active) {
      _nav.update(f.pos, _loc.heading.value);
      _follow(f.pos);
    } else if (_panel == _Panel.idle) {
      _rebuild();
    }
  }

  void _onHeading() {
    final f = _loc.fix.value;
    if (_nav.active && f != null) _nav.update(f.pos, _loc.heading.value);
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // ───────────── الخريطة ─────────────
  void _openSite(HaramainSite s) {
    setState(() {
      _site = s;
      _pois = _data.poisFor(s);
      _filter = null;
      _sel = null;
      _route = null;
      _panel = _Panel.idle;
      _styleReady = false;
    });
    _loadOsm(s);
  }

  // ───────────── أسماء OpenStreetMap (محلات، فنادق، مطاعم، مساجد، صيدليات...) ─────────────
  Future<void> _loadOsm(HaramainSite s) async {
    if (_osm.containsKey(s.name)) return;
    try {
      final c = s.center;
      const d = 0.012; // ≈ 1.3 كم حول مركز الحرم
      final bb =
          '${c.latitude - d},${c.longitude - d},${c.latitude + d},${c.longitude + d}';
      final q = '[out:json][timeout:25];('
          'node["name"]["amenity"]($bb);'
          'node["name"]["shop"]($bb);'
          'node["name"]["tourism"]($bb);'
          'node["name"]["public_transport"]($bb);'
          'node["name"]["religion"]($bb);'
          ');out body 1500;';
      final res = await http
          .post(Uri.parse('https://overpass-api.de/api/interpreter'), body: {'data': q})
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return;
      final els = (jsonDecode(utf8.decode(res.bodyBytes))['elements'] as List?) ?? [];
      final feats = <Map<String, dynamic>>[];
      for (final e in els) {
        final tags = (e['tags'] as Map?) ?? const {};
        final name = (tags['name:ar'] ?? tags['name'])?.toString();
        if (name == null || name.isEmpty) continue;
        feats.add(_pt(LatLng((e['lat'] as num).toDouble(), (e['lon'] as num).toDouble()),
            {'name': name}));
      }
      _osm[s.name] = feats;
      if (_site == s) _pushOsm();
    } catch (_) {
      // بدون إنترنت: تبقى أسماء الخريطة الأساسية والمعالم تعمل
    }
  }

  Future<void> _pushOsm() async {
    final c = _map, s = _site;
    if (c == null || !_styleReady || s == null) return;
    try {
      await c.setGeoJsonSource(_srcOsm, _fc(_osm[s.name] ?? <Map<String, dynamic>>[]));
    } catch (_) {}
  }

  Map<String, dynamic> _pt(LatLng p, Map<String, dynamic> props) => {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [p.longitude, p.latitude]
        },
        'properties': props,
      };

  Map<String, dynamic> _fc(List<Map<String, dynamic>> f) =>
      {'type': 'FeatureCollection', 'features': f};

  // ───────────── الطبقات ─────────────
  Future<void> _onStyle() async {
    _styleReady = true;
    _imgs.clear();
    await _setupLayers();
    await _sync();
    await _pushOsm();
    if (mounted) setState(() {});
  }

  Future<void> _setupLayers() async {
    final c = _map;
    final site = _site;
    if (c == null || site == null) return;
    final txt = _sat ? '#FFFFFF' : '#1B2A27';
    final halo = _sat ? '#0B1F1A' : '#FFFFFF';
    final empty = _fc(<Map<String, dynamic>>[]);

    for (final id in [_lyMajor, _lyMinor, _lyRoute, _lyCase, _lyLand, _lyOsm]) {
      try {
        await c.removeLayer(id);
      } catch (_) {}
    }
    for (final id in [_srcPoi, _srcRoute, _srcLand, _srcOsm]) {
      try {
        await c.removeSource(id);
      } catch (_) {}
    }

    // معالم كبرى حول هذا الحرم
    final land = <Map<String, dynamic>>[
      for (final l in _landmarks)
        if (HmGeo.distance(site.center, LatLng(l.$2, l.$3)) < 60000)
          _pt(LatLng(l.$2, l.$3), {'name': l.$1}),
    ];

    await c.addGeoJsonSource(_srcOsm, empty);
    await c.addGeoJsonSource(_srcLand, _fc(land));
    await c.addGeoJsonSource(_srcRoute, empty);
    await c.addGeoJsonSource(_srcPoi, empty);

    // 1) أسماء OSM الصغيرة
    await c.addSymbolLayer(
      _srcOsm,
      _lyOsm,
      SymbolLayerProperties(
        textField: ['get', 'name'],
        textFont: _fontR,
        textSize: 11,
        textColor: _sat ? '#FFF8E1' : '#4A5A56',
        textHaloColor: halo,
        textHaloWidth: 1.5,
        textMaxWidth: 6,
        textAllowOverlap: false,
      ),
      minzoom: 16.3,
    );

    // 2) المعالم الكبرى
    await c.addSymbolLayer(
      _srcLand,
      _lyLand,
      SymbolLayerProperties(
        textField: ['get', 'name'],
        textFont: _fontB,
        textSize: ['interpolate', ['linear'], ['zoom'], 10, 12, 18, 19],
        textColor: _sat ? '#FFD54F' : '#075B4A',
        textHaloColor: halo,
        textHaloWidth: 2.2,
        textMaxWidth: 7,
        textAllowOverlap: true,
      ),
      minzoom: 10,
    );

    // 3) المسار
    await c.addLineLayer(
        _srcRoute,
        _lyCase,
        LineLayerProperties(
            lineColor: '#FFFFFF', lineWidth: 11, lineJoin: 'round', lineCap: 'round'));
    await c.addLineLayer(
        _srcRoute,
        _lyRoute,
        LineLayerProperties(
            lineColor: '#1677FF', lineWidth: 7, lineJoin: 'round', lineCap: 'round'));

    // 4) نقاط الخدمات (الصغيرة تظهر مع التقريب، الأبواب دائمًا)
    SymbolLayerProperties poiProps(double size) => SymbolLayerProperties(
          iconImage: ['get', 'icon'],
          iconSize: [
            'case',
            ['==', ['get', 'sel'], 1],
            _kIconSize * 1.25,
            _kIconSize
          ],
          iconAnchor: 'bottom',
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          textField: ['get', 'label'],
          textFont: _fontB,
          textSize: size,
          textColor: txt,
          textHaloColor: halo,
          textHaloWidth: 2,
          textAnchor: 'top',
          textOffset: [0, 0.3],
          textOptional: true,
          textMaxWidth: 7,
        );
    await c.addSymbolLayer(_srcPoi, _lyMinor, poiProps(12),
        minzoom: 16, filter: ['!=', ['get', 'major'], 1]);
    await c.addSymbolLayer(_srcPoi, _lyMajor, poiProps(13.5),
        minzoom: 13, filter: ['==', ['get', 'major'], 1]);

    await _applyLabelVisibility();
  }

  Future<void> _applyLabelVisibility() async {
    final c = _map;
    if (c == null || !_styleReady) return;
    for (final id in [_lyOsm, _lyLand, if (_sat) ..._baseLabelIds]) {
      try {
        await c.setLayerVisibility(id, _labels);
      } catch (_) {}
    }
  }

  Future<String> _icon(String emoji, Color color, String? label, bool sel) async {
    final name = HaramainMarkers.nameFor(emoji, color, label, sel);
    if (!_imgs.contains(name)) {
      await _map!.addImage(name,
          await HaramainMarkers.badge(emoji: emoji, color: color, label: label, selected: sel));
      _imgs.add(name);
    }
    return name;
  }

  List<HlPoi> _visible() {
    final l = _pois.where((p) => _filter == null || p.category == _filter).toList();
    final s = _sel;
    if (s != null && !s.isPin && !l.any((p) => p.id == s.id)) l.add(s);
    return l;
  }

  Future<void> _sync() async {
    final c = _map;
    final site = _site;
    if (c == null || !_styleReady || site == null) return;
    final seq = ++_syncSeq;

    final feats = <Map<String, dynamic>>[];
    for (final p in _visible()) {
      final sel = _sel?.id == p.id;
      feats.add(_pt(p.position, {
        'id': p.id,
        'icon': await _icon(p.category.emoji, p.category.color, p.gateNumber, sel),
        'label': p.title,
        'major': p.category == HlCategory.gate ? 1 : 0,
        'sel': sel ? 1 : 0,
      }));
    }
    for (final pin in _store.pinsFor(site)) {
      final sel = _sel?.id == pin.id;
      feats.add(_pt(pin.position, {
        'id': pin.id,
        'icon': await _icon(pin.kind.emoji, const Color(0xFFD94F4F), null, sel),
        'label': HlPoi.fromPin(pin).title,
        'major': 0,
        'sel': sel ? 1 : 0,
      }));
    }
    if (seq != _syncSeq) return;

    try {
      await c.setGeoJsonSource(_srcPoi, _fc(feats));
      final r = _nav.route ?? _route;
      await c.setGeoJsonSource(
        _srcRoute,
        _fc(r == null
            ? <Map<String, dynamic>>[]
            : [
                {
                  'type': 'Feature',
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': [for (final p in r.points) [p.longitude, p.latitude]],
                  },
                  'properties': <String, dynamic>{},
                }
              ]),
      );
    } catch (_) {}
  }

  HlPoi? _poiById(String id) {
    for (final p in _pois) {
      if (p.id == id) return p;
    }
    for (final pin in _store.pins) {
      if (pin.id == id) return HlPoi.fromPin(pin);
    }
    return null;
  }

  Future<void> _onMapTap(math.Point<double> pt, LatLng ll) async {
    final c = _map;
    if (c == null) return;
    try {
      final hits = await c.queryRenderedFeatures(pt, [_lyMajor, _lyMinor], null);
      if (hits.isNotEmpty) {
        dynamic f = hits.first;
        if (f is String) f = jsonDecode(f);
        final id = (f['properties'] as Map?)?['id']?.toString();
        final p = id == null ? null : _poiById(id);
        if (p != null) {
          _select(p);
          return;
        }
      }
    } catch (_) {}
    if (_panel == _Panel.poi) _clearSel();
  }

  void _select(HlPoi p) {
    HapticFeedback.selectionClick();
    setState(() {
      _sel = p;
      _route = null;
      _panel = _Panel.poi;
    });
    _sync();
    _map?.animateCamera(CameraUpdate.newLatLngZoom(p.position, 18.5),
        duration: const Duration(milliseconds: 500));
  }

  void _clearSel() {
    setState(() {
      _sel = null;
      _route = null;
      _panel = _Panel.idle;
    });
    _sync();
  }

  Future<void> _toggleTilt() async {
    final cam = _map?.cameraPosition;
    if (cam == null) return;
    setState(() => _tilt = !_tilt);
    await _map?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: cam.target, zoom: cam.zoom, bearing: cam.bearing, tilt: _tilt ? 60 : 0)));
  }

  Future<void> _toggleLabels() async {
    setState(() => _labels = !_labels);
    await _applyLabelVisibility();
  }

  void _locate() {
    final f = _loc.fix.value;
    if (f == null) {
      _toast(_locOk
          ? 'جارٍ تحديد موقعك... انتظر لحظات.'
          : 'الموقع غير مفعّل. فعّل الـGPS وأذونات الموقع للتطبيق.');
      return;
    }
    _map?.animateCamera(CameraUpdate.newLatLngZoom(f.pos, 18.8));
  }

  Future<void> _retryLoc() async {
    final ok = await _loc.start();
    setState(() => _locOk = ok);
    if (!ok) _toast('تعذّر تفعيل الموقع. افتح إعدادات الجهاز وامنح الإذن.');
  }

  void _follow(LatLng p) {
    final now = DateTime.now();
    if (now.difference(_lastCam).inMilliseconds < 1200) return;
    _lastCam = now;
    final z = math.max(_map?.cameraPosition?.zoom ?? 18, 18.5);
    _map?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
          target: p, zoom: z, tilt: 50, bearing: _loc.heading.value ?? 0)),
      duration: const Duration(milliseconds: 900),
    );
  }

  // ───────────── الخدمات والمسار ─────────────
  Future<void> _quick(HlCategory cat) async {
    final list = _pois
        .where((p) => p.category == cat && (!_store.profile.wheelchairMode || p.wheelchair))
        .toList();
    if (list.isEmpty) {
      _toast('لا توجد نقاط موثّقة لهذه الخدمة في بيانات هذا الحرم بعد.');
      return;
    }
    final me = _loc.fix.value?.pos;
    if (me == null) {
      _toast('لم يُحدَّد موقعك بعد. فعّل الـGPS وانتظر لحظات.');
      return;
    }
    list.sort((a, b) => HmGeo.distance(me, a.position).compareTo(HmGeo.distance(me, b.position)));
    final pick = await showNearestSheet(context,
        title: 'أقرب ${cat.label}',
        items: [for (final p in list.take(5)) (p, HmGeo.distance(me, p.position))]);
    if (pick != null) {
      _select(pick);
      _plan(pick);
    }
  }

  void _plan(HlPoi dest) {
    final me = _loc.fix.value?.pos;
    if (me == null) {
      _toast('لم يُحدَّد موقعك بعد، فلا يمكن حساب الاتجاه.');
      return;
    }
    final r = _data.route(_site!, me, dest, accessible: _store.profile.wheelchairMode);
    setState(() {
      _sel = dest;
      _route = r;
      _panel = _Panel.preview;
    });
    _sync();
    final pts = r?.points ?? [me, dest.position];
    final lats = pts.map((e) => e.latitude), lngs = pts.map((e) => e.longitude);
    _map?.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
          southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
          northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max))),
      left: 60, right: 60, top: 220, bottom: 380,
    ));
  }

  void _startNav() {
    final dest = _sel;
    if (dest == null) return;
    final route = _route;
    if (route == null) {
      _toast('لا يمكن بدء التوجيه الداخلي قبل توفر مسار موثّق لهذه الوجهة.');
      return;
    }
    _nav.startRoute(route);
    setState(() => _panel = _Panel.nav);
    final f = _loc.fix.value;
    if (f != null) {
      _nav.update(f.pos, _loc.heading.value);
      _lastCam = DateTime.fromMillisecondsSinceEpoch(0);
      _follow(f.pos);
    }
    _sync();
  }

  void _stopNav() {
    _nav.stop();
    setState(() => _panel = _Panel.idle);
    _sync();
    final cam = _map?.cameraPosition;
    if (cam != null) {
      _map?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: cam.target, zoom: cam.zoom, tilt: 0, bearing: 0)));
    }
    setState(() => _tilt = false);
  }

  void _longPress(LatLng ll) {
    HapticFeedback.mediumImpact();
    final site = _site!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('ثبّت هذا المكان كـ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ),
            for (final k in HlPinKind.values)
              ListTile(
                leading: Text(k.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(k.label),
                onTap: () {
                  _store.addPin(site, k, ll);
                  Navigator.pop(ctx);
                },
              ),
            if (kDebugMode)
              ListTile(
                leading: const Icon(Icons.data_object_rounded),
                title: const Text('نسخ كنقطة JSON (لبناء البيانات)'),
                subtitle: const Text('وضع المطوّر فقط'),
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text:
                          '{"id":"NEW_ID","site":"${site.name}","name":"الاسم","category":"gate","lat":${ll.latitude.toStringAsFixed(6)},"lng":${ll.longitude.toStringAsFixed(6)},"verificationStatus":"UNVERIFIED"}'));
                  Navigator.pop(ctx);
                  _toast('تم النسخ. الصقه داخل pois في ملف JSON.');
                },
              ),
          ]),
        ),
      ),
    );
  }

  // ───────────── البناء ─────────────
  @override
  Widget build(BuildContext context) {
    final p = _store.profile;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(p.largeText ? 1.25 : 1.0)),
        child: _booting
            ? const Scaffold(
                backgroundColor: _ivory,
                body: Center(child: CircularProgressIndicator(color: _emerald)))
            : _site == null
                ? _chooser()
                : _mapScreen(),
      ),
    );
  }

  Widget _chooser() => Scaffold(
        backgroundColor: _ivory,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                IconButton.filledTonal(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_forward_rounded)),
                const Spacer(),
                const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('الحرمين',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  Text('اختر الموقع', style: TextStyle(color: Colors.black54)),
                ]),
              ]),
              const SizedBox(height: 20),
              for (final s in HaramainSite.values) ...[
                Expanded(child: _siteCard(s)),
                const SizedBox(height: 14),
              ],
            ]),
          ),
        ),
      );

  Widget _siteCard(HaramainSite s) {
    final img = 'assets/images/haramain/${s.name}.jpg'; // اختياري
    return InkWell(
      onTap: () => _openSite(s),
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
              colors: [Color(0xFF0A6653), Color(0xFF063F35)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
            Container(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0x00000000), Color(0xCC063F35)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter))),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.emoji, style: const TextStyle(fontSize: 40)),
                const Spacer(),
                Text(s.title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                Text(s.city, style: const TextStyle(color: Color(0xFFD8E9E5))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _mapScreen() {
    final site = _site!;
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: _ivory,
      body: Stack(children: [
        Positioned.fill(
          child: MapLibreMap(
            styleString: _sat ? _hybrid : _streetStyle,
            initialCameraPosition:
                CameraPosition(target: site.center, zoom: site.initialZoom + .6),
            minMaxZoomPreference: const MinMaxZoomPreference(11, 20.5),
            myLocationEnabled: _locOk,
            myLocationRenderMode:
                _locOk ? MyLocationRenderMode.compass : MyLocationRenderMode.normal,
            compassEnabled: false,
            trackCameraPosition: true,
            onMapCreated: (c) => _map = c,
            onStyleLoadedCallback: _onStyle,
            onMapClick: (pt, ll) => _onMapTap(pt, ll),
            onMapLongClick: (_, ll) => _longPress(ll),
          ),
        ),
        if (_hc)
          Positioned.fill(
              child: IgnorePointer(child: Container(color: Colors.white.withAlpha(20)))),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _panel == _Panel.nav
              ? _navHud(top)
              : Column(children: [_header(top, site), _chips()]),
        ),
        Positioned(
          left: 12,
          top: top + (_panel == _Panel.nav ? 190 : 200),
          child: _fabs(),
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: _bottom()),
        if (!_styleReady)
          const Positioned.fill(
              child: ColoredBox(
                  color: _ivory,
                  child: Center(child: CircularProgressIndicator(color: _emerald)))),
      ]),
    );
  }

  // ───────────── الرأس والفلاتر ─────────────
  Widget _header(double top, HaramainSite site) => Container(
        padding: EdgeInsets.fromLTRB(14, top + 8, 14, 14),
        decoration: const BoxDecoration(
          color: _emerald,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
          boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Column(children: [
          Row(children: [
            Text(site.emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(width: 10),
            PopupMenuButton<HaramainSite>(
              onSelected: _openSite,
              itemBuilder: (_) => [
                for (final s in HaramainSite.values)
                  PopupMenuItem(value: s, child: Text('${s.emoji} ${s.title}')),
              ],
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(site.title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                  Text(site.city,
                      style: const TextStyle(color: Color(0xFFD8E9E5), fontSize: 12)),
                ]),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
              ]),
            ),
            const Spacer(),
            IconButton(
                onPressed: () => setState(() {
                      _site = null;
                      _nav.stop();
                    }),
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white)),
          ]),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final p = await showSearchSheet(context, pois: [
                ..._pois,
                ..._store.pinsFor(site).map(HlPoi.fromPin),
              ]);
              if (p != null) _select(p);
            },
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration:
                  BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Row(children: [
                Icon(Icons.search_rounded, color: _emerald),
                SizedBox(width: 8),
                Text('أين تريد الذهاب؟',
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
      );

  Widget _chips() {
    final cats = HlCategory.values.where((c) => _pois.any((p) => p.category == c)).toList();
    if (cats.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.white.withAlpha(235), borderRadius: BorderRadius.circular(14)),
        child: const Text(
            'نقاط الخدمات والأبواب قيد التوثيق من المصادر الرسمية. الخريطة والموقع والمرشد والتثبيت تعمل الآن.',
            style: TextStyle(fontSize: 12)),
      );
    }
    Widget chip(String t, HlCategory? c) => Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: ChoiceChip(
            label: Text(t),
            selected: _filter == c,
            selectedColor: const Color(0xFFCDE8DF),
            backgroundColor: Colors.white,
            onSelected: (_) {
              setState(() => _filter = _filter == c ? null : c);
              _sync();
            },
          ),
        );
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        children: [chip('الكل', null), for (final c in cats) chip('${c.emoji} ${c.label}', c)],
      ),
    );
  }

  Widget _fab(IconData i, VoidCallback f, {bool on = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          elevation: 6,
          shape: const CircleBorder(),
          color: on ? _emerald : Colors.white,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: f,
            child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(i, color: on ? Colors.white : const Color(0xFF26312D))),
          ),
        ),
      );

  Widget _fabs() => Column(children: [
        _fab(_sat ? Icons.satellite_alt_rounded : Icons.map_outlined, () {
          setState(() {
            _sat = !_sat;
            _styleReady = false;
          });
        }, on: _sat),
        _fab(Icons.label_rounded, _toggleLabels, on: _labels),
        _fab(Icons.view_in_ar_rounded, _toggleTilt, on: _tilt),
        _fab(Icons.my_location_rounded, _locate),
        _fab(Icons.settings_rounded,
            () => showSettingsSheet(context, store: _store, onChanged: _rebuild)),
      ]);

  // ───────────── اللوحات السفلية ─────────────
  Widget _card(Widget child) => Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .58),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: _hc ? Border.all(color: Colors.black, width: 2) : null,
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, -5))],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                  child: Container(
                      width: 42,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                          color: const Color(0xFFD7DAD8), borderRadius: BorderRadius.circular(9)))),
              child,
            ]),
          ),
        ),
      );

  Widget _bottom() => AnimatedSize(
        duration: const Duration(milliseconds: 220),
        child: switch (_panel) {
          _Panel.idle => _idle(),
          _Panel.poi => _sel == null ? _idle() : _poiCard(_sel!),
          _Panel.preview => _sel == null ? _idle() : _preview(_sel!),
          _Panel.nav => _navBar(),
        },
      );

  Widget _gps() {
    final f = _loc.fix.value;
    final weak = f != null && f.accuracy > 40;
    final txt = !_locOk
        ? 'الموقع غير مفعّل'
        : f == null
            ? 'جارٍ تحديد الموقع...'
            : 'دقة ±${f.accuracy.round()} م${weak ? ' • الإشارة ضعيفة' : ''}';
    return InkWell(
      onTap: _locOk ? null : _retryLoc,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: (!_locOk || weak) ? const Color(0xFFFFF1DC) : const Color(0xFFE3F1EC),
            borderRadius: BorderRadius.circular(12)),
        child: Text('📡 $txt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _tile(String e, String t, VoidCallback f) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: f,
        child: Container(
          decoration: BoxDecoration(
              color: const Color(0xFFF4F7F5),
              borderRadius: BorderRadius.circular(16),
              border: _hc ? Border.all(color: Colors.black) : null),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(e, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 2),
            Text(t,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ]),
        ),
      );

  Widget _mini(String e, String t, VoidCallback f) => Expanded(
        child: InkWell(
          onTap: f,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              Text(e, style: const TextStyle(fontSize: 22)),
              Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );

  Widget _idle() {
    final site = _site!;
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const Text('خدمات سريعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const Spacer(),
        _gps(),
      ]),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.5,
        children: [
          _tile('🚪', 'الباب الأقرب', () => _quick(HlCategory.gate)),
          _tile('🚻', 'أقرب دورة مياه', () => _quick(HlCategory.toilet)),
          _tile('💧', 'أقرب موضأ', () => _quick(HlCategory.wudu)),
          _tile('🛗', 'أقرب مصعد', () => _quick(HlCategory.elevator)),
          _tile('♿', 'ذوي الهمم', () => _quick(HlCategory.accessibility)),
          _tile('📍', 'موقعي', _locate),
        ],
      ),
      const SizedBox(height: 6),
      Row(children: [
        _mini('🎧', 'المرشد', () => showGuideSheet(context,
            site: site,
            store: _store,
            voice: _voice,
            hasPoi: (id) => _data.byId(id) != null,
            onShow: (id) {
              final p = _data.byId(id);
              if (p != null) _select(p);
            })),
        _mini('🔢', 'العدّاد', () => showCounterSheet(context,
            site: site, store: _store, voice: _voice, voiceOn: _store.profile.voiceGuidance)),
        _mini('📌', 'مواقعي', () => showPinsSheet(context,
            site: site,
            store: _store,
            me: _loc.fix.value?.pos,
            onSelect: (pin) => _select(HlPoi.fromPin(pin)))),
        _mini('🆘', 'أنا تائه', () => showLostSheet(context,
            site: site,
            store: _store,
            me: _loc.fix.value?.pos,
            accuracy: _loc.fix.value?.accuracy,
            pois: _pois)),
        _mini('🚑', 'طوارئ', () => showCardSheet(context, store: _store)),
      ]),
    ]));
  }

  Widget _trustBadge(HlPoi p) {
    final (txt, col) = p.isPin
        ? ('حدّدته أنت', _blue)
        : switch (p.trust) {
            HlTrust.verifiedPoi => ('✓ موقع موثّق', _emerald),
            HlTrust.verifiedAccess => ('✓ اتصال موثّق', _emerald),
            HlTrust.verifiedRoute => ('✓ مسار موثّق', _emerald),
            HlTrust.unverified => ('⚠ موقع غير موثّق', const Color(0xFFE08A1E)),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: col.withAlpha(30), borderRadius: BorderRadius.circular(10)),
      child: Text(txt, style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }

  Widget _poiCard(HlPoi p) => _card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (p.photo != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(p.photo!,
                height: 120, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
          ),
        Row(children: [
          Text(p.emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              if (p.subtitle.isNotEmpty)
                Text(p.subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ]),
          ),
          IconButton(onPressed: _clearSel, icon: const Icon(Icons.close_rounded)),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _trustBadge(p),
          if (p.wheelchair) const Chip(label: Text('♿ ميسّر'), visualDensity: VisualDensity.compact),
          if (p.womenOnly) const Chip(label: Text('🧕 للنساء'), visualDensity: VisualDensity.compact),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: _emerald, minimumSize: const Size.fromHeight(48)),
              onPressed: () => _plan(p),
              icon: const Icon(Icons.directions_walk_rounded),
              label: const Text('المسار'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
              onPressed: () => _voice.speak('${p.title}. ${p.subtitle}'),
              icon: const Icon(Icons.volume_up_rounded)),
          if (p.isPin)
            IconButton.filledTonal(
                onPressed: () {
                  _store.removePin(p.id);
                  _clearSel();
                },
                icon: const Icon(Icons.delete_outline_rounded)),
        ]),
      ]));

  Widget _preview(HlPoi dest) {
    final r = _route;
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
            child: Text('إلى ${dest.title}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
        IconButton(onPressed: _clearSel, icon: const Icon(Icons.close_rounded)),
      ]),
      if (r != null) ...[
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${r.minutes}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          const Text(' دقائق ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text('(حوالي ${HmGeo.meters(r.meters)})', style: const TextStyle(color: Colors.black54)),
        ]),
        const SizedBox(height: 4),
        Wrap(spacing: 8, children: [
          _okChip('✓ مسار موثّق من مصادر رسمية'),
          if (r.accessible) _okChip('♿ مسار ميسّر'),
        ]),
        const SizedBox(height: 10),
        FilledButton.icon(
          style: FilledButton.styleFrom(
              backgroundColor: _emerald, minimumSize: const Size.fromHeight(52)),
          onPressed: _startNav,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('ابدأ التوجيه الصوتي'),
        ),
        const SizedBox(height: 8),
        for (final s in r.steps)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE3F1EC),
                child: Icon(s.turn.icon, color: _emerald, size: 20)),
            title: Text(s.text, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: s.meters > 0 ? Text('لمسافة ${HmGeo.meters(s.meters)} تقريبًا') : null,
          ),
      ] else ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF1DC), borderRadius: BorderRadius.circular(14)),
          child: const Text(
              'لا يوجد مسار موثّق داخل الحرم لهذه الوجهة بعد. لا يمكن بدء التوجيه الداخلي الآن؛ اتبعي اللوحات الإرشادية وتعليمات العاملين.',
              style: TextStyle(fontSize: 13, height: 1.5)),
        ),
      ],
    ]));
  }

  Widget _okChip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFFE3F1EC), borderRadius: BorderRadius.circular(10)),
        child: Text(t,
            style: const TextStyle(color: _emerald, fontSize: 12, fontWeight: FontWeight.w800)),
      );

  // ───────────── التوجيه أثناء الحركة ─────────────
  Widget _navHud(double top) {
    final n = _nav;
    final nx = n.next;
    final main = nx?.text ?? 'الوصول إلى ${n.targetName}';
    return Container(
      padding: EdgeInsets.fromLTRB(12, top + 8, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          IconButton(onPressed: _stopNav, icon: const Icon(Icons.close_rounded)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.arrived ? 'وصلت إلى وجهتك' : main,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Text(
                  n.arrived ? n.targetName : 'لمسافة ${HmGeo.meters(n.toNext)} تقريبًا',
                  style: const TextStyle(color: Colors.black54)),
            ]),
          ),
          Transform.rotate(
            angle: n.arrow * math.pi / 180,
            child: Icon(n.arrived ? Icons.flag_rounded : Icons.navigation_rounded,
                size: 54, color: n.arrived ? _emerald : _blue),
          ),
        ]),
        if (n.offRoute)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFFFFE3E3), borderRadius: BorderRadius.circular(12)),
            child: const Text('⚠ ابتعدت عن المسار. عد إلى الخط الأزرق.',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
      ]),
    );
  }

  Widget _navBar() {
    final n = _nav;
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        IconButton.filledTonal(
          onPressed: () {
            n.voiceOn = !n.voiceOn;
            if (!n.voiceOn) _voice.stop();
            setState(() {});
          },
          icon: Icon(n.voiceOn ? Icons.volume_up_rounded : Icons.volume_off_rounded),
        ),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${n.minutes} دقائق متبقية',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text('${HmGeo.meters(n.remaining)} تقريبًا',
              style: const TextStyle(color: Colors.black54)),
        ]),
      ]),
      const SizedBox(height: 4),
      _gps(),
      const SizedBox(height: 10),
      FilledButton.icon(
        style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE53935), minimumSize: const Size.fromHeight(50)),
        onPressed: _stopNav,
        icon: const Icon(Icons.stop_rounded),
        label: const Text('إيقاف التوجيه'),
      ),
    ]));
  }
}