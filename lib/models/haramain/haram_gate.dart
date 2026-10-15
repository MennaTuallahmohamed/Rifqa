import 'haram_poi.dart';

class HaramGate {
  final String id;
  final HaramPoi poi;

  final String? gateNumber;

  final bool isEntrance;
  final bool isExit;

  final bool wheelchairAccessible;

  final List<String> leadsTo;

  const HaramGate({
    required this.id,
    required this.poi,
    this.gateNumber,
    this.isEntrance = true,
    this.isExit = true,
    this.wheelchairAccessible = false,
    this.leadsTo = const [],
  });

  String get displayName {
    if (gateNumber == null || gateNumber!.trim().isEmpty) {
      return poi.name;
    }

    return '${poi.name} • $gateNumber';
  }
}