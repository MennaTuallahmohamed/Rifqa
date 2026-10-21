import 'package:flutter/material.dart';
import '../../rawdah/rawdah_screen.dart';
import '../madinah_gate_experience.dart';
import 'cinematic_theme.dart';
import 'cinematic_tour.dart';
import 'seerah_museum.dart';

/// Entry screen: one consistent cinematic visual system for three journeys.
class MadinahImmersiveHub extends StatefulWidget {
  const MadinahImmersiveHub({super.key});
  @override
  State<MadinahImmersiveHub> createState() => _MadinahImmersiveHubState();
}

class _MadinahImmersiveHubState extends State<MadinahImmersiveHub> {
  int selected = 0;
  static const _titles = [
    'دخول المسجد النبوي', 'الروضة الشريفة', 'معرض السيرة النبوية',
  ];
  static const _subs = [
    'رحلة تبدأ من الأبواب إلى رحاب المسجد',
    'سكون المكان وروحانية الروضة الشريفة',
    'خمسون حكاية موثقة بمصادرها وصوت راوي',
  ];
  static const _photos = [
    'gate_sultan_abdulmajeed.jpg', 'rawdah_grille.jpg', 'quran_courtyard.jpg',
  ];

  void _open(int index) {
    switch (index) {
      case 0:
        // Reuse the real 3D-perspective door-opening animation already present
        // in the Rifqa repository, then enter our guided cinematic scenes.
        Navigator.of(context).push(cinematicRoute(MadinahGateExperience(
          backgroundAsset: '$cinematicAssets/scenes/courtyard_day_umbrella.jpg',
          gateAsset: '$cinematicAssets/scenes/gate_sultan_abdulmajeed.jpg',
          onEnter: () {
            Navigator.of(context).pushReplacement(cinematicRoute(
              const CinematicTourScreen(kind: CinematicJourneyKind.mosque)));
          },
        )));
        break;
      case 1:
        Navigator.of(context).push(cinematicRoute(const CinematicTourScreen(
          kind: CinematicJourneyKind.rawdah)));
        break;
      default:
        Navigator.of(context).push(cinematicRoute(const SeerahMuseumScreen()));
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: cinematicDeep,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: MediaQuery.sizeOf(context).height * .50,
          backgroundColor: cinematicGreen,
          leading: IconButton(icon: const Icon(Icons.arrow_forward_ios, color: cinematicCream),
            onPressed: () => Navigator.of(context).pop()),
          title: const Text('المدينة المنورة', style: TextStyle(color: cinematicCream)),
          flexibleSpace: FlexibleSpaceBar(background: Stack(fit: StackFit.expand, children: [
            const CinematicImage('$cinematicAssets/scenes/minarets_sunset.jpg'),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0x55041710), cinematicDeep],
              stops: [0, .46, 1]))),
            SafeArea(child: Align(alignment: Alignment.bottomCenter,
              child: Padding(padding: const EdgeInsets.fromLTRB(24, 35, 24, 28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CinematicPill(text: 'RIFQA · رحلة المدينة'),
                  const SizedBox(height: 16),
                  const CinematicHeading('رحلة إلى رحاب المدينة',
                    subtitle: 'ثلاث تجارب سينمائية • رحلة للصورة والصوت والتأمل'),
                  const SizedBox(height: 12),
                  const Text('صَلِّ عَلَى مُحَمَّدٍ ﷺ',
                    style: TextStyle(color: cinematicGold, letterSpacing: 1, fontSize: 17)),
                ]),
              ),
            )),
          ])),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 25),
          sliver: SliverList(delegate: SliverChildListDelegate([
            const Text('اختاري رحلتك', style: TextStyle(
              color: cinematicCream, fontWeight: FontWeight.bold, fontSize: 24)),
            const SizedBox(height: 12),
            for (int i = 0; i < 3; i++) ...[
              _JourneyCard(index: i, title: _titles[i], subtitle: _subs[i],
                image: _photos[i], onTap: () => _open(i)),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: cinematicGreen.withOpacity(.7),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cinematicGold.withOpacity(.35))),
              child: Column(children: [
                const Icon(Icons.event_available_rounded, color: cinematicGold, size: 28),
                const SizedBox(height: 8),
                const Text('حجز الروضة وإرشادات الزيارة',
                  style: TextStyle(color: cinematicCream, fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('احتفظنا بالقسم الأصلي: مواعيد المحاولة، المعلومات والأدعية.',
                  textAlign: TextAlign.center, style: TextStyle(color: cinematicMuted, height: 1.6)),
                const SizedBox(height: 14),
                CinematicButton(label: 'افتحي دليل الروضة',
                  onPressed: () => Navigator.of(context).push(cinematicRoute(const RawdahScreen()))),
              ]),
            ),
            const SizedBox(height: 22),
            const Text('ملحوظة: المشاهد جولات بصرية موجّهة بحركة عمق وليست مسحًا هندسيًا دقيقًا للمكان. '
              'المحتوى الشرعي يحتاج مراجعة علمية قبل النشر.',
              style: TextStyle(color: cinematicMuted, height: 1.6, fontSize: 11),
              textAlign: TextAlign.center),
          ])),
        ),
      ]),
    ),
  );
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.index, required this.title, required this.subtitle,
    required this.image, required this.onTap});
  final int index;
  final String title, subtitle, image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.85,
    child: ClipRRect(borderRadius: BorderRadius.circular(26),
      child: Material(color: cinematicGreen, child: InkWell(onTap: onTap,
        child: Stack(fit: StackFit.expand, children: [
          CinematicImage('$cinematicAssets/scenes/$image'),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            colors: [Color(0xE600170D), Color(0x6600170D), Color(0x10000000)],
            begin: Alignment.centerRight, end: Alignment.centerLeft))),
          Padding(padding: const EdgeInsets.all(18), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              CinematicPill(text: index == 2 ? '50 حكاية' : 'جولة ثلاثية الإحساس'),
              const Spacer(),
              Text(title, style: const TextStyle(color: cinematicCream,
                fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: cinematicMuted, height: 1.5, fontSize: 13)),
              const SizedBox(height: 9),
              const Row(children: [
                Text('ابدئي الرحلة', style: TextStyle(color: cinematicGold,
                  fontWeight: FontWeight.bold)),
                SizedBox(width: 6),
                Icon(Icons.arrow_back_ios_new, color: cinematicGold, size: 15),
              ]),
            ]),
          ),
        ]),
      )),
    ),
  );
}
