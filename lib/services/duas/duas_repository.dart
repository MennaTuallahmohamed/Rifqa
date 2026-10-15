import 'package:flutter/foundation.dart';

import '../../models/dua_model.dart';
import '../../models/dua_request_model.dart';
import '../../screens/duas/duas_data.dart';
import 'duas_local_storage.dart';

class DuasRepository extends ChangeNotifier {
  DuasRepository({
    DuasLocalStorage? storage,
  }) : _storage = storage ?? DuasLocalStorage();

  final DuasLocalStorage _storage;

  List<Dua> _user = [];
  Set<String> _favorites = {};
  List<DuaRequest> _amanat = [];

  double _fontScale = 1.0;

  bool _showTransliteration = true;
  bool _showTranslation = true;
  bool _ready = false;

  // =========================================================
  // Getters
  // =========================================================

  bool get isReady => _ready;

  double get fontScale => _fontScale;

  bool get showTransliteration => _showTransliteration;

  bool get showTranslation => _showTranslation;

  List<Dua> get documented => DuasData.all;

  List<Dua> get userDuas {
    return List.unmodifiable(_user);
  }

  List<Dua> get all {
    return [
      ...DuasData.all,
      ..._user,
    ];
  }

  List<DuaRequest> get amanat {
    return List.unmodifiable(_amanat);
  }

  List<DuaRequest> get pendingAmanat {
    return _amanat.where((request) => !request.isPrayed).toList();
  }

  List<DuaRequest> get completedAmanat {
    return _amanat.where((request) => request.isPrayed).toList();
  }

  int get pendingAmanatCount {
    return pendingAmanat.length;
  }

  int get completedAmanatCount {
    return completedAmanat.length;
  }

  // =========================================================
  // Init
  // =========================================================

  Future<void> init() async {
    _user = await _storage.loadUserDuas();

    _favorites = await _storage.loadFavorites();

    _amanat = await _storage.loadAmanat();

    _fontScale = await _storage.loadFontScale();

    _showTransliteration = await _storage.loadShowTransliteration();

    _showTranslation = await _storage.loadShowTranslation();

    _ready = true;

    notifyListeners();
  }

  // =========================================================
  // Find Dua
  // =========================================================

  Dua? byId(String id) {
    for (final dua in all) {
      if (dua.id == id) {
        return dua;
      }
    }

    return null;
  }

  int countIn(DuaCategory category) {
    return documented
        .where(
          (dua) => dua.category == category,
        )
        .length;
  }

  // =========================================================
  // Favorites
  // =========================================================

  List<Dua> get favorites {
    return all
        .where(
          (dua) => _favorites.contains(dua.id),
        )
        .toList();
  }

  bool isFavorite(String id) {
    return _favorites.contains(id);
  }

  Future<void> toggleFavorite(String id) async {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }

    notifyListeners();

