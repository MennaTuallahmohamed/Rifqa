import 'package:flutter/material.dart';
import '../../../models/madinah/madinah_memory.dart';
import '../../../models/madinah/madinah_journey_state.dart';
import '../../../models/madinah/spiritual_reflection.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../madinah_ui.dart';

class RawdahAfterScreen extends StatefulWidget {
  const RawdahAfterScreen({super.key, required this.repository});
  final MadinahRepository repository;
  @override
  State<RawdahAfterScreen> createState() => _RawdahAfterScreenState();
}

class _RawdahAfterScreenState extends State<RawdahAfterScreen> {
  final note = TextEditingController();
  String pledge = 'ورد قرآن صغير';

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final text = note.text.trim();
    await widget.repository.addReflection(
      SpiritualReflection(
        id: 'after_rawdah_$id',
        type: SpiritualReflectionType.afterRawdah,
        prompt: 'ما الذي أريد أن يبقى معي بعد الزيارة؟',
        answer: text.isEmpty ? pledge : '$pledge\n$text',
        carriedValue: pledge,
        createdAt: DateTime.now(),
      ),
    );
    if (text.isNotEmpty) {
      await widget.repository.addMemory(
        MadinahMemory.rawdahReflection(id: 'rawdah_mem_$id', text: text),
      );
    }
    await widget.repository.carryValue(pledge);
    await widget.repository.setRawdahStage(RawdahJourneyStage.completed);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => MPage(
        title: 'الحمد لله 🤍',
        emoji: '✨',
        subtitle: 'اختاري أثرًا شخصيًا بلا نقاط ولا مكافآت.',
        children: [
          ...[
            'ورد قرآن صغير',
            'أذكار الصباح والمساء',
            'صلة رحم',
            'عمل أختاره بنفسي',
          ].map(
            (x) => RadioListTile<String>(
              value: x,
              groupValue: pledge,
              activeColor: emerald,
              title: Text(x),
              onChanged: (v) => setState(() => pledge = v ?? pledge),
            ),
          ),
          TextField(
            controller: note,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'كلمة من الزيارة (اختياري)...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: save,
            style: FilledButton.styleFrom(backgroundColor: emerald),
            child: const Text('حفظ الأثر وإتمام الزيارة'),
          ),
        ],
      );
}
