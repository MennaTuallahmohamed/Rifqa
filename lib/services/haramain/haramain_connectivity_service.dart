import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// What we actually KNOW about connectivity right now.
///
/// We deliberately never claim that map tiles are available offline.
/// The Haramain module ships POI data, personal pins and preferences as a
/// bundled asset, so those genuinely work with no network. Raster/vector map
/// tiles do not.
enum HaramainConnectivity {
  /// Nothing observed yet. We must not draw a conclusion.
  unknown,

  /// A real request to the tile host succeeded within the recent window.
  online,

  /// Repeated real requests to the tile host failed.
  offline,
}

extension HaramainConnectivityX on HaramainConnectivity {
  String get label => switch (this) {
        HaramainConnectivity.unknown => 'لم يتم التحقق من الاتصال',
        HaramainConnectivity.online => 'متصل',
        HaramainConnectivity.offline => 'ضعيف أو غير متصل',
      };

  bool get isOffline => this == HaramainConnectivity.offline;
}

/// Observes connectivity from a real HTTP probe of the map tile host.
///
/// Why a probe and not a "we're offline" guess:
///
///  * MapLibre 0.27 exposes no tile-error callback, so tile failures are not
///    observable from the map object itself.
///  * Guessing would let the app show a reassuring green banner on a device
///    that cannot actually load the map.
///
/// So this service performs a small, real, cancellable HTTP request against a
/// public tile host. Success proves connectivity; repeated failures prove a
/// problem; anything else stays `unknown`.
///
/// Offline behaviour that remains genuinely true:
///  - bundled POI data, personal pins, meeting points and preferences work
///  - search across bundled data works
///  - the offline banner states explicitly that map tiles are not loading
class HaramainConnectivityService extends ChangeNotifier {
  static const Duration _probeInterval = Duration(seconds: 20);
  static const Duration _probeTimeout = Duration(seconds: 6);
  static const int _failureThreshold = 2;

  /// A real, high-zoom OSM tile: small, cached everywhere, and served by a
  /// host that is also a genuine dependency of the street map style.
  static const String _probeUrl =
      'https://tile.openstreetmap.org/17/69000/48000.png';

  Timer? _timer;
  HttpClient? _client;
  bool _probing = false;
  bool _disposed = false;

  int _consecutiveFailures = 0;
  DateTime? _lastSuccessAt;
  HaramainConnectivity _state = HaramainConnectivity.unknown;

  HaramainConnectivity get current => _state;

  bool get isOffline => _state == HaramainConnectivity.offline;

  /// Starts probing. Safe to call more than once.
  void start() {
    if (_timer != null) return;
    _client = HttpClient()
      ..connectionTimeout = _probeTimeout
      ..userAgent = 'Rifqa/1.0 (Haramain connectivity probe)';
    unawaited(probeNow());
    _timer = Timer.periodic(_probeInterval, (_) => unawaited(probeNow()));
  }

  /// The tile host changed (satellite <-> street): re-probe immediately,
  /// because the new host may behave differently.
  void onStyleHostChanged() {
    _consecutiveFailures = 0;
    unawaited(probeNow());
  }

  /// A style finished loading. That is itself proof the current host answered,
  /// so we can promote to `online` without waiting for the next probe.
  void reportStyleLoaded() => _applySuccess();

  /// MapLibre reported a style failure (bad style URL or decode error).
  void reportStyleFailure() => _applyFailure();

  Future<void> probeNow() async {
    if (_probing || _disposed) return;
    final client = _client;
    if (client == null) return;
    _probing = true;
    try {
      final request = await client.getUrl(Uri.parse(_probeUrl));
      final response = await request.close().timeout(_probeTimeout);
      // Drain so the socket is reused rather than torn down each probe.
      await response.drain<void>().timeout(_probeTimeout);
      if (response.statusCode >= 200 && response.statusCode < 400) {
        _applySuccess();
      } else {
        _applyFailure();
      }
    } on Object {
      // Timeout, DNS failure, refused connection, TLS error: we could not
      // reach the tile host right now.
      _applyFailure();
    } finally {
      _probing = false;
    }
  }

  void _applySuccess() {
    _consecutiveFailures = 0;
    _lastSuccessAt = DateTime.now();
    _setState(HaramainConnectivity.online);
  }

  void _applyFailure() {
    _consecutiveFailures++;
    if (_consecutiveFailures >= _failureThreshold) {
      _setState(HaramainConnectivity.offline);
    }
  }

  void _setState(HaramainConnectivity next) {
    if (_disposed || _state == next) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _client?.close(force: true);
    _client = null;
    super.dispose();
  }
}