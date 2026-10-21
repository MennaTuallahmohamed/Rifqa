import 'package:flutter/material.dart';
import '../../rawdah/rawdah_screen.dart';
import '../madinah_gate_experience.dart';
import 'cinematic_theme.dart';
import 'cinematic_tour.dart';
import 'seerah_museum.dart';
import 'cinematic_salawat.dart';

/// Photographic entry hub; retains the old Madinah pages and repositories.
class MadinahImmersiveHub extends StatelessWidget {
  const MadinahImmersiveHub({super.key});

  void _open(BuildContext context, int index) {
    if (index == 0) {
      Navigator.of(context).push(cinematicRoute(MadinahGateExperience(
        backgroundAsset: '$cinematicAssets/scenes/courtyard_day_umbrella.jpg',
        gateAsset: '$cinematicAssets/scenes/gate_sultan_abdulmajeed.jpg',
        onEnter: () {
          Navigator.of(context).pushReplacement(cinematicRoute(
            const CinematicTourScreen(kind: CinematicJourneyKind.mosque)));
        },
      )));
    } else if (index == 1) {
      Navigator.of(context).push(cinematicRoute(
        const CinematicTourScreen(kind: CinematicJourneyKind.rawdah)));
    } else {
      Navigator.of(context).push(cinematicRoute(const SeerahMuseumScreen()));
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: const Color(0xFFFCF8EF),
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: MediaQuery.sizeOf(context).height * .49,
          backgroundColor: cinematicGreen,
          foregroundColor: cinematicCream,
          leading: IconButton(onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_forward_ios_rounded)),
          title: const Text('المدينة المنورة'),
          flexibleSpace: FlexibleSpaceBar(background: Stack(fit: StackFit.expand, children: [
            const CinematicImage('$cinematicAssets/scenes/exterior_sunset_wide.jpg'),
            DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
              colors: [Colors.black.withOpacity(.16), Colors.transparent,
                cinematicDeep.withOpacity(.94)],
              stops: const [0, .34, 1], begin: Alignment.topCenter,
              end: Alignment.bottomCenter))),
            SafeArea(child: Align(alignment: Alignment.bottomCenter,
              child: Padding(padding: const EdgeInsets.fromLTRB(22, 25, 22, 20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CinematicPill(text: 'RIFQA · رحلة المدينة'),
                  const SizedBox(height: 13),
                  const CinematicHeading('رحلة إلى رحاب المدينة',
                    subtitle: 'ثلاث تجارب سينمائية للصورة والصوت والتأمل', size: 28),
                  const SizedBox(height: 8),
                  const Text('صَلِّ وَسَلِّمْ عَلَى النَّبِيِّ ﷺ',
                    style: TextStyle(color: cinematicGold, fontSize: 16)),
                ]))),
            ),
          ])),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(17, 18, 17, 24),
          sliver: SliverList(delegate: SliverChildListDelegate([
            const Text('اختاري رحلتك', style: TextStyle(fontSize: 26,
              color: cinematicGreen, fontWeight: FontWeight.w900)),
            const SizedBox(height: 13),
            _JourneyCard(title: 'دخول المسجد النبوي',
              subtitle: 'من الأبواب إلى ساحات المسجد وأروقته',
              pill: 'بوابة متحركة + جولة سينمائية', photo: 'gate_sultan_abdulmajeed.jpg',
              onTap: () => _open(context, 0)),
            const SizedBox(height: 14),
            _JourneyCard(title: 'الروضة الشريفة',
              subtitle: 'مشاهد حقيقية للمكان، وهدوء وصوت وتأمل',
              pill: 'جولة بصريّة وصوتية', photo: 'rawdah_grille.jpg',
              onTap: () => _open(context, 1)),
            const SizedBox(height: 14),
            _JourneyCard(title: 'معرض السيرة النبوية',
              subtitle: '50 موقفًا من السيرة، بالصور والمصادر',
              pill: '50 حكاية • استمعي واقرئي', photo: 'quran_courtyard.jpg',
              onTap: () => _open(context, 2)),
            const SizedBox(height: 17),
            _LinkTile(icon: Icons.favorite_outline_rounded,
              title: 'الصلاة والسلام على النبي ﷺ',
              subtitle: 'صيغ موثقة • استماع صوتي وقراءة هادئة',
              onTap: () => Navigator.of(context).push(
                cinematicRoute(const CinematicSalawatScreen()))),
            const SizedBox(height: 12),
            _LinkTile(icon: Icons.event_available_outlined,
              title: 'إرشادات زيارة الروضة والحجز',
              subtitle: 'صفحتك الأصلية: نسك والمواعيد والأسئلة',
              onTap: () => Navigator.of(context).push(
                cinematicRoute(const RawdahScreen()))),
            const SizedBox(height: 16),
            const Text('الجولات مشاهد مصورة ذات حركة منظورية وليست نموذج 3D هندسيًا للمكان.\nالمصادر الدينية معروضة للتحقق قبل النشر.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6F7E73), fontSize: 11, height: 1.6)),
          ])),
        ),
      ]),
    ),
  );
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.title, required this.subtitle,
    required this.photo, required this.pill, required this.onTap});
  final String title, subtitle, photo, pill;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.82,
    child: Material(color: cinematicGreen,
      borderRadius: BorderRadius.circular(27),
      elevation: 5,
      shadowColor: cinematicGreen.withOpacity(.2),
      child: ClipRRect(borderRadius: BorderRadius.circular(27),
        child: InkWell(onTap: onTap, child: Stack(fit: StackFit.expand, children: [
          CinematicImage('$cinematicAssets/scenes/$photo'),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.centerRight, end: Alignment.centerLeft,
            colors: [Color(0xEF052B20), Color(0xC5084031), Color(0x18001008)]))),
          Padding(padding: const EdgeInsets.all(17), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              CinematicPill(text: pill),
              const Spacer(),
              Text(title, style: const TextStyle(color: cinematicCream,
                fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: cinematicCream,
                fontSize: 13, height: 1.4)),
              const SizedBox(height: 8),
              const Row(children: [
                Text('ابدئي الرحلة', style: TextStyle(color: cinematicGold,
                  fontSize: 14, fontWeight: FontWeight.w800)),
                SizedBox(width: 8),
                Icon(Icons.arrow_back_ios_new_rounded,
                  color: cinematicGold, size: 14),
              ]),
            ])),
        ])),
      ),
    ),
  );
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.icon, required this.title, required this.subtitle,
    required this.onTap});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white, borderRadius: BorderRadius.circular(22),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(22),
      child: Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFDFD0B1))),
        child: Row(children: [
          CircleAvatar(radius: 24, backgroundColor: const Color(0xFFE7EEE6),
            child: Icon(icon, color: cinematicGreen)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: cinematicGreen,
              fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(color: Color(0xFF798279), fontSize: 12)),
          ])),
          const Icon(Icons.chevron_left, color: cinematicGreen),
        ])),
    ),
  );
}
