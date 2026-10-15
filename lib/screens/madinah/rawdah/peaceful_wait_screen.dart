import 'package:flutter/material.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../madinah_ui.dart';

class PeacefulWaitScreen extends StatefulWidget {
  const PeacefulWaitScreen({super.key, required this.repository});
  final MadinahRepository repository;
  @override
  State<PeacefulWaitScreen> createState() => _PeacefulWaitScreenState();
}

class _PeacefulWaitScreenState extends State<PeacefulWaitScreen> {
  int i = 0;
  final reminders = const [
    'خففي استخدام الهاتف.',
    'اتركي مساحة لمن حولك.',
    'لا تحولي الانتظار إلى سباق مع الوقت.',
    'عودي إلى أدعيتك فقط عندما تحتاجينها.',
  ];

  @override
  Widget build(BuildContext context) => MPage(
        title: 'انتظار بسكينة',
        emoji: '🌿',
        subtitle: 'لا عداد، لا streak، ولا ضغط. مجرد تذكير هادئ.',
        children: [
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              reminders[i],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: emerald,
                fontSize: 20,
                height: 1.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() => i = (i + 1) % reminders.length),
            child: const Text('تذكير آخر'),
          ),
        ],
      );
}
