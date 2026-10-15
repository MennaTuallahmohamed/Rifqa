import 'package:flutter/material.dart';
import '../../../models/dua_model.dart';
import '../../../services/duas/duas_repository.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../../duas/dua_details_screen.dart';
import '../../duas/my_duas_screen.dart';
import '../madinah_ui.dart';

class PrayerBagScreen extends StatelessWidget {
  const PrayerBagScreen({
    super.key,
    required this.repository,
    required this.duasRepository,
  });

  final MadinahRepository repository;
  final DuasRepository duasRepository;

  @override
  Widget build(BuildContext context) {
    final favorites = duasRepository.favorites;
    final mine = duasRepository.userDuas;
    return MPage(
      title: 'حقيبة دعائي',
      emoji: '🤲',
      subtitle: 'نفس أدعيتك الموجودة في رِفقة — لا قاعدة بيانات ثانية.',
      children: [
        MCard(
          title: 'أدعيتي الخاصة',
          subtitle: '${mine.length} دعاء محفوظ',
          emoji: '📝',
          onTap: () => go(
            context,
            MyDuasScreen(repository: duasRepository),
          ),
        ),
        const MSection('المفضلة'),
        if (favorites.isEmpty)
          const MCard(
            title: 'لا توجد مفضلة بعد',
            subtitle: 'أضيفي الأدعية المهمة للمفضلة من مكتبة الأدعية.',
            emoji: '♡',
          )
        else
          ...favorites.map(
            (dua) => MCard(
              title: dua.title,
              subtitle: dua.sourceType.label,
              emoji: '🤲',
              onTap: () => go(
                context,
                DuaDetailsScreen(
                  repository: duasRepository,
                  duaId: dua.id,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
