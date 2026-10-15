import 'package:flutter_tts/flutter_tts.dart';

class HaramainVoiceService {
  final FlutterTts _tts = FlutterTts();
  String? _last;

  Future<void> speak(String text) async {
    final t = text.trim();
    if (t.isEmpty || t == _last) return;
    _last = t;
    await _tts.setLanguage('ar-SA');
    await _tts.setSpeechRate(.42);
    await _tts.stop();
    await _tts.speak(t);
  }

  Future<void> stop() {
    _last = null;
    return _tts.stop();
  }
}
