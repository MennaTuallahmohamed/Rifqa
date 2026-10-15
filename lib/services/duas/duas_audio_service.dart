import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DuasAudioService extends ChangeNotifier {
  DuasAudioService() {
    _setup();
  }

  final FlutterTts _tts = FlutterTts();

  bool _playing = false;
  bool _paused = false;

  double _speed = 0.42;

  String? _currentText;

  bool get isPlaying => _playing;

  bool get isPaused => _paused;

  double get speed => _speed;

  String? get currentText => _currentText;

  Future<void> _setup() async {
    await _tts.setLanguage(
      'ar-SA',
    );

    await _tts.setSpeechRate(
      _speed,
    );

    await _tts.setPitch(
      1.0,
    );

    await _tts.awaitSpeakCompletion(
      true,
    );

    _tts.setStartHandler(
      () {
        _playing = true;
        _paused = false;

        notifyListeners();
      },
    );

    _tts.setCompletionHandler(
      () {
        _playing = false;
        _paused = false;
        _currentText = null;

        notifyListeners();
      },
    );

    _tts.setCancelHandler(
      () {
        _playing = false;
        _paused = false;

        notifyListeners();
      },
    );

    _tts.setErrorHandler(
      (_) {
        _playing = false;
        _paused = false;

        notifyListeners();
      },
    );
  }

  Future<void> speak(
    String text,
  ) async {
    if (text.trim().isEmpty) {
      return;
    }

    await stop();

    _currentText = text;

    await _tts.setLanguage(
      'ar-SA',
    );

    await _tts.setSpeechRate(
      _speed,
    );

    await _tts.speak(
      text,
    );
  }

  Future<void> pause() async {
    await _tts.pause();

    _playing = false;
    _paused = true;

    notifyListeners();
  }

  Future<void> resume() async {
    if (_currentText == null) {
      return;
    }

    await speak(
      _currentText!,
    );
  }

  Future<void> stop() async {
    await _tts.stop();

    _playing = false;
    _paused = false;

    notifyListeners();
  }

  Future<void> setSpeed(
    double value,
  ) async {
    _speed = value.clamp(0.25, 0.65);

    await _tts.setSpeechRate(
      _speed,
    );

    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();

    super.dispose();
  }
}
