import 'package:flutter/material.dart';

enum HaramUserPinType {
  myGate,
  hotel,
  bus,
  meetingPoint,
  custom,
}

extension HaramUserPinTypeX on HaramUserPinType {
  String get label {
    switch (this) {
      case HaramUserPinType.myGate:
        return 'بابي';
      case HaramUserPinType.hotel:
        return 'فندقي';
      case HaramUserPinType.bus:
        return 'الباص';
      case HaramUserPinType.meetingPoint:
        return 'نقطة التجمع';
      case HaramUserPinType.custom:
        return 'مكان محفوظ';
    }
  }

  String get emoji {
    switch (this) {
      case HaramUserPinType.myGate:
        return '🚪';
      case HaramUserPinType.hotel:
        return '🏨';
      case HaramUserPinType.bus:
        return '🚌';
      case HaramUserPinType.meetingPoint:
        return '👥';
      case HaramUserPinType.custom:
        return '📌';
    }
  }
}

class HaramUserPin {
  final String id;
  final String haramId;

  final HaramUserPinType type;

  final String label;

  final Offset position;

  final String? linkedPoiId;
  final String? note;

  final DateTime createdAt;

  const HaramUserPin({
    required this.id,
    required this.haramId,
    required this.type,
    required this.label,
    required this.position,
    required this.createdAt,
    this.linkedPoiId,
    this.note,
  });

  String get emoji => type.emoji;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'haramId': haramId,
      'type': type.name,
      'label': label,
      'x': position.dx,
      'y': position.dy,
      'linkedPoiId': linkedPoiId,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HaramUserPin.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;

    final type = HaramUserPinType.values.firstWhere(
      (item) => item.name == typeName,
      orElse: () => HaramUserPinType.custom,
    );

    return HaramUserPin(
      id: json['id'] as String? ?? '',
      haramId: json['haramId'] as String? ?? '',
      type: type,
      label: json['label'] as String? ?? '',
      position: Offset(
        (json['x'] as num?)?.toDouble() ?? 0,
        (json['y'] as num?)?.toDouble() ?? 0,
      ),
      linkedPoiId: json['linkedPoiId'] as String?,
      note: json['note'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}