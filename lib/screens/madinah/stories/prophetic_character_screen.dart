import 'package:flutter/material.dart';
import '../../../services/madinah/prophetic_stories_repository.dart';
import '../madinah_ui.dart';

class PropheticCharacterScreen extends StatelessWidget {
  const PropheticCharacterScreen({
    super.key,
    required this.storiesRepository,
  });
  final PropheticStoriesRepository storiesRepository;

  @override
  Widget build(BuildContext context) {
    final values = <String>{};
    for (final story in storiesRepository.publishedStories) {
      values.addAll(story.suggestedValues);
    }
    return MPage(
      title: 'كيف كان ﷺ؟',
      emoji: 'ﷺ',
      subtitle:
          'لا نتخيل كلامًا أو موقفًا جديدًا؛ هذه معانٍ مرتبطة بالحكايات الموثقة داخل المكتبة.',
      children: [
        ...values.map(
          (v) => MCard(
            title: v,
            subtitle: 'معنى يظهر في موقف موثق داخل حكايات من هنا ﷺ',
            emoji: '🤍',
          ),
        ),
        const MSourceBox(
          source: 'منهج المحتوى',
          note:
              'المعنى التحريري ليس حديثًا. افتحي القصة نفسها لرؤية النص الموثق والمصدر.',
        ),
      ],
    );
  }
}
