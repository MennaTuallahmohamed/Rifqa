import 'package:flutter/material.dart';

enum HaramRouteType {
  normal,
  accessible,
  quiet,
  emergency,
}

class HaramRoute {
  final String id;

  final String haramId;

  final String? fromPoiId;
  final String? toPoiId;

  final List<Offset> points;

  final double distanceMeters;
  final Duration estimatedDuration;

  final HaramRouteType type;

  final bool approximate;

  const HaramRoute({
    required this.id,
    required this.haramId,
    required this.points,
    required this.distanceMeters,
    required this.estimatedDuration,
    this.fromPoiId,
    this.toPoiId,
    this.type = HaramRouteType.normal,
    this.approximate = true,
  });

  bool get isAccessible => type == HaramRouteType.accessible;

  int get estimatedMinutes {
    if (estimatedDuration.inMinutes < 1) {
      return 1;
    }

    return estimatedDuration.inMinutes;
  }
}