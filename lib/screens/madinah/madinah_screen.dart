
import 'package:flutter/material.dart';

import '../../models/madinah/prophetic_story.dart';
import '../../services/madinah/madinah_content_repository.dart';
import '../../services/madinah/madinah_repository.dart';
import '../../screens/duas/amanat_screen.dart';
import '../../state/app_state.dart';
import 'immersive/cinematic_hub.dart';
import 'immersive/cinematic_tour.dart';
import 'immersive/seerah_museum.dart';
import 'madinah_ui.dart';
import 'immersive/seerah_museum_v3.dart';
import 'immersive/rawdah_booking_v3.dart';
import 'immersive/madinah_v3_home.dart';
import 'immersive/cinematic_salawat.dart';
import 'memories/madinah_memories_screen.dart';
import 'mosque/prophet_mosque_screen.dart';
import 'stories/prophetic_story_screen.dart';
import 'stories/prophetic_story_player.dart';

const _green = Color(0xFF104B39);
const _dark = Color(0xFF073C2D);
const _gold = Color(0xFFC5A15F);
const _cream = Color(0xFFFAF8F2);
const _ink = Color(0xFF20352C);
const _muted = Color(0xFF77837A);
const _heroImage = 'assets/images/madinah/exterior_sunset_wide.png';

class MadinahScreen extends StatefulWidget {
  const MadinahScreen({
    super.key,
    required this.repository,
    required this.contentRepository,
  });

  final MadinahRepository repository;
  final MadinahContentRepository contentRepository;

  @override
  State<MadinahScreen> createState() => _MadinahScreenState();
}

class _MadinahScreenState extends State<MadinahScreen> {
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      if (!widget.repository.initialized) {
        await widget.repository.init();
      }

      await widget.repository.markMadinahOpened();

      if (widget.repository.journey.phase.name == 'notStarted') {
        await widget.repository.startJourney();
      }

