import 'package:flutter/material.dart';
import 'cinematic_theme.dart';
import 'cinematic_tour.dart';
import '../madinah_gate_experience.dart';
import 'mosque_entrance_audio.dart';

/// New Rifqa Madinah landing page. Kept independent from repositories so
/// the existing MadinahScreen remains in charge of state, initialization,
/// Firebase, and navigation. Every action is supplied by that screen.
class MadinahV3Home extends StatefulWidget {
  const MadinahV3Home({
    super.key,
    required this.onMosqueTour,
    required this.onRawdahTour,
    required this.onBooking,
    required this.onGuide,
    required this.onStories,
    required this.onSalawat,
    required this.onMemories,
  });

  final VoidCallback onMosqueTour, onRawdahTour, onBooking, onGuide;
  final VoidCallback onStories, onSalawat, onMemories;

  @override
  State<MadinahV3Home> createState() => _MadinahV3HomeState();
}

class _MadinahV3HomeState extends State<MadinahV3Home>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..forward();

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 360;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF8F1),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: width < 400 ? 345 : 385,
                child: Stack(fit: StackFit.expand, children: [
                  const CinematicImage(
                    '$cinematicAssets/scenes/exterior_sunset_wide.jpg',
                    alignment: Alignment.centerLeft,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [0, .52, 1],
                        colors: [Color(0x10000000), Color(0x9BFDF9F0), Color(0xFFFDF9F0)],
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.transparent, Color(0xFFFCF8F1)],
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 22, 28),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FadeTransition(
                          opacity: _intro,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('رِفقة', style: TextStyle(
                                fontSize: 36, fontWeight: FontWeight.w900,
                                color: cinematicGreen, height: 1.1,
                              )),
                              const Text('R I F Q A', style: TextStyle(
                                fontSize: 10, letterSpacing: 3,
                                color: Color(0xFF986D2B), fontWeight: FontWeight.bold,
                              )),
                              const SizedBox(height: 24),
                              Text('مرحباً بك', style: TextStyle(
                                fontSize: narrow ? 30 : 37,
                                fontWeight: FontWeight.w900, color: cinematicGreen,
                              )),
                              const Text('في رحلتك الإيمانية  ♥',
                                style: TextStyle(color: cinematicGreen,
                                  fontSize: 17, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 5),
                              const Text('في المدينة المنورة', style: TextStyle(
                                color: Color(0xFF6E786D), fontSize: 14,
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 27),
              sliver: SliverList(delegate: SliverChildListDelegate([
                _SearchAction(onTap: widget.onGuide),
                const SizedBox(height: 15),
                _FeaturedBooking(onTap: widget.onBooking),
                const SizedBox(height: 15),
                Row(children: [
                  Expanded(child: _QuickLink(icon: Icons.mosque_rounded,
                    title: 'المدينة المنورة', subtitle: 'دليل الزيارة',
                    onTap: widget.onMosqueTour)),
                  const SizedBox(width: 8),
                  Expanded(child: _QuickLink(icon: Icons.event_available_rounded,
                    title: 'حجز الروضة', subtitle: 'خطة واضحة',
                    onTap: widget.onBooking)),
                  const SizedBox(width: 8),
                  Expanded(child: _QuickLink(icon: Icons.volunteer_activism_rounded,
                    title: 'أدعية وصلوات', subtitle: 'صوت وسكينة',
                    onTap: widget.onSalawat)),
                  const SizedBox(width: 8),
                  Expanded(child: _QuickLink(icon: Icons.auto_stories_rounded,
                    title: 'حكايات من هنا', subtitle: '50 قصة',
                    onTap: widget.onStories)),
                ]),
                const SizedBox(height: 25),
                _SectionTitle(title: 'عيشِي رحاب المدينة', onMore: widget.onMosqueTour),
                const SizedBox(height: 12),
                _WideVisualCard(
                  image: 'gate_sultan_abdulmajeed.jpg',
                  title: 'دخول المسجد النبوي', subtitle: 'جولة سينمائية بين الأبواب والساحات',
                  onTap: widget.onMosqueTour,
                ),
                const SizedBox(height: 10),
                _WideVisualCard(
                  image: 'rawdah_grille.jpg',
                  title: 'داخل الروضة الشريفة', subtitle: 'مشاهد مصوّرة وتجربة سكينة',
                  onTap: widget.onRawdahTour,
                ),
                const SizedBox(height: 24),
                _SectionTitle(title: 'أكملي رحلتك', onMore: widget.onMemories),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _SmallVisualCard(
                    image: 'minarets_sunset.jpg',
                    label: 'ذكريات المدينة', detail: 'لحظات لا تُنسى',
                    onTap: widget.onMemories)),
                  const SizedBox(width: 10),
                  Expanded(child: _SmallVisualCard(
                    image: 'exterior_sunset_wide.jpg',
                    label: 'الصلاة والسلام', detail: 'السلام عليك يا رسول الله',
                    onTap: widget.onSalawat)),
                ]),
                const SizedBox(height: 20),
                Text('الجولات البصرية للتأمل والاستعداد، ولا تُغني عن الزيارة الحقيقية. الحجز الفعلي عبر منصة نسك الرسمية.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600,
                    fontSize: 11, height: 1.5)),
              ])),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchAction extends StatelessWidget {
  const _SearchAction({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 5,
    shadowColor: const Color(0x180D4833),
    borderRadius: BorderRadius.circular(25),
    child: InkWell(
      borderRadius: BorderRadius.circular(25), onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        child: Row(children: [
          const Expanded(child: Text('كيف أستعد لزيارة المدينة؟',
            style: TextStyle(color: Color(0xFF7C827C), fontSize: 14))),
          const Icon(Icons.search, color: cinematicGreen, size: 26),
        ])),
    ),
  );
}

