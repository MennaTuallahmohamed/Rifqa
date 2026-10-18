import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../state/app_state.dart';
import 'umrah_data.dart';
import 'umrah_tools.dart';
import 'umrah_3d.dart';
import 'umrah_premium.dart';
import 'rifqa_narration_player.dart';

/// دليل العمرة — design guided by the five-screen cinematic reference.
/// All ritual content, progress storage and both 3D engines are reused.
class UmrahScreen extends StatelessWidget {
  const UmrahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final selected = st.step.clamp(0, 6).toInt();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: UGold.cream,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _JourneyHero(done: st.done.length)),
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(21, 24, 21, 13),
              child: _TitleRow('خطوات عمرتك',
                  trailing: '${st.done.length} من 7 مكتملة'),
            )),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              sliver: SliverList.builder(
                itemCount: umrahGuide.length,
                itemBuilder: (c, i) => _JourneyRow(
                  index: i,
                  current: i == selected,
                  completed: st.done.contains(i),
                  onTap: () {
                    st.change(() => st.step = i);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => UmrahStepPage(index: i)));
                  },
                ),
              ),
            ),
            if (st.done.length >= 7)
              SliverToBoxAdapter(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(17, 12, 17, 0),
                child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: const Color(0xFF0A6049),
                        borderRadius: BorderRadius.circular(22)),
                    child: Column(children: [
                      const Icon(Icons.celebration_rounded,
                          color: UGold.gold, size: 30),
                      const SizedBox(height: 5),
                      const Text('تقبّل الله عمرتك',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                      TextButton(
                          onPressed: () => st.change(() {
                                st.done.clear();
                                st.step = 0;
                                st.tawaf = 0;
                                st.sai = 0;
                              }),
                          child: const Text('بدء عمرة جديدة',
                              style: TextStyle(color: UGold.gold))),
                    ])),
              )),
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 13, 17, 0),
              child: _CtaButton(
                label:
                    'ابدئي الخطوة ${selected + 1}  ·  ${umrahGuide[selected].tabLabel}',
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => UmrahStepPage(index: selected))),
              ),
            )),
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(21, 25, 21, 13),
              child: _TitleRow(
                'أدوات رحلتك',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UmrahToolsGallery())),
              ),
            )),
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Row(children: [
                Expanded(
                    child: _MiniTool(
                        image: 'assets/umrah/tool_tawaf.jpg',
                        title: 'طواف 3D',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UmrahImmersiveTourPage(
                                    tawaf: true))))),
                const SizedBox(width: 10),
                Expanded(
                    child: _MiniTool(
                        image: 'assets/umrah/tool_sai.jpg',
                        title: 'سعي 3D',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UmrahImmersiveTourPage(
                                    tawaf: false))))),
              ]),
            )),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }
}

