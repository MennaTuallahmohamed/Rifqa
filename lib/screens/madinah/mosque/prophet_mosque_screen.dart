import 'package:flutter/material.dart';

import '../../../models/madinah/madinah_journey_state.dart';
import '../../../services/madinah/madinah_content_repository.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../madinah_ui.dart';
import '../salawat/salawat_library_screen.dart';
import '../stories/prophetic_stories_screen.dart';
import 'mosque_prepare_screen.dart';
import 'mosque_reflection_screen.dart';
import 'mosque_sanctuary_screen.dart';
import 'mosque_wird_screen.dart';

class ProphetMosqueScreen extends StatefulWidget {
  const ProphetMosqueScreen({
    super.key,
    required this.repository,
    required this.contentRepository,
  });

  final MadinahRepository repository;
  final MadinahContentRepository contentRepository;

  @override
  State<ProphetMosqueScreen> createState() => _ProphetMosqueScreenState();
}

class _ProphetMosqueScreenState extends State<ProphetMosqueScreen> {
  Future<void> _stage(ProphetMosqueStage stage, Widget page) async {
    await widget.repository.enterProphetMosque();
    await widget.repository.setMosqueStage(stage);
    if (!mounted) return;
    await go(context, page);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.repository.journey.mosqueStage;
    return MPage(
      title: 'صحبتي في المسجد النبوي',
      emoji: '🕌',
      subtitle: 'أين أنتِ الآن؟ اختاري المرحلة، ورِفقة يساعدك ثم يختفي.',
      children: [
        MCard(
          title: 'في طريقي للمسجد',
          subtitle: 'تهيّئي بهدوء قبل الوصول',
          emoji: '🚶',
          selected: current == ProphetMosqueStage.onTheWay,
          onTap: () => _stage(
            ProphetMosqueStage.onTheWay,
            MosquePrepareScreen(repository: widget.repository),
          ),
        ),
        MCard(
          title: 'وصلت إلى المسجد',
          subtitle: 'وضع السكينة: أقل شاشة وأكثر حضورًا',
          emoji: '🤍',
          selected: current == ProphetMosqueStage.arrived,
          onTap: () => _stage(
            ProphetMosqueStage.arrived,
            MosqueSanctuaryScreen(repository: widget.repository),
          ),
        ),
        MCard(
          title: 'داخل المسجد',
          subtitle: 'وردي الشخصي بلا نقاط ولا منافسة',
          emoji: '🌿',
          selected: current == ProphetMosqueStage.inside,
          onTap: () => _stage(
            ProphetMosqueStage.inside,
            const MosqueWirdScreen(),
          ),
        ),
        MCard(
          title: 'انتهيت من زيارتي',
          subtitle: 'احتفظي بكلمة من قلبك إن أحببتِ',
          emoji: '🌙',
          selected: current == ProphetMosqueStage.completed,
          onTap: () => _stage(
            ProphetMosqueStage.completed,
            MosqueReflectionScreen(repository: widget.repository),
          ),
        ),
        const MSection('من هنا ﷺ'),
        MCard(
          title: 'حكايات من هنا ﷺ',
          subtitle: 'مواقف موثقة، والنص التحريري منفصل عن المصدر',
          emoji: '📖',
          onTap: () => go(
            context,
            PropheticStoriesScreen(
              repository: widget.repository,
              storiesRepository: widget.contentRepository.storiesRepository,
            ),
          ),
        ),
        MCard(
          title: 'الصلاة والسلام ﷺ',
          subtitle: 'الصيغ الموثقة في قارئ هادئ',
          emoji: 'ﷺ',
          onTap: () => go(
            context,
            SalawatLibraryScreen(
              repository: widget.repository,
              salawatRepository: widget.contentRepository.salawatRepository,
            ),
          ),
        ),
      ],
    );
  }
}
