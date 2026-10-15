import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/dua_model.dart';
import '../../models/dua_request_model.dart';

class DuasLocalStorage {
  static const _kUserDuas = 'rifqa.duas.user.v1';
  static const _kFavorites = 'rifqa.duas.favorites.v1';
  static const _kFontScale = 'rifqa.duas.fontScale.v1';
  static const _kShowTranslit = 'rifqa.duas.showTranslit.v1';
  static const _kShowTranslation = 'rifqa.duas.showTranslation.v1';

  static const _kAmanat = 'rifqa.duas.amanat.v1';

  Future<SharedPreferences> get _prefs {
    return SharedPreferences.getInstance();
  }

  // =========================================================
  // User Duas
  // =========================================================

  Future<List<Dua>> loadUserDuas() async {
    final raw = (await _prefs).getString(_kUserDuas);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final list = jsonDecode(raw) as List;

      return list
          .map(
            (e) => Dua.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveUserDuas(List<Dua> duas) async {
    final json = duas.map((d) => d.toJson()).toList();

    await (await _prefs).setString(
      _kUserDuas,
      jsonEncode(json),
    );
  }

  // =========================================================
  // Favorites
  // =========================================================

  Future<Set<String>> loadFavorites() async {
    final list = (await _prefs).getStringList(_kFavorites) ?? const [];

    return list.toSet();
  }

  Future<void> saveFavorites(Set<String> ids) async {
    await (await _prefs).setStringList(
      _kFavorites,
      ids.toList(),
    );
  }

  // =========================================================
  // Reading Settings
  // =========================================================

  Future<double> loadFontScale() async {
    return (await _prefs).getDouble(_kFontScale) ?? 1.0;
  }

  Future<void> saveFontScale(double value) async {
    await (await _prefs).setDouble(
      _kFontScale,
      value,
    );
  }

  Future<bool> loadShowTransliteration() async {
    return (await _prefs).getBool(_kShowTranslit) ?? true;
  }

  Future<void> saveShowTransliteration(bool value) async {
    await (await _prefs).setBool(
      _kShowTranslit,
      value,
    );
  }

  Future<bool> loadShowTranslation() async {
    return (await _prefs).getBool(_kShowTranslation) ?? true;
  }

  Future<void> saveShowTranslation(bool value) async {
    await (await _prefs).setBool(
      _kShowTranslation,
      value,
    );
  }

  // =========================================================
  // Amanat Al-Duaa
  // =========================================================

  Future<List<DuaRequest>> loadAmanat() async {
    final raw = (await _prefs).getString(_kAmanat);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List;

      return decoded
          .map(
            (item) => DuaRequest.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAmanat(
    List<DuaRequest> requests,
  ) async {
    final data = requests
        .map(
          (request) => request.toJson(),
        )
        .toList();

    await (await _prefs).setString(
      _kAmanat,
      jsonEncode(data),
    );
  }
}