class _JourneyHero extends StatelessWidget {
  const _JourneyHero({required this.done});
  final int done;
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(33)),
      child: SizedBox(
          height: 415 + top,
          child: Stack(fit: StackFit.expand, children: [
            const UPhoto(
                asset: 'assets/umrah/umrah_hero.jpg',
                alignment: Alignment.center),
            const DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .48, .75, 1],
              colors: [
                Color(0x990D2D25),
                Color(0x000A382C),
                Color(0x300C4234),
                Color(0xD204372D)
              ],
            ))),
            Positioned(
                top: top + 18,
                right: 22,
                left: 20,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('دليل العمرة',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    shadows: [
                                      Shadow(
                                          color: Colors.black38, blurRadius: 10)
                                    ])),
                            SizedBox(height: 4),
                            Text('الخطوات السبع للعمرة بسهولة ويُسر',
                                style: TextStyle(
                                    color: Color(0xFFFFE9B6),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600)),
                          ])),
                      Material(
                          color: const Color(0xBBFCF8F0),
                          shape: const CircleBorder(),
                          child: IconButton(
                              tooltip: 'أدوات العمرة',
                              icon: const Icon(Icons.menu_book_outlined,
                                  color: UGold.deep),
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const UmrahToolsGallery())))),
                    ])),
            Positioned(
                top: top + 105,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 154,
                    height: 154,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xEDFFF9ED),
                        border: Border.all(color: Colors.white70, width: 5),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF152B24).withOpacity(.25),
                              blurRadius: 24,
                              offset: const Offset(0, 10))
                        ]),
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox(
                          width: 132,
                          height: 132,
                          child: CircularProgressIndicator(
                              value: done / 7,
                              strokeWidth: 5,
                              strokeCap: StrokeCap.round,
                              backgroundColor: const Color(0xFFE7D9C0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  UGold.gold))),
                      Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.mosque_rounded,
                                color: UGold.deep, size: 25),
                            const SizedBox(height: 5),
                            Text('$done/7',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                    fontSize: 30,
                                    height: 1.1,
                                    color: UGold.deep,
                                    fontWeight: FontWeight.w900)),
                            const Text('أكملت من الخطوات',
                                style: TextStyle(
                                    color: UGold.ink, fontSize: 10.5)),
                          ]),
                    ]),
                  ),
                )),
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipPath(
                  clipper: _BlessingWave(),
                  child: Container(
                    height: 154,
                    padding: const EdgeInsets.fromLTRB(22, 44, 22, 18),
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [Color(0xFF12684F), Color(0xFF05382D)])),
                    child: const Column(children: [
                      Text('عمرة مباركة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 19,
                              color: Color(0xFFEBCB84),
                              fontWeight: FontWeight.w900)),
                      SizedBox(height: 5),
                      Text('لبيك اللهم عمرة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 3),
                      Text(
                          'رحلة إلى الله تبدأ بالنية، ويرافقك فيها رِفقة خطوة بخطوة',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                              fontSize: 11,
                              height: 1.5,
                              color: Color(0xFFE2F0E8))),
                    ]),
                  ),
                )),
          ])),
    );
  }
}

class _BlessingWave extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 24)
    ..quadraticBezierTo(size.width * .25, -11, size.width * .5, 21)
    ..quadraticBezierTo(size.width * .8, 51, size.width, 18)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TitleRow extends StatelessWidget {
  const _TitleRow(this.title, {this.trailing, this.onTap});
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(title,
            style: const TextStyle(
                color: UGold.deep, fontSize: 19, fontWeight: FontWeight.w900)),
        const Spacer(),
        if (trailing != null)
          Text(trailing!,
              style: const TextStyle(color: UGold.ink, fontSize: 11)),
        if (onTap != null)
          TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 13),
              label: const Text('عرض الكل'),
              style: TextButton.styleFrom(foregroundColor: UGold.deep)),
      ]);
}

const _stepIcons = <IconData>[
  Icons.menu_book_rounded,
  Icons.checkroom_rounded,
  Icons.mosque_rounded,
  Icons.view_in_ar_rounded,
  Icons.water_drop_rounded,
  Icons.directions_walk_rounded,
  Icons.content_cut_rounded,
];

class _JourneyRow extends StatelessWidget {
  const _JourneyRow(
      {required this.index,
      required this.current,
      required this.completed,
      required this.onTap});
  final int index;
  final bool current, completed;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final item = umrahGuide[index];
    return Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Material(
          color: current ? const Color(0xFFEDF4E9) : Colors.white,
          borderRadius: BorderRadius.circular(21),
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(21),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(
                        color: current
                            ? const Color(0xFFD1BB87)
                            : const Color(0xFFECE1CF)),
                    boxShadow: [
                      BoxShadow(
                          color: UGold.deep.withOpacity(.04),
                          blurRadius: 9,
                          offset: const Offset(0, 3))
                    ]),
                child: Row(children: [
                  Container(
                      width: 35,
                      height: 35,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              current ? UGold.green : const Color(0xFFF4ECDC),
                          border: Border.all(
                              color: current
                                  ? UGold.gold
                                  : const Color(0xFFE0D3B7))),
                      child: completed
                          ? Icon(Icons.check_rounded,
                              color: current ? Colors.white : UGold.green,
                              size: 20)
                          : Text('${index + 1}',
                              style: TextStyle(
                                  color: current ? Colors.white : UGold.ink,
                                  fontWeight: FontWeight.w800))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: UGold.deep,
                              fontSize: 14,
                              fontWeight: FontWeight.w800))),
                  Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                          color: Color(0xFFF6EAD4), shape: BoxShape.circle),
                      child:
                          Icon(_stepIcons[index], color: UGold.deep, size: 21)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_left_rounded,
                      size: 21, color: UGold.ink),
                ]),
              )),
        ));
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 53,
        child: FilledButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 19),
            label: Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            style: FilledButton.styleFrom(
                backgroundColor: UGold.deep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                side: const BorderSide(color: UGold.gold, width: 1.4))),
      );
}

