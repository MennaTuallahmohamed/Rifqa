import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../models/haramain/accessibility_profile.dart';
import '../../../models/haramain/haramain_experience_state.dart';
import '../../../models/haramain/haramain_map_demo_models.dart';
import '../../../repositories/haramain/haramain_user_data_repository.dart';
import '../../../services/haramain/haramain_connectivity_service.dart';
import '../../../services/haramain/haramain_nav_safety.dart';
import '../../../services/haramain/haramain_search_service.dart';
import '../../../services/haramain/haramain_voice_service.dart';
import '../haramain_data_service.dart';
import '../haramain_geo.dart';
import '../haramain_live_models.dart';
import '../haramain_location_service.dart';
import '../haramain_nav_session.dart';

/// What the pilgrim is currently looking at / doing.
///
/// These are UI-facing states. `HaramainExperienceState` in models/ is the
/// documented vocabulary; this enum is what the widgets actually switch on,
/// because [HaramainExperienceState.noVerifiedRoute] and
/// [HaramainExperienceState.connectivityLimited] are *modifiers* on top of a
/// primary state rather than primary states themselves.
enum HmPanel {
  /// A. Explore — idle map with quick services.
  explore,

  /// B/C. Searching / search results live in a modal sheet; the map stays put.
  poi,

  /// E. Route preview.
  preview,

  /// F. Active navigation.
  navigating,

  /// G. Lost mode.
  lost,
}

/// Immutable snapshot of everything the map needs to draw.
///
/// Building one snapshot and diffing it is what lets the map coordinator
/// repaint once per meaningful change instead of on every GPS tick.
@immutable
class HmMapSnapshot {
  final List<HlPoi> pois;
  final List<HlPin> pins;
  final HlPoi? selected;
  final HlRoute? route;

  const HmMapSnapshot({
    this.pois = const [],
    this.pins = const [],
    this.selected,
    this.route,
  });

  static const empty = HmMapSnapshot();

  /// Cheap structural identity used to skip redundant MapLibre repaints.
  int get signature => Object.hash(
        Object.hashAll(pois.map((p) => p.id)),
        Object.hashAll(pins.map((p) => p.id)),
        selected?.id ?? '',
        route == null ? '' : route!.points.length,
      );

  @override
  bool operator ==(Object other) =>
      other is HmMapSnapshot && other.signature == signature;

  @override
  int get hashCode => signature.hashCode;
}

/// Owns every piece of Haramain state that the UI and the map react to.
///
/// Deliberately a single [ChangeNotifier] rather than a tree of them: the map
/// screen rebuilds on notification, so consolidating here means one rebuild
/// per logical change instead of N. Widgets that are expensive (the MapLibre
/// canvas) read from [listenable]-free snapshots so they do not rebuild when,
/// for example, only the connectivity banner changes.
class HaramainController extends ChangeNotifier {
  HaramainController({
    required this.data,
    required this.repository,
    required this.navSafety,
    required this.location,
    required this.voice,
    required this.search,
    required this.connectivity,
    required this.navSession,
  });

  final HaramainDataService data;
  final HaramainUserDataRepository repository;
  final HaramainNavSafety navSafety;
  final HaramainLocationService location;
  final HaramainVoiceService voice;
  final HaramainSearchService search;
  final HaramainConnectivityService connectivity;
  final HaramainNavSession navSession;

  // ─────────────────────── loading / entry ───────────────────────

  bool _booting = true;
  bool get booting => _booting;

  String? _fatalError;
  String? get fatalError => _fatalError;

  // ─────────────────────── site ───────────────────────

  HaramainSite? _site;
  HaramainSite? get site => _site;

  List<HlPoi> _pois = const [];
  List<HlPoi> get allPois => _pois;

  List<HlPoi> get pinnedPois =>
      repository.pinsFor(_site ?? HaramainSite.makkah).map(HlPoi.fromPin).toList();

  // ─────────────────────── map presentation ───────────────────────

  HlCategory? _filter;
  HlCategory? get filter => _filter;

