import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/haramain/accessibility_profile.dart';
import 'haramain_live_models.dart';
import '../../models/haramain/haramain_map_demo_models.dart' show HaramainSite;

class HaramainLiveStore extends ChangeNotifier {
  static const _key = 'rifqa_haramain_live_v1';

  AccessibilityProfile profile = const AccessibilityProfile();
  String name = '', hotel = '', leader = '', medical = '';
  int tawaf = 0, sai = 0;
  final List<HlPin> pins = [];
  final Map<String, int> guide = {'makkah': 0, 'madinah': 0};
  final List<String> recentSearches = [];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      profile = AccessibilityProfile.fromJson(
          Map<String, dynamic>.from(j['profile'] as Map? ?? {}));
      name = j['name'] ?? '';
      hotel = j['hotel'] ?? '';
      leader = j['leader'] ?? '';
      medical = j['medical'] ?? '';
      tawaf = (j['tawaf'] as num?)?.toInt() ?? 0;
      sai = (j['sai'] as num?)?.toInt() ?? 0;
      guide['makkah'] = (j['gMakkah'] as num?)?.toInt() ?? 0;
      guide['madinah'] = (j['gMadinah'] as num?)?.toInt() ?? 0;
      pins
        ..clear()
        ..addAll(((j['pins'] as List?) ?? const [])
            .map((e) => HlPin.fromJson(Map<String, dynamic>.from(e as Map))));
      recentSearches
        ..clear()
        ..addAll(((j['recentSearches'] as List?) ?? const [])
            .map((e) => e.toString()));
    } catch (_) {}
    notifyListeners();
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _key,
      jsonEncode({
        'profile': profile.toJson(),
        'name': name,
        'hotel': hotel,
        'leader': leader,
        'medical': medical,
        'tawaf': tawaf,
        'sai': sai,
        'gMakkah': guide['makkah'],
        'gMadinah': guide['madinah'],
        'pins': pins.map((e) => e.toJson()).toList(),
        'recentSearches': recentSearches,
      }),
    );
    notifyListeners();
  }

  void setProfile(AccessibilityProfile p) {
    profile = p;
    save();
  }

  void setTawaf(int v) {
    tawaf = v.clamp(0, 7).toInt();
    save();
  }

  void setSai(int v) {
    sai = v.clamp(0, 7).toInt();
    save();
  }

  void setGuide(HaramainSite s, int i) {
    guide[s.name] = i;
    save();
  }

  void saveCard({String? n, String? h, String? l, String? m}) {
    name = n ?? name;
    hotel = h ?? hotel;
    leader = l ?? leader;
    medical = m ?? medical;
    save();
  }

  List<HlPin> pinsFor(HaramainSite s) =>
      pins.where((p) => p.site == s).toList(growable: false);

  /// الأنواع الأساسية (بابي/فندقي/الباص/التجمع) لها نقطة واحدة فقط لكل حرم.
  void addPin(HaramainSite s, HlPinKind k, LatLng at,
      {String? label, String? poiId}) {
    if (k != HlPinKind.custom) {
      pins.removeWhere((p) => p.site == s && p.kind == k);
    }
    pins.add(HlPin(
      id: '${k.name}_${DateTime.now().microsecondsSinceEpoch}',
      label: label ?? k.label,
      site: s,
      kind: k,
      position: at,
      createdAt: DateTime.now(),
      poiId: poiId,
    ));
    save();
  }

  void rememberSearch(String q) {
    final v = q.trim();
    if (v.isEmpty) return;
    recentSearches.remove(v);
    recentSearches.insert(0, v);
    if (recentSearches.length > 12) {
      recentSearches.removeRange(12, recentSearches.length);
    }
    save();
  }

  HlPin? pinOf(HaramainSite s, HlPinKind k) {
    for (final p in pins) {
      if (p.site == s && p.kind == k) return p;
    }
    return null;
  }

  void removePin(String id) {
    pins.removeWhere((p) => p.id == id);
    save();
  }
}
