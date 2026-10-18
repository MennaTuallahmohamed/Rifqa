import 'package:flutter/material.dart';

// RIFQA Haramain experience. Photos and Saudi overview are illustration assets.
// All facility points are reference entries, NOT verified indoor coordinates.
const kRifqaGreen = Color(0xFF09533D);
const kRifqaGold = Color(0xFFB88A36);
const kRifqaCream = Color(0xFFF9F6EF);
const kRifqaInk = Color(0xFF172C27);

/// Inject real application services rather than fabricating GPS or SOS results.
class HaramainActions {
  final Future<void> Function()? shareLiveLocation;
  final Future<void> Function()? requestHelp;
  final Future<void> Function()? openMeetingPoint;
  final Future<void> Function(String placeId)? navigateTo;
  final Future<void> Function()? showMyLocation;
  const HaramainActions({this.shareLiveLocation, this.requestHelp,
    this.openMeetingPoint, this.navigateTo, this.showMyLocation});
}

class HaramainExperience extends StatelessWidget {
  final HaramainActions actions;
  final ValueChanged<int>? onNavigationSelected;
  const HaramainExperience({super.key, this.actions = const HaramainActions(), this.onNavigationSelected});

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: HaramainDashboard(actions: actions, onNavigationSelected: onNavigationSelected),
  );
}

class HaramainDashboard extends StatefulWidget {
  final HaramainActions actions;
  final ValueChanged<int>? onNavigationSelected;
  const HaramainDashboard({super.key, required this.actions, this.onNavigationSelected});
  @override
  State<HaramainDashboard> createState() => _HaramainDashboardState();
}

