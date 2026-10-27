import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../umrah/umrah_data.dart';
import 'hajj_data.dart';
import 'hajj_duas.dart';

const _num = ['الأولى','الثانية','الثالثة','الرابعة','الخامسة','السادسة','السابعة','الثامنة'];
const _ord = ['أولًا','ثانيًا','ثالثًا','رابعًا','خامسًا','سادسًا','سابعًا','ثامنًا'];

/// Hajj narration: spoken using natural MP3 where available, otherwise Arabic TTS.
String hajjStepNarration(UStep s, int i) {
  final b = StringBuffer('الخطوة ${_num[i]} من الحج: ${s.title}. ${s.summary} ');
  for (int k = 0; k < s.how.length; k++) {
    b.write('${_ord[k < 8 ? k : 7]}، ${s.how[k]} ');
  }
  b.write('نصيحة: ${s.tip}');
  return b.toString();
}

String hajjMicroNarration(int k, int total, String text) =>
    'الخطوة ${k + 1} من $total. $text';

class HSay {
  final String text;
  final double rate; // Requested speech rate used by Arabic TTS fallback.
  const HSay(this.text, {this.rate = .5});
}

/// Plays *recorded human speech only* from local MP3 assets.
/// No synthetic fallback. When an asset is missing, [notice] explains why.
/// Hajj audio: natural Arabic MP3 tracks take priority, with a spoken fallback
/// for EVERY guide instruction, dua, timeline event and step narration.
/// The fallback deliberately remains active if tracks are unavailable.
class HajjSpeaker {
  HajjSpeaker._();
  static final HajjSpeaker I = HajjSpeaker._();

  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  final ValueNotifier<bool> busy = ValueNotifier<bool>(false);
  final ValueNotifier<String?> notice = ValueNotifier<String?>(null);

  int _token = 0;
  Future<void>? _setupFuture;

  String? _path(String sentence) {
    if (sentence == 'ويقال فيها:') return null;
    if (sentence == 'تقبّل الله منك. اضغط أتممت المنسك للانتقال إلى الخطوة التالية.') {
      return 'assets/audio/hajj/closing.mp3';
    }
    for (int i = 0; i < hajjGuide.length; i++) {
      final step = hajjGuide[i];
      if (sentence == hajjStepNarration(step, i)) {
        return 'assets/audio/hajj/step_${i + 1}.mp3';
      }
      if (sentence == step.dua) {
        return 'assets/audio/hajj/step_${i + 1}_dua.mp3';
      }
      for (int k = 0; k < step.how.length; k++) {
        if (sentence == hajjMicroNarration(k, step.how.length, step.how[k])) {
          return 'assets/audio/hajj/step_${i + 1}_part_${k + 1}.mp3';
        }
      }
      if (sentence == 'نصيحة: ${step.tip}') {
        return 'assets/audio/hajj/step_${i + 1}_final.mp3';
      }
      if (step.women != null && sentence == 'للمرأة: ${step.women}') {
        return 'assets/audio/hajj/step_${i + 1}_women.mp3';
      }
    }
    for (final dua in hajjDuas) {
      if (sentence == dua.ar) return 'assets/audio/hajj/dua_${dua.id}.mp3';
    }
    for (int i = 0; i < hajjTimeline.length; i++) {
      if (sentence == hajjTimeline[i].say) {
        return 'assets/audio/hajj/timeline_${i + 1}.mp3';
      }
    }
    return null;
  }

  Future<void> _setup() => _setupFuture ??= _configureTts();

