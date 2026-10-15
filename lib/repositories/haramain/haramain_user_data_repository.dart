import 'package:maplibre_gl/maplibre_gl.dart';

import '../../models/haramain/accessibility_profile.dart';
import '../../models/haramain/haramain_map_demo_models.dart';
import '../../screens/haramain/haramain_live_models.dart';
import '../../screens/haramain/haramain_live_store.dart';

/// Local-first user data. A later Firebase implementation can wrap the same
/// methods without changing UI. Do not add continuous location sharing here.
abstract class HaramainUserDataRepository {
  AccessibilityProfile get profile;
  List<HlPin> pinsFor(HaramainSite site);
  HlPin? pinOf(HaramainSite site, HlPinKind kind);
  List<String> get recentSearches;
  String get pilgrimName;
  String get hotelNote;
  String get companionPhone;
  String get medicalNote;

  Future<void> load();
  Future<void> save();
  void setProfile(AccessibilityProfile profile);
  void addPin(HaramainSite site, HlPinKind kind, LatLng at,
      {String? label, String? poiId});
  void removePin(String id);
  void rememberSearch(String query);
  void saveCard({String? n, String? h, String? l, String? m});
}

/// SharedPreferences-backed implementation (current production path).
class LocalHaramainUserDataRepository implements HaramainUserDataRepository {
  LocalHaramainUserDataRepository(this._store);

  final HaramainLiveStore _store;

  @override
  AccessibilityProfile get profile => _store.profile;

  @override
  List<HlPin> pinsFor(HaramainSite site) => _store.pinsFor(site);

  @override
  HlPin? pinOf(HaramainSite site, HlPinKind kind) => _store.pinOf(site, kind);

  @override
  List<String> get recentSearches => List.unmodifiable(_store.recentSearches);

  @override
  String get pilgrimName => _store.name;

  @override
  String get hotelNote => _store.hotel;

  @override
  String get companionPhone => _store.leader;

  @override
  String get medicalNote => _store.medical;

  @override
  Future<void> load() => _store.load();

  @override
  Future<void> save() => _store.save();

  @override
  void setProfile(AccessibilityProfile profile) => _store.setProfile(profile);

  @override
  void addPin(HaramainSite site, HlPinKind kind, LatLng at,
          {String? label, String? poiId}) =>
      _store.addPin(site, kind, at, label: label, poiId: poiId);

  @override
  void removePin(String id) => _store.removePin(id);

  @override
  void rememberSearch(String query) => _store.rememberSearch(query);

  @override
  void saveCard({String? n, String? h, String? l, String? m}) =>
      _store.saveCard(n: n, h: h, l: l, m: m);
}
