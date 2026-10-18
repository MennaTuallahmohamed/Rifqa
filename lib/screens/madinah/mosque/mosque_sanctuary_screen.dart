import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../services/madinah/madinah_repository.dart';
import 'mosque_grandeur_experience.dart';
import '../madinah_ui.dart';

class MosqueSanctuaryScreen extends StatefulWidget {
  const MosqueSanctuaryScreen({super.key, required this.repository});
  final MadinahRepository repository;
  @override
  State<MosqueSanctuaryScreen> createState() => _MosqueSanctuaryScreenState();
}

class _MosqueSanctuaryScreenState extends State<MosqueSanctuaryScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MPage(
        title: 'أنتِ هنا الآن',
        emoji: '🕌',
        subtitle: 'رِفقة لن يطلب منك إنجاز شيء. اتركي الهاتف قليلًا.',
        calm: true,
        children: [
          const SizedBox(height: 50),
          const Text(
            '🤍',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 58),
          ),
          const SizedBox(height: 20),
          Text(
            'خذي ما تحتاجينه من التطبيق، ثم عودي للحظة نفسها.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .84),
              fontSize: 18,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () => go(context, const MosqueGrandeurExperience()),
            icon: const Icon(Icons.view_in_ar_rounded),
            label: const Text('استشعري عظمة المكان · 3D'),
            style: FilledButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: emeraldDark,
            ),
          ),
          const SizedBox(height: 40),

          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('العودة عند الحاجة'),
          ),
        ],
      );
}
