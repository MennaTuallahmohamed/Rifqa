import 'package:flutter/foundation.dart';
import '../umrah/umrah_data.dart';
import '../umrah/umrah_voice.dart';

const _num = [
  'الأولى',
  'الثانية',
  'الثالثة',
  'الرابعة',
  'الخامسة',
  'السادسة',
  'السابعة',
  'الثامنة'
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

/// نص الشرح الصوتي لخطوة من خطوات الحج (يُقرأ عبر UVoice من ملف العمرة)
String hajjStepNarration(UStep s, int i) {
  final b =
      StringBuffer('الخطوة ${_num[i]} من الحج: ${s.title}. ${s.summary} ');
  for (int k = 0; k < s.how.length; k++) {
    b.write('${_ord[k < 8 ? k : 7]}، ${s.how[k]} ');
  }
  b.write('نصيحة: ${s.tip}');
  return b.toString();
}

/// نص نطق خطوة فرعية واحدة (وضع المرشد)
String hajjMicroNarration(int k, int total, String text) =>
    'الخطوة ${k + 1} من $total. $text';

/// جملة تُنطق ضمن قائمة انتظار
class HSay {
  final String text;
  final double rate;
  const HSay(this.text, {this.rate = .5});
}

/// مُشغّل صوتي بقائمة انتظار: ينطق جملة بعد جملة ويمكن إيقافه فورًا.
/// لا يعتمد على أن يكون UVoice.speak ينتظر انتهاء الكلام، بل يراقب حالة speaking.
class HajjSpeaker {
  HajjSpeaker._();
  static final HajjSpeaker I = HajjSpeaker._();

  int _token = 0;
  final ValueNotifier<bool> busy = ValueNotifier<bool>(false);

  Future<void> _one(HSay s, int token) async {
    if (token != _token) return;
    try {
      await UVoice.I.speak(s.text, rate: s.rate);
    } catch (_) {
      return;
    }
    var w = 0;
    while (token == _token && !UVoice.I.speaking.value && w < 15) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      w++;
    }
    while (token == _token && UVoice.I.speaking.value) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  /// ينطق القائمة كلها بالترتيب، ويرجع عند الانتهاء أو عند الإيقاف.
  Future<void> queue(List<HSay> items) async {
    stopSilently();
    final my = ++_token;
    busy.value = true;
    for (final s in items) {
      if (my != _token) break;
      await _one(s, my);
    }
    if (my == _token) busy.value = false;
  }

  Future<void> say(String text, {double rate = .5}) =>
      queue([HSay(text, rate: rate)]);

  void stopSilently() {
    _token++;
  }

  Future<void> stop() async {
    _token++;
    busy.value = false;
    try {
      await UVoice.I.stop();
    } catch (_) {}
  }
}
