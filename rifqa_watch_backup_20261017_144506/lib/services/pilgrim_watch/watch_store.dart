import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// All watch settings are local to this phone. This is NOT a Wear OS connection.
class PilgrimWatchAlarm {
  const PilgrimWatchAlarm({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    this.days = const [1, 2, 3, 4, 5, 6, 7],
    this.enabled = true,
    this.earlyMinutes = 10,
    this.important = false,
    this.kind = 'custom',
  });
  final int id, hour, minute, earlyMinutes;
  final String title, kind;
  final List<int> days; // DateTime.monday .. DateTime.sunday
  final bool enabled, important;

  PilgrimWatchAlarm copyWith({String? title, int? hour, int? minute,
    List<int>? days, bool? enabled, int? earlyMinutes, bool? important,
    String? kind}) => PilgrimWatchAlarm(
      id: id, title: title ?? this.title, hour: hour ?? this.hour,
      minute: minute ?? this.minute, days: days ?? this.days,
      enabled: enabled ?? this.enabled, earlyMinutes: earlyMinutes ?? this.earlyMinutes,
      important: important ?? this.important, kind: kind ?? this.kind);

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'hour': hour, 'minute': minute,
    'days': days, 'enabled': enabled, 'earlyMinutes': earlyMinutes,
    'important': important, 'kind': kind,
  };

  factory PilgrimWatchAlarm.fromJson(Map<String, dynamic> j) => PilgrimWatchAlarm(
    id: (j['id'] as num?)?.toInt() ?? 101,
    title: '${j['title'] ?? 'تذكير'}',
    hour: (j['hour'] as num?)?.toInt() ?? 8,
    minute: (j['minute'] as num?)?.toInt() ?? 0,
    days: (j['days'] as List?)?.whereType<num>().map((e) => e.toInt()).toList()
        ?? [1, 2, 3, 4, 5, 6, 7],
    enabled: j['enabled'] == true,
    earlyMinutes: (j['earlyMinutes'] as num?)?.toInt() ?? 10,
    important: j['important'] == true,
    kind: '${j['kind'] ?? 'custom'}',
  );
}

/// Educational simulation progress only; not evidence of completing a real ritual.
class WatchJourney {
  const WatchJourney({this.type = 'umrah', this.step = 0,
    this.tawafLaps = 0, this.saiLaps = 0});
  final String type;
  final int step, tawafLaps, saiLaps;
  WatchJourney copyWith({String? type, int? step, int? tawafLaps, int? saiLaps}) =>
      WatchJourney(type: type ?? this.type, step: step ?? this.step,
        tawafLaps: tawafLaps ?? this.tawafLaps, saiLaps: saiLaps ?? this.saiLaps);
  Map<String, dynamic> toJson() => {'type': type, 'step': step,
    'tawafLaps': tawafLaps, 'saiLaps': saiLaps};
  factory WatchJourney.fromJson(Map<String, dynamic> j) => WatchJourney(
    type: '${j['type'] ?? 'umrah'}',
    step: (j['step'] as num?)?.toInt() ?? 0,
    tawafLaps: (j['tawafLaps'] as num?)?.toInt() ?? 0,
    saiLaps: (j['saiLaps'] as num?)?.toInt() ?? 0);
}

class RifqaWatchStore extends ChangeNotifier {
  RifqaWatchStore._();
  static final instance = RifqaWatchStore._();
  static const _key = 'rifqa_pilgrim_watch_v1';
  Future<void>? _loading;
  bool ready = false;

  int face = 0; // 0: photographic, 1: classic, 2: minimal
  bool is24Hour = false;
  bool makkahTime = true; // display timezone only; does not set OS clock
  int displayOffsetMinutes = 0; // watch face preview adjustment only
  double brightness = .8;
  int vibration = 1; // phone preview setting, wearable not paired
  bool largeText = false;
  bool quietMode = false;
  bool haptics = true;
  String displayName = '';
  WatchJourney journey = const WatchJourney();
  List<PilgrimWatchAlarm> alarms = [];
  int snoozeMinutes = 10;
  int dhikrCount = 0;
  String dhikrText = 'سبحان الله';
  int waterCups = 0;
  String waterDay = "";

  Future<void> load() => _loading ??= _read();
  Future<void> _read() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw != null) {
        final j = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        face = ((j['face'] as num?)?.toInt() ?? 0).clamp(0, 2).toInt();
        is24Hour = j['is24Hour'] == true;
        makkahTime = j['makkahTime'] != false;
        displayOffsetMinutes = ((j['offset'] as num?)?.toInt() ?? 0).clamp(-720, 720).toInt();
        brightness = ((j['brightness'] as num?)?.toDouble() ?? .8).clamp(.3, 1.0).toDouble();
        vibration = ((j['vibration'] as num?)?.toInt() ?? 1).clamp(0, 2).toInt();
        largeText = j['largeText'] == true;
        quietMode = j['quietMode'] == true;
        haptics = j['haptics'] != false;
        displayName = '${j['displayName'] ?? ''}';
        snoozeMinutes = ((j['snoozeMinutes'] as num?)?.toInt() ?? 10).clamp(5, 60).toInt();
        dhikrCount = (j['dhikrCount'] as num?)?.toInt() ?? 0;
        dhikrText = '${j['dhikrText'] ?? 'سبحان الله'}';
        waterCups = (j['waterCups'] as num?)?.toInt() ?? 0;
        waterDay = '${j['waterDay'] ?? ''}';
        if (j['journey'] is Map) journey = WatchJourney.fromJson(
          Map<String, dynamic>.from(j['journey'] as Map));
        if (j['alarms'] is List) {
          alarms = (j['alarms'] as List).whereType<Map>().map((e) =>
            PilgrimWatchAlarm.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
    } catch (e) {
      debugPrint('RifqaWatchStore read: $e');
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Future<void> change(void Function() update) async {
    await load();
    update();
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode({
      'face': face, 'is24Hour': is24Hour, 'makkahTime': makkahTime,
      'offset': displayOffsetMinutes, 'brightness': brightness,
      'vibration': vibration, 'largeText': largeText,
      'quietMode': quietMode, 'haptics': haptics,
      'displayName': displayName, 'snoozeMinutes': snoozeMinutes,
      'dhikrCount': dhikrCount, 'dhikrText': dhikrText,
      'waterCups': waterCups, 'waterDay': waterDay,
      'journey': journey.toJson(),
      'alarms': alarms.map((e) => e.toJson()).toList(),
    }));
  }

  int get todaysWaterCups {
    final today = DateTime.now();
    final stamp = '${today.year}-${today.month}-${today.day}';
    return waterDay == stamp ? waterCups : 0;
  }

  Future<void> addWaterCup() => change(() {
    final today = DateTime.now();
    final stamp = '${today.year}-${today.month}-${today.day}';
    if (waterDay != stamp) { waterDay = stamp; waterCups = 0; }
    waterCups = (waterCups + 1).clamp(0, 30).toInt();
  });

  Future<void> putAlarm(PilgrimWatchAlarm alarm) async => change(() {
    final index = alarms.indexWhere((e) => e.id == alarm.id);
    if (index < 0) { alarms.add(alarm); } else { alarms[index] = alarm; }
  });
  Future<void> removeAlarm(int id) async => change(() => alarms.removeWhere((e) => e.id == id));

  DateTime displayedTime([DateTime? now]) {
    final local = now ?? DateTime.now();
    final base = makkahTime ? local.toUtc().add(const Duration(hours: 3)) : local;
    return base.add(Duration(minutes: displayOffsetMinutes));
  }
}
