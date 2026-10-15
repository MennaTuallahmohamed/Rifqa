import 'package:flutter/material.dart';
import '../../../models/madinah/prophetic_story.dart';
import '../../../models/madinah/spiritual_reflection.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../madinah_ui.dart';

class PropheticStoryModeScreen extends StatefulWidget {
  const PropheticStoryModeScreen({
    super.key,
    required this.repository,
    required this.story,
  });
  final MadinahRepository repository;
  final PropheticStory story;

  @override
  State<PropheticStoryModeScreen> createState() =>
      _PropheticStoryModeScreenState();
}

class _PropheticStoryModeScreenState extends State<PropheticStoryModeScreen> {
  int index = 0;
  final reflection = TextEditingController();
  String? value;

  @override
  void dispose() {
    reflection.dispose();
    super.dispose();
  }

  Future<void> finish() async {
    await widget.repository.markStoryRead(widget.story.id);
    if (value != null) await widget.repository.carryValue(value!);
    if (reflection.text.trim().isNotEmpty) {
      await widget.repository.addReflection(
        SpiritualReflection(
          id: 'story_${DateTime.now().microsecondsSinceEpoch}',
          type: SpiritualReflectionType.afterPropheticStory,
          prompt: widget.story.reflectionQuestion,
          answer: reflection.text.trim(),
          storyId: widget.story.id,
          carriedValue: value,
          createdAt: DateTime.now(),
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scenes = widget.story.scenes;
    final finishedScenes = index >= scenes.length;
    if (finishedScenes) {
      return MPage(
        title: 'وقفة مع القلب',
        emoji: '🤍',
        subtitle: widget.story.reflectionQuestion,
        children: [
          ...widget.story.suggestedValues.map(
            (v) => RadioListTile<String>(
              value: v,
              groupValue: value,
              activeColor: emerald,
              title: Text(v),
              onChanged: (x) => setState(() => value = x),
            ),
          ),
          TextField(
            controller: reflection,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'وقفة خاصة (اختياري)...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: finish,
            style: FilledButton.styleFrom(backgroundColor: emerald),
            child: const Text('احتفظي بالأثر'),
          ),
        ],
      );
    }

    final scene = scenes[index];
    return Scaffold(
      backgroundColor: scene.calm ? emeraldDark : ivory,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: scene.calm ? Colors.white : emerald,
                  ),
                ),
              ),
              const Spacer(),
              if (scene.title != null) ...[
                Text(
                  scene.title!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scene.calm ? gold : emerald,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                scene.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scene.calm ? Colors.white : ink,
                  fontSize: 22,
                  height: 1.9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              LinearProgressIndicator(
                value: (index + 1) / scenes.length,
                color: gold,
                backgroundColor: (scene.calm ? Colors.white : emerald)
                    .withValues(alpha: .15),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => setState(() => index++),
                style: FilledButton.styleFrom(
                  backgroundColor: scene.calm ? gold : emerald,
                ),
                child: Text(
                    index == scenes.length - 1 ? 'وقفة مع القلب' : 'التالي'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
