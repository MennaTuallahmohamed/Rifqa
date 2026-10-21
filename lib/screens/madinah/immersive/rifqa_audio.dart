import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// مؤثرات رِفقة. الملفات في assets/audio/<name>.wav
enum Sfx { tap, swipe, success, alert, slot }

/// خدمة الصوت: مؤثرات قصيرة + أجواء هادئة + تعليق صوتي عربي (TTS).
/// كل استدعاء محمي بـ try/catch حتى لا ينهار التطبيق على منصة لا تدعم الصوت.
class RifqaAudio {
  RifqaAudio._();
  static final RifqaAudio instance = RifqaAudio._();

  final ValueNotifier<bool> effectsOn = ValueNotifier<bool>(true);
  final ValueNotifier<bool> ambientOn = ValueNotifier<bool>(false);
  final ValueNotifier<bool> speaking = ValueNotifier<bool>(false);

  final List<AudioPlayer> _pool = [AudioPlayer(), AudioPlayer(), AudioPlayer()];
  final AudioPlayer _ambient = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  int _next = 0;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      await _ambient.setReleaseMode(ReleaseMode.loop);
      await _ambient.setVolume(0.22);
      for (final p in _pool) {
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(0.85);
      }
    } catch (e) {
      debugPrint('RifqaAudio: audio init failed: $e');
    }
    try {
      await _tts.setLanguage('ar-SA');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _tts.setStartHandler(() => speaking.value = true);
      _tts.setCompletionHandler(() => speaking.value = false);
      _tts.setCancelHandler(() => speaking.value = false);
      _tts.setErrorHandler((_) => speaking.value = false);
    } catch (e) {
      debugPrint('RifqaAudio: tts init failed: $e');
    }
  }

  /// يشغّل مؤثرًا قصيرًا مع اهتزاز خفيف.
  Future<void> play(Sfx sfx) async {
    if (!effectsOn.value) return;
    try {
      switch (sfx) {
        case Sfx.success:
          HapticFeedback.heavyImpact();
        case Sfx.alert:
          HapticFeedback.mediumImpact();
        case Sfx.slot:
          HapticFeedback.lightImpact();
        case Sfx.tap:
        case Sfx.swipe:
          HapticFeedback.selectionClick();
      }
      final player = _pool[_next++ % _pool.length];
      await player.stop();
      await player.play(AssetSource('audio/${sfx.name}.wav'));
    } catch (e) {
      debugPrint('RifqaAudio: play ${sfx.name} failed: $e');
    }
  }

  void setEffects(bool on) => effectsOn.value = on;

  Future<void> setAmbient(bool on) async {
    ambientOn.value = on;
    try {
      if (on) {
        await _ambient.play(AssetSource('audio/ambient.wav'));
      } else {
        await _ambient.stop();
      }
    } catch (e) {
      debugPrint('RifqaAudio: ambient failed: $e');
    }
  }

  /// يقرأ النص بصوت عربي. إن كان يتكلم الآن يوقفه أولًا.
  Future<void> narrate(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      speaking.value = false;
      debugPrint('RifqaAudio: narrate failed: $e');
    }
  }

  Future<void> stopNarration() async {
    try {
      await _tts.stop();
    } catch (_) {}
    speaking.value = false;
  }

  /// عند مغادرة الشاشة.
  Future<void> stopAll() async {
    await stopNarration();
    try {
      await _ambient.stop();
    } catch (_) {}
    ambientOn.value = false;
  }
}