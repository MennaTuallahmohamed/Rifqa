import 'package:flutter/material.dart';
import '../madinah_ui.dart';

class SpiritualQuoteCard extends StatelessWidget {
  const SpiritualQuoteCard({super.key});
  @override
  Widget build(BuildContext context) => MPage(
          title: 'وقفة',
          emoji: '◇',
          subtitle: 'مكوّن جاهز.',
          children: const [
            MCard(
                title: 'هذه الشاشة جاهزة للربط',
                subtitle:
                    'سيتم تغذية المحتوى من المستودعات الحالية بدون تكرار البيانات.',
                emoji: '🤍')
          ]);
}
