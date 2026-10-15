import 'package:flutter/material.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../../../services/madinah/prophetic_stories_repository.dart';
import '../madinah_ui.dart';
import 'prophetic_character_screen.dart';
import 'prophetic_story_screen.dart';

class PropheticStoriesScreen extends StatelessWidget {
  const PropheticStoriesScreen({
    super.key,
    required this.repository,
    required this.storiesRepository,
  });
  final MadinahRepository repository;
  final PropheticStoriesRepository storiesRepository;

  @override
  Widget build(BuildContext context) {
    final stories = storiesRepository.publishedStories;
    return MPage(
      title: 'حكايات من هنا ﷺ',
      emoji: '📖',
      subtitle:
          'الحدث الموثق منفصل عن الوقفة التحريرية. لا حوار متخيّل ولا تفاصيل مخترعة.',
      children: [
        MCard(
          title: 'كيف كان ﷺ؟',
          subtitle: 'معانٍ مستفادة من مواقف موثقة، لا تخيّل لشخصه أو كلامه',
          emoji: '🤍',
          onTap: () => go(
            context,
            PropheticCharacterScreen(storiesRepository: storiesRepository),
          ),
        ),
        const MSection('الحكايات الموثقة'),
        ...stories.map(
          (story) => MCard(
            title: story.title,
            subtitle:
                '${story.subtitle} • ${story.readingMinutes} د • ${story.sourceBadge}',
            emoji: story.categoryEmoji,
            selected: repository.journey.readStoryIds.contains(story.id),
            onTap: () => go(
              context,
              PropheticStoryScreen(
                repository: repository,
                story: story,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
