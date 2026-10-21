import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cinematic_theme.dart';
import 'cinematic_tour.dart';
import 'rawdah_booking_simulator_v4.dart';

/// Booking assistant only. No fictitious availability, appointments or claims
/// to act on behalf of Nusuk. All actual reservations are on Nusuk.
class RawdahBookingV3 extends StatefulWidget {
  const RawdahBookingV3({super.key});
  @override
  State<RawdahBookingV3> createState() => _RawdahBookingV3State();
}

class _RawdahBookingV3State extends State<RawdahBookingV3> {
  bool women = true;
  late final Timer _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  String _clockString(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ${time.hour < 12 ? 'صباحًا' : 'مساءً'}';
  }

  Future<void> _nusuk() async {
    final uri = Uri.parse('https://www.nusuk.sa/');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح نسك. افتحي https://www.nusuk.sa/ من المتصفح.')),
      );
    }
  }

  void _open(Widget page) => Navigator.of(context).push(cinematicRoute(page));

  @override
  Widget build(BuildContext context) {
    final saudi = _now.toUtc().add(const Duration(hours: 3));
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: const Color(0xFFFCF8F1),
      body: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
        SliverToBoxAdapter(child: _BookingHero(onBack: () => Navigator.pop(context))),
        SliverPadding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 25),
          sliver: SliverList(delegate: SliverChildListDelegate([
            const SizedBox(height: 10),
            Material(color: Colors.white, borderRadius: BorderRadius.circular(23),
              child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
                Expanded(child: _ClockBlock(title: 'الوقت في السعودية',
                  value: _clockString(saudi), icon: Icons.mosque_rounded)),
                Container(width: 1, height: 58, color: const Color(0xFFE8DCC6)),
                Expanded(child: _ClockBlock(title: 'عندك',
                  value: _clockString(_now), icon: Icons.access_time_rounded)),
              ]))),
            const SizedBox(height: 15),
            _NoticePanel(
              heading: 'المواعيد المتاحة تُعرض داخل نسك',
              details: 'رفقة يساعدك في التحضير والخطوات والمتابعة. لا يعرض أوقات حجز مباشرة ولا يحجز نيابةً عنك.',
            ),
            const SizedBox(height: 15),
            Material(borderRadius: BorderRadius.circular(25), color: Colors.white,
              child: Padding(padding: const EdgeInsets.all(9),
                child: Row(children: [
                  Expanded(child: _GenderOption(active: women, text: 'السيدات',
                    icon: Icons.face_3_rounded,
                    onTap: () => setState(() => women = true))),
                  const SizedBox(width: 8),
                  Expanded(child: _GenderOption(active: !women, text: 'الرجال',
                    icon: Icons.person_rounded,
                    onTap: () => setState(() => women = false))),
                ]))),
            const SizedBox(height: 7),
            Text('اختيار النوع لتخصيص الدليل فقط؛ المواعيد وشروط الزيارة تُحدَّد من نسك.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: CinematicButton(
              label: 'ابدئي خطة الحجز', icon: Icons.event_available_rounded,
              gold: false,
              onPressed: () => _open(RawdahBookingSimulatorV5(
                initialWomen: women,
                onOpenFullGuide: () => _open(const RawdahBookingPlanV3()),
              )))),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(child: _ActionTile(title: 'الدليل الكامل',
                icon: Icons.play_circle_fill_rounded,
                onTap: () => _open(const RawdahBookingPlanV3()))),
              const SizedBox(width: 12),
              Expanded(child: _ActionTile(title: 'تجربة الزيارة المصوّرة',
                icon: Icons.view_in_ar_rounded,
                onTap: () => _open(const CinematicTourScreen(
                  kind: CinematicJourneyKind.rawdah)))),
            ]),
            const SizedBox(height: 15),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new),
              onPressed: _nusuk,
              style: OutlinedButton.styleFrom(foregroundColor: cinematicGreen,
                side: const BorderSide(color: cinematicGold),
                padding: const EdgeInsets.symmetric(vertical: 16)),
              label: const Text('الانتقال إلى منصة نسك للحجز الرسمي',
                textAlign: TextAlign.center),
            )),
            const SizedBox(height: 22),
            const _TrustRow(),
          ]))),
      ]),
    ));
  }
}

class _BookingHero extends StatelessWidget {
  const _BookingHero({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).width < 380 ? 350 : 380,
    child: Stack(fit: StackFit.expand, children: [
      const CinematicImage('$cinematicAssets/scenes/rawdah_grille.jpg',
        alignment: Alignment.centerLeft),
      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.centerLeft, end: Alignment.centerRight,
        colors: [Color(0x10000000), Color(0xB8FFF8EC), Color(0xFFFFF8EC)],
        stops: [0, .60, 1],
      ))),
      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.transparent, Color(0xFFFCF8F1)],
      ))),
      SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.all(21),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('رِفقة', style: TextStyle(fontWeight: FontWeight.w900,
              color: cinematicGreen, fontSize: 31)),
            CircleAvatar(backgroundColor: const Color(0xEFFFF8ED),
              child: IconButton(icon: const Icon(Icons.arrow_forward_ios_rounded,
                size: 18, color: cinematicGreen), onPressed: onBack)),
          ]),
          const Spacer(),
          const Align(alignment: Alignment.centerRight, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              DecoratedBox(decoration: BoxDecoration(color: Color(0xFFFFE8B4),
                borderRadius: BorderRadius.all(Radius.circular(30))),
                child: Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Text('دليل للحجز عبر نسك', style: TextStyle(
                    color: cinematicGreen, fontWeight: FontWeight.bold)))),
              SizedBox(height: 12),
              Text('حجز الروضة الشريفة', style: TextStyle(color: cinematicGreen,
                fontSize: 31, fontWeight: FontWeight.w900)),
              SizedBox(height: 7),
              Text('خطوات واضحة لزيارة مباركة بإذن الله',
                style: TextStyle(color: cinematicGreen, fontSize: 15, height: 1.5)),
            ],
          )),
        ]),
      )),
    ]),
  );
}

class _ClockBlock extends StatelessWidget {
  const _ClockBlock({required this.title, required this.value, required this.icon});
  final String title, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: const Color(0xFFC09348)),
    const SizedBox(height: 6),
    Text(title, style: const TextStyle(color: cinematicGreen, fontSize: 12)),
    Text(value, textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.w900,
        color: cinematicGreen, fontSize: 19)),
  ]);
}

class _NoticePanel extends StatelessWidget {
  const _NoticePanel({required this.heading, required this.details});
  final String heading, details;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(23),
      image: const DecorationImage(
        image: AssetImage('$cinematicAssets/scenes/courtyard_day_umbrella.jpg'),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(Color(0xD0023A2B), BlendMode.srcOver),
      ),
    ),
    child: Row(children: [
      const Icon(Icons.event_note_rounded, color: cinematicGold, size: 31),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(heading, style: const TextStyle(color: Colors.white,
          fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Text(details, style: const TextStyle(color: Color(0xFFEEEADC),
          fontSize: 12, height: 1.6)),
      ])),
    ]),
  );
}

class _GenderOption extends StatelessWidget {
  const _GenderOption({required this.active, required this.text,
    required this.icon, required this.onTap});
  final bool active;
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: active ? cinematicGreen : const Color(0xFFF8F6F0),
    borderRadius: BorderRadius.circular(19), child: InkWell(
      borderRadius: BorderRadius.circular(19), onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: active ? Colors.white : const Color(0xFF879087)),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: active ? Colors.white : cinematicGreen,
            fontWeight: FontWeight.bold)),
        ])),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.title, required this.icon, required this.onTap});
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white, borderRadius: BorderRadius.circular(21),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(21),
      child: Container(padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(21),
          border: Border.all(color: cinematicGold)),
        child: Column(children: [
          Icon(icon, size: 29, color: cinematicGreen),
          const SizedBox(height: 9),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(
            color: cinematicGreen, fontSize: 14, fontWeight: FontWeight.w800)),
        ])),
    ),
  );
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();
  @override
  Widget build(BuildContext context) => const Row(children: [
    Expanded(child: _TrustItem(icon: Icons.verified_outlined,
      title: 'نسك للحجز', subtitle: 'المصدر الرسمي')),
    Expanded(child: _TrustItem(icon: Icons.fact_check_outlined,
      title: 'خطوات مبسطة', subtitle: 'دليل إرشادي')),
    Expanded(child: _TrustItem(icon: Icons.favorite_outline,
      title: 'الاستعداد', subtitle: 'بسكينة واطمئنان')),
  ]);
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, size: 24, color: const Color(0xFFBE9148)),
    const SizedBox(height: 6),
    FittedBox(child: Text(title, style: const TextStyle(
      color: cinematicGreen, fontWeight: FontWeight.w700, fontSize: 12))),
    Text(subtitle, textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFF848A81), fontSize: 10)),
  ]);
}

class RawdahBookingPlanV3 extends StatefulWidget {
  const RawdahBookingPlanV3({super.key});
  @override
  State<RawdahBookingPlanV3> createState() => _RawdahBookingPlanV3State();
}

class _RawdahBookingPlanV3State extends State<RawdahBookingPlanV3> {
  final checks = List<bool>.filled(5, false);
  final steps = const <(String, String, IconData)>[
    ('حددي وقت زيارتك', 'حددي تاريخ السفر واستمري في متابعة الموعد عبر نسك.', Icons.calendar_month_rounded),
    ('افتحي نسك', 'افتحي المنصة الرسمية، وسجّلي الدخول وأكملي بياناتك.', Icons.search_rounded),
    ('ابحثي عن التصاريح المتاحة', 'اختاري زيارة الروضة واتّبعي الخيارات المعروضة بالفعل.', Icons.event_available_rounded),
    ('فعّلي التذكير', 'استعدّي بوقت كافٍ، واحتفظي بتفاصيل التصريح بعد صدوره.', Icons.notifications_active_rounded),
    ('استعدّي للزيارة', 'راجعي تعليمات نسك والزي المسموح والأوراق المطلوبة.', Icons.mosque_rounded),
  ];

  Future<void> _openNusuk() async {
    final uri = Uri.parse('https://www.nusuk.sa/');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تعذر فتح الموقع، افتحي nusuk.sa من متصفحك.')));
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: const Color(0xFFFCF8F1),
      appBar: AppBar(title: const Text('خطة الحجز خطوة بخطوة'),
        backgroundColor: const Color(0xFFFCF8F1),
        foregroundColor: cinematicGreen),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ClipRRect(borderRadius: BorderRadius.circular(24), child: SizedBox(
          height: 185, child: Stack(fit: StackFit.expand, children: [
            const CinematicImage('$cinematicAssets/scenes/exterior_sunset_wide.jpg'),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.centerLeft, end: Alignment.centerRight,
              colors: [Color(0x18002C21), Color(0xEA063C2D)]))),
            const Padding(padding: EdgeInsets.all(20), child: Align(
              alignment: Alignment.centerRight, child: Text(
                'خطتك الهادئة للروضة الشريفة\nمن الاستعداد حتى تصريح نسك',
                style: TextStyle(color: Colors.white, fontSize: 23,
                  height: 1.5, fontWeight: FontWeight.w900)),
            )),
          ]))),
        const SizedBox(height: 20),
        for (int i = 0; i < steps.length; i++) ...[
          Material(borderRadius: BorderRadius.circular(21), color: Colors.white,
            child: InkWell(borderRadius: BorderRadius.circular(21),
              onTap: () => setState(() => checks[i] = !checks[i]),
              child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [
                CircleAvatar(backgroundColor: cinematicGreen,
                  child: Text('${i + 1}', style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(steps[i].$1, style: const TextStyle(color: cinematicGreen,
                    fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 6),
                  Text(steps[i].$2, style: const TextStyle(fontSize: 12,
                    color: Color(0xFF727F76), height: 1.5)),
                ])),
                Checkbox(value: checks[i], activeColor: cinematicGreen,
                  onChanged: (v) => setState(() => checks[i] = v ?? false)),
              ])),
            )),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 10),
        const Text('هذه قائمة متابعة داخل الجهاز وليست حجزًا فعليًا. مواعيد توفر التصاريح متغيرة وغير مضمونة.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF737C74), fontSize: 12, height: 1.6)),
        const SizedBox(height: 14),
        CinematicButton(label: 'افتحي نسك الرسمي',
          icon: Icons.open_in_new, onPressed: _openNusuk),
        const SizedBox(height: 25),
      ]),
    ),
  );
}