  bool _satellite = true;
  bool get satellite => _satellite;

  bool _tilt = false;
  bool get tilt => _tilt;

  

  // ─────────────────────── selection / panel ───────────────────────

  HmPanel _panel = HmPanel.explore;
  HmPanel get panel => _panel;

  HlPoi? _selected;
  HlPoi? get selected => _selected;

  HlRoute? _route;
  HlRoute? get route => _route;

  /// True when the user asked for a route but the dataset has no verified one.
  bool get routeBlockedBySafety => _panel == HmPanel.preview && _route == null;

  bool get isNavigating => _panel == HmPanel.navigating && navSession.active;

  // ─────────────────────── location ───────────────────────

  bool _locationEnabled = false;
  bool get locationEnabled => _locationEnabled;

  bool _accuracyPoor = false;
  bool get accuracyPoor => _accuracyPoor;

  double? get accuracy => location.fix.value?.accuracy;
  LatLng? get myPosition => location.fix.value?.pos;

  // ─────────────────────── derived experience state ───────────────────────

  AccessibilityProfile get profile => repository.profile;

  bool get wheelchairMode => profile.wheelchairMode;
  bool get highContrast => profile.highContrast;
  bool get largeText => profile.largeText;
  bool get reduceVisualComplexity => profile.reduceVisualComplexity;
  bool get voiceGuidance => profile.voiceGuidance;

  HaramainConnectivity get connectivityState => connectivity.current;

  /// Documented state vocabulary, used for state assertions and so the rest of
  /// the app can reason about the map without reading UI code.
  HaramainExperienceState get experienceState {
    if (connectivity.current == HaramainConnectivity.offline &&
        _pois.isEmpty) {
      return HaramainExperienceState.connectivityLimited;
    }
    if (_panel == HmPanel.lost) return HaramainExperienceState.lostMode;
    if (isNavigating) return HaramainExperienceState.activeNavigation;
    if (_panel == HmPanel.preview) {
      return _route == null
          ? HaramainExperienceState.noVerifiedRoute
          : HaramainExperienceState.routePreview;
    }
    if (_panel == HmPanel.poi) {
      return wheelchairMode
          ? HaramainExperienceState.accessibilityMode
          : HaramainExperienceState.poiSelected;
    }
    if (wheelchairMode) return HaramainExperienceState.accessibilityMode;
    return HaramainExperienceState.explore;
  }

  // ─────────────────────── snapshot for the map ───────────────────────

  HmMapSnapshot _snapshot = HmMapSnapshot.empty;
  HmMapSnapshot get snapshot => _snapshot;

  /// POIs currently visible on the map after the active category filter.
  List<HlPoi> get visiblePois => _visible();

  List<HlCategory> get availableQuickServices =>
      HaramainSearchService.availableQuickServices(_pois);

  bool get hasVerifiedPois => _pois.any((p) => p.verified);

  int get verifiedPoiCount => _pois.where((p) => p.verified).length;

  /// Whether a verified walking network exists for the current site.
  ///
  /// This is the single honest source of "can we navigate?" and it is the same
  /// gate the start-navigation button uses, so the UI can never offer
  /// navigation that the safety gate would then refuse.
  bool get navigationPossible => _site != null && navSafety.hasVerifiedNetwork(_site!);

  // ─────────────────────── lifecycle ───────────────────────

  Future<void> boot() async {
    try {
      await repository.load();
    } catch (e) {
      _fatalError = 'تعذّر حفظ بياناتك المحفوظة: $e';
    }
    _applyVoicePreference();
    connectivity.start();
    _locationEnabled = await location.start();
    location.fix.addListener(_onFix);
    location.heading.addListener(_onHeading);
    navSession.addListener(_onNavSession);
    connectivity.addListener(_onConnectivity);
    _booting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    location.fix.removeListener(_onFix);
    location.heading.removeListener(_onHeading);
    navSession.removeListener(_onNavSession);
    connectivity.removeListener(_onConnectivity);
    navSession.dispose();
    location.dispose();
    voice.stop();
    connectivity.dispose();
    super.dispose();
  }