    await _storage.saveFavorites(
      _favorites,
    );
  }

  // =========================================================
  // Smart Context
  // =========================================================

  List<Dua> duasForStage(
    RitualStage stage,
  ) {
    return all
        .where(
          (dua) => dua.stages.contains(stage),
        )
        .toList();
  }

  Dua? smartDuaForStage(
    RitualStage stage,
  ) {
    final results = duasForStage(stage);

    if (results.isEmpty) {
      return null;
    }

    final documentedResults = results
        .where(
          (dua) => dua.sourceType.isDocumented,
        )
        .toList();

    if (documentedResults.isNotEmpty) {
      return documentedResults.first;
    }

    return results.first;
  }

  // =========================================================
  // Dua of the Day
  // =========================================================

  Dua duaOfTheDay([
    DateTime? now,
  ]) {
    final time = now ?? DateTime.now();

    final startOfYear = DateTime(
      time.year,
      1,
      1,
    );

    final dayOfYear = time.difference(startOfYear).inDays;

    final pool = documented
        .where(
          (dua) => dua.sourceType.isDocumented,
        )
        .toList();

    return pool[dayOfYear % pool.length];
  }

  // =========================================================
  // Search
  // =========================================================

  static String normalizeArabic(
    String value,
  ) {
    return value
        .replaceAll(
          RegExp(
            r'[\u064B-\u065F\u0670\u0640]',
          ),
          '',
        )
        .replaceAll(
          RegExp(r'[أإآٱ]'),
          'ا',
        )
        .replaceAll(
          'ى',
          'ي',
        )
        .replaceAll(
          'ة',
          'ه',
        )
        .toLowerCase();
  }

  List<Dua> search({
    String query = '',
    DuaCategory? category,
    Set<DuaSourceType>? sources,
    bool favoritesOnly = false,
    bool mineOnly = false,
  }) {
    final q = normalizeArabic(
      query.trim(),
    );

    Iterable<Dua> results = mineOnly ? _user : all;

    if (favoritesOnly) {
      results = results.where(
        (dua) => _favorites.contains(dua.id),
      );
    }

    if (category != null) {
      results = results.where(
        (dua) => dua.category == category,
      );
    }

    if (sources != null) {
      results = results.where(
        (dua) => sources.contains(
          dua.sourceType,
        ),
      );
    }

    if (q.isNotEmpty) {
      results = results.where(
        (dua) {
          final text = normalizeArabic(
            [
              dua.title,
              dua.arabicText,
              dua.reference,
              dua.transliteration ?? '',
              ...dua.translations.values,
            ].join(' '),
          );

          return text.contains(q);
        },
      );
    }

    return results.toList();
  }

  // =========================================================
  // Reading Settings
  // =========================================================

  Future<void> setFontScale(
    double value, {
    bool persist = true,
  }) async {
    _fontScale = value.clamp(0.8, 2.0);

    notifyListeners();

    if (persist) {
      await _storage.saveFontScale(
        _fontScale,
      );
    }
  }

  Future<void> setShowTransliteration(
    bool value,
  ) async {
    _showTransliteration = value;

    notifyListeners();

    await _storage.saveShowTransliteration(
      value,
    );
  }

  Future<void> setShowTranslation(
    bool value,
  ) async {
    _showTranslation = value;

    notifyListeners();

    await _storage.saveShowTranslation(
      value,
    );
  }

  // =========================================================
  // My Duas
  // =========================================================

  Future<Dua> addUserDua({
    required String title,
    required String arabicText,
    required DuaCategory category,
  }) async {
    final now = DateTime.now();

    final dua = Dua(
      id: 'user_${now.microsecondsSinceEpoch}',
      title: title.trim(),
      arabicText: arabicText.trim(),
      category: category,
      sourceType: DuaSourceType.userCreated,
      reference: 'دعاء أضافه المستخدم',
      isUserCreated: true,
      syncStatus: SyncStatus.pending,
      updatedAt: now,
    );

    _user = [
      dua,
      ..._user,
    ];

    notifyListeners();

    await _storage.saveUserDuas(
      _user,
    );

    return dua;
  }

  Future<void> updateUserDua(
    String id, {
    String? title,
    String? arabicText,
    DuaCategory? category,
  }) async {
    final index = _user.indexWhere(
      (dua) => dua.id == id,
    );

    if (index < 0) {
      return;
    }

    _user[index] = _user[index].copyWith(
      title: title?.trim(),
      arabicText: arabicText?.trim(),
      category: category,
      syncStatus: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );

    notifyListeners();

    await _storage.saveUserDuas(
      _user,
    );
  }

  Future<void> deleteUserDua(
    String id,
  ) async {
    _user = _user
        .where(
          (dua) => dua.id != id,
        )
        .toList();

    _favorites.remove(id);

    notifyListeners();

    await _storage.saveUserDuas(
      _user,
    );

    await _storage.saveFavorites(
      _favorites,
    );
  }

  // =========================================================
  // Amanat Al-Duaa
  // =========================================================

  Future<DuaRequest> addAmanah({
    required String personName,
    required String request,
    String note = '',
  }) async {
    final now = DateTime.now();

    final item = DuaRequest(
      id: 'amanah_${now.microsecondsSinceEpoch}',
      personName: personName.trim(),
      request: request.trim(),
      note: note.trim(),
      createdAt: now,
    );

    _amanat = [
      item,
      ..._amanat,
    ];

    notifyListeners();

    await _storage.saveAmanat(
      _amanat,
    );

    return item;
  }

  Future<void> updateAmanah(
    String id, {
    String? personName,
    String? request,
    String? note,
  }) async {
    final index = _amanat.indexWhere(
      (item) => item.id == id,
    );

    if (index < 0) {
      return;
    }

    _amanat[index] = _amanat[index].copyWith(
      personName: personName?.trim(),
      request: request?.trim(),
      note: note?.trim(),
    );

    notifyListeners();

    await _storage.saveAmanat(
      _amanat,
    );
  }

  Future<void> toggleAmanahDone(
    String id,
  ) async {
    final index = _amanat.indexWhere(
      (item) => item.id == id,
    );

    if (index < 0) {
      return;
    }

    final old = _amanat[index];

    if (old.isPrayed) {
      _amanat[index] = old.copyWith(
        status: DuaRequestStatus.pending,
        clearPrayedAt: true,
      );
    } else {
      _amanat[index] = old.copyWith(
        status: DuaRequestStatus.prayed,
        prayedAt: DateTime.now(),
      );
    }

    notifyListeners();

    await _storage.saveAmanat(
      _amanat,
    );
  }

  Future<void> deleteAmanah(
    String id,
  ) async {
    _amanat = _amanat
        .where(
          (item) => item.id != id,
        )
        .toList();

    notifyListeners();

    await _storage.saveAmanat(
      _amanat,
    );
  }
}