class _MiniTool extends StatelessWidget {
  const _MiniTool(
      {required this.image, required this.title, required this.onTap});
  final String image, title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEADEC9))),
            child: Column(children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                      aspectRatio: 1.75, child: UPhoto(asset: image))),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Text(title,
                      style: const TextStyle(
                          color: UGold.deep, fontWeight: FontWeight.w900))),
            ]),
          )));
}

class UmrahToolsGallery extends StatelessWidget {
  const UmrahToolsGallery({super.key});
  @override
  Widget build(BuildContext context) {
    const tools = <({
      String title,
      String subtitle,
      String image,
      IconData icon,
      Widget page
    })>[
      (
        title: 'طواف 3D',
        subtitle: 'جولة تفاعلية حول الكعبة',
        image: 'assets/umrah/tool_tawaf.jpg',
        icon: Icons.view_in_ar_rounded,
        page: UmrahImmersiveTourPage(tawaf: true)
      ),
      (
        title: 'سعي 3D',
        subtitle: 'مسار الصفا والمروة',
        image: 'assets/umrah/tool_sai.jpg',
        icon: Icons.directions_walk_rounded,
        page: UmrahImmersiveTourPage(tawaf: false)
      ),
      (
        title: 'المواقيت',
        subtitle: 'أماكن الإحرام',
        image: 'assets/umrah/tool_miqat.jpg',
        icon: Icons.explore_rounded,
        page: MawaqitPage()
      ),
      (
        title: 'المحظورات',
        subtitle: 'الممنوع والمباح',
        image: 'assets/umrah/tool_rules.jpg',
        icon: Icons.block_rounded,
        page: IhramRulesPage()
      ),
      (
        title: 'أسئلة شائعة',
        subtitle: 'إجابات موثوقة',
        image: 'assets/umrah/tool_faq.jpg',
        icon: Icons.help_outline_rounded,
        page: FaqPage()
      ),
      (
        title: 'اختبر نفسك',
        subtitle: 'راجع معلوماتك',
        image: 'assets/umrah/tool_quiz.jpg',
        icon: Icons.quiz_outlined,
        page: QuizPage()
      ),
      (
        title: 'حقيبتك',
        subtitle: 'قائمة تجهيزات العمرة',
        image: 'assets/umrah/tool_bag.jpg',
        icon: Icons.luggage_outlined,
        page: ChecklistPage()
      ),
    ];
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: UGold.cream,
          body: CustomScrollView(slivers: [
            SliverAppBar(
                pinned: true,
                backgroundColor: UGold.cream,
                foregroundColor: UGold.deep,
                title: const Text('أدوات العمرة',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                centerTitle: true),
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.fromLTRB(22, 16, 22, 18),
                    child: Text('أدوات تفاعلية تساعدك في كل مرحلة من رحلتك',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: UGold.ink, fontSize: 13)))),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: SliverLayoutBuilder(builder: (context, constraints) {
                final cols = constraints.crossAxisExtent < 350
                    ? 2
                    : (constraints.crossAxisExtent < 700 ? 2 : 3);
                return SliverGrid.builder(
                  itemCount: tools.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 11,
                      mainAxisSpacing: 11,
                      mainAxisExtent: 219),
                  itemBuilder: (c, i) => _ToolGalleryCard(
                      title: tools[i].title,
                      subtitle: tools[i].subtitle,
                      image: tools[i].image,
                      icon: tools[i].icon,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => tools[i].page))),
                );
              }),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ]),
        ));
  }
}