  void _applyVoicePreference() {
    navSession.voiceOn = voiceGuidance;
  }

  void _onConnectivity() {
    // Only the banner cares about this; avoid a full rebuild storm.
    notifyListeners();
  }

  void _onFix() {
    final f = location.fix.value;
    _accuracyPoor = f != null && f.accuracy > 40;
    if (isNavigating) {
      navSession.update(f!.pos, location.heading.value);
      _rebuildSnapshot();
    }
    notifyListeners();
  }

  void _onHeading() {
    final f = location.fix.value;
    if (isNavigating && f != null) {
      navSession.update(f.pos, location.heading.value);
    }
  }

  void _onNavSession() {
    // The nav HUD renders from navSession directly via ListenableBuilder, so
    // the controller only needs to keep the snapshot's route in sync.
    _rebuildSnapshot();
  }

  void _rebuild() {
    if (_booting) return;
    notifyListeners();
  }

  void _rebuildSnapshot() {
    final next = HmMapSnapshot(
      pois: _visible(),
      pins: repository.pinsFor(_site ?? HaramainSite.makkah),
      selected: _selected,
      route: navSession.route ?? _route,
    );
    if (next == _snapshot) return;
    _snapshot = next;
    notifyListeners();
  }

  // ─────────────────────── site switching ───────────────────────

  /// Opens a site. Returns the site the caller should render.
  HaramainSite openSite(HaramainSite s) {
    if (navSession.active) navSession.stop();
    _site = s;
    _pois = data.poisFor(s);
    _filter = null;
    _selected = null;
    _route = null;
    _panel = HmPanel.explore;
    _rebuildSnapshot();
    _rebuild();
    return s;
  }

  /// Returns to the site chooser.
  void closeSite() {
    if (navSession.active) navSession.stop();
    _site = null;
    _pois = const [];
    _selected = null;
    _route = null;
    _filter = null;
    _panel = HmPanel.explore;
    _snapshot = HmMapSnapshot.empty;
    _rebuild();
  }

  // ─────────────────────── POI filtering ───────────────────────

  List<HlPoi> _visible() {
    final base = HaramainSearchService.filterByCategory(
      _pois,
      _filter,
      accessibleOnly: wheelchairMode,
    );
    final sel = _selected;
    if (sel != null && !sel.isPin && !base.any((p) => p.id == sel.id)) {
      return [...base, sel];
    }
    return base;
  }

  void setFilter(HlCategory? c) {
    if (_filter == c) return;
    _filter = c;
    _rebuildSnapshot();
    _rebuild();
  }

  void toggleSatellite() {
    _satellite = !_satellite;
    _rebuild();
  }

  void toggleTilt() {
    _tilt = !_tilt;
    _rebuild();
  }

  void setTilt(bool v) {
    if (_tilt == v) return;
    _tilt = v;
    _rebuild();
  }

  // ─────────────────────── selection ───────────────────────

  /// Selects a POI or personal pin. Returns the focus position for the camera.
  LatLng? select(HlPoi p) {
    _selected = p;
    _route = null;
    _panel = HmPanel.poi;
    _rebuildSnapshot();
    _rebuild();
    return p.position;
  }

  void clearSelection() {
    _selected = null;
    _route = null;
    _panel = HmPanel.explore;
    _rebuildSnapshot();
    _rebuild();
  }

  void openLostMode() {
    _panel = HmPanel.lost;
    _rebuild();
  }

  void closeLostMode() {
    if (_panel == HmPanel.lost) _panel = HmPanel.explore;
    _rebuild();
  }

