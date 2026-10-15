import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/madinah/madinah_journey_state.dart';
import '../../models/madinah/madinah_memory.dart';
import '../../models/madinah/rawdah_appointment.dart';
import '../../models/madinah/spiritual_reflection.dart';

class MadinahLocalStorage {
  // ============================================================
  // KEYS
  // ============================================================

  static const String _journeyStateKey = 'madinah_journey_state';

  static const String _rawdahAppointmentKey = 'madinah_rawdah_appointment';

  static const String _memoriesKey = 'madinah_memories';

  static const String _reflectionsKey = 'madinah_spiritual_reflections';

  static const String _departureDateKey = 'madinah_departure_date';

  static const String _firstVisitKey = 'madinah_first_visit';

  // ============================================================
  // SHARED PREFERENCES
  // ============================================================

  Future<SharedPreferences> get _prefs async {
    return SharedPreferences.getInstance();
  }

  // ============================================================
  // JOURNEY STATE
  // ============================================================

  Future<void> saveJourneyState(
    MadinahJourneyState state,
  ) async {
    final prefs = await _prefs;

    final encoded = jsonEncode(
      state.toJson(),
    );

    await prefs.setString(
      _journeyStateKey,
      encoded,
    );
  }

  Future<MadinahJourneyState> loadJourneyState() async {
    final prefs = await _prefs;

    final encoded = prefs.getString(
      _journeyStateKey,
    );

    if (encoded == null || encoded.isEmpty) {
      return MadinahJourneyState.initial();
    }

    try {
      final decoded = jsonDecode(encoded);

      if (decoded is! Map) {
        return MadinahJourneyState.initial();
      }

      return MadinahJourneyState.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return MadinahJourneyState.initial();
    }
  }

  Future<void> clearJourneyState() async {
    final prefs = await _prefs;

    await prefs.remove(
      _journeyStateKey,
    );
  }

  // ============================================================
  // RAWDAH APPOINTMENT
  // ============================================================

  Future<void> saveRawdahAppointment(
    RawdahAppointment appointment,
  ) async {
    final prefs = await _prefs;

    final encoded = jsonEncode(
      appointment.toJson(),
    );

    await prefs.setString(
      _rawdahAppointmentKey,
      encoded,
    );
  }

  Future<RawdahAppointment?> loadRawdahAppointment() async {
    final prefs = await _prefs;

    final encoded = prefs.getString(
      _rawdahAppointmentKey,
    );

    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(encoded);

      if (decoded is! Map) {
        return null;
      }

      return RawdahAppointment.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearRawdahAppointment() async {
    final prefs = await _prefs;

    await prefs.remove(
      _rawdahAppointmentKey,
    );
  }

  // ============================================================
  // MEMORIES
  // ============================================================

  Future<List<MadinahMemory>> loadMemories() async {
    final prefs = await _prefs;

    final encoded = prefs.getString(
      _memoriesKey,
    );

    if (encoded == null || encoded.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(encoded);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => MadinahMemory.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMemories(
    List<MadinahMemory> memories,
  ) async {
    final prefs = await _prefs;

    final encoded = jsonEncode(
      memories
          .map(
            (memory) => memory.toJson(),
          )
          .toList(),
    );

    await prefs.setString(
      _memoriesKey,
      encoded,
    );
  }

  Future<void> addMemory(
    MadinahMemory memory,
  ) async {
    final memories = await loadMemories();

    final existingIndex = memories.indexWhere(
      (item) => item.id == memory.id,
    );

    if (existingIndex >= 0) {
      memories[existingIndex] = memory;
    } else {
      memories.add(memory);
    }

    await saveMemories(memories);
  }

  Future<void> updateMemory(
    MadinahMemory memory,
  ) async {
    final memories = await loadMemories();

    final index = memories.indexWhere(
      (item) => item.id == memory.id,
    );

    if (index == -1) {
      return;
    }

    memories[index] = memory;

    await saveMemories(memories);
  }

  Future<void> deleteMemory(
    String memoryId,
  ) async {
    final memories = await loadMemories();

    memories.removeWhere(
      (item) => item.id == memoryId,
    );

    await saveMemories(memories);
  }

  Future<void> clearMemories() async {
    final prefs = await _prefs;

    await prefs.remove(
      _memoriesKey,
    );
  }

  // ============================================================
  // SPIRITUAL REFLECTIONS
  // ============================================================

  Future<List<SpiritualReflection>> loadReflections() async {
    final prefs = await _prefs;

    final encoded = prefs.getString(
      _reflectionsKey,
    );

    if (encoded == null || encoded.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(encoded);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => SpiritualReflection.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveReflections(
    List<SpiritualReflection> reflections,
  ) async {
    final prefs = await _prefs;

    final encoded = jsonEncode(
      reflections
          .map(
            (reflection) => reflection.toJson(),
          )
          .toList(),
    );

    await prefs.setString(
      _reflectionsKey,
      encoded,
    );
  }

  Future<void> addReflection(
    SpiritualReflection reflection,
  ) async {
    final reflections = await loadReflections();

    final existingIndex = reflections.indexWhere(
      (item) => item.id == reflection.id,
    );

    if (existingIndex >= 0) {
      reflections[existingIndex] = reflection;
    } else {
      reflections.add(reflection);
    }

    await saveReflections(
      reflections,
    );
  }

  Future<void> deleteReflection(
    String reflectionId,
  ) async {
    final reflections = await loadReflections();

    reflections.removeWhere(
      (item) => item.id == reflectionId,
    );

    await saveReflections(
      reflections,
    );
  }

  Future<void> clearReflections() async {
    final prefs = await _prefs;

    await prefs.remove(
      _reflectionsKey,
    );
  }

  // ============================================================
  // DEPARTURE DATE
  // ============================================================

  Future<void> saveDepartureDate(
    DateTime date,
  ) async {
    final prefs = await _prefs;

    await prefs.setString(
      _departureDateKey,
      date.toIso8601String(),
    );
  }

  Future<DateTime?> loadDepartureDate() async {
    final prefs = await _prefs;

    final value = prefs.getString(
      _departureDateKey,
    );

    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  Future<void> clearDepartureDate() async {
    final prefs = await _prefs;

    await prefs.remove(
      _departureDateKey,
    );
  }

  // ============================================================
  // FIRST VISIT
  // ============================================================

  Future<bool> isFirstMadinahVisit() async {
    final prefs = await _prefs;

    return prefs.getBool(
          _firstVisitKey,
        ) ??
        true;
  }

  Future<void> markMadinahOpened() async {
    final prefs = await _prefs;

    await prefs.setBool(
      _firstVisitKey,
      false,
    );
  }

  // ============================================================
  // RESET MADINAH DATA
  // ============================================================

  Future<void> clearAll() async {
    final prefs = await _prefs;

    await prefs.remove(
      _journeyStateKey,
    );

    await prefs.remove(
      _rawdahAppointmentKey,
    );

    await prefs.remove(
      _memoriesKey,
    );

    await prefs.remove(
      _reflectionsKey,
    );

    await prefs.remove(
      _departureDateKey,
    );

    await prefs.remove(
      _firstVisitKey,
    );
  }
}