class _HaramainDashboardState extends State<HaramainDashboard> {
  bool layers = false;
  double zoom = 1.0;
  void go(MosqueSite site) => Navigator.push(context, MaterialPageRoute<void>(
    builder: (_) => MosqueExplorer(site: site, actions: widget.actions)));
  void showSearch() => Navigator.push(context, MaterialPageRoute<void>(
    builder: (_) => HaramainSearch(actions: widget.actions)));
  void lost() => Navigator.push(context, MaterialPageRoute<void>(
    builder: (_) => LostPilgrimScreen(actions: widget.actions)));
  Future<void> invoke(Future<void> Function()? action, String unavailable) async {
    if (action == null) { await message(context, 'الخدمة غير متصلة', unavailable); return; }
    try { await action(); } catch (_) { if (mounted) await message(context, 'تعذّر التنفيذ', 'تأكد من اتصال الإنترنت وأذونات التطبيق، ثم حاول مجددًا.'); }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Scaffold(backgroundColor: kRifqaCream, body: SafeArea(bottom: false, child: Column(children: [
      Container(height: 70, color: kRifqaCream, padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          roundIcon(Icons.chevron_right, () => Navigator.maybePop(context)),
          const Expanded(child: Text('خريطة الحرمين', textAlign: TextAlign.center,
            style: TextStyle(color: kRifqaInk, fontSize: 26, fontWeight: FontWeight.w900))),
          roundIcon(Icons.search, showSearch),
        ])),
      Expanded(child: ListView(padding: EdgeInsets.zero, children: [
        SizedBox(height: (height * .49).clamp(330.0, 500.0), child: Stack(fit: StackFit.expand, children: [
          ClipRect(child: Transform.scale(scale: zoom, child: Image.asset('assets/haramain/saudi_map_art.png', fit: BoxFit.cover))),
          Positioned(top: 112, left: 14, child: Column(children: [
            roundIcon(Icons.layers_outlined, () => setState(() => layers = !layers)),
            const SizedBox(height: 10),
            roundIcon(Icons.my_location, () => invoke(widget.actions.showMyLocation, 'اربط خدمة الموقع الفعلية قبل استخدامها.')),
            const SizedBox(height: 10),
            roundIcon(Icons.add, () => setState(() => zoom = (zoom + .15).clamp(1.0, 2.0))),
            const SizedBox(height: 5),
            roundIcon(Icons.remove, () => setState(() => zoom = (zoom - .15).clamp(1.0, 2.0))),
          ])),
          if (layers) Positioned(left: 70, top: 110, child: Container(
            padding: const EdgeInsets.all(12), decoration: surface(),
            child: const Text('خريطة توضيحية وليست GPS', style: TextStyle(fontWeight: FontWeight.w700)))),
          Positioned(bottom: 12, left: 8, right: 8, child: Row(children: [
            quickAction(Icons.location_on_outlined, 'موقعي', () => invoke(widget.actions.showMyLocation, 'يتطلب تحديد الموقع صلاحية GPS وربط مزود الخرائط.')),
            quickAction(Icons.help_outline, 'أنا تائه', lost),
            quickAction(Icons.share_outlined, 'مشاركة الموقع', () => invoke(widget.actions.shareLiveLocation, 'يلزم ربط مشاركة الموقع بالمجموعة بعد إذن المستخدم.')),
            quickAction(Icons.door_front_door_outlined, 'أقرب بوابة', () => go(MosqueSite.haram)),
            quickAction(Icons.groups_outlined, 'نقطة التجمع', () => invoke(widget.actions.openMeetingPoint, 'حدد نقطة التجمع من بيانات مجموعة الرحلة.')),
          ])),
        ])),
        Container(padding: const EdgeInsets.fromLTRB(14, 18, 14, 22),
          decoration: const BoxDecoration(color: kRifqaCream, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(children: [
            Container(width: 46, height: 5, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(9))),
            const SizedBox(height: 16),
            Row(children: [const Icon(Icons.map_outlined, color: kRifqaInk), const SizedBox(width: 8),
              const Expanded(child: Text('الوجهات الرئيسية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
              TextButton(onPressed: showSearch, child: const Text('عرض الكل', style: TextStyle(color: kRifqaGreen)))]),
            Row(children: [Expanded(child: homeMosqueCard(MosqueSite.haram, () => go(MosqueSite.haram))),
              const SizedBox(width: 10), Expanded(child: homeMosqueCard(MosqueSite.nabawi, () => go(MosqueSite.nabawi)))]),
            const SizedBox(height: 14),
            InkWell(onTap: lost, borderRadius: BorderRadius.circular(17), child: Container(
              decoration: BoxDecoration(color: const Color(0xFFFBE9E8), borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFF6C4BD))),
              padding: const EdgeInsets.all(15), child: const Row(children: [Icon(Icons.emergency, color: Color(0xFFBA292B), size: 28), SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('طلب مساعدة', style: TextStyle(fontSize: 17, color: Color(0xFFAE252B), fontWeight: FontWeight.w900)),
                Text('للحالات الطارئة أو عند الشعور بالخطر', style: TextStyle(fontSize: 11))])),
                Text('افتح الآن ←', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFAE252B)))]))),
          ])),
      ])),
      Container(padding: const EdgeInsets.fromLTRB(8, 7, 8, 12), decoration: const BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: Row(children: [
          navItem(Icons.home_outlined, 'الرئيسية', false, () => widget.onNavigationSelected?.call(0)),
          navItem(Icons.auto_stories_outlined, 'العمرة', false, () => widget.onNavigationSelected?.call(1)),
          navItem(Icons.map_rounded, 'الخريطة', true, () {}),
          navItem(Icons.warning_amber_rounded, 'أنا تائه', false, lost),
        ])),
    ])));
  }
}

enum MosqueSite { haram, nabawi }
extension MosqueSiteDetails on MosqueSite {
  String get label => this == MosqueSite.haram ? 'المسجد الحرام' : 'المسجد النبوي';
  String get city => this == MosqueSite.haram ? 'مكة المكرمة' : 'المدينة المنورة';
  String get image => 'assets/haramain/${this == MosqueSite.haram ? 'haram_thumb' : 'nabawi_thumb'}.png';
  String get highlight => this == MosqueSite.haram ? 'الكعبة المشرفة' : 'الروضة الشريفة';
}