class _ToolGalleryCard extends StatelessWidget {
  const _ToolGalleryCard(
      {required this.title,
      required this.subtitle,
      required this.image,
      required this.icon,
      required this.onTap});
  final String title, subtitle, image;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: const Color(0xFFE8DCC8))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                height: 122,
                width: double.infinity,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(fit: StackFit.expand, children: [
                      UPhoto(asset: image),
                      const DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                            Colors.transparent,
                            Color(0x62092E26)
                          ]))),
                      Center(
                          child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                  color: UGold.deep.withOpacity(.93),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: UGold.gold)),
                              child: Icon(icon, color: UGold.gold, size: 29))),
                    ]))),
            const SizedBox(height: 10),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(title,
                    style: const TextStyle(
                        color: UGold.deep,
                        fontSize: 15,
                        fontWeight: FontWeight.w900))),
            Padding(
                padding: const EdgeInsets.fromLTRB(5, 3, 5, 0),
                child: Text(subtitle,
                    maxLines: 2,
                    style: const TextStyle(
                        color: UGold.ink, fontSize: 11, height: 1.3))),
            const Spacer(),
            const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                    padding: EdgeInsets.only(left: 6, bottom: 2),
                    child: CircleAvatar(
                        radius: 14,
                        backgroundColor: UGold.green,
                        child: Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 16)))),
          ]),
        ),
      ));
}

/// Separate step page matching the centre reference screen, including live progress.
class UmrahStepPage extends StatefulWidget {
  const UmrahStepPage({super.key, required this.index});
  final int index;
  @override
  State<UmrahStepPage> createState() => _UmrahStepPageState();
}

class _UmrahStepPageState extends State<UmrahStepPage> {
  late int current = widget.index;
  int tab = 0;
  double duaScale = 1;
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final s = umrahGuide[current];
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: UGold.cream,
          body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _StepHero(index: current, step: s)),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 15, 18, 0),
                        child: Row(children: [
                          _Tag(Icons.timer_outlined, s.duration),
                          const SizedBox(width: 7),
                          _Tag(Icons.verified_outlined, s.rank),
                          const Spacer(),
                          Text('الخطوة ${current + 1} من 7',
                              style: const TextStyle(
                                  color: UGold.ink,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11)),
                        ]))),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(21, 20, 21, 13),
                        child: Text(s.summary,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: UGold.ink, height: 1.7, fontSize: 14)))),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(children: [
                          Expanded(
                              child: _StepQuickBtn(
                                  icon: Icons.headphones_rounded,
                                  title: 'جولة صوتية',
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => UmrahAudioPage(
                                              index: current))))),
                          const SizedBox(width: 7),
                          Expanded(
                              child: _StepQuickBtn(
                                  icon: Icons.menu_book_outlined,
                                  title: 'الدعاء',
                                  onTap: () => setState(() => tab = 1))),
                          const SizedBox(width: 7),
                          Expanded(
                              child: _StepQuickBtn(
                                  icon: Icons.play_arrow_rounded,
                                  title: 'استمع للشرح',
                                  primary: true,
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => UmrahAudioPage(
                                              index: current))))),
                        ]))),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 19, 16, 18),
                        child: _SegmentedStep(
                            selected: tab,
                            onSelect: (i) => setState(() => tab = i)))),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 19),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 230),
                          child: KeyedSubtree(
                              key: ValueKey('$current-$tab'),
                              child: tab == 1
                                  ? _DuaContent(
                                      step: s,
                                      scale: duaScale,
                                      onScale: (v) =>
                                          setState(() => duaScale = v))
                                  : tab == 2
                                      ? _ErrorsContent(step: s)
                                      : _StepsContent(step: s)),
                        ))),
                if (s.sim != null)
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                          child: _CtaButton(
                              label: s.sim == 'tawaf'
                                  ? 'جرّبي الطواف التفاعلي 3D'
                                  : 'جرّبي السعي التفاعلي 3D',
                              icon: Icons.view_in_ar_rounded,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => UmrahImmersiveTourPage(
                                          tawaf: s.sim == 'tawaf')))))),
                if (s.sim != null)
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                          child: _ManualCounter(type: s.sim!))),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                        child: _CtaButton(
                            label: current == 6
                                ? 'أتممت العمرة — تقبّل الله'
                                : 'أكملت هذه الخطوة  ·  التالية',
                            icon: Icons.check_circle_outline_rounded,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              st.change(() {
                                st.done.add(current);
                                if (current < 6) st.step = current + 1;
                              });
                              if (current < 6) {
                                setState(() {
                                  current++;
                                  tab = 0;
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('تقبّل الله منك عمرتك 🤲')));
                              }
                            }))),
                if (current > 0)
                  SliverToBoxAdapter(
                      child: Center(
                          child: TextButton.icon(
                              onPressed: () => setState(() {
                                    current--;
                                    tab = 0;
                                    st.change(() => st.step = current);
                                  }),
                              icon: const Icon(Icons.chevron_right_rounded),
                              label: const Text('الخطوة السابقة')))),
                const SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 26),
                        child: Text(
                            'محتوى إرشادي عام، وللفتوى الخاصة راجعي أهل العلم.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: UGold.ink, fontSize: 11)))),
              ]),
        ));
  }
}

