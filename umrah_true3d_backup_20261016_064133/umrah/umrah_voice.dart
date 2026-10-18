import 'umrah_data.dart';
import 'package:flutter/foundation.dart';

/// Legacy compatibility: device text-to-speech is intentionally disabled.
/// All Umrah narration uses the recorded documentary voice in RifqaNarrationPlayer.
class UVoice {
  UVoice._();
  static final UVoice I = UVoice._();
  final ValueNotifier<bool> speaking = ValueNotifier<bool>(false);
  final ValueNotifier<bool> arabicMissing = ValueNotifier<bool>(false);
  Future<bool> speak(String text, {double rate = .42}) async => false;
  Future<void> stop() async {
    speaking.value = false;
  }
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