class PlaceEntry {
  final String id, title, subtitle;
  final IconData icon;
  final Color tone;
  final MosqueSite mosque;
  const PlaceEntry(this.id, this.title, this.subtitle, this.icon, this.tone, this.mosque);
}

const places = <PlaceEntry>[
  PlaceEntry('haram-kaaba', 'الكعبة المشرفة', 'قلب المسجد الحرام', Icons.mosque, kRifqaGreen, MosqueSite.haram),
  PlaceEntry('haram-mataf', 'صحن المطاف', 'منطقة الطواف حول الكعبة', Icons.explore_outlined, kRifqaGold, MosqueSite.haram),
  PlaceEntry('haram-safa-marwa', 'الصفا والمروة', 'منطقة السعي', Icons.route_outlined, Color(0xFF168A8E), MosqueSite.haram),
  PlaceEntry('haram-gates', 'المداخل والبوابات', 'دليل المداخل والمخارج', Icons.door_front_door, Color(0xFFE58C30), MosqueSite.haram),
  PlaceEntry('haram-zamzam', 'مياه زمزم', 'نقاط تقديم مياه زمزم', Icons.water_drop, Color(0xFF2579D2), MosqueSite.haram),
  PlaceEntry('haram-restrooms', 'دورات المياه', 'مرافق الوضوء ودورات المياه', Icons.wc, Color(0xFF7D53C8), MosqueSite.haram),
  PlaceEntry('haram-prayer', 'المصليات', 'أماكن الصلاة', Icons.mosque_outlined, Color(0xFF27946E), MosqueSite.haram),
  PlaceEntry('haram-medical', 'الخدمات الطبية', 'الإسعاف ومراكز الرعاية', Icons.medical_services, Color(0xFFD64146), MosqueSite.haram),
  PlaceEntry('haram-food', 'المطاعم والمقاهي', 'مرافق قريبة من الحرم', Icons.restaurant, Color(0xFFBD7937), MosqueSite.haram),
  PlaceEntry('haram-info', 'الإرشاد والمساعدة', 'مكاتب الاستعلامات', Icons.info, Color(0xFF3C81CD), MosqueSite.haram),
  PlaceEntry('nabawi-rawda', 'الروضة الشريفة', 'معلومات الزيارة والحجز الرسمي', Icons.mosque, kRifqaGreen, MosqueSite.nabawi),
  PlaceEntry('nabawi-dome', 'القبة الخضراء', 'معلم بارز في المسجد النبوي', Icons.account_balance, kRifqaGold, MosqueSite.nabawi),
  PlaceEntry('nabawi-gates', 'المداخل والبوابات', 'دليل المداخل والمخارج', Icons.door_front_door, Color(0xFFE58C30), MosqueSite.nabawi),
  PlaceEntry('nabawi-umbrellas', 'مظلات الساحات', 'الساحات المحيطة بالمسجد', Icons.beach_access, Color(0xFF308AC1), MosqueSite.nabawi),
  PlaceEntry('nabawi-zamzam', 'مياه زمزم', 'نقاط مياه الشرب', Icons.water_drop, Color(0xFF2579D2), MosqueSite.nabawi),
  PlaceEntry('nabawi-restrooms', 'دورات المياه', 'مرافق الوضوء ودورات المياه', Icons.wc, Color(0xFF7D53C8), MosqueSite.nabawi),
  PlaceEntry('nabawi-prayer', 'المصليات', 'أماكن الصلاة', Icons.mosque_outlined, Color(0xFF27946E), MosqueSite.nabawi),
  PlaceEntry('nabawi-medical', 'الخدمات الطبية', 'الإسعاف ومراكز الرعاية', Icons.medical_services, Color(0xFFD64146), MosqueSite.nabawi),
  PlaceEntry('nabawi-info', 'الإرشاد والمساعدة', 'مكاتب الاستعلامات', Icons.info, Color(0xFF3C81CD), MosqueSite.nabawi),
];

