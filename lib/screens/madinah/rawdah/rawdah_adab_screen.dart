import 'package:flutter/material.dart';
import '../madinah_ui.dart';

class RawdahAdabScreen extends StatelessWidget {
  const RawdahAdabScreen({super.key});

  @override
  Widget build(BuildContext context) => const MPage(
        title: 'آداب ورفق',
        emoji: '🕊️',
        subtitle: 'سلامتك وسلامة من حولك جزء أساسي من التجربة.',
        children: [
          MCard(
            title: 'لا مزاحمة ولا إيذاء',
            subtitle:
                'لا تجعلي الوصول لموضع بعينه سببًا في دفع أو أذى الآخرين.',
            emoji: '🤍',
          ),
          MCard(
            title: 'اتبعي تنظيم المكان',
            subtitle: 'التزمي بتعليمات الجهة المنظمة ومسارات الدخول والخروج.',
            emoji: '↔️',
          ),
          MCard(
            title: 'اللحظة ليست سباقًا',
            subtitle: 'رِفقة لا يستخدم نقاطًا أو ترتيبًا أو منافسة في العبادة.',
            emoji: '🌿',
          ),
          MSourceBox(
            source: 'إرشادات تنظيمية عامة',
            note:
                'هذه الصفحة لا تستبدل تعليمات الجهة الرسمية في المسجد أو التصريح.',
          ),
        ],
      );
}
