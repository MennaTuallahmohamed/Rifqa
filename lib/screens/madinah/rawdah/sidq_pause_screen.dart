import 'package:flutter/material.dart';
import '../../../models/madinah/spiritual_reflection.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../madinah_ui.dart';

class SidqPauseScreen extends StatefulWidget {
  const SidqPauseScreen({super.key, required this.repository});
  final MadinahRepository repository;
  @override
  State<SidqPauseScreen> createState() => _SidqPauseScreenState();
}

class _SidqPauseScreenState extends State<SidqPauseScreen> {
  final c = TextEditingController();
  String prompt = 'ما الذي أريد أن أصلحه في قلبي؟';

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (c.text.trim().isEmpty) return;
    await widget.repository.addReflection(
      SpiritualReflection(
        id: 'sidq_${DateTime.now().microsecondsSinceEpoch}',
        type: SpiritualReflectionType.beforeRawdah,
        prompt: prompt,
        answer: c.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => MPage(
        title: 'وقفة صدق',
        emoji: '🤍',
        subtitle:
            'هذه أسئلة تأمل شخصية من رِفقة وليست أذكارًا مأثورة أو نصوصًا شرعية.',
        children: [
          ...[
            'ما الذي أريد أن أصلحه في قلبي؟',
            'لمن أحتاج أن أسامح أو أعتذر؟',
            'ما الدعاء الذي أحمله منذ زمن؟',
          ].map(
            (p) => RadioListTile<String>(
              value: p,
              groupValue: prompt,
              activeColor: emerald,
              title: Text(p),
              onChanged: (v) => setState(() => prompt = v ?? prompt),
            ),
          ),
          TextField(
            controller: c,
            minLines: 5,
            maxLines: 9,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'اكتبي لنفسك فقط...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: save,
            style: FilledButton.styleFrom(backgroundColor: emerald),
            child: const Text('حفظ خاص 🔒'),
          ),
        ],
      );
}
