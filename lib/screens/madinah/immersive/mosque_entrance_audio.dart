import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// One player shared across the animated gate and the mosque photo tour.
/// It only starts after opening the mosque experience (never at app launch).
/// Audio is the original user-supplied recording, not synthesized speech.
class MosqueEntranceAudio {
  MosqueEntranceAudio._();
  static final MosqueEntranceAudio instance = MosqueEntranceAudio._();

  static const recording = 'assets/audio/madinah/salam_entrance_20261020.m4a';
  final AudioPlayer player = AudioPlayer();
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);
  int _generation = 0;
  bool _loading = false;

  bool get isActive => player.playing || _loading;

  Future<void> start({bool restart = false}) async {
    if (!restart && isActive) return;
    final generation = ++_generation;
    _loading = true;
    error.value = null;
    try {
      await player.stop();
      await player.setAsset(recording);
      if (generation != _generation) return;
      await player.setVolume(1.0);
      if (generation != _generation) return;
      // Intentionally not awaited: play() resolves at the end of the recording.
      player.play().catchError((Object e) {
        if (generation == _generation) {
          error.value = 'تعذّر تشغيل التسجيل: $e';
        }
      });
    } catch (e) {
      if (generation == _generation) {
        error.value = 'تعذّر تحميل تسجيل السلام: $e';
        debugPrint('Rifqa mosque entrance audio: $e');
      }
    } finally {
      if (generation == _generation) _loading = false;
    }
  }

  Future<void> toggle() async {
    if (_loading) return;
    if (player.playing) {
      await player.pause();
      return;
    }
    if (player.processingState == ProcessingState.completed) {
      await start(restart: true);
      return;
    }
    if (player.processingState == ProcessingState.idle) {
      await start(restart: true);
      return;
    }
    await player.play();
  }

  Future<void> stop() async {
    ++_generation;
    _loading = false;
    await player.stop();
  }
}
