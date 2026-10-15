import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class HmFix {
  final LatLng pos;
  final double accuracy; // بالمتر
  const HmFix(this.pos, this.accuracy);
}

/// GPS حقيقي + بوصلة الجهاز. تنبيه: دقة الـGPS تضعف داخل المباني (قد تصل لعشرات الأمتار).
class HaramainLocationService {
  final ValueNotifier<HmFix?> fix = ValueNotifier(null);
  final ValueNotifier<double?> heading = ValueNotifier(null);
  StreamSubscription<Position>? _pos;
  StreamSubscription<CompassEvent>? _cmp;
  bool _hasCompass = false;

  Future<bool> start() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return false;
    }
    _pos?.cancel();
    _pos = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 2,
      ),
    ).listen((p) {
      fix.value = HmFix(LatLng(p.latitude, p.longitude), p.accuracy);
      // لو مفيش بوصلة نستخدم اتجاه الحركة
      if (!_hasCompass && p.speed > 0.6 && p.heading >= 0) {
        heading.value = p.heading;
      }
    });
    _cmp?.cancel();
    _cmp = FlutterCompass.events?.listen((e) {
      final h = e.heading;
      if (h == null) return;
      _hasCompass = true;
      final v = (h + 360) % 360;
      final old = heading.value;
      if (old == null || (v - old).abs() > 3) heading.value = v;
    });
    return true;
  }

  void dispose() {
    _pos?.cancel();
    _cmp?.cancel();
    fix.dispose();
    heading.dispose();
  }
}
