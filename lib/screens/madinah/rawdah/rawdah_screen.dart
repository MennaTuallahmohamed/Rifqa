import 'package:flutter/material.dart';

import '../../../models/madinah/madinah_journey_state.dart';
import '../../../services/duas/duas_repository.dart';
import '../../../services/madinah/madinah_repository.dart';
import '../madinah_ui.dart';
import 'peaceful_wait_screen.dart';
import 'prayer_bag_screen.dart';
import 'prayer_trusts_screen.dart';
import 'rawdah_adab_screen.dart';
import 'rawdah_after_screen.dart';
import 'rawdah_appointment_screen.dart';
import 'rawdah_quiet_mode_screen.dart';
import 'sidq_pause_screen.dart';

class RawdahScreen extends StatefulWidget {
  const RawdahScreen({
    super.key,
    required this.repository,
    required this.duasRepository,
    this.openTrustsDirectly = false,
  });

  final MadinahRepository repository;
  final DuasRepository duasRepository;
  final bool openTrustsDirectly;

  @override
  State<RawdahScreen> createState() => _RawdahScreenState();
}

class _RawdahScreenState extends State<RawdahScreen> {
  bool openedDirect = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.openTrustsDirectly && !openedDirect) {
      openedDirect = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _open(
          RawdahJourneyStage.prayerTrusts,
          PrayerTrustsScreen(
            repository: widget.repository,
            duasRepository: widget.duasRepository,
          ),
        );
      });
    }
  }

  Future<void> _open(RawdahJourneyStage stage, Widget page) async {
    await widget.repository.enterRawdah();
    await widget.repository.setRawdahStage(stage);
    if (!mounted) return;
    await go(context, page);
    if (mounted) setState(() {});
  }

  String _appointmentSubtitle() {
    final a = widget.repository.rawdahAppointment;
    if (a == null) return 'سجّلي موعدك بعد الحصول على التصريح الرسمي';
    final left = a.timeRemaining();
    if (left.isNegative) return 'الموعد المحفوظ مضى — راجعيه';
    if (left.inDays > 0) return 'متبقي ${left.inDays} يوم';
    if (left.inHours > 0) return 'متبقي ${left.inHours} ساعة';
    return 'متبقي ${left.inMinutes} دقيقة';
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.repository.journey.rawdahStage;
    return MPage(
      title: 'موعد مع الروضة',
      emoji: '🌿',
      subtitle: 'استعدي قبل الزيارة، ثم دعي التطبيق يختفي عند حضور اللحظة.',
      children: [
        const MSourceBox(
          source: 'صحيح البخاري • حديث 1888',
          note: '«ما بين بيتي ومنبري روضة من رياض الجنة»',
        ),
        MCard(
          title: '1. الموعد',
          subtitle: _appointmentSubtitle(),
          emoji: '🗓️',
          selected: stage == RawdahJourneyStage.appointment,
          onTap: () => _open(
            RawdahJourneyStage.appointment,
            RawdahAppointmentScreen(repository: widget.repository),
          ),
        ),
        MCard(
          title: '2. وقفة صدق',
          subtitle: 'نية، توبة، وكلمة خاصة لا يراها أحد',
          emoji: '🤍',
          selected: stage == RawdahJourneyStage.sidqPause,
          onTap: () => _open(
            RawdahJourneyStage.sidqPause,
            SidqPauseScreen(repository: widget.repository),
          ),
        ),
        MCard(
          title: '3. حقيبة دعائي',
          subtitle: 'أدعيتي الموجودة أصلًا في رِفقة',
          emoji: '🤲',
          selected: stage == RawdahJourneyStage.prayerBag,
          onTap: () => _open(
            RawdahJourneyStage.prayerBag,
            PrayerBagScreen(
              repository: widget.repository,
              duasRepository: widget.duasRepository,
            ),
          ),
        ),
        MCard(
          title: '4. أمانات الدعاء',
          subtitle:
              '${widget.duasRepository.pendingAmanatCount} أمانة لم تُعلَّم كمُنجزة بعد',
          emoji: '💌',
          selected: stage == RawdahJourneyStage.prayerTrusts,
          onTap: () => _open(
            RawdahJourneyStage.prayerTrusts,
            PrayerTrustsScreen(
              repository: widget.repository,
              duasRepository: widget.duasRepository,
            ),
          ),
        ),
        MCard(
          title: '5. انتظار بسكينة',
          subtitle: 'شاشة هادئة بلا عدادات أو ضغط',
          emoji: '🌿',
          selected: stage == RawdahJourneyStage.peacefulWaiting,
          onTap: () => _open(
            RawdahJourneyStage.peacefulWaiting,
            PeacefulWaitScreen(repository: widget.repository),
          ),
        ),
        MCard(
          title: '6. آداب ورفق',
          subtitle: 'لا مزاحمة، لا إيذاء، واللحظة ليست سباقًا',
          emoji: '🕊️',
          selected: stage == RawdahJourneyStage.adab,
          onTap: () => _open(
            RawdahJourneyStage.adab,
            const RawdahAdabScreen(),
          ),
        ),
        MCard(
          title: '7. لحظة الروضة',
          subtitle: 'Quiet Mode — التطبيق يختفي تقريبًا',
          emoji: '🤍',
          selected: stage == RawdahJourneyStage.quietMode,
          onTap: () => _open(
            RawdahJourneyStage.quietMode,
            RawdahQuietModeScreen(
              repository: widget.repository,
              duasRepository: widget.duasRepository,
            ),
          ),
        ),
        MCard(
          title: '8. ثبّتي الأثر',
          subtitle: 'التزام شخصي وذكرى خاصة بعد الزيارة',
          emoji: '✨',
          selected: stage == RawdahJourneyStage.afterVisit ||
              stage == RawdahJourneyStage.completed,
          onTap: () => _open(
            RawdahJourneyStage.afterVisit,
            RawdahAfterScreen(repository: widget.repository),
          ),
        ),
      ],
    );
  }
}