class _FeaturedBooking extends StatelessWidget {
  const _FeaturedBooking({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 190,
    child: Material(borderRadius: BorderRadius.circular(27), color: cinematicGreen,
      clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap,
        child: Stack(fit: StackFit.expand, children: [
          const CinematicImage('$cinematicAssets/scenes/rawdah_grille.jpg',
            alignment: Alignment.centerLeft),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.centerRight, end: Alignment.centerLeft,
            stops: [0, .6, 1],
            colors: [Color(0xFF003A2A), Color(0xE500382B), Color(0x22002E22)],
          ))),
          Padding(padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.auto_awesome, color: cinematicGold, size: 22),
              const SizedBox(height: 10),
              const Text('حجز الروضة الشريفة', style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              const Text('خطوة بخطوة .. حتى تجهزي لزيارتك',
                style: TextStyle(color: Color(0xFFE5E9E2), fontSize: 12)),
              const Spacer(),
              Align(alignment: Alignment.centerRight,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: cinematicGold,
                    borderRadius: BorderRadius.circular(20)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('ابدئي دليل الحجز', style: TextStyle(color: cinematicGreen,
                        fontWeight: FontWeight.w800)),
                      SizedBox(width: 10), Icon(Icons.chevron_left, color: cinematicGreen),
                    ]),
                  ),
                )),
            ])),
        ])),
      ),
  );
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white, borderRadius: BorderRadius.circular(19),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(19),
      child: Container(
        constraints: const BoxConstraints(minHeight: 111),
        padding: const EdgeInsets.fromLTRB(3, 13, 3, 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0xFFEEE8DB))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 26, color: const Color(0xFFBD934A)),
          const SizedBox(height: 10),
          FittedBox(fit: BoxFit.scaleDown, child: Text(title,
            style: const TextStyle(color: cinematicGreen,
              fontSize: 12, fontWeight: FontWeight.w800))),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(subtitle,
            style: const TextStyle(color: Color(0xFF828981), fontSize: 10))),
        ]),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.onMore});
  final String title;
  final VoidCallback onMore;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: const TextStyle(color: cinematicGreen,
      fontSize: 21, fontWeight: FontWeight.w900))),
    TextButton(onPressed: onMore, child: const Text('عرض الكل',
      style: TextStyle(color: cinematicGreen))),
  ]);
}

class _WideVisualCard extends StatelessWidget {
  const _WideVisualCard({required this.image, required this.title,
    required this.subtitle, required this.onTap});
  final String image, title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 128,
    child: Material(color: cinematicGreen,
      clipBehavior: Clip.antiAlias, borderRadius: BorderRadius.circular(24),
      child: InkWell(onTap: onTap,
        child: Stack(fit: StackFit.expand, children: [
          CinematicImage('$cinematicAssets/scenes/$image', alignment: Alignment.centerLeft),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.centerRight, end: Alignment.centerLeft,
            colors: [Color(0xFF063B2C), Color(0xD9063929), Color(0x30033225)],
          ))),
          Padding(padding: const EdgeInsets.all(17), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(title, style: const TextStyle(color: Colors.white,
                fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              Text(subtitle, style: const TextStyle(color: Color(0xFFE4E1D5),
                fontSize: 12)),
              const SizedBox(height: 6),
              const Icon(Icons.arrow_back_ios_new, color: cinematicGold, size: 16),
            ])),
        ])),
      ),
  );
}

class _SmallVisualCard extends StatelessWidget {
  const _SmallVisualCard({required this.image, required this.label,
    required this.detail, required this.onTap});
  final String image, label, detail;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.5,
    child: Material(borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias, color: cinematicGreen,
      child: InkWell(onTap: onTap,
        child: Stack(fit: StackFit.expand, children: [
          CinematicImage('$cinematicAssets/scenes/$image'),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0xF000291F)]))),
          Padding(padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 17)),
                Text(detail, maxLines: 2,
                  style: const TextStyle(color: Color(0xFFE3D7BE), fontSize: 11)),
              ])),
        ])),
      ),
  );
}

/// Direct mosque journey: animated gate -> immersive photo tour.
class MadinahV3GateEntry extends StatefulWidget {
  const MadinahV3GateEntry({super.key});

  @override
  State<MadinahV3GateEntry> createState() => _MadinahV3GateEntryState();
}

class _MadinahV3GateEntryState extends State<MadinahV3GateEntry> {
  bool _handedOff = false;

  @override
  void initState() {
    super.initState();
    // Opening this page starts the provided salam recording automatically.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) MosqueEntranceAudio.instance.start(restart: true);
    });
  }

  @override
  void dispose() {
    // Do not interrupt the narration when the gate transitions to the tour.
    if (!_handedOff) MosqueEntranceAudio.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MadinahGateExperience(
    backgroundAsset: '$cinematicAssets/scenes/courtyard_day_umbrella.jpg',
    gateAsset: '$cinematicAssets/scenes/gate_sultan_abdulmajeed.jpg',
    onEnter: () {
      if (!mounted) return;
      _handedOff = true;
      Navigator.of(context).pushReplacement(cinematicRoute(
        const CinematicTourScreen(kind: CinematicJourneyKind.mosque),
      ));
    },
  );
}

/// Visual entrance to the existing on-device memory tools.
/// Actual saved memories remain in the original repository-backed screen.
class MadinahMemoriesV3 extends StatelessWidget {
  const MadinahMemoriesV3({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(backgroundColor: const Color(0xFFFCF8F1),
      appBar: AppBar(title: const Text('ذكريات المدينة'),
        backgroundColor: const Color(0xFFFCF8F1),
        foregroundColor: cinematicGreen),
      body: ListView(padding: const EdgeInsets.fromLTRB(15, 12, 15, 32), children: [
        ClipRRect(borderRadius: BorderRadius.circular(25), child: SizedBox(
          height: 220, child: Stack(fit: StackFit.expand, children: [
            const CinematicImage('$cinematicAssets/scenes/exterior_sunset_wide.jpg'),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.centerLeft, end: Alignment.centerRight,
              colors: [Color(0x12023326), Color(0xCDEAE5D5)]))),
            const Align(alignment: Alignment.centerRight, child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ذكريات المدينة', style: TextStyle(color: cinematicGreen,
                    fontWeight: FontWeight.w900, fontSize: 29)),
                  SizedBox(height: 10),
                  Text('لحظاتك التي تبقى .. وتضيء قلبك دائمًا',
                    style: TextStyle(color: cinematicGreen, fontSize: 14)),
                ]),
              ),
            ),
          ]))),
        const SizedBox(height: 18),
        _MemoryTile(icon: Icons.mail_outline_rounded,
          title: 'رسالتي لنفسي', detail: 'اكتبي رسالة تقرئينها بعد العودة',
          onTap: onOpen),
        const SizedBox(height: 12),
        _MemoryTile(icon: Icons.nights_stay_rounded,
          title: 'ليلتي الأخيرة', detail: 'وداع هادئ ووقفة من القلب',
          onTap: onOpen),
        const SizedBox(height: 12),
        _MemoryTile(icon: Icons.collections_bookmark_outlined,
          title: 'المحفوظ', detail: 'راجعي كلماتك وذكرياتك المسجّلة',
          onTap: onOpen),
        const SizedBox(height: 16),
        const Text('كل الخيارات تفتح أدوات ذكريات المدينة المحفوظة على جهازك.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF7F867D), fontSize: 11)),
      ]),
    ),
  );
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.icon, required this.title,
    required this.detail, required this.onTap});
  final IconData icon;
  final String title, detail;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    borderRadius: BorderRadius.circular(23), color: Colors.white,
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(23),
      child: Padding(padding: const EdgeInsets.all(17), child: Row(children: [
        CircleAvatar(radius: 26, backgroundColor: const Color(0xFFF6EAD2),
          child: Icon(icon, color: cinematicGreen)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: cinematicGreen,
            fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(detail, style: const TextStyle(color: Color(0xFF7D857F), fontSize: 12)),
        ])),
        const Icon(Icons.chevron_left, color: cinematicGold),
      ])),
    ),
  );
}
