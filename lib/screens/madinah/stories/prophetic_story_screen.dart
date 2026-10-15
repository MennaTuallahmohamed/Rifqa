import 'package:flutter/material.dart';
import '../../../models/madinah/prophetic_story.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../madinah_ui.dart';
import 'prophetic_story_mode_screen.dart';

class PropheticStoryScreen extends StatelessWidget {
  const PropheticStoryScreen({
    super.key,
    required this.repository,
    required this.story,
  });

  final MadinahRepository repository;
  final PropheticStory story;

  @override
  Widget build(BuildContext context) => MPage(
        title: story.title,
        emoji: story.categoryEmoji,
        subtitle: story.subtitle,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              story.narrativeText,
              style: const TextStyle(color: ink, fontSize: 16, height: 1.9),
            ),
          ),
          const SizedBox(height: 12),
          if (story.authenticText != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEE2),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                story.authenticText!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: emerald,
                  fontSize: 20,
                  height: 1.9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 12),
          MSourceBox(
            source: [story.sourceName, story.sourceReference]
                .whereType<String>()
                .where((e) => e.trim().isNotEmpty)
                .join(' • '),
            note: story.editorialNote,
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: emerald),
            onPressed: () => go(
              context,
              PropheticStoryModeScreen(
                repository: repository,
                story: story,
              ),
            ),
            icon: const Icon(Icons.auto_stories_rounded),
            label: const Text('ابدئي وضع الحكاية'),
          ),
        ],
      );
}
