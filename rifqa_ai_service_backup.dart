// lib/services/haramain/rifqa_ai_service.dart
//
// طبقة الذكاء الاصطناعي لـ «اسأل رفقة».
// - Gemini عبر Firebase AI Logic (Spark / Free Tier)
// - مقيّد بموضوع الحج والعمرة فقط عن طريق System Instruction
// - حد أقصى للأسئلة في الجلسة + مهلة زمنية
// - لو فشل أي شيء (نت / حصة / خطأ) نرجع تلقائيًا للمساعد المحلي بدون ما المستخدم يحس
//
// pubspec.yaml:
//   firebase_core: ^latest
//   firebase_ai: ^latest
//
// وفعّلي Firebase App Check قبل الإطلاق.

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../services/haramain/haramain_assistant_service.dart';

enum RifqaSource { ai, local, limit }

class RifqaReply {
  const RifqaReply(this.text, this.source);
  final String text;
  final RifqaSource source;
}

class RifqaAiService {
  RifqaAiService({this.maxQuestionsPerSession = 25});

  final int maxQuestionsPerSession;
  final _local = const LocalHaramainAssistantBackend();

  int _count = 0;
  ChatSession? _chat;

  Iterable<String> get suggestions => _local.suggestions;

  static const _systemPrompt = '''
أنتِ «رفقة»، مساعدة صوتية هادئة للحجاج والمعتمرين داخل تطبيق رفقة.

النطاق المسموح فقط:
- خطوات العمرة والحج (إحرام، طواف، سعي، حلق/تقصير، منى، عرفة، مزدلفة، رمي الجمرات).
- التنقل العام في مكة والمدينة والحرمين، وتجهيز السفر، ونصائح الصحة العامة غير التشخيصية.
- شرح مزايا التطبيق.

القواعد الصارمة:
1. لو السؤال خارج النطاق، اعتذري بلطف في جملة واحدة وارجعي للموضوع.
2. لا تُصدري فتاوى. اشرحي المتفق عليه باختصار، وفي المسائل الخلافية أو الحالات الخاصة قولي: «راجعي جهة إفتاء معتمدة أو مشرف الحملة».
3. لا تشخّصي أمراضًا ولا تصفي أدوية. في الطوارئ الصحية: وجّهيها فورًا للاتصال بالإسعاف 997 أو أقرب نقطة هلال أحمر.
4. لا تخترعي أماكن أو مواقع أو مواعيد. لو لا تعرفين قولي: «مش متأكدة، افتحي الخريطة في التطبيق».
5. لو قالت إنها تائهة أو في خطر: اطمئنيها في جملة، وقولي لها تضغط زر «أنا تائه» في التطبيق. لا تتخذي قرارًا بنفسك.

الأسلوب:
- عربي بسيط بلهجة مصرية مهذبة، مخاطبة المؤنث افتراضيًا.
- جمل قصيرة جدًا تُقرأ بصوت عالٍ بسهولة (أقل من 80 كلمة).
- خطوات مرقمة عند الشرح، بدون جداول أو رموز معقدة أو Markdown.
- ابدئي بالإجابة مباشرة.
''';

  GenerativeModel _buildModel() {
    return FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash-lite', // أخف نموذج وأنسب للحصة المجانية
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.3, // ثبات أكبر = هلوسة أقل
        maxOutputTokens: 400,
      ),
    );
  }

  Future<RifqaReply> ask(String question) async {
    if (_count >= maxQuestionsPerSession) {
      return const RifqaReply(
        'وصلتي للحد اليومي من الأسئلة الذكية. تقدري تستخدمي الاقتراحات الجاهزة، أو تجربي بعد شوية.',
        RifqaSource.limit,
      );
    }

    try {
      _chat ??= _buildModel().startChat();
      final response = await _chat!
          .sendMessage(Content.text(question))
          .timeout(const Duration(seconds: 20));
      final text = response.text?.trim();
      if (text == null || text.isEmpty) throw StateError('empty');
      _count++;
      return RifqaReply(text, RifqaSource.ai);
    } catch (e) {
      debugPrint('RifqaAiService fallback: $e');
      _chat = null; // نبدأ جلسة جديدة عند أي خطأ
      final local = await _local.resolve(question);
      return RifqaReply(local.utterance, RifqaSource.local);
    }
  }

  void resetConversation() => _chat = null;
}