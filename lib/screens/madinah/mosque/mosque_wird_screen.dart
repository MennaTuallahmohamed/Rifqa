import 'package:flutter/material.dart';
import '../madinah_ui.dart';

class MosqueWirdScreen extends StatefulWidget {
  const MosqueWirdScreen({super.key});
  @override
  State<MosqueWirdScreen> createState() => _MosqueWirdScreenState();
}

class _MosqueWirdScreenState extends State<MosqueWirdScreen> {
  final items = <String, bool>{
    'قرآن': false,
    'ذكر': false,
    'الصلاة والسلام على النبي ﷺ': false,
    'دعاء': false,
    'أمانات الدعاء': false,
  };

  @override
  Widget build(BuildContext context) => MPage(
        title: 'وردي في المسجد',
        emoji: '🌿',
        subtitle: 'تذكير شخصي فقط؛ بلا نقاط أو streaks أو تقييم.',
        children: [
          ...items.keys.map(
            (key) => CheckboxListTile(
              value: items[key],
              activeColor: emerald,
              title: Text(key),
              onChanged: (v) => setState(() => items[key] = v ?? false),
            ),
          ),
          const MSourceBox(
            source: 'تنظيم شخصي',
            note: 'هذه القائمة ليست ترتيبًا لفضائل الأعمال ولا حكمًا شرعيًا.',
          ),
        ],
      );
}