  Future<void> _configureTts() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.46);
    try { await _tts.setLanguage('ar-EG'); } catch (_) {}

    // Prefer a clear Egyptian Arabic voice if the device has one installed.
    // Network voices may sound more natural; if none exists, default Arabic
    // speech stays available without any cloud credentials.
    try {
      final voices = await _tts.getVoices;
      final candidates = <Map<String, String>>[];
      if (voices is List) {
        for (final raw in voices) {
          if (raw is! Map) continue;
          final locale = '${raw['locale'] ?? ''}';
          final name = '${raw['name'] ?? ''}';
          if (!locale.toLowerCase().startsWith('ar')) continue;
          candidates.add({'locale': locale, 'name': name,
            'quality': '${raw['quality'] ?? ''}',
            'network': '${raw['network_required'] ?? ''}'});
        }
      }
      if (candidates.isNotEmpty) {
        int score(Map<String, String> v) {
          final loc = v['locale']!.toLowerCase().replaceAll('_', '-');
          final name = v['name']!.toLowerCase();
          var result = loc == 'ar-eg' ? 100 : (loc == 'ar-sa' ? 80 : 60);
          if (v['network'] == 'true') result += 8;
          if (name.contains('google')) result += 6;
          final quality = int.tryParse(v['quality'] ?? '');
          if (quality != null) result += quality.clamp(0, 20).toInt();
          return result;
        }
        candidates.sort((a, b) => score(b).compareTo(score(a)));
        final selected = candidates.first;
        try {
          await _tts.setVoice({
            'name': selected['name']!,
            'locale': selected['locale']!,
          });
          debugPrint('Rifqa Hajj Arabic voice: ${selected['name']}');
          return;
        } catch (e) {
          debugPrint('Rifqa Hajj: voice selection unavailable: $e');
        }
      }
    } catch (e) {
      debugPrint('Rifqa Hajj: voice list unavailable: $e');
    }
    try {
      await _tts.setLanguage('ar-EG');
    } catch (_) {
      await _tts.setLanguage('ar-SA');
    }
  }

  Future<bool> _tryAudio(String text, int token) async {
    final requested = _path(text);
    if (requested == null) return false;
    for (final asset in <String>[
      requested,
      requested.replaceFirst('.mp3', '.wav'),
    ]) {
      try {
        await rootBundle.load(asset);
        if (token != _token) return true;
        await _player.setAsset(asset);
        if (token != _token) return true;
        await _player.play();
        return true;
      } catch (e) {
        debugPrint('Rifqa Hajj recorded track unavailable: $asset ($e)');
      }
    }
    return false;
  }

  Future<void> _one(HSay item, int token) async {
    if (token != _token || item.text.trim().isEmpty) return;
    if (item.text == 'ويقال فيها:') return;

    if (await _tryAudio(item.text, token)) return;
    if (token != _token) return;

    try {
      await _setup();
      if (token != _token) return;
      await _tts.setSpeechRate(item.rate.clamp(0.38, 0.53).toDouble());
      if (token != _token) return;
      final result = await _tts.speak(item.text);
      if (token != _token) return;
      if (result == 0 || result == false) {
        throw StateError('Arabic text-to-speech did not start');
      }
    } catch (e) {
      if (token == _token) {
        notice.value = 'تعذّر تشغيل الصوت. تأكد من تفعيل محرّك النطق العربي في إعدادات الهاتف.';
        debugPrint('Rifqa Hajj TTS failure: $e');
      }
    }
  }

  /// A new speech request cancels the previous one, then plays in order.
  /// It returns only when narration completes or is interrupted.
  Future<void> queue(List<HSay> items) async {
    final token = ++_token;
    busy.value = true;
    notice.value = null;
    try {
      try { await _player.stop(); } catch (_) {}
      try { await _tts.stop(); } catch (_) {}
      if (token != _token) return;
      for (final item in items) {
        if (token != _token) break;
        await _one(item, token);
        if (notice.value != null) break;
      }
    } finally {
      if (token == _token) busy.value = false;
    }
  }

  Future<void> say(String text, {double rate = .5}) =>
      queue([HSay(text, rate: rate)]);

  void stopSilently() {
    ++_token;
    busy.value = false;
    notice.value = null;
    _player.stop();
    _tts.stop();
  }

  Future<void> stop() async {
    ++_token;
    busy.value = false;
    notice.value = null;
    try { await _player.stop(); } catch (_) {}
    try { await _tts.stop(); } catch (_) {}
  }
}