      error = null;
    } catch (e) {
      error = e.toString();
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _openPage(Widget page) async {
    await go(context, page);

    if (mounted) {
      setState(() {});
    }
  }

  void _openMosque() {
    _openPage(
      ProphetMosqueScreen(
        repository: widget.repository,
        contentRepository: widget.contentRepository,
      ),
    );
  }

  void _openRawdah() {
    _openPage(const CinematicTourScreen(kind: CinematicJourneyKind.rawdah));
  }

  void _openStories() {
    _openPage(const SeerahMuseumScreen());
  }

  void _openSalawat() {
    _openPage(const CinematicSalawatScreen());
  }

  void _openMemories() {
    _openPage(
      MadinahMemoriesScreen(repository: widget.repository),
    );
  }

  void _openVirtualTour() {
    _openPage(const MadinahImmersiveHub());
  }

  void _openAmanat() {
    final duas = AppScope.of(context).duas;
    _openPage(AmanatScreen(repository: duas));
  }

  void _quickHelp() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _cream,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'كيف نساعدك في المدينة؟',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _helpOption(
                    sheetContext,
                    'الروضة الشريفة',
                    Icons.spa_rounded,
                    _openRawdah,
                  ),
                  _helpOption(
                    sheetContext,
                    'المسجد النبوي',
                    Icons.mosque_rounded,
                    _openMosque,
                  ),
                  _helpOption(
                    sheetContext,
                    'حكايات المدينة',
                    Icons.auto_stories_rounded,
                    _openStories,
                  ),
                  _helpOption(
                    sheetContext,
                    'الصلاة والسلام ﷺ',
                    Icons.favorite_rounded,
                    _openSalawat,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _helpOption(
    BuildContext sheetContext,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: _green),
      title: Text(title),
      trailing: const Icon(Icons.chevron_left, color: _gold),
      onTap: () {
        Navigator.of(sheetContext).pop();
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // RIFQA_MADINAH_V3_ENTRY: original repository state and error UI remain intact.
    if (!loading && error == null) {
      return MadinahV3Home(
        onMosqueTour: () { _openPage(const MadinahV3GateEntry()); },
        onRawdahTour: () { _openPage(const CinematicTourScreen(kind: CinematicJourneyKind.rawdah)); },
        onBooking: () { _openPage(const RawdahBookingV3()); },
        onGuide: _openMosque,
        onStories: () { _openPage(const SeerahMuseumV3()); },
        onSalawat: () { _openPage(const CinematicSalawatScreen()); },
        onMemories: () { _openPage(MadinahMemoriesV3(onOpen: _openMemories)); },
      );
    }
    if (loading) {
      return const Scaffold(
        backgroundColor: _cream,
        body: Center(
          child: CircularProgressIndicator(color: _green),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          title: const Text('المدينة المنورة'),
          backgroundColor: _cream,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تعذّر تحميل بيانات المدينة'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  setState(() => loading = true);
                  _initialize();
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final journey = widget.repository.journey;
    final stories = widget.contentRepository.madinahStories;
    final featured = widget.contentRepository.featuredStories;

    final readCount = stories
        .where((story) => journey.readStoryIds.contains(story.id))
        .length;

    final PropheticStory? featuredStory = stories.isEmpty
        ? null
        : stories.firstWhere(
            (story) => featured.any((f) => f.id == story.id),
            orElse: () => stories.first,
          );

    final otherStories = stories
        .where((story) => story.id != featuredStory?.id)
        .toList();

    final duas = AppScope.of(context).duas;

    return Scaffold(
      backgroundColor: _cream,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero: separate from search, so no overlap.
            SliverToBoxAdapter(
              child: _MadinahHero(
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: _SearchBar(onTap: _quickHelp),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _VirtualTourBanner(onTap: _openVirtualTour),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = MediaQuery.sizeOf(context).width;
                  final columns = width >= 650 ? 3 : 2;

                  final items = [
                    _Shortcut(
                      'الروضة',
                      'دليل الزيارة وآدابها',
                      Icons.spa_rounded,
                      _openRawdah,
                    ),
                    _Shortcut(
                      'المسجد النبوي',
                      'المرافق والمداخل',
                      Icons.mosque_rounded,
                      _openMosque,
                    ),
                    _Shortcut(
                      'مواعيد الزيارة',
                      'إرشادات زيارة الروضة',
                      Icons.event_available_rounded,
                      _openRawdah,
                    ),
                    _Shortcut(
                      'حكايات المدينة',
                      'قصص وسيرة موثقة',
                      Icons.auto_stories_rounded,
                      _openStories,
                    ),
                    _Shortcut(
                      'الصلاة والسلام',
                      'صيغ مأثورة وموثقة',
                      Icons.favorite_border_rounded,
                      _openSalawat,
                    ),
                    _Shortcut(
                      'ذكريات المدينة',
                      'احتفظ بلحظاتك',
                      Icons.photo_album_outlined,
                      _openMemories,
                    ),
                  ];

                  return SliverGrid.builder(
                    itemCount: items.length,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 178,
                    ),
                    itemBuilder: (context, index) {
                      return _ShortcutCard(item: items[index]);
                    },
                  );
                },
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: _GuideBanner(onTap: _openStories),
              ),
            ),

            SliverToBoxAdapter(
              child: _Heading(
                title: 'محتوى مقترح لك',
                subtitle: '$readCount من ${stories.length} حكايات مقروءة',
                action: 'عرض الكل',
                onAction: _openStories,
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 145,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _MiniCard(
                      title: 'المسجد النبوي',
                      subtitle: 'دليل الزيارة',
                      icon: Icons.mosque_rounded,
                      onTap: _openMosque,
                    ),
                    const SizedBox(width: 10),
                    _MiniCard(
                      title: 'آداب الروضة',
                      subtitle: 'استعد للزيارة',
                      icon: Icons.spa_rounded,
                      onTap: _openRawdah,
                    ),
                    const SizedBox(width: 10),
                    _MiniCard(
                      title: 'حكايات المدينة',
                      subtitle: 'اقرأ وتدبّر',
                      icon: Icons.menu_book_rounded,
                      onTap: _openStories,
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: _Heading(
                title: 'حكايات من هنا ﷺ',
                subtitle: 'محتوى موثق يرافق زيارتك',
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (featuredStory != null) ...[
                    _StoryTile(
                      title: 'حكاية تفاعلية: ${featuredStory.title}',
                      subtitle: 'مشاهد متتابعة مع عرض النص والمصدر',
                      icon: Icons.play_circle_outline_rounded,
                      onTap: () => _openPage(
                        PropheticStoryPlayer(
                          story: featuredStory,
                          backgroundAssets: const [
                            'assets/images/madinah/exterior_sunset_wide.png',
                            'assets/images/madinah/courtyard_day_umbrella.png',
                            'assets/images/madinah/minarets_sunset.png',
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (featuredStory != null)
                    _StoryTile(
                      title: featuredStory.title,
                      subtitle: featuredStory.subtitle,
                      icon: Icons.auto_stories_rounded,
                      onTap: () => _openPage(
                        PropheticStoryScreen(
                          repository: widget.repository,
                          story: featuredStory,
                        ),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'تُعرض الحكايات بعد اعتماد نصوصها ومصادرها.',
                      ),
                    ),
                  for (final story in otherStories)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _StoryTile(
                        title: story.title,
                        subtitle: story.subtitle,
                        icon: Icons.menu_book_rounded,
                        onTap: () => _openPage(
                          PropheticStoryScreen(
                            repository: widget.repository,
                            story: story,
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(
              child: _Heading(
                title: 'أثر يبقى معك',
                subtitle: 'مساحتك الخاصة بعد الزيارة',
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _StoryTile(
                    title: 'الصلاة والسلام ﷺ',
                    subtitle:
                        '${widget.repository.favoriteSalawatCount} في المفضلة',
                    icon: Icons.favorite_rounded,
                    onTap: _openSalawat,
                  ),
                  const SizedBox(height: 10),
                  _StoryTile(
                    title: 'أمانات الدعاء',
                    subtitle:
                        '${duas.pendingAmanatCount} أمانة تنتظر دعاءك',
                    icon: Icons.mail_outline_rounded,
                    onTap: _openAmanat,
                  ),
                  const SizedBox(height: 10),
                  _StoryTile(
                    title: 'ذكريات المدينة',
                    subtitle:
                        '${widget.repository.memoriesCount + widget.repository.reflectionsCount} لحظة محفوظة',
                    icon: Icons.photo_album_rounded,
                    onTap: _openMemories,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────
// Hero
// ───────────────────────────────────────────────────────

class _MadinahHero extends StatelessWidget {
  const _MadinahHero({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: top + 315,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _heroImage,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(color: Color(0xFFE9E3D5));
            },
          ),

          // Softer gradient, but still readable.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Color(0xF5FFF9EE),
                  Color(0xBBFFF9EE),
                  Color(0x00FFFFFF),
                ],
                stops: [0, .54, 1],
              ),
            ),
          ),

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [
                  Color(0x77FAF8F2),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .94),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mosque_rounded,
                              color: _green,
                              size: 17,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'المدينة المنورة',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton.filledTonal(
                        onPressed: onBack,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: _green,
                          size: 17,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'أهلًا بك في',
                    style: TextStyle(
                      fontSize: 18,
                      color: _green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Text(
                    'المدينة',
                    style: TextStyle(
                      color: _dark,
                      fontSize: 43,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    '✦ ─────────',
                    style: TextStyle(color: _gold, fontSize: 14),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'رحلتك الهادئة في المدينة المنورة',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: _ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'في رحاب مسجد رسول الله ﷺ\nحيث السكينة والطمأنينة',
                    style: TextStyle(
                      fontSize: 12,
                      color: _ink,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────
// Search / Quick Help
// ───────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      elevation: 2,
      shadowColor: _dark.withValues(alpha: .12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: SizedBox(
          height: 62,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Row(
              children: [
                Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'كيف يمكننا مساعدتك في المدينة؟',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: _muted,
                    ),
                  ),
                ),
                const Icon(Icons.search_rounded, color: _ink),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────
// Shortcut Cards
// ───────────────────────────────────────────────────────

class _Shortcut {
  const _Shortcut(
    this.title,
    this.subtitle,
    this.icon,
    this.onTap,
  );

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.item});

  final _Shortcut item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(9, 10, 9, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFECE7DB)),
            boxShadow: [
              BoxShadow(
                color: _dark.withValues(alpha: .035),
                blurRadius: 11,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF8F4E9),
                      Color(0xFFEAF0E7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  item.icon,
                  color: _green,
                  size: 30,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  height: 1.35,
                ),
              ),
              const Spacer(),
              const CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFFF6EBD2),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: _green,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────
// Virtual Tour Banner
// ───────────────────────────────────────────────────────

class _VirtualTourBanner extends StatefulWidget {
  const _VirtualTourBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_VirtualTourBanner> createState() => _VirtualTourBannerState();
}

class _VirtualTourBannerState extends State<_VirtualTourBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _dark,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_dark, Color(0xFF042019)],
            ),
            border: Border.all(color: _gold.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final double glow = _pulse.value * 8 + 6;
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.4),
                          blurRadius: glow,
                          spreadRadius: glow * 0.12,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _gold),
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  child: const Icon(
                    Icons.view_in_ar_rounded,
                    color: _gold,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✦ جديد',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'جولة افتراضية داخل المسجد النبوي',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'بوابة ثلاثية الأبعاد، ثم صور حقيقية تستشعرين فيها المكان',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_left_rounded, color: _gold),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────
// Guide Banner
// ───────────────────────────────────────────────────────

class _GuideBanner extends StatelessWidget {
  const _GuideBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _green,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [_green, _dark],
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✦ دليل المدينة',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'استكشف معالم المدينة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'حكايات موثقة ومعلومات تثري زيارتك',
                      style: TextStyle(
                        color: Color(0xFFE8EBDD),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 65,
                width: 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: _gold,
                  size: 33,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────
// Sections / Articles
// ───────────────────────────────────────────────────────

class _Heading extends StatelessWidget {
  const _Heading({
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 23, 18, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                action!,
                style: const TextStyle(color: _green),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 143,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFECE7DB)),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDF1E7),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                    child: Icon(icon, color: _green, size: 37),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(9),
                  child: Column(
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFECE7DB),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 49,
                width: 49,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F0E7),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: _green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: _gold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