class MosqueExplorer extends StatefulWidget {
  final MosqueSite site;
  final HaramainActions actions;
  const MosqueExplorer({super.key, required this.site, required this.actions});
  @override
  State<MosqueExplorer> createState() => _MosqueExplorerState();
}

class _MosqueExplorerState extends State<MosqueExplorer> {
  int tab = 0, floor = 1;
  bool layersOpen = false;
  final selected = <String>{'المصليات', 'دورات المياه', 'مياه زمزم', 'المداخل والبوابات'};
  String filter = '';
  List<PlaceEntry> get entries => places.where((p) => p.mosque == widget.site &&
    (filter.isEmpty || '${p.title} ${p.subtitle}'.contains(filter))).toList();

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl,
    child: Scaffold(backgroundColor: kRifqaCream, body: SafeArea(child: Column(children: [
      Stack(children: [
        SizedBox(height: 140, width: double.infinity, child: Image.asset(widget.site.image, fit: BoxFit.cover)),
        Container(height: 140, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter,
          end: Alignment.bottomCenter, colors: [Color(0xB9132923), Color(0xD9193029)]))),
        Positioned(top: 14, right: 14, child: roundIcon(Icons.chevron_right, () => Navigator.pop(context))),
        Positioned(top: 48, right: 70, left: 54, child: Column(children: [
          Text(widget.site.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(widget.site.city, style: const TextStyle(color: Colors.white70))])),
      ]),
      Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 9), child: Container(
        padding: const EdgeInsets.all(4), decoration: surface(), child: Row(children: [
          _tabButton(0, 'خريطة داخلية'), _tabButton(1, 'المرافق'), _tabButton(2, 'معلومات'),
        ]))),
      Expanded(child: tab == 0 ? indoorView() : tab == 1 ? facilitiesView() : infoView()),
    ]))));

  Widget _tabButton(int index, String label) => Expanded(child: GestureDetector(
    onTap: () => setState(() => tab = index), child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: tab == index ? kRifqaGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(13)), child: Text(label, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tab == index ? Colors.white : kRifqaInk)))));

  Widget indoorView() => Stack(children: [
    Positioned.fill(child: InteractiveViewer(minScale: 1, maxScale: 3,
      child: Container(decoration: const BoxDecoration(color: Color(0xFFE7E4D8)),
        child: Stack(fit: StackFit.expand, children: [
          Image.asset(widget.site.image, fit: BoxFit.cover,
            color: const Color(0xFFB4AFA1), colorBlendMode: BlendMode.saturation),
          Container(color: const Color(0x55E7E2D6)),
          Center(child: Container(padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: const Color(0xEFFFFFFF), borderRadius: BorderRadius.circular(20)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.map_outlined, size: 38, color: kRifqaGreen),
              const SizedBox(height: 8), const Text('المخطط الداخلي قيد الربط',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 6), const Text('لا توجد إحداثيات داخلية موثّقة حتى الآن',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
            ]))),
        ])))),
    Positioned(top: 12, right: 12, left: 12, child: TextField(
      onChanged: (v) { setState(() { filter = v; if (v.isNotEmpty) tab = 1; }); },
      decoration: InputDecoration(hintText: 'ابحث داخل ${widget.site.label}...', prefixIcon: const Icon(Icons.search),
        fillColor: Colors.white, filled: true, contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)))),
    Positioned(top: 78, left: 12, child: Column(children: [
      roundIcon(Icons.layers_outlined, () => setState(() => layersOpen = !layersOpen)),
      const SizedBox(height: 8), roundIcon(Icons.my_location, () => service(widget.actions.showMyLocation,
        'الموقع الداخلي يحتاج نظام تحديد مواقع موثوقًا.')),
    ])),
    Positioned(top: 89, right: 12, child: Container(decoration: surface(), child: Column(children: [
      floorButton(2, '2F'), floorButton(1, '1F'), floorButton(0, 'B1'),
    ]))),
    if (layersOpen) Positioned(top: 160, left: 12, right: 12, child: Container(
      padding: const EdgeInsets.all(12), decoration: surface(), child: Column(children: [
        const Text('عرض المرافق', style: TextStyle(fontWeight: FontWeight.w900)),
        ...['المصليات', 'دورات المياه', 'مياه زمزم', 'المداخل والبوابات', 'الخدمات الطبية'].map((name) =>
          SwitchListTile.adaptive(dense: true, title: Text(name, style: const TextStyle(fontSize: 12)),
            activeColor: kRifqaGreen, value: selected.contains(name), onChanged: (value) => setState(() => value ? selected.add(name) : selected.remove(name)))),
      ]))),
    Positioned(bottom: 12, right: 10, left: 10, child: Column(children: [
      SizedBox(height: 97, child: ListView(scrollDirection: Axis.horizontal, children: entries.take(7).map((p) =>
        Padding(padding: const EdgeInsets.only(left: 9), child: GestureDetector(onTap: () => openPlace(p),
          child: Container(width: 130, padding: const EdgeInsets.all(12), decoration: surface(),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(p.icon, color: p.tone, size: 27), const SizedBox(height: 6),
              Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))]))))).toList())),
      const SizedBox(height: 7), Container(padding: const EdgeInsets.all(9),
        decoration: surface(), child: const Row(children: [Icon(Icons.info_outline, color: kRifqaGold), SizedBox(width: 7),
          Expanded(child: Text('تصور بصري فقط — لا تستخدم هذه الصورة كخريطة تنقل فعلية',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)))])),
    ])),
  ]);

  Widget floorButton(int index, String title) => InkWell(onTap: () => setState(() => floor = index),
    child: Container(width: 49, height: 47, alignment: Alignment.center,
      decoration: BoxDecoration(color: floor == index ? kRifqaGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(12)), child: Text(title,
          style: TextStyle(color: floor == index ? Colors.white : kRifqaInk, fontWeight: FontWeight.w800))));

  Widget facilitiesView() => Column(children: [
    Padding(padding: const EdgeInsets.all(14), child: TextField(onChanged: (v) => setState(() => filter = v),
      decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'ابحث عن المرافق أو المعالم',
        filled: true, fillColor: Colors.white, border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)))),
    Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(12, 2, 12, 25),
      itemCount: entries.length, itemBuilder: (_, i) {
        final p = entries[i];
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: Material(color: Colors.white,
          borderRadius: BorderRadius.circular(17), child: ListTile(onTap: () => openPlace(p),
            contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
            leading: Container(width: 48, height: 48, decoration: BoxDecoration(
              color: p.tone.withValues(alpha: .11), borderRadius: BorderRadius.circular(14)),
              child: Icon(p.icon, color: p.tone)),
            title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(p.subtitle, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_left))));
      })),
  ]);

  Widget infoView() => ListView(padding: const EdgeInsets.all(15), children: [
    ClipRRect(borderRadius: BorderRadius.circular(21), child: Image.asset(widget.site.image,
      height: 220, width: double.infinity, fit: BoxFit.cover)),
    const SizedBox(height: 16), Text(widget.site.label, style: const TextStyle(
      fontSize: 25, fontWeight: FontWeight.w900, color: kRifqaGreen)),
    const SizedBox(height: 7), Text(widget.site.city,
      style: const TextStyle(fontSize: 15, color: Colors.black54)),
    const SizedBox(height: 12), Text(widget.site == MosqueSite.haram
      ? 'استكشف معالم المسجد الحرام، مواقع المرافق، وإرشادات الاستعداد للطواف والسعي. مداخل المسجد ومساراته تتغير بحسب التنظيم والزحام.'
      : 'استكشف معالم المسجد النبوي والمرافق والخدمات. زيارة الروضة الشريفة تخضع للضوابط والمواعيد الرسمية المعمول بها.',
      style: const TextStyle(height: 1.8)),
    const SizedBox(height: 22), const Text('أهم المعالم والخدمات', style: TextStyle(
      fontSize: 19, fontWeight: FontWeight.w900)), const SizedBox(height: 10),
    ...entries.take(5).map((p) => ListTile(onTap: () => openPlace(p), leading: Icon(p.icon, color: p.tone),
      title: Text(p.title), trailing: const Icon(Icons.chevron_left))),
  ]);

  void openPlace(PlaceEntry place) => Navigator.push(context, MaterialPageRoute<void>(
    builder: (_) => PlaceDetails(place: place, actions: widget.actions)));
  Future<void> service(Future<void> Function()? fn, String text) async {
    if (fn == null) return message(context, 'غير متاح حاليًا', text);
    try { await fn(); } catch (_) { if (mounted) await message(context, 'تعذّر التنفيذ', 'يرجى المحاولة مجددًا.'); }
  }
}

