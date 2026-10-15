import 'package:flutter/material.dart';
import '../../../models/madinah/spiritual_reflection.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../madinah_ui.dart';
import 'letter_to_myself_screen.dart';

class LastNightScreen extends StatefulWidget {
  const LastNightScreen({super.key, required this.repository});
  final MadinahRepository repository;
  @override
  State<LastNightScreen> createState() => _LastNightScreenState();
}

class _LastNightScreenState extends State<LastNightScreen> {
  final note = TextEditingController();

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> chooseDeparture() async {
    final x = await showDatePicker(
      context: context,
      initialDate: widget.repository.departureDate ??
          DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (x != null) {
      await widget.repository.setDepartureDate(x);
      if (mounted) setState(() {});
    }
  }

  Future<void> save() async {
    if (note.text.trim().isEmpty) return;
    await widget.repository.addReflection(
      SpiritualReflection(
        id: 'last_${DateTime.now().microsecondsSinceEpoch}',
        type: SpiritualReflectionType.lastNight,
        prompt: 'ما الذي ستأخذينه معك من المدينة؟',
        answer: note.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
    note.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.repository.departureDate;
    return MPage(
      title: 'ليلتي الأخيرة',
      emoji: '🌙',
      subtitle: widget.repository.isLastNightInMadinah
          ? 'هذه ليلتك الأخيرة حسب تاريخ المغادرة المحفوظ.'
          : 'اجمعي أثر الرحلة قبل المغادرة.',
      children: [
        MCard(
          title: 'تاريخ المغادرة',
          subtitle:
              d == null ? 'لم يتم تحديده' : '${d.day}/${d.month}/${d.year}',
          emoji: '📅',
          onTap: chooseDeparture,
        ),
        MCard(
          title: 'رسالتي لنفسي',
          subtitle: 'كلمة تعودين إليها بعد الرحلة',
          emoji: '💌',
          onTap: () => go(
            context,
            LetterToMyselfScreen(repository: widget.repository),
          ),
        ),
        const MSection('ما الذي ستأخذينه معك من المدينة؟'),
        TextField(
          controller: note,
          minLines: 5,
          maxLines: 9,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'اكتبي لنفسك...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: save,
          style: FilledButton.styleFrom(backgroundColor: emerald),
          child: const Text('حفظ الوقفة 🔒'),
        ),
        const SizedBox(height: 14),
        MCard(
          title: 'ملخص رحلتي',
          subtitle:
              '${widget.repository.memoriesCount} ذكرى • ${widget.repository.reflectionsCount} وقفة • ${widget.repository.storiesReadCount} حكاية',
          emoji: '📖',
        ),
      ],
    );
  }
}