class _StepHero extends StatelessWidget {
  const _StepHero({required this.index, required this.step});
  final int index;
  final UStep step;
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
        height: 310 + top,
        child: Stack(fit: StackFit.expand, children: [
          UPhoto(asset: 'assets/umrah/step_${index + 1}.jpg'),
          const DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                Color(0x66051F1B),
                Colors.transparent,
                Color(0xD4073C30)
              ]))),
          Positioned(
              top: top + 10,
              right: 12,
              left: 12,
              child: Row(children: [
                Material(
                    color: const Color(0xCFFFFFF7),
                    shape: const CircleBorder(),
                    child: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded,
                            color: UGold.deep),
                        onPressed: () => Navigator.pop(context))),
                const Spacer(),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                        color: const Color(0xCEFFF9EE),
                        borderRadius: BorderRadius.circular(30)),
                    child: Text('الخطوة ${index + 1} من 7',
                        style: const TextStyle(
                            color: UGold.deep,
                            fontSize: 12,
                            fontWeight: FontWeight.w800))),
              ])),
          Positioned(
              bottom: 24,
              right: 23,
              left: 23,
              child: Column(children: [
                Text(step.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 8)
                        ])),
                const SizedBox(height: 6),
                Text(step.summary,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                        color: Color(0xFFFFF0D6), fontSize: 13, height: 1.5)),
              ])),
        ]));
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.icon, this.title);
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          color: const Color(0xFFE7F0E7),
          borderRadius: BorderRadius.circular(25)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: UGold.green, size: 15),
        const SizedBox(width: 5),
        Text(title,
            style: const TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w700, color: UGold.deep))
      ]));
}

class _StepQuickBtn extends StatelessWidget {
  const _StepQuickBtn(
      {required this.icon,
      required this.title,
      required this.onTap,
      this.primary = false});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool primary;
  @override
  Widget build(BuildContext context) => Material(
      color: primary ? UGold.deep : Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: SizedBox(
              height: 78,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        color: primary ? UGold.gold : UGold.deep, size: 24),
                    const SizedBox(height: 6),
                    Text(title,
                        style: TextStyle(
                            color: primary ? Colors.white : UGold.deep,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800))
                  ]))));
}

