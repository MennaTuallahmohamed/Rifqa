import '../umrah/rifqa_premium_journey.dart';
import '../umrah/umrah_ultimate_page.dart';

import 'package:flutter/material.dart';
import '../community/community_screen.dart';

import '../../state/app_state.dart';
import '../../services/madinah/madinah_content_repository.dart';
import '../../services/madinah/madinah_repository.dart';

import '../duas/duas_screen.dart';
import '../hajj/hajj_screen.dart';
import '../haramain/haramain_ultimate_screen.dart';
import '../madinah/madinah_screen.dart';
import '../umrah/umrah_cinematic_v2.dart';
import '../ziyarat/ziyarat_screen.dart';
import '../services/service_screen.dart';
import '../markets/markets_screen.dart';
import '../refqa_community/refqa_community.dart';
import '../profile/rifqa_profile_screen.dart';
import '../assistant/lost_help_screen.dart';
import '../pilgrim_watch/pilgrim_watch_screen.dart';

// =====================================================
// RIFQA - PREMIUM HOME
// UI redesign only. AppShell remains unchanged.
// =====================================================

class _R {
  static const bg = Color(0xFFFAF8F3);
  static const green = Color(0xFF104B39);
  static const deep = Color(0xFF073C2D);
  static const gold = Color(0xFFC5A15F);
  static const softGold = Color(0xFFF6EEDB);
  static const text = Color(0xFF1E302A);
  static const muted = Color(0xFF78847D);
  static const border = Color(0xFFEEE9E0);
  static const softGreen = Color(0xFFEAF0E8);
}

class _HomeService {
  const _HomeService(
    this.title,
    this.subtitle,
    this.icon,
    this.code,
  );

  final String title;
  final String subtitle;
  final IconData icon;
  final int code;
}

const _mainServices = <_HomeService>[
  _HomeService(
    'الخريطة',
    'اكتشف الأماكن المهمة',
    Icons.map_rounded,
    2,
  ),
  _HomeService(
    'الرفاق',
    'مع مجموعتك في كل خطوة',
    Icons.groups_rounded,
    -5,
  ),
  _HomeService(
    'الأدعية',
    'دعاء يرافق رحلتك',
    Icons.menu_book_rounded,
    -4,
  ),
  _HomeService(
    'المدينة',
    'أجواء المسجد النبوي',
    Icons.mosque_rounded,
    -2,
  ),
  _HomeService(
    'المزارات',
    'تعرّف على الأماكن',
    Icons.place_rounded,
    -3,
  ),
  _HomeService(
    'دليل العمرة',
    'أدِّ المناسك بطمأنينة',
    Icons.auto_stories_rounded,
    1,
  ),
];

const _moreServices = <_HomeService>[
  _HomeService('مجتمع رِفقة', 'أسئلة ونصائح ضيوف الرحمن', Icons.forum_rounded, -11),
  _HomeService(
    'الحج',
    'دليل مناسك الحج',
    Icons.landscape_rounded,
    -1,
  ),
  _HomeService(
    'ساعة رِفقة',
    'رفيقك في كل خطوة',
    Icons.watch_rounded,
    -10,
  ),
  _HomeService(
    'الأسواق',
    'خدمات قريبة منك',
    Icons.storefront_rounded,
    -7,
  ),
  _HomeService(
    'مجتمع رفقة',
    'أسئلة ونصائح ومعلومات',
    Icons.forum_rounded,
    -11,
  ),
  _HomeService(
    'أرقام مهمة',
    'أرقام قد تحتاجها',
    Icons.call_rounded,
    -8,
  ),
  _HomeService(
    'حسابي',
    'ملفك الشخصي',
    Icons.person_rounded,
    -9,
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.open,
  });

  final ValueChanged<int> open;

  static final MadinahRepository _madinahRepository =
      MadinahRepository();

  static final MadinahContentRepository
      _madinahContentRepository =
      MadinahContentRepository();

  // -----------------------------------------------
  // Existing navigation
  // -----------------------------------------------

  void _go(BuildContext context, int code) {
    // Special Home actions must not be interpreted as Shell tab indexes.
    if (code == -5) {
      open(2); // Rifqati / Groups tab
      return;
    }
    if (code == -9) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const RifqaProfileScreen(),
        ),
      );
      return;
    }
    if (code == -10) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const RifqaPilgrimWatchScreen(),
        ),
      );
      return;
    }
    if (code == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RifqaPremiumJourney()),
      );
      return;
    }
    if (code == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const HaramainUltimateScreen(),
        ),
      );
      return;
    }

    if (code == -1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const HajjScreen(),
        ),
      );
      return;
    }

    if (code == -2) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MadinahScreen(
            repository: _madinahRepository,
            contentRepository: _madinahContentRepository,
          ),
        ),
      );
      return;
    }

    if (code == -3) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ZiyaratScreen(),
        ),
      );
      return;
    }

    if (code == -4) {
      final state = AppScope.of(context);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DuasScreen(
            repository: state.duas,
          ),
        ),
      );
      return;
    }

    if (code == -11) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const RefqaCommunityScreen(),
        ),
      );
      return;
    }
    if (code == -7) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const MarketsScreen(),
        ),
      );
      return;
    }

    if (code >= 0) {
      // This uses the existing AppShell contract.
      // We are not changing tab indexes here.
      open(code);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceScreen(code: code),
      ),
    );
  }

  void _openQuickHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _R.bg,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                18, 8, 18, 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'كيف نساعدك في رحلتك؟',
                    style: TextStyle(
                      color: _R.deep,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _quickAction(
                    sheetContext,
                    context,
                    'خريطة الحرم',
                    Icons.map_rounded,
                    2,
                  ),
                  _quickAction(
                    sheetContext,
                    context,
                    'دليل الأدعية',
                    Icons.menu_book_rounded,
                    -4,
                  ),
                  _quickAction(
                    sheetContext,
                    context,
                    'المدينة المنورة',
                    Icons.mosque_rounded,
                    -2,
                  ),
                  _quickAction(
                    sheetContext,
                    context,
                    'المزارات',
                    Icons.place_rounded,
                    -3,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _quickAction(
    BuildContext sheetContext,
    BuildContext pageContext,
    String title,
    IconData icon,
    int code,
  ) {
    return ListTile(
      leading: Icon(icon, color: _R.green),
      title: Text(title),
      trailing: const Icon(
        Icons.chevron_left_rounded,
        color: _R.gold,
      ),
      onTap: () {
        Navigator.of(sheetContext).pop();
        _go(pageContext, code);
      },
    );
  }

  String _journeyHint(int progress) {
    if (progress == 0) {
      return 'ابدأ بنية خالصة، والبداية من الإحرام';
    }
    if (progress < 50) {
      return 'ما شاء الله، واصل بخطى ثابتة';
    }
    if (progress < 100) {
      return 'اقتربت من إتمام عمرتك، تقبّل الله منك';
    }
    return 'أتممت عمرتك، تقبّل الله طاعتك';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final progress = state.progress.clamp(0, 100).toInt();
    final name = state.name.trim().isEmpty
        ? 'ضيف الرحمن'
        : state.name.trim();

    final width = MediaQuery.sizeOf(context).width;
    final padding = width < 355 ? 12.0 : 16.0;

    // Three cards on typical mobile widths.
    final columns = width >= 355 ? 3 : 2;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: _R.bg,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero is independent, no negative offsets.
            SliverToBoxAdapter(
              child: _HomeHero(name: name),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  padding, 14, padding, 10,
                ),
                child: _SearchCard(
                  onTap: () => _openQuickHelp(context),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  padding, 5, padding, 0,
                ),
                child: _JourneyCard(
                  progress: progress,
                  hint: _journeyHint(progress),
                  onTap: () => _go(context, 1),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  padding, 22, padding, 12,
                ),
                child: const _SectionHeading(
                  title: 'رفقة في كل خطوة',
                  subtitle:
                      'كل ما تحتاجه لرحلة إيمانية مطمئنة',
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
              ),
              sliver: SliverGrid.builder(
                itemCount: _mainServices.length,
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 164,
                ),
                itemBuilder: (context, index) {
                  final service = _mainServices[index];

                  return _ServiceCard(
                    service: service,
                    onTap: () => _go(
                      context,
                      service.code,
                    ),
                  );
                },
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  padding, 16, padding, 0,
                ),
                child: _SosCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LostHelpScreen(),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  padding, 16, padding, 0,
                ),
                child: const _SpiritualCard(),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  padding, 23, padding, 12,
                ),
                child: const _SectionHeading(
                  title: 'استكشف المزيد',
                  subtitle:
                      'خدمات وتفاصيل تسهّل رحلتك',
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
              ),
              sliver: SliverList.separated(
                itemCount: _moreServices.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final service = _moreServices[index];

                  return _MoreTile(
                    service: service,
                    onTap: () => _go(
                      context,
                      service.code,
                    ),
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// HERO
// =====================================================

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: top + 350,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Existing project image.
            Image.asset(
              'assets/images/rifqa_home_hero.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0, .25),
              errorBuilder: (context, error, stackTrace) {
                return const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFF5E9D5),
                        Color(0xFFD5E4D6),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.mosque_rounded,
                      size: 130,
                      color: _R.green,
                    ),
                  ),
                );
              },
            ),

            // Readable text without hiding the Kaaba.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  stops: [0, .48, 1],
                  colors: [
                    Color(0xF8FFF9EC),
                    Color(0xC9FFF6E6),
                    Color(0x00FFFFFF),
                  ],
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  19, 10, 19, 15,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: .94),
                            borderRadius:
                                BorderRadius.circular(24),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: _R.green,
                                size: 17,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'مكة المكرمة',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _R.text,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const CircleAvatar(
                          radius: 19,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: _R.gold,
                            size: 20,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'السلام عليكم يا $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _R.green,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'رفيق المعتمر',
                      style: TextStyle(
                        color: _R.deep,
                        fontSize: 35,
                        height: 1.17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 9),

                    const _GoldDivider(),

                    const SizedBox(height: 13),

                    const Text(
                      'معك في كل خطوة من رحلتك المباركة\n'
                      'لعمرة أسهل وقلب أكثر طمأنينة',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.65,
                        color: _R.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const Spacer(),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: .94),
                        borderRadius:
                            BorderRadius.circular(19),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: .05),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            color: _R.gold,
                            size: 20,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'اللهم يسّر لنا عمرةً متقبّلة',
                              style: TextStyle(
                                color: _R.green,
                                fontWeight:
                                    FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: _R.gold,
                            size: 17,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 34,
          child: Divider(
            color: _R.gold,
            thickness: 1.2,
          ),
        ),
        SizedBox(width: 5),
        Icon(
          Icons.diamond_outlined,
          color: _R.gold,
          size: 16,
        ),
        SizedBox(width: 5),
        SizedBox(
          width: 34,
          child: Divider(
            color: _R.gold,
            thickness: 1.2,
          ),
        ),
      ],
    );
  }
}

// =====================================================
// SEARCH
// =====================================================

class _SearchCard extends StatelessWidget {
  const _SearchCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _WhiteSurface(
      onTap: onTap,
      radius: 22,
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _R.green,
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'كيف يمكننا مساعدتك في رحلتك؟',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _R.muted,
                    fontSize: 12,
                  ),
                ),
              ),
              const Icon(
                Icons.search_rounded,
                color: _R.text,
                size: 23,
              ),
              const SizedBox(width: 11),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// JOURNEY PROGRESS
// =====================================================

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({
    required this.progress,
    required this.hint,
    required this.onTap,
  });

  final int progress;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _WhiteSurface(
      onTap: onTap,
      radius: 23,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 61,
              height: 61,
              decoration: const BoxDecoration(
                color: _R.softGreen,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  progress == 0
                      ? '🕋'
                      : '$progress%',
                  style: TextStyle(
                    color: _R.green,
                    fontSize: progress == 0 ? 25 : 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'رحلة عمرتك',
                    style: TextStyle(
                      color: _R.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _R.muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 11),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 6,
                      color: _R.gold,
                      backgroundColor:
                          _R.softGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_left_rounded,
              color: _R.green,
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// SECTION TITLE
// =====================================================

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _R.deep,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _R.muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// =====================================================
// MAIN SERVICE CARD
// =====================================================

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onTap,
  });

  final _HomeService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _WhiteSurface(
      onTap: onTap,
      radius: 21,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          7, 9, 7, 9,
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 59,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFF8F4EC),
                    Color(0xFFE9F0E8),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: Icon(
                service.icon,
                color: _R.green,
                size: 30,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              service.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _R.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              service.subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _R.muted,
                fontSize: 9.5,
                height: 1.3,
              ),
            ),
            const Spacer(),
            const CircleAvatar(
              radius: 11,
              backgroundColor: _R.softGold,
              child: Icon(
                Icons.chevron_left_rounded,
                color: _R.green,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// SOS
// =====================================================

class _SosCard extends StatelessWidget {
  const _SosCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _WhiteSurface(
      onTap: onTap,
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE7E2),
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.sos_rounded,
                color: Color(0xFFB74A3F),
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'أنا تائه — المساعدة السريعة',
                    style: TextStyle(
                      color: _R.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'اعرف طريقك واطلب المساعدة عند الحاجة',
                    style: TextStyle(
                      color: _R.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFFB74A3F),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// SPIRITUAL BANNER
// =====================================================

class _SpiritualCard extends StatelessWidget {
  const _SpiritualCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            _R.green,
            _R.deep,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              left: -17,
              bottom: -20,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: _R.gold.withValues(alpha: .16),
                size: 160,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(21),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '✦  من أجمل لحظات العمر',
                    style: TextStyle(
                      color: Color(0xFFE9D1A1),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 11),
                  Text(
                    'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 23,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'اللهم بلّغنا بيتك الحرام واجعلها عمرةً مقبولة',
                    style: TextStyle(
                      color: Color(0xFFE9EDE6),
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// EXTRA SERVICES
// =====================================================

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.service,
    required this.onTap,
  });

  final _HomeService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _WhiteSurface(
      onTap: onTap,
      radius: 19,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                color: _R.softGreen,
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: Icon(
                service.icon,
                color: _R.green,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: const TextStyle(
                      color: _R.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.subtitle,
                    style: const TextStyle(
                      color: _R.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left_rounded,
              color: _R.gold,
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// REUSABLE WHITE SURFACE
// =====================================================

class _WhiteSurface extends StatelessWidget {
  const _WhiteSurface({
    required this.child,
    required this.onTap,
    this.radius = 20,
  });

  final Widget child;
  final VoidCallback onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: _R.border,
        ),
        boxShadow: [
          BoxShadow(
            color: _R.deep.withValues(alpha: .055),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: child,
        ),
      ),
    );
  }
}

// The original project's Umrah screen path was not supplied.
// A dedicated self-contained guide prevents navigating to "Lost" by mistake.
// Once the original Umrah widget is identified, replace this route only.
class _UmrahGuideScreen extends StatelessWidget {
  const _UmrahGuideScreen();

  @override
  Widget build(BuildContext context) {
    const items = <(String, String, IconData)>[
      ('الإحرام والنية', 'استعد للنسك، وراجع الميقات ومحظورات الإحرام.', Icons.checkroom_rounded),
      ('الطواف', 'سبعة أشواط حول الكعبة، مع مراعاة التعليمات والتنظيم.', Icons.sync_rounded),
      ('السعي', 'سبعة أشواط بين الصفا والمروة.', Icons.directions_walk_rounded),
      ('الحلق أو التقصير', 'أكمل النسك بالحلق أو التقصير وفق أحكامه.', Icons.content_cut_rounded),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _R.bg,
        appBar: AppBar(
          title: const Text('دليل العمرة'),
          backgroundColor: _R.bg,
          foregroundColor: _R.deep,
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text('خطوات عمرتك', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _R.deep)),
            const SizedBox(height: 7),
            const Text('دليل مبسط للمراحل الأساسية، وليس بديلًا عن الإرشاد الشرعي الموثوق.', style: TextStyle(color: _R.muted, height: 1.6)),
            const SizedBox(height: 18),
            for (final item in items) ...[
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: _R.softGreen, child: Icon(item.$3, color: _R.green)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w900, color: _R.deep)),
                            const SizedBox(height: 4),
                            Text(item.$2, style: const TextStyle(color: _R.muted, height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
