import '../../models/madinah/madinah_journey_state.dart';
import '../../models/madinah/madinah_memory.dart';
import '../../models/madinah/rawdah_appointment.dart';
import '../../models/madinah/spiritual_reflection.dart';
import 'madinah_local_storage.dart';

class MadinahRepository {
  final MadinahLocalStorage localStorage;

  MadinahJourneyState _journey = MadinahJourneyState.initial();

  RawdahAppointment? _rawdahAppointment;

  List<MadinahMemory> _memories = [];

  List<SpiritualReflection> _reflections = [];

  DateTime? _departureDate;

  bool _initialized = false;

  MadinahRepository({
    MadinahLocalStorage? localStorage,
  }) : localStorage = localStorage ?? MadinahLocalStorage();

  // ============================================================
  // GETTERS
  // ============================================================

  bool get initialized => _initialized;

  MadinahJourneyState get journey => _journey;

  RawdahAppointment? get rawdahAppointment => _rawdahAppointment;

  List<MadinahMemory> get memories => List.unmodifiable(_memories);

  List<SpiritualReflection> get reflections => List.unmodifiable(_reflections);

  DateTime? get departureDate => _departureDate;

  bool get hasRawdahAppointment => _rawdahAppointment != null;

  // ============================================================
  // INIT
  // ============================================================

  Future<void> init() async {
    _journey = await localStorage.loadJourneyState();

    _rawdahAppointment = await localStorage.loadRawdahAppointment();

    _memories = await localStorage.loadMemories();

    _reflections = await localStorage.loadReflections();

    _departureDate = await localStorage.loadDepartureDate();

    _initialized = true;
  }

  // ============================================================
  // JOURNEY
  // ============================================================

  Future<void> startJourney() async {
    _journey = _journey.startJourney();

    await _saveJourney();
  }

  Future<void> enterProphetMosque() async {
    _journey = _journey.enterProphetMosqueJourney();

    await _saveJourney();
  }

  Future<void> setMosqueStage(
    ProphetMosqueStage stage,
  ) async {
    _journey = _journey.updateMosqueStage(stage);

    await _saveJourney();
  }

  Future<void> enterRawdah() async {
    _journey = _journey.enterRawdahJourney();

    await _saveJourney();
  }

  Future<void> setRawdahStage(
    RawdahJourneyStage stage,
  ) async {
    _journey = _journey.updateRawdahStage(stage);

    await _saveJourney();
  }

  Future<void> completeJourney() async {
    _journey = _journey.completeJourney();

    await _saveJourney();
  }

  Future<void> _saveJourney() async {
    await localStorage.saveJourneyState(
      _journey,
    );
  }

  // ============================================================
  // RAWDAH APPOINTMENT
  // ============================================================

  Future<void> saveRawdahAppointment(
    RawdahAppointment appointment,
  ) async {
    _rawdahAppointment = appointment;

    await localStorage.saveRawdahAppointment(
      appointment,
    );
  }

  Future<void> updateRawdahAppointment(
    RawdahAppointment appointment,
  ) async {
    _rawdahAppointment = appointment;

    await localStorage.saveRawdahAppointment(
      appointment,
    );
  }

  Future<void> deleteRawdahAppointment() async {
    _rawdahAppointment = null;

    await localStorage.clearRawdahAppointment();
  }

  // ============================================================
  // PROPHETIC STORIES
  // ============================================================

  Future<void> markStoryRead(
    String storyId,
  ) async {
    _journey = _journey.markStoryRead(
      storyId: storyId,
    );

    await _saveJourney();
  }

  Future<void> carryValue(
    String value,
  ) async {
    _journey = _journey.addCarriedValue(value);

    await _saveJourney();
  }

  Future<void> removeCarriedValue(
    String value,
  ) async {
    _journey = _journey.removeCarriedValue(value);

    await _saveJourney();
  }

  // ============================================================
  // SALAWAT
  // ============================================================

  Future<void> toggleFavoriteSalawat(
    String salawatId,
  ) async {
    _journey = _journey.toggleFavoriteSalawat(
      salawatId,
    );

    await _saveJourney();
  }

  bool isFavoriteSalawat(
    String salawatId,
  ) {
    return _journey.isFavoriteSalawat(
      salawatId,
    );
  }

  // ============================================================
  // MEMORIES
  // ============================================================

  Future<void> addMemory(
    MadinahMemory memory,
  ) async {
    final index = _memories.indexWhere(
      (item) => item.id == memory.id,
    );

    if (index >= 0) {
      _memories[index] = memory;
    } else {
      _memories.add(memory);
    }

    await localStorage.saveMemories(
      _memories,
    );
  }

  Future<void> updateMemory(
    MadinahMemory memory,
  ) async {
    final index = _memories.indexWhere(
      (item) => item.id == memory.id,
    );

    if (index == -1) {
      return;
    }

    _memories[index] = memory;

    await localStorage.saveMemories(
      _memories,
    );
  }

  Future<void> deleteMemory(
    String memoryId,
  ) async {
    _memories.removeWhere(
      (item) => item.id == memoryId,
    );

    await localStorage.saveMemories(
      _memories,
    );
  }

  List<MadinahMemory> memoriesByType(
    MadinahMemoryType type,
  ) {
    return _memories
        .where(
          (memory) => memory.type == type,
        )
        .toList();
  }

  // ============================================================
  // REFLECTIONS
  // ============================================================

  Future<void> addReflection(
    SpiritualReflection reflection,
  ) async {
    final index = _reflections.indexWhere(
      (item) => item.id == reflection.id,
    );

    if (index >= 0) {
      _reflections[index] = reflection;
    } else {
      _reflections.add(reflection);
    }

    await localStorage.saveReflections(
      _reflections,
    );
  }

  Future<void> deleteReflection(
    String reflectionId,
  ) async {
    _reflections.removeWhere(
      (item) => item.id == reflectionId,
    );

    await localStorage.saveReflections(
      _reflections,
    );
  }

  List<SpiritualReflection> reflectionsByType(
    SpiritualReflectionType type,
  ) {
    return _reflections
        .where(
          (reflection) => reflection.type == type,
        )
        .toList();
  }

  // ============================================================
  // DEPARTURE DATE
  // ============================================================

  Future<void> setDepartureDate(
    DateTime date,
  ) async {
    _departureDate = date;

    await localStorage.saveDepartureDate(
      date,
    );
  }

  Future<void> clearDepartureDate() async {
    _departureDate = null;

    await localStorage.clearDepartureDate();
  }

  bool get isLastNightInMadinah {
    final departure = _departureDate;

    if (departure == null) {
      return false;
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final departureDay = DateTime(
      departure.year,
      departure.month,
      departure.day,
    );

    return departureDay.difference(today).inDays == 1;
  }

  // ============================================================
  // FIRST OPEN
  // ============================================================

  Future<bool> isFirstMadinahVisit() {
    return localStorage.isFirstMadinahVisit();
  }

  Future<void> markMadinahOpened() {
    return localStorage.markMadinahOpened();
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  int get memoriesCount => _memories.length;

  int get reflectionsCount => _reflections.length;

  int get carriedValuesCount => _journey.carriedValues.length;

  int get storiesReadCount => _journey.readStoryIds.length;

  int get favoriteSalawatCount => _journey.favoriteSalawatIds.length;

  // ============================================================
  // RESET
  // ============================================================

  Future<void> resetMadinahJourney() async {
    _journey = MadinahJourneyState.initial();

    _rawdahAppointment = null;

    _memories = [];

    _reflections = [];

    _departureDate = null;

    await localStorage.clearAll();
  }
}