class _SegmentedStep extends StatelessWidget {
  const _SegmentedStep({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: const Color(0xFFE6EEE7),
          borderRadius: BorderRadius.circular(17)),
      child: Row(children: [
        for (var i = 0; i < 3; i++)
          Expanded(
              child: GestureDetector(
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                          color:
                              selected == i ? UGold.deep : Colors.transparent,
                          borderRadius: BorderRadius.circular(13)),
                      child: Text(['الشرح', 'الدعاء', 'أخطاء شائعة'][i],
                          style: TextStyle(
                              color: selected == i ? Colors.white : UGold.deep,
                              fontSize: 12,
                              fontWeight: FontWeight.w800))))),
      ]));
}

class _StepsContent extends StatelessWidget {
  const _StepsContent({required this.step});
  final UStep step;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: Text('خطوات ${step.title}',
                style: const TextStyle(
                    color: UGold.deep,
                    fontWeight: FontWeight.w900,
                    fontSize: 17))),
        for (var i = 0; i < step.how.length; i++)
          Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    width: 27,
                    height: 27,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: UGold.green, shape: BoxShape.circle),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12))),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(step.how[i],
                        style: const TextStyle(
                            color: UGold.deep, height: 1.75, fontSize: 14))),
              ])),
        _Notice(
            icon: Icons.lightbulb_outline_rounded,
            title: 'نصيحة',
            text: step.tip),
        if (step.women != null)
          Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _Notice(
                  icon: Icons.spa_rounded,
                  title: 'للمرأة',
                  text: step.women!,
                  lavender: true)),
      ]);
}

class _Notice extends StatelessWidget {
  const _Notice(
      {required this.icon,
      required this.title,
      required this.text,
      this.lavender = false});
  final IconData icon;
  final String title, text;
  final bool lavender;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: lavender ? const Color(0xFFF5EDF8) : const Color(0xFFF8EBCF),
          borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: UGold.deep),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  color: UGold.deep, fontWeight: FontWeight.w900))
        ]),
        const SizedBox(height: 6),
        Text(text,
            style: const TextStyle(color: UGold.ink, height: 1.7, fontSize: 13))
      ]));
}

class _DuaContent extends StatelessWidget {
  const _DuaContent(
      {required this.step, required this.scale, required this.onScale});
  final UStep step;
  final double scale;
  final ValueChanged<double> onScale;
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(21),
                gradient:
                    const LinearGradient(colors: [UGold.green, UGold.deep])),
            child: Column(children: [
              const Icon(Icons.auto_awesome_rounded, color: UGold.gold),
              const SizedBox(height: 10),
              SelectableText(step.dua,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20 * scale,
                      height: 1.95,
                      fontWeight: FontWeight.w700)),
            ])),
        Row(children: [
          IconButton(
              tooltip: 'تصغير النص',
              onPressed: () => onScale((scale - .1).clamp(.8, 1.5).toDouble()),
              icon: const Icon(Icons.text_decrease_rounded, color: UGold.deep)),
          IconButton(
              tooltip: 'تكبير النص',
              onPressed: () => onScale((scale + .1).clamp(.8, 1.5).toDouble()),
              icon: const Icon(Icons.text_increase_rounded, color: UGold.deep)),
          const Spacer(),
          TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: step.dua));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ الدعاء')));
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('نسخ'))
        ]),
        _Notice(
            icon: Icons.info_outline,
            title: 'معلومة عن الدعاء',
            text: step.duaNote),
      ]);
}

class _ErrorsContent extends StatelessWidget {
  const _ErrorsContent({required this.step});
  final UStep step;
  @override
  Widget build(BuildContext context) => Column(children: [
        for (final issue in step.errors)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEBDECC))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFB05042)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(issue.wrong,
                                  style: const TextStyle(
                                      color: UGold.ink,
                                      height: 1.55,
                                      fontWeight: FontWeight.w700)))
                        ]),
                        const Divider(height: 24),
                        Row(children: [
                          const Icon(Icons.check_circle_outline,
                              color: UGold.green),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(issue.right,
                                  style: const TextStyle(
                                      color: UGold.ink, height: 1.55)))
                        ]),
                      ])))
      ]);
}

