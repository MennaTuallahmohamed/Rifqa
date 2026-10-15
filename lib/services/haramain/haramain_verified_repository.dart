import 'dart:convert';

import 'package:flutter/services.dart';

/// Verification levels used by the Haramain verified dataset.
///
/// Important:
/// VERIFIED_POI does NOT mean that a navigation route is verified.
/// VERIFIED_ACCESS means an official source confirms an access/connection.
/// VERIFIED_ROUTE is required before a route can be used for navigation.
enum HaramainVerificationStatus {
  verifiedPoi,
  verifiedAccess,
  verifiedRoute,
  unverified,
}

class HaramainVerifiedRepository {
  static const String _makkahDatasetPath =
      'assets/data/haramain/makkah_haram_verified.json';

  Map<String, dynamic>? _makkahData;

  /// Loads the verified Makkah dataset from Flutter assets.
  Future<void> loadMakkahDataset() async {
    final jsonString = await rootBundle.loadString(_makkahDatasetPath);

    final decoded = jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid Haramain dataset format.',
      );
    }

    _validateDataset(decoded);

    _makkahData = decoded;
  }

  /// True after the Makkah dataset has been loaded successfully.
  bool get isMakkahLoaded => _makkahData != null;

  /// Returns the complete loaded dataset.
  ///
  /// This should mainly be used for debugging or future data services.
  Map<String, dynamic> get makkahData {
    final data = _makkahData;

    if (data == null) {
      throw StateError(
        'Makkah Haramain dataset has not been loaded yet.',
      );
    }

    return Map<String, dynamic>.unmodifiable(data);
  }

  /// Dataset ID.
  String get datasetId {
    return makkahData['datasetId'] as String? ?? '';
  }

  /// Dataset schema version.
  String get schemaVersion {
    return makkahData['schemaVersion'] as String? ?? '';
  }

  /// Returns the site information.
  Map<String, dynamic> get site {
    final value = makkahData['site'];

    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.unmodifiable(value);
    }

    return const {};
  }

  /// Returns all official sources stored in the dataset.
  List<Map<String, dynamic>> get sources {
    return _readMapList('sources');
  }

  /// Returns verified accessible gates.
  List<Map<String, dynamic>> get accessibleGates {
    return _readMapList('accessibleGates');
  }

  /// Returns verified accessible prayer areas.
  List<Map<String, dynamic>> get accessiblePrayerAreas {
    return _readMapList('accessiblePrayerAreas');
  }

  /// Returns verified gates associated with women's services.
  List<Map<String, dynamic>> get womenServiceAccessGates {
    return _readMapList('womenServiceAccessGates');
  }

  /// Returns verified ablution-area information.
  List<Map<String, dynamic>> get ablutionAreas {
    return _readMapList('ablutionAreas');
  }

  /// Returns official accessibility connections.
  ///
  /// These are NOT automatically considered full navigation routes.
  List<Map<String, dynamic>> get officialAccessibleConnections {
    return _readMapList('officialAccessibleConnections');
  }

  /// Returns only routes explicitly marked VERIFIED_ROUTE
  /// and explicitly allowed for navigation.
  ///
  /// This is an intentional safety gate.
  List<Map<String, dynamic>> get navigationRoutes {
    final routes = _readMapList('navigationRoutes');

    return routes.where((route) {
      final status = parseVerificationStatus(
        route['verificationStatus'] as String?,
      );

      final navigationAllowed =
          route['navigationAllowed'] == true;

      return status ==
              HaramainVerificationStatus.verifiedRoute &&
          navigationAllowed;
    }).toList(growable: false);
  }

  /// Production navigation must only be enabled when the dataset
  /// explicitly permits it AND at least one verified route exists.
  bool get isProductionNavigationEnabled {
    final safety = makkahData['safety'];

    if (safety is! Map<String, dynamic>) {
      return false;
    }

    final enabled =
        safety['productionNavigationEnabled'] == true;

    return enabled && navigationRoutes.isNotEmpty;
  }

  /// Returns whether a specific data item may be used as a route.
  ///
  /// A verified POI or verified access connection alone is not enough.
  bool canUseForNavigation(
    Map<String, dynamic> item,
  ) {
    final status = parseVerificationStatus(
      item['verificationStatus'] as String?,
    );

    return status ==
            HaramainVerificationStatus.verifiedRoute &&
        item['navigationAllowed'] == true;
  }

  /// Converts the JSON verification string into a safe enum.
  HaramainVerificationStatus parseVerificationStatus(
    String? value,
  ) {
    switch (value) {
      case 'VERIFIED_POI':
        return HaramainVerificationStatus.verifiedPoi;

      case 'VERIFIED_ACCESS':
        return HaramainVerificationStatus.verifiedAccess;

      case 'VERIFIED_ROUTE':
        return HaramainVerificationStatus.verifiedRoute;

      default:
        return HaramainVerificationStatus.unverified;
    }
  }

  /// Reads a list containing JSON objects safely.
  List<Map<String, dynamic>> _readMapList(
    String key,
  ) {
    final value = makkahData[key];

    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList(growable: false);
  }

  /// Basic dataset safety validation.
  ///
  /// Loading fails if the dataset is not the expected verified
  /// Masjid al-Haram dataset.
  void _validateDataset(
    Map<String, dynamic> data,
  ) {
    if (data['datasetId'] !=
        'rifqa_makkah_haram_verified') {
      throw const FormatException(
        'Unexpected Haramain dataset ID.',
      );
    }

    final site = data['site'];

    if (site is! Map) {
      throw const FormatException(
        'Haramain dataset is missing site information.',
      );
    }

    if (site['id'] != 'masjid_al_haram') {
      throw const FormatException(
        'This dataset is not for Masjid al-Haram.',
      );
    }

    final policy = data['datasetPolicy'];

    if (policy is! Map) {
      throw const FormatException(
        'Haramain dataset is missing its verification policy.',
      );
    }

    if (policy['verifiedDataOnly'] != true) {
      throw const FormatException(
        'Unverified Haramain datasets are not accepted.',
      );
    }

    if (policy['allowInferredRoutes'] != false) {
      throw const FormatException(
        'Inferred Haramain routes are not allowed.',
      );
    }

    if (policy['allowInferredCoordinates'] != false) {
      throw const FormatException(
        'Inferred Haramain coordinates are not allowed.',
      );
    }
  }
}