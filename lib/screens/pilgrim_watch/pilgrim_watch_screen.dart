import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/pilgrim_watch/watch_store.dart';
import 'watch_ui.dart';
import 'watch_settings_page.dart';
import 'watch_journey_page.dart';
import 'watch_alarms_page.dart';
import 'watch_group_page.dart';
import 'watch_qibla_page.dart';
import 'watch_prayer_page.dart';

/// Entry point: Navigator.push(context, MaterialPageRoute(
///   builder: (_) => const RifqaPilgrimWatchScreen()));
/// This is a premium PHONE-based companion, not a Wear OS app.
class RifqaPilgrimWatchScreen extends StatefulWidget {
  const RifqaPilgrimWatchScreen({super.key});
  @override State<RifqaPilgrimWatchScreen> createState() => _RifqaPilgrimWatchScreenState();
}

class _RifqaPilgrimWatchScreenState extends State<RifqaPilgrimWatchScreen> {
  final store = RifqaWatchStore.instance;
  Timer? ticker;
  DateTime now = DateTime.now();
  @override void initState() {
    super.initState();
    store.addListener(_refresh);
    store.load();
    ticker = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }
  @override void dispose() { ticker?.cancel(); store.removeListener(_refresh); super.dispose(); }
  void _refresh() { if (mounted) setState(() {}); }
  void _open(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  void _dhikr() => showModalBottomSheet<void>(context: context,
    isScrollControlled: true, backgroundColor: RW.black,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
      padding: const EdgeInsets.all(22), child: SafeArea(top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('مسبحة رِفقة', style: RW.style(25, weight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text('اختاري الذكر وعدّي بنفسك دون تحديد فضل مخصوص لعدد معيّن.',
            style: RW.style(12, color: RW.muted), textAlign: TextAlign.center),
          const SizedBox(height: 15),
          Wrap(spacing: 7, children: [for (final s in const ['سبحان الله','الحمد لله','الله أكبر','أستغفر الله'])
            ChoiceChip(label: Text(s), selected: store.dhikrText == s,
              selectedColor: RW.gold, backgroundColor: RW.green,
              labelStyle: RW.style(11, color: store.dhikrText == s ? RW.black : RW.ivory),
              onSelected: (_) async {
                await store.change(() { store.dhikrText = s; store.dhikrCount = 0; });
                setSheet(() {});
              }),
          ]),
          const SizedBox(height: 16),
          Material(color: RW.green2, shape: const CircleBorder(),
            child: InkWell(customBorder: const CircleBorder(), onTap: () async {
              await store.change(() => store.dhikrCount++);
              if (store.haptics) HapticFeedback.selectionClick();
              setSheet(() {});
            }, child: SizedBox(width: 170, height: 170, child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${store.dhikrCount}', style: RW.style(46, color: RW.lightGold,
                  weight: FontWeight.w900)),
                Text('اضغطي للتسبيح', style: RW.style(11)),
              ])))),
          const SizedBox(height: 12),
          Text(store.dhikrText, style: RW.style(23, color: RW.gold)),
          TextButton.icon(onPressed: () async { await store.change(() => store.dhikrCount = 0);
            setSheet(() {}); }, icon: const Icon(Icons.restart_alt), label: const Text('تصفير العدّاد')),
        ])))));

  Widget _stat(IconData icon, String value, String label, VoidCallback tap) => Expanded(
    child: InkWell(onTap: tap, borderRadius: BorderRadius.circular(20),
      child: WatchPanel(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 17),
        child: Column(children: [
          Icon(icon, color: RW.gold, size: 25), const SizedBox(height: 7),
          FittedBox(child: Text(value, style: RW.style(21,
            color: RW.lightGold, weight: FontWeight.w900))),
          Text(label, style: RW.style(10, color: RW.muted), textAlign: TextAlign.center),
        ]))));

  Widget _mainHeader() => Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
    child: Row(children: [
      IconButton(onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_forward_ios_rounded, color: RW.ivory)),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ساعة رِفقة', style: RW.style(27, weight: FontWeight.w900,
          color: RW.lightGold)),
        Text('للحاج والمعتمر • رفيقك في كل خطوة', style: RW.style(11)),
      ])),
      IconButton(tooltip: 'الإعدادات', onPressed: () => _open(const RifqaWatchSettingsPage()),
        icon: const Icon(Icons.settings_rounded, color: RW.gold, size: 27)),
    ]));

  Widget _journeyWidget() {
    final j = store.journey;
    final count = j.type == 'umrah' ? 8 : 9;
    final step = j.step.clamp(0, count);
    return WatchPanel(glow: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Row(children: [
        const Icon(Icons.mosque_rounded, color: RW.gold, size: 28),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(j.type == 'umrah' ? 'رحلة العمرة' : 'رحلة الحج',
            style: RW.style(17, weight: FontWeight.w900)),
          Text('محاكاة تعليمية • ${j.step} من $count مراحل', style: RW.style(11, color: RW.muted)),
        ])),
        IconButton(onPressed: () => _open(const RifqaWatchJourneyPage()),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RW.gold)),
      ]),
      const SizedBox(height: 10),
      ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(
        value: step / count, minHeight: 8, backgroundColor: Colors.white12, color: RW.gold)),
      const SizedBox(height: 12),
      if (j.type == 'umrah') Row(children: [
        const Icon(Icons.autorenew, color: RW.jade, size: 21),
        Text('الطواف ${j.tawafLaps}/7', style: RW.style(12)),
        const Spacer(), const Icon(Icons.directions_walk, color: RW.jade, size: 21),
        Text('السعي ${j.saiLaps}/7', style: RW.style(12)),
      ]) else Text('اختاري مناسك الحج للاطلاع على المراحل حسب النسك.',
        style: RW.style(12, color: RW.muted)),
      const SizedBox(height: 14),
      WatchPrimaryButton(label: 'متابعة مراحل المناسك', icon: Icons.route,
        onTap: () => _open(const RifqaWatchJourneyPage())),
    ]));
  }

  Widget _photoHero() => Container(height: 132,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(23),
      image: const DecorationImage(image: AssetImage('assets/rifqa_watch/madinah.jpg'), fit: BoxFit.cover),
      border: Border.all(color: RW.gold.withOpacity( .45))),
    clipBehavior: Clip.antiAlias,
    child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.centerRight, end: Alignment.centerLeft,
      colors: [RW.black.withOpacity( .88), Colors.transparent])),
      child: Padding(padding: const EdgeInsets.all(17), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('رفيقك في رحلتك', style: RW.style(21, color: RW.lightGold,
            weight: FontWeight.w900)),
          Text('وقتك • مناسكك • مجموعتك • سلامتك', style: RW.style(11)),
          const SizedBox(height: 9),
          const Icon(Icons.arrow_back_rounded, color: RW.gold),
        ]))),
  );

  @override Widget build(BuildContext context) {
    final dt = store.displayedTime(now);
    return WatchGradientScaffold(topPhoto: true,
      child: !store.ready ? const Center(child: CircularProgressIndicator(color: RW.gold))
      : Column(children: [
        _mainHeader(),
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), children: [
          _photoHero(), const SizedBox(height: 20),
          WatchSectionTitle('ساعتك الذكية', trailing: Text(
            store.makkahTime ? 'مكة المكرمة' : 'توقيت الهاتف',
            style: RW.style(11, color: RW.lightGold))),
          const SizedBox(height: 12),
          Center(child: Opacity(opacity: store.brightness,
            child: RifqaWatchFace(store: store, now: dt,
              onTap: () => _open(const RifqaWatchSettingsPage())))),
          const SizedBox(height: 10),
          Text('واجهة ساعة داخل الموبايل • ليست متصلة بساعة Wear OS حاليًا',
            textAlign: TextAlign.center, style: RW.style(11, color: RW.muted)),
          const SizedBox(height: 19),
          Row(children: [
            _stat(Icons.notifications_active_outlined, '${store.alarms.where((a) => a.enabled).length}',
              'منبّهات مفعّلة', () => _open(const RifqaWatchAlarmsPage())),
            const SizedBox(width: 9),
            _stat(Icons.water_drop_outlined, '${store.todaysWaterCups}',
              'أكواب سجلتيها', () => store.addWaterCup()),
            const SizedBox(width: 9),
            _stat(Icons.touch_app_outlined, '${store.dhikrCount}',
              'تسبيحاتك', _dhikr),
          ]),
          const SizedBox(height: 21),
          _journeyWidget(), const SizedBox(height: 20),
          WatchSectionTitle('أدوات رحلتك'), const SizedBox(height: 12),
          GridView.count(crossAxisCount: 2, childAspectRatio: 1.25,
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 9, mainAxisSpacing: 9, children: [
            WatchAction(icon: Icons.alarm_add_rounded, title: 'منبّه المناسك',
              caption: 'موعد + تذكير مسبق', onTap: () => _open(const RifqaWatchAlarmsPage())),
            WatchAction(icon: Icons.explore_outlined, title: 'اتجاه القبلة',
              caption: 'من الموقع والبوصلة', onTap: () => _open(const RifqaWatchQiblaPage())),
            WatchAction(icon: Icons.groups_2_outlined, title: 'فوجي وغرفتي',
              caption: 'مرافقيّ وأرقام الفندق', onTap: () => _open(const RifqaWatchGroupPage())),
            WatchAction(icon: Icons.menu_book_rounded, title: 'مسبحة وأذكار',
              caption: 'عداد تسبيح محفوظ', onTap: _dhikr),
            WatchAction(icon: Icons.settings_suggest_rounded, title: 'ضبط الساعة',
              caption: 'واجهة • وقت • خط • هدوء', onTap: () => _open(const RifqaWatchSettingsPage())),
            WatchAction(icon: Icons.mosque_rounded, title: 'مواقيت الصلاة',
              caption: 'حساب بموقعك بعد الموافقة', onTap: () => _open(const RifqaWatchPrayerPage())),
            WatchAction(icon: Icons.water_drop_rounded, title: 'شرب الماء',
              caption: 'اضغطي لتسجيل كوب', accent: RW.jade,
              onTap: () async {
                await store.addWaterCup();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('سجلنا كوبًا؛ الإجمالي اليوم ${store.todaysWaterCups}.')));
              }),
          ]),
          const SizedBox(height: 20),
          WatchSectionTitle('مساعدة سريعة'), const SizedBox(height: 10),
          WatchPanel(color: const Color(0xFF4A1B20), glow: true,
            child: Column(children: [
              Row(children: [
                const Icon(Icons.sos_rounded, color: Color(0xFFFF8075), size: 42),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('تايهة أو محتاجة مساعدة؟', style: RW.style(16, weight: FontWeight.w900)),
                  Text('افتحي أرقام الفندق والمرافقين أو اختاري الطوارئ',
                    style: RW.style(11, color: RW.muted)),
                ])),
              ]),
              const SizedBox(height: 11),
              WatchPrimaryButton(label: 'مساعدة ومعلومات رحلتي', icon: Icons.phone_in_talk,
                onTap: () => _open(const RifqaWatchGroupPage())),
            ])),
          const SizedBox(height: 17),
          WatchPanel(child: Column(children: [
            Row(children: [const Icon(Icons.info_outline, color: RW.gold),
              const SizedBox(width: 10),
              Expanded(child: Text('المواقيت والطاقة والخطوات الحقيقية',
                style: RW.style(14, weight: FontWeight.w800)))]),
            const SizedBox(height: 7),
            Text('لا نعرض عدد خطوات أو نبضًا أو نسبة زحام غير مقاسة. يمكن حساب مواقيت الصلاة من موقعك بإذنك، وتظل بحاجة للمراجعة مع الجدول الرسمي.',
              style: RW.style(12, color: RW.muted)),
          ])),
          const SizedBox(height: 23),
          Center(child: Text('رِفقة • رفيقك في كل خطوة',
            style: RW.style(12, color: RW.lightGold))),
        ])),
      ]),
    );
  }
}
