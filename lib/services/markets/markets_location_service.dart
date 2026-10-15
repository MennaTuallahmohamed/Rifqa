import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/markets/market_place.dart';

class MarketUserLocation {
  const MarketUserLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
}

class MarketsLocationService {
  MarketsLocationService();

  final ValueNotifier<MarketUserLocation?> location =
      ValueNotifier<MarketUserLocation?>(null);

  bool _loading = false;

  bool get isLoading => _loading;

  bool get hasLocation => location.value != null;

  Future<bool> requestCurrentLocation() async {
    if (_loading) {
      return location.value != null;
    }

    _loading = true;

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return false;
      }

      var permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        return false;
      }

      Position? position;

      try {
        position =
            await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(
              seconds: 15,
            ),
          ),
        );
      } catch (_) {
        position =
            await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return false;
      }

      location.value = MarketUserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

      return true;
    } finally {
      _loading = false;
    }
  }

  double? distanceToMarket(
    MarketPlace market,
  ) {
    final current = location.value;

    if (current == null ||
        !market.hasCoordinates ||
        market.latitude == null ||
        market.longitude == null) {
      return null;
    }

    return Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      market.latitude!,
      market.longitude!,
    );
  }

  List<MarketPlace> sortNearest(
    Iterable<MarketPlace> markets,
  ) {
    final current = location.value;

    if (current == null) {
      return markets.toList();
    }

    final result = markets.toList();

    result.sort((a, b) {
      final distanceA = distanceToMarket(a);
      final distanceB = distanceToMarket(b);

      if (distanceA == null &&
          distanceB == null) {
        return 0;
      }

      if (distanceA == null) {
        return 1;
      }

      if (distanceB == null) {
        return -1;
      }

      return distanceA.compareTo(
        distanceB,
      );
    });

    return result;
  }

  MarketPlace? nearestMarket(
    Iterable<MarketPlace> markets,
  ) {
    if (location.value == null) {
      return null;
    }

    final available = markets
        .where(
          (market) =>
              market.hasCoordinates &&
              market.latitude != null &&
              market.longitude != null,
        )
        .toList();

    if (available.isEmpty) {
      return null;
    }

    available.sort((a, b) {
      final aDistance =
          distanceToMarket(a) ??
              double.infinity;

      final bDistance =
          distanceToMarket(b) ??
              double.infinity;

      return aDistance.compareTo(
        bDistance,
      );
    });

    return available.first;
  }

  String formatDistance(
    double meters,
  ) {
    if (!meters.isFinite ||
        meters < 0) {
      return '';
    }

    if (meters < 1000) {
      return '${meters.round()} م';
    }

    final kilometers =
        meters / 1000;

    if (kilometers < 10) {
      return '${kilometers.toStringAsFixed(1)} كم';
    }

    return '${kilometers.round()} كم';
  }

  double bearingToMarket(
    MarketPlace market,
  ) {
    final current = location.value;

    if (current == null ||
        !market.hasCoordinates ||
        market.latitude == null ||
        market.longitude == null) {
      return 0;
    }

    final lat1 =
        _degreesToRadians(
      current.latitude,
    );

    final lat2 =
        _degreesToRadians(
      market.latitude!,
    );

    final deltaLongitude =
        _degreesToRadians(
      market.longitude! -
          current.longitude,
    );

    final y =
        math.sin(deltaLongitude) *
            math.cos(lat2);

    final x =
        math.cos(lat1) *
                math.sin(lat2) -
            math.sin(lat1) *
                math.cos(lat2) *
                math.cos(
                  deltaLongitude,
                );

    final bearing =
        math.atan2(y, x);

    return (_radiansToDegrees(
              bearing,
            ) +
            360) %
        360;
  }

  double _degreesToRadians(
    double degrees,
  ) {
    return degrees *
        math.pi /
        180;
  }

  double _radiansToDegrees(
    double radians,
  ) {
    return radians *
        180 /
        math.pi;
  }

  void dispose() {
    location.dispose();
  }
}