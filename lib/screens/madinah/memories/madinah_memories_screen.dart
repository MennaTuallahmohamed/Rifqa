import 'package:flutter/material.dart';
import '../../../models/madinah/madinah_memory.dart';
import '../../../models/madinah/spiritual_reflection.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../madinah_ui.dart';
import 'last_night_screen.dart';
import 'letter_to_myself_screen.dart';

class MadinahMemoriesScreen extends StatefulWidget {
  const MadinahMemoriesScreen({super.key, required this.repository});
  final MadinahRepository repository;
  @override
  State<MadinahMemoriesScreen> createState() => _MadinahMemoriesScreenState();
}

class _MadinahMemoriesScreenState extends State<MadinahMemoriesScreen> {
  Future<void> showMemory(MadinahMemory memory) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${memory.displayEmoji} ${memory.displayTitle}'),
        content: SingleChildScrollView(child: Text(memory.text)),
        actions: [
          TextButton(
            onPressed: () async {
              await widget.repository.deleteMemory(memory.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حذف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => MPage(
        title: 'ذكريات المدينة',
        emoji: '🤍',
        subtitle: 'خاصة على جهازك حاليًا، ويمكنك حذفها متى شئتِ.',
        children: [
          MCard(
            title: 'رسالتي لنفسي',
            subtitle: 'رسالة خاصة تعودين إليها بعد الرحلة',
            emoji: '💌',
            onTap: () async {
              await go(
                context,
                LetterToMyselfScreen(repository: widget.repository),
              );
              if (mounted) setState(() {});
            },
          ),
          MCard(
            title: 'ليلتي الأخيرة',
            subtitle: 'تاريخ المغادرة + وقفة ختامية',
            emoji: '🌙',
            onTap: () async {
              await go(
                context,
                LastNightScreen(repository: widget.repository),
              );
              if (mounted) setState(() {});
            },
          ),
          const MSection('المحفوظ'),
          if (widget.repository.memories.isEmpty &&
              widget.repository.reflections.isEmpty)
            const MCard(
              title: 'لا ذكريات بعد',
              subtitle: 'ستظهر هنا كلماتك الخاصة من المسجد والروضة.',
              emoji: '◇',
            ),
          ...widget.repository.memories.map(
            (m) => MCard(
              title: m.displayTitle,
              subtitle: m.preview,
              emoji: m.displayEmoji,
              onTap: () => showMemory(m),
            ),
          ),
          ...widget.repository.reflections.map(
            (r) => MCard(
              title: r.type.label,
              subtitle: r.answer.length > 100
                  ? '${r.answer.substring(0, 100)}...'
                  : r.answer,
              emoji: '✦',
            ),
          ),
        ],
      );
}