class PlaceDetails extends StatefulWidget {
  final PlaceEntry place;
  final HaramainActions actions;
  const PlaceDetails({super.key, required this.place, required this.actions});
  @override
  State<PlaceDetails> createState() => _PlaceDetailsState();
}

class _PlaceDetailsState extends State<PlaceDetails> {
  bool saved = false;
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl,
    child: Scaffold(backgroundColor: kRifqaCream, appBar: AppBar(backgroundColor: kRifqaCream,
      title: Text(widget.place.title, style: const TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(children: [
        Stack(children: [
          SizedBox(height: 270, width: double.infinity, child: Image.asset(widget.place.mosque.image, fit: BoxFit.cover)),
          Positioned(bottom: 14, right: 14, child: Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
            child: Text(widget.place.mosque.city, style: const TextStyle(fontWeight: FontWeight.w800)))),
        ]),
        Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(widget.place.icon, color: widget.place.tone, size: 30), const SizedBox(width: 9),
            Expanded(child: Text(widget.place.title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)))]),
          const SizedBox(height: 12), Text(widget.place.subtitle, style: const TextStyle(color: Colors.black54, fontSize: 16)),
          const SizedBox(height: 18), Container(padding: const EdgeInsets.all(15), decoration: surface(),
            child: const Row(children: [Icon(Icons.info_outline, color: kRifqaGold), SizedBox(width: 10),
              Expanded(child: Text('هذه بطاقة معلومات؛ موقع المرفق ورقم بوابته ومساره غير محددين قبل إضافة بيانات رسمية موثقة.',
                style: TextStyle(fontSize: 12, height: 1.7)))])),
          const SizedBox(height: 20), Row(children: [
            Expanded(child: ElevatedButton.icon(onPressed: () async {
              if (widget.actions.navigateTo == null) { await message(context, 'الملاحة غير متصلة',
                'لم تتوفر إحداثيات ومسارات داخلية موثّقة لهذا المكان بعد.'); return; }
              try { await widget.actions.navigateTo!(widget.place.id); }
              catch (_) { if (context.mounted) await message(context, 'خطأ في التوجيه', 'تعذر عرض المسار.'); }
            }, icon: const Icon(Icons.near_me_outlined), label: const Text('اذهب إلى هنا'),
              style: ElevatedButton.styleFrom(backgroundColor: kRifqaGreen, foregroundColor: Colors.white,
                minimumSize: const Size(0, 52)))),
            const SizedBox(width: 10), IconButton.filledTonal(onPressed: () => setState(() => saved = !saved),
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border)),
          ]),
          const SizedBox(height: 10), if (saved) const Text('محفوظ في هذه الجلسة', style: TextStyle(color: kRifqaGreen)),
        ])),
      ])));
}

class HaramainSearch extends StatefulWidget {
  final HaramainActions actions;
  const HaramainSearch({super.key, required this.actions});
  @override State<HaramainSearch> createState() => _HaramainSearchState();
}
class _HaramainSearchState extends State<HaramainSearch> {
  String q = '';
  @override Widget build(BuildContext context) {
    final results = places.where((p) => '${p.title} ${p.subtitle} ${p.mosque.city}'.contains(q)).toList();
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(backgroundColor: kRifqaCream,
      appBar: AppBar(title: const Text('البحث في الحرمين'), backgroundColor: kRifqaCream),
      body: Column(children: [Padding(padding: const EdgeInsets.all(14), child: TextField(
        autofocus: true, onChanged: (text) => setState(() => q = text),
        decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'زمزم، الروضة، البوابات... ',
          filled: true, fillColor: Colors.white, border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)))),
        Expanded(child: ListView(children: [
          ...results.map((p) => ListTile(onTap: () => Navigator.push(context,
            MaterialPageRoute<void>(builder: (_) => PlaceDetails(place: p, actions: widget.actions))),
            leading: Icon(p.icon, color: p.tone), title: Text(p.title), subtitle: Text(p.mosque.label),
            trailing: const Icon(Icons.chevron_left))),
          if (results.isEmpty) const Padding(padding: EdgeInsets.all(35),
            child: Center(child: Text('لا توجد نتائج مطابقة'))),
        ])),
      ])));
  }
}

class LostPilgrimScreen extends StatelessWidget {
  final HaramainActions actions;
  const LostPilgrimScreen({super.key, required this.actions});
  Future<void> call(BuildContext context, Future<void> Function()? action, String label) async {
    if (action == null) return message(context, 'لم يتم الربط بعد', '$label يحتاج خدمة متصلة بحساب المستخدم والمجموعة وصلاحيات الموقع.');
    try { await action(); } catch (_) { if (context.mounted) await message(context, 'تعذّر الإرسال', 'تأكد من الاتصال وصلاحيات التطبيق.'); }
  }
  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl,
    child: Scaffold(backgroundColor: kRifqaCream, appBar: AppBar(title: const Text('أنا تائه'), backgroundColor: kRifqaCream),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(25)), child: const Column(children: [
            Icon(Icons.health_and_safety_outlined, color: Color(0xFFBF3030), size: 62), SizedBox(height: 12),
            Text('نحن هنا لمساعدتك', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
            SizedBox(height: 8), Text('يمكنك مشاركة موقعك مع المشرف أو الرجوع إلى نقطة التجمع المحددة لرحلتك.',
              textAlign: TextAlign.center, style: TextStyle(height: 1.8)),
          ])),
        const SizedBox(height: 22),
        actionTile(Icons.location_on_outlined, 'مشاركة موقعي مع المشرف', 'تحتاج إذن الموقع وربط المجموعة',
          () => call(context, actions.shareLiveLocation, 'مشاركة الموقع')),
        actionTile(Icons.groups_2_outlined, 'نقطة التجمع', 'عرض الموقع الذي يحدده مشرف الرحلة',
          () => call(context, actions.openMeetingPoint, 'نقطة التجمع')),
        actionTile(Icons.sos, 'إرسال طلب مساعدة', 'يتطلب إرسال الطلب لمشرف المجموعة',
          () => call(context, actions.requestHelp, 'إرسال SOS')),
        const SizedBox(height: 18),
        const Text('عند وجود خطر مباشر استخدم خدمات الطوارئ الرسمية المحلية. لا يُرسل التطبيق طلبًا تلقائيًا قبل ربط الخدمة.',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, height: 1.6)),
      ])));
}

Widget actionTile(IconData icon, String title, String subtitle, VoidCallback tap) => Padding(
  padding: const EdgeInsets.only(bottom: 12), child: Material(color: Colors.white,
    borderRadius: BorderRadius.circular(20), child: ListTile(onTap: tap,
      contentPadding: const EdgeInsets.all(12), leading: CircleAvatar(backgroundColor: const Color(0xFFE8F1EA),
        child: Icon(icon, color: kRifqaGreen)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)), trailing: const Icon(Icons.chevron_left))));

Widget homeMosqueCard(MosqueSite site, VoidCallback tap) => Container(
  padding: const EdgeInsets.all(9), decoration: surface(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset(site.image, height: 115, fit: BoxFit.cover)),
    const SizedBox(height: 9), FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight,
      child: Text(site.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
    Text(site.city, style: const TextStyle(fontSize: 12, color: Colors.black54)),
    const SizedBox(height: 9), Text(site.highlight, style: const TextStyle(fontSize: 11, color: kRifqaGreen)),
    const SizedBox(height: 10), SizedBox(height: 41, child: FilledButton.icon(onPressed: tap,
      style: FilledButton.styleFrom(backgroundColor: kRifqaGreen, padding: const EdgeInsets.symmetric(horizontal: 4)),
      icon: const Icon(Icons.near_me_outlined, size: 16),
      label: const FittedBox(fit: BoxFit.scaleDown, child: Text('استكشف المسجد', style: TextStyle(fontWeight: FontWeight.w800))))),
  ]));

Widget quickAction(IconData icon, String title, VoidCallback tap) => Expanded(child: Padding(
  padding: const EdgeInsets.symmetric(horizontal: 3), child: Material(color: const Color(0xFFFDFBF7),
    borderRadius: BorderRadius.circular(15), elevation: 3, child: InkWell(onTap: tap,
      borderRadius: BorderRadius.circular(15), child: SizedBox(height: 73,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: title == 'موقعي' ? kRifqaGreen : kRifqaGold), const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, child: Text(title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900))),
        ]))))));

Widget roundIcon(IconData icon, VoidCallback tap) => Material(
  color: const Color(0xFFFFFCF7), elevation: 2, borderRadius: BorderRadius.circular(16),
  child: InkWell(onTap: tap, borderRadius: BorderRadius.circular(16),
    child: SizedBox(width: 48, height: 48, child: Icon(icon, size: 26, color: kRifqaInk))));

Widget navItem(IconData icon, String title, bool active, VoidCallback tap) => Expanded(
  child: InkWell(onTap: tap, child: Container(padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(color: active ? const Color(0xFFECF1ED) : Colors.transparent,
      borderRadius: BorderRadius.circular(17)), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: active ? kRifqaGreen : Colors.black54),
      const SizedBox(height: 3), Text(title, style: TextStyle(color: active ? kRifqaGreen : Colors.black54,
        fontSize: 11, fontWeight: active ? FontWeight.w900 : FontWeight.w600)),
    ]))));

BoxDecoration surface() => BoxDecoration(color: Colors.white,
  borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF0EBE3)),
  boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 4))]);

Future<void> message(BuildContext context, String title, String detail) => showModalBottomSheet<void>(
  context: context, showDragHandle: true, isScrollControlled: true, builder: (ctx) => Directionality(
    textDirection: TextDirection.rtl, child: Padding(padding: const EdgeInsets.fromLTRB(23, 8, 23, 36),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kRifqaGreen)),
        const SizedBox(height: 10), Text(detail, style: const TextStyle(height: 1.8)),
        const SizedBox(height: 18), SizedBox(width: double.infinity, child: FilledButton(
          onPressed: () => Navigator.pop(ctx), style: FilledButton.styleFrom(backgroundColor: kRifqaGreen),
          child: const Text('حسنًا'))),
      ]))));
