import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'umrah_data.dart';

/// خدمة الصوت: قراءة الشرح والأدعية بصوت عربي (TTS).
/// لاحقًا يمكن استبدال speak() بتشغيل تسجيلات صوتية لشيخ دون تغيير باقي الشاشات.
class UVoice {
  UVoice._();
  static final UVoice I = UVoice._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  int _token = 0;

  /// هل الصوت يعمل الآن؟
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  /// true إذا لم يجد الجهاز صوتًا عربيًا
  final ValueNotifier<bool> arabicMissing = ValueNotifier(false);

  Future<void> _init() async {
    if (_ready) return;
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('ar-SA');
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(.42);
      try {
        final ok = await _tts.isLanguageAvailable('ar-SA');
        if (ok == false) arabicMissing.value = true;
      } catch (_) {}
      _ready = true;
    } catch (_) {
      arabicMissing.value = true;
    }
  }

  /// يقرأ النص. يرجع true إذا انتهت القراءة طبيعيًا (لم تُقاطَع).
  Future<bool> speak(String text, {double rate = .42}) async {
    final my = ++_token;
    await _init();
    if (my != _token) return false;
    try {
      await _tts.stop();
      await _tts.setSpeechRate(rate);
      speaking.value = true;
      await _tts.speak(clean(text));
    } catch (_) {}
    final done = my == _token;
    if (done) speaking.value = false;
    return done;
  }

  Future<void> stop() async {
    _token++;
    try {
      await _tts.stop();
    } catch (_) {}
    speaking.value = false;
  }

  /// تنظيف النص ليُقرأ بشكل صحيح
  static String clean(String t) => t
      .replaceAll('ﷺ', 'صلى الله عليه وسلم')
      .replaceAll('←', 'إلى')
      .replaceAll('"', '')
      .replaceAll('•', '،');
}

const _num = [
  'الأولى',
  'الثانية',
  'الثالثة',
  'الرابعة',
  'الخامسة',
  'السادسة',
  'السابعة'
];
const _ord = [
  'أولًا',
  'ثانيًا',
  'ثالثًا',
  'رابعًا',
  'خامسًا',
  'سادسًا',
  'سابعًا',
  'ثامنًا'
];

/// نص الشرح الصوتي لخطوة كاملة
String stepNarration(UStep s, int i) {
  final b = StringBuffer('الخطوة ${_num[i]}: ${s.title}. ${s.summary} ');
  for (int k = 0; k < s.how.length; k++) {
    b.write('${_ord[k < 8 ? k : 7]}، ${s.how[k]} ');
  }
  b.write('نصيحة: ${s.tip}');
  return b.toString();
}