class UmrahAudioPage extends StatelessWidget {
  const UmrahAudioPage({super.key, required this.index});
  final int index;
  @override
  Widget build(BuildContext context) => Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
          backgroundColor: UGold.cream,
          body: CustomScrollView(slivers: [
            SliverAppBar(
                pinned: true,
                backgroundColor: UGold.cream,
                foregroundColor: UGold.deep,
                title: const Text('جولة صوتية',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                centerTitle: true),
            SliverToBoxAdapter(
                child: SizedBox(
                    height: 242,
                    child: Stack(fit: StackFit.expand, children: [
                      const UPhoto(asset: 'assets/umrah/umrah_hero.jpg'),
                      const DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                            Color(0x35FFFFFF),
                            Color(0xC4FFF8EB)
                          ]))),
                      const Center(
                          child: Icon(Icons.headphones_rounded,
                              size: 105, color: UGold.deep)),
                      const Positioned(
                          bottom: 15,
                          right: 0,
                          left: 0,
                          child: Text('استمع إلى مناسك العمرة خطوة بخطوة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: UGold.deep,
                                  fontWeight: FontWeight.w800))),
                    ]))),
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 19, 16, 14),
                    child: RifqaNarrationPlayer(
                        stepIndex: index,
                        onDua: () => showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            isScrollControlled: true,
                            builder: (c) => SafeArea(
                                child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(22),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('الدعاء',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w900)),
                                          const SizedBox(height: 12),
                                          SelectableText(umrahGuide[index].dua,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 19, height: 1.9)),
                                          const SizedBox(height: 12),
                                          Text(umrahGuide[index].duaNote,
                                              textAlign: TextAlign.center)
                                        ]))))))),
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                        'التعليق الوثائقي المسجّل، وليس قراءة صوت آلية. للتشغيل الكامل دون إنترنت أضيفي ملفات التسجيلات الكاملة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: UGold.ink, fontSize: 12, height: 1.6)))),
          ])));
}

class UmrahImmersiveTourPage extends StatelessWidget {
  const UmrahImmersiveTourPage({super.key, required this.tawaf});
  final bool tawaf;
  @override
  Widget build(BuildContext context) => Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
          backgroundColor: UGold.cream,
          body: Column(children: [
            Expanded(
                child: Stack(fit: StackFit.expand, children: [
              UPhoto(
                  asset: tawaf
                      ? 'assets/umrah/tawaf_panorama.jpg'
                      : 'assets/umrah/sai_panorama.jpg'),
              const DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                    Color(0xB9083029),
                    Colors.transparent,
                    Color(0xAA082F28)
                  ]))),
              Positioned(
                  top: MediaQuery.paddingOf(context).top + 10,
                  right: 12,
                  left: 12,
                  child: Row(children: [
                    Material(
                        color: const Color(0xB0083F32),
                        shape: const CircleBorder(),
                        child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_forward,
                                color: Colors.white))),
                    Expanded(
                        child: Column(children: [
                      Text(tawaf ? 'طواف 3D' : 'سعي 3D',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                      const Text('تعرّفي على المسار قبل أداء النسك',
                          style:
                              TextStyle(color: Color(0xFFFFE0A3), fontSize: 12))
                    ])),
                    const SizedBox(width: 47),
                  ])),
              Positioned(
                  bottom: 24,
                  right: 20,
                  left: 20,
                  child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: const Color(0xDF083A30),
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(color: UGold.gold)),
                      child: Column(children: [
                        Icon(
                            tawaf
                                ? Icons.view_in_ar_rounded
                                : Icons.directions_walk_rounded,
                            color: UGold.gold,
                            size: 32),
                        const SizedBox(height: 8),
                        Text(
                            tawaf
                                ? 'سبعة أشواط حول الكعبة'
                                : 'سبعة أشواط بين الصفا والمروة',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 17)),
                        const SizedBox(height: 7),
                        Text(
                            tawaf
                                ? 'تبدأ من الحجر الأسود، والكعبة عن يسارك'
                                : 'تبدأ من الصفا وتنتهي عند المروة',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Color(0xFFFFE8BD),
                                fontSize: 12,
                                height: 1.5)),
                      ]))),
            ])),
            Padding(
                padding: EdgeInsets.fromLTRB(
                    18, 12, 18, MediaQuery.paddingOf(context).bottom + 16),
                child: Column(children: [
                  _CtaButton(
                      label: 'ابدئي المحاكاة التفاعلية 3D',
                      icon: Icons.play_arrow_rounded,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => tawaf
                                  ? const Tawaf3DPage()
                                  : const Sai3DPage()))),
                  const SizedBox(height: 8),
                  const Text(
                      'الصورة معاينة سينمائية، والمحاكاة في الخطوة التالية مجسم تفاعلي يتحرك ويمكن تغيير منظور الكاميرا فيه.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: UGold.ink, fontSize: 10.5, height: 1.5)),
                ])),
          ])));
}

