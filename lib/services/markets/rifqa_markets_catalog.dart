import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum RifqaCity { makkah, madinah }

extension RifqaCityText on RifqaCity {
  String get title => this == RifqaCity.makkah ? 'مكة المكرمة' : 'المدينة المنورة';
  String get caption => this == RifqaCity.makkah ? 'حول المسجد الحرام وفي أحياء مكة' : 'حول المسجد النبوي وفي أحياء المدينة';
  String get key => name;
}

class RifqaMarket {
  const RifqaMarket({
    required this.id,
    required this.name,
    required this.city,
    required this.area,
    required this.type,
    required this.description,
    required this.tags,
    required this.sourceUrl,
    required this.sourceKind,
    required this.informationStatus,
    this.parentId,
    this.latitude,
    this.longitude,
    this.openingHours,
  });

  final String id, name, area, type, description, sourceUrl, sourceKind, informationStatus;
  final RifqaCity city;
  final List<String> tags;
  final String? parentId, openingHours;
  final double? latitude, longitude;
  bool get hasCoordinates => latitude != null && longitude != null &&
      latitude!.isFinite && longitude!.isFinite &&
      latitude! >= -90 && latitude! <= 90 && longitude! >= -180 && longitude! <= 180;
  bool get officialSource => sourceKind == 'official';
  bool get isSubMarket => parentId != null && parentId!.isNotEmpty;
  String get cityName => city.title;
  String get category => switch (type) {
    'mall' || 'shopping_complex' || 'market_inside_mall' || 'retail_zone' => 'مول ومركز تجاري',
    'wholesale_market' => 'أسواق الجملة',
    'specialty_market' => 'سوق متخصص',
    'food_market' => 'أطعمة ومأكولات',
    'market_promenade' => 'ممشى تجاري',
    _ => 'أسواق شعبية',
  };
  String get assetImage {
    if (id.contains('clock') || id.contains('zamzam_towers')) return 'assets/markets/images/clocks.jpg';
    if (id.contains('safwa')) return 'assets/markets/images/safwa.jpg';
    if (id.contains('khalil') || id.contains('makkah_gate')) return 'assets/markets/images/khalil.jpg';
    if (id.contains('aziziyah') || id.contains('otaibiyah') || type.contains('wholesale')) return 'assets/markets/images/aziziyah.jpg';
    if (id.contains('makkah_mall') || id.contains('diyafa') || id.contains('hijaz')) return 'assets/markets/images/makkah_mall.jpg';
    if (id.contains('dates')) return 'assets/markets/images/dates.jpg';
    if (city == RifqaCity.madinah && type == 'mall') return 'assets/markets/images/madinah_mall.jpg';
    if (city == RifqaCity.madinah) return 'assets/markets/images/madinah_market.jpg';
    return 'assets/markets/images/family.jpg';
  }

  static RifqaMarket fromJson(Map<String, dynamic> data) {
    final coord = data['location_coordinates'];
    double? lat, lng;
    if (coord is Map) {
      lat = (coord['latitude'] as num?)?.toDouble();
      lng = (coord['longitude'] as num?)?.toDouble();
    }
    return RifqaMarket(
      id: (data['id'] ?? '').toString(),
      name: (data['name_ar'] ?? '').toString(),
      city: data['city'] == 'madinah' ? RifqaCity.madinah : RifqaCity.makkah,
      area: (data['area_ar'] ?? '').toString(),
      type: (data['type'] ?? '').toString(),
      description: (data['description_ar'] ?? '').toString(),
      tags: (data['suggested_filters_ar'] as List? ?? const []).map((e) => e.toString()).toList(),
      sourceUrl: (data['source_url'] ?? '').toString(),
      sourceKind: (data['source_kind'] ?? '').toString(),
      informationStatus: (data['information_status'] ?? '').toString(),
      parentId: data['parent_market_id']?.toString(),
      openingHours: data['opening_hours']?.toString(),
      latitude: lat,
      longitude: lng,
    );
  }
}

class RifqaMarketsCatalog {
  RifqaMarketsCatalog._();
  static final RifqaMarketsCatalog instance = RifqaMarketsCatalog._();
  List<RifqaMarket>? _cached;

  Future<List<RifqaMarket>> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString('assets/markets/markets_seed.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final rawList = data['markets'] as List;
    final markets = rawList
        .map((e) => RifqaMarket.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((m) => m.id.isNotEmpty && m.name.isNotEmpty)
        .toList(growable: false);
    _cached = markets;
    return markets;
  }

  RifqaMarket? parentOf(List<RifqaMarket> all, RifqaMarket m) {
    if (m.parentId == null) return null;
    for (final p in all) { if (p.id == m.parentId) return p; }
    return null;
  }

  List<RifqaMarket> childrenOf(List<RifqaMarket> all, RifqaMarket m) =>
      all.where((p) => p.parentId == m.id).toList(growable: false);
}

class RifqaMarketSaved {
  RifqaMarketSaved._();
  static final RifqaMarketSaved instance = RifqaMarketSaved._();
  static const _key = 'rifqa_markets_premium_favorites_v1';
  final Set<String> favorites = <String>{};
  bool _ready = false;

  Future<void> load() async {
    if (_ready) return;
    final prefs = await SharedPreferences.getInstance();
    favorites.addAll(prefs.getStringList(_key) ?? const []);
    _ready = true;
  }

  bool contains(String id) => favorites.contains(id);

  Future<void> toggle(String id) async {
    if (!favorites.add(id)) favorites.remove(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, favorites.toList()..sort());
  }
}

class RifqaMarketsLinks {
  static Future<bool> source(RifqaMarket market) async {
    final uri = Uri.tryParse(market.sourceUrl);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// A Google Maps *search*, not a verified pin, route length, or navigation ETA.
  static Future<bool> mapSearch(RifqaMarket market) async {
    final uri = market.hasCoordinates
        ? Uri.https('www.google.com', '/maps/dir/', {
            'api': '1',
            'destination': '${market.latitude},${market.longitude}',
          })
        : Uri.https('www.google.com', '/maps/search/', {
            'api': '1',
            'query': '${market.name}، ${market.area}، ${market.city.title}، السعودية',
          });
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
