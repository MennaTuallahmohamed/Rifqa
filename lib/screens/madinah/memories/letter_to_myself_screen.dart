import 'package:flutter/material.dart';
import '../../../models/madinah/spiritual_reflection.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../madinah_ui.dart';

class LetterToMyselfScreen extends StatefulWidget {
  final MadinahRepository repository;
  const LetterToMyselfScreen({super.key, required this.repository});
  @override
  State<LetterToMyselfScreen> createState() => _S();
}

class _S extends State<LetterToMyselfScreen> {
  final c = TextEditingController();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (c.text.trim().isEmpty) return;
    await widget.repository.addReflection(SpiritualReflection(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: SpiritualReflectionType.letterToSelf,
        prompt: 'إلى نفسي عندما أعود...',
        answer: c.text.trim(),
        createdAt: DateTime.now(),
        isPrivate: true));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => MPage(
          title: 'رسالتي لنفسي',
          emoji: '💌',
          subtitle: 'رسالة خاصة بكِ.',
          children: [
            TextField(
                controller: c,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'اكتبي رسالتك...')),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: save,
                style: FilledButton.styleFrom(backgroundColor: emerald),
                child: const Text('حفظ 🔒'))
          ]);
}
