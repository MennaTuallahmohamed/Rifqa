import 'package:flutter/material.dart';
import '../../../models/madinah/spiritual_reflection.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../madinah_ui.dart';

class MosquePrepareScreen extends StatefulWidget {
  const MosquePrepareScreen({super.key, required this.repository});
  final MadinahRepository repository;
  @override
  State<MosquePrepareScreen> createState() => _MosquePrepareScreenState();
}

class _MosquePrepareScreenState extends State<MosquePrepareScreen> {
  final note = TextEditingController();
  final checks = <String, bool>{
    'أستعد للصلاة بهدوء': false,
    'أضع الهاتف على الوضع الهادئ': false,
    'أترك مساحة للآخرين وأتجنب المزاحمة': false,
  };

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (note.text.trim().isNotEmpty) {
      await widget.repository.addReflection(
        SpiritualReflection(
          id: 'before_mosque_${DateTime.now().microsecondsSinceEpoch}',
          type: SpiritualReflectionType.beforeMosque,
          prompt: 'بماذا أريد أن أدخل هذه الزيارة؟',
          answer: note.text.trim(),
          createdAt: DateTime.now(),
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => MPage(
        title: 'تهيّئي للمسجد',
        emoji: '🎒',
        subtitle: 'قائمة تنظيمية بسيطة؛ ليست تقييمًا للعبادة.',
        children: [
          ...checks.keys.map(
            (key) => CheckboxListTile(
              value: checks[key],
              activeColor: emerald,
              title: Text(key),
              onChanged: (v) => setState(() => checks[key] = v ?? false),
            ),
          ),
          TextField(
            controller: note,
            maxLines: 4,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'بماذا أريد أن أدخل هذه الزيارة؟',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: save,
            style: FilledButton.styleFrom(backgroundColor: emerald),
            child: const Text('حفظ والاستمرار'),
          ),
        ],
      );
}