  HlPoi? poiById(String id) {
    for (final p in _pois) {
      if (p.id == id) return p;
    }
    for (final p in pinnedPois) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ─────────────────────── navigation safety gate ───────────────────────

  /// Attempts to build a route preview.
  ///
  /// This is the ONLY place a route is produced, and it delegates to
  /// [HaramainNavSafety], which only ever builds from edges explicitly marked
  /// VERIFIED_ROUTE + navigationAllowed. A verified POI is not enough.
  ///
  /// Returns null when no verified route exists — the caller must then show the
  /// "navigation unavailable" state rather than inventing a line on the map.
  HlRoute? planRoute(HlPoi dest) {
    final s = _site;
    final from = myPosition;
    if (s == null || from == null) {
      _selected = dest;
      _route = null;
      _panel = HmPanel.preview;
      _rebuildSnapshot();
      _rebuild();
      return null;
    }

    final route = navSafety.verifiedRouteTo(
      site: s,
      from: from,
      dest: dest,
      profile: profile,
    );

    _selected = dest;
    _route = route;
    _panel = HmPanel.preview;
    _rebuildSnapshot();
    _rebuild();
    return route;
  }

  /// Starts turn-by-turn navigation.
  ///
  /// Returns false and leaves the panel in preview when there is no verified
  /// route. There is deliberately no code path that can start navigation
  /// without a route instance produced by [planRoute].
  bool startNavigation() {
    final r = _route;
    if (r == null) return false;
    if (!navSafety.canStartNavigation(r)) return false;
    if (wheelchairMode && !r.accessible) return false;

    navSession.voiceOn = voiceGuidance;
    navSession.startRoute(r);
    _panel = HmPanel.navigating;
    _rebuildSnapshot();
    _rebuild();
    return true;
  }

  void stopNavigation() {
    navSession.stop();
    setTilt(false);
    _panel = _selected == null ? HmPanel.explore : HmPanel.poi;
    _rebuildSnapshot();
    _rebuild();
  }

  void toggleNavigationVoice() {
    navSession.voiceOn = !navSession.voiceOn;
    if (!navSession.voiceOn) voice.stop();
    _applyVoicePreference();
    _rebuild();
  }

  void speak(String text) => voice.speak(text);

  // ─────────────────────── personal pins ───────────────────────

  HlPin? pinOf(HlPinKind kind) =>
      _site == null ? null : repository.pinOf(_site!, kind);

  void savePinAtCurrentPosition(HlPinKind kind, {String? label, String? poiId}) {
    final s = _site;
    final p = myPosition;
    if (s == null || p == null) return;
    repository.addPin(s, kind, p, label: label, poiId: poiId);
    _rebuildSnapshot();
    _rebuild();
  }

  /// Saves a gate as "my gate", storing the gate id, name, site and timestamp
  /// exactly as the Pilgrim saved it.
  void saveMyGate(HlPoi gate) {
    final s = _site;
    if (s == null) return;
    repository.addPin(
      s,
      HlPinKind.myGate,
      gate.position,
      label: gate.title,
      poiId: gate.id,
    );
    _rebuildSnapshot();
    _rebuild();
  }

  void removePin(String id) {
    repository.removePin(id);
    _rebuildSnapshot();
    _rebuild();
  }

  /// Points the map at a saved pin without fabricating a route.
  LatLng? showPin(HlPin pin) {
    final poi = HlPoi.fromPin(pin);
    return select(poi);
  }

  // ─────────────────────── preferences ───────────────────────

  void updateProfile(AccessibilityProfile p) {
    repository.setProfile(p);
    _applyVoicePreference();
    if (p.wheelchairMode != wheelchairMode) {
      // Accessibility filtering changed: recompute visible POIs and drop any
      // route that is no longer proven accessible.
      if (p.wheelchairMode && _route != null && !_route!.accessible) {
        _route = null;
      }
      _rebuildSnapshot();
    }
    _rebuild();
  }

  void rememberSearch(String query) => repository.rememberSearch(query);

  List<String> get recentSearches => repository.recentSearches;

  // ─────────────────────── distance helpers ───────────────────────

  /// Straight-line distance only. Never rendered as a walking route length.
  double? distanceFromMe(LatLng to) {
    final me = myPosition;
    if (me == null) return null;
    return HmGeo.distance(me, to);
  }

  void resetVoice() => voice.stop();
}