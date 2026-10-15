import 'package:flutter/material.dart';
import '../../../models/madinah/madinah_memory.dart';
import '../../../models/madinah/spiritual_reflection.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../madinah_ui.dart';

class MosqueReflectionScreen extends StatefulWidget {
  const MosqueReflectionScreen({super.key, required this.repository});
  final MadinahRepository repository;
  @override
  State<MosqueReflectionScreen> createState() => _MosqueReflectionScreenState();
}

class _MosqueReflectionScreenState extends State<MosqueReflectionScreen> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await widget.repository.addReflection(
      SpiritualReflection(
        id: 'mosque_ref_$id',
        type: SpiritualReflectionType.insideMosque,
        prompt: 'كلمة من اللحظة',
        answer: text,
        createdAt: DateTime.now(),
      ),
    );
    await widget.repository.addMemory(
      MadinahMemory.mosqueReflection(id: 'mosque_mem_$id', text: text),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => MPage(
        title: 'الحمد لله 🤍',
        emoji: '🕌',
        subtitle: 'لا يلزم أن تكتبي شيئًا. وإن أحببتِ، احتفظي بكلمة خاصة.',
        children: [
          TextField(
            controller: controller,
            minLines: 5,
            maxLines: 9,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'كلمة من قلبي...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: save,
            style: FilledButton.styleFrom(backgroundColor: emerald),
            child: const Text('حفظ كذكرى خاصة 🔒'),
          ),
        ],
      );
}