/// Manual counters remain available even without launching the animated 3D.
/// 3D engines update these same two AppScope values.
class _ManualCounter extends StatelessWidget {
  const _ManualCounter({required this.type});
  final String type;
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final isTawaf = type == 'tawaf';
    final n = isTawaf ? st.tawaf : st.sai;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE6D8C2))),
      child: Column(children: [
        Row(children: [
          Icon(
              isTawaf
                  ? Icons.view_in_ar_rounded
                  : Icons.directions_walk_rounded,
              color: UGold.deep),
          const SizedBox(width: 8),
          Expanded(
              child: Text(isTawaf ? 'عدّاد أشواط الطواف' : 'عدّاد أشواط السعي',
                  style: const TextStyle(
                      color: UGold.deep, fontWeight: FontWeight.w800))),
          Text('$n / 7',
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                  color: UGold.deep,
                  fontWeight: FontWeight.w900,
                  fontSize: 19)),
        ]),
        const SizedBox(height: 8),
        LinearProgressIndicator(
            value: n.clamp(0, 7) / 7.0,
            backgroundColor: const Color(0xFFE4E9DF),
            color: UGold.green,
            borderRadius: BorderRadius.circular(10),
            minHeight: 7),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: n == 0
                      ? null
                      : () => st.change(() {
                            if (isTawaf) {
                              st.tawaf = n - 1;
                            } else {
                              st.sai = n - 1;
                            }
                          }),
                  icon: const Icon(Icons.remove_rounded),
                  label: const Text('تراجع'))),
          const SizedBox(width: 10),
          Expanded(
              child: FilledButton.icon(
                  onPressed: n >= 7
                      ? null
                      : () => st.change(() {
                            if (isTawaf) {
                              st.tawaf = n + 1;
                            } else {
                              st.sai = n + 1;
                            }
                          }),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(isTawaf ? 'أتممت شوطًا' : 'وصلت الطرف الآخر'),
                  style: FilledButton.styleFrom(backgroundColor: UGold.green))),
        ]),
      ]),
    );
  }
}

/// Public compatibility widgets retained for any other page that imported them.
class CounterCard extends StatelessWidget {
  const CounterCard({super.key, required this.type});
  final String type;
  @override
  Widget build(BuildContext context) => _ManualCounter(type: type);
}

class InfoBox extends StatelessWidget {
  const InfoBox(this.title, this.text, this.color,
      {super.key, this.center = false});
  final String title, text;
  final Color color;
  final bool center;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(17)),
        child: Column(
            crossAxisAlignment:
                center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(title,
                  textAlign: center ? TextAlign.center : null,
                  style: const TextStyle(
                      color: UGold.deep, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(text,
                  textAlign: center ? TextAlign.center : null,
                  style: TextStyle(
                      color: UGold.ink,
                      height: center ? 1.9 : 1.6,
                      fontSize: center ? 17 : 13)),
            ]),
      );
}
