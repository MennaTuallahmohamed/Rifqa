import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/pilgrim_watch/watch_notifications.dart';
import '../../services/pilgrim_watch/watch_store.dart';
import 'watch_ui.dart';

class RifqaWatchSettingsPage extends StatefulWidget {
  const RifqaWatchSettingsPage({super.key});
  @override State<RifqaWatchSettingsPage> createState() => _RifqaWatchSettingsPageState();
}
class _RifqaWatchSettingsPageState extends State<RifqaWatchSettingsPage> {
  final store = RifqaWatchStore.instance;
  @override void initState() { super.initState(); store.addListener(_refresh); store.load(); }
  @override void dispose() { store.removeListener(_refresh); super.dispose(); }
  void _refresh() { if (mounted) setState(() {}); }
  Future<void> _setQuiet(bool val) async {
    await store.change(() => store.quietMode = val);
    try { await RifqaWatchNotifications.instance.refresh(store); } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تعذّر تحديث بعض إشعارات الجهاز: $e')));
    }
  }
  Widget _switch(String title, String subtitle, bool value, ValueChanged<bool> onChange) =>
    SwitchListTile.adaptive(value: value, onChanged: onChange,
      activeTrackColor: RW.gold,
      title: Text(title, style: RW.style(14, weight: FontWeight.w800)),
      subtitle: Text(subtitle, style: RW.style(10, color: RW.muted)));

  @override Widget build(BuildContext context) {
    final now = store.displayedTime();
    return WatchGradientScaffold(topPhoto: true, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10), child: Row(children: [
        IconButton(onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_forward, color: RW.ivory)),
        Expanded(child: Text('تخصيص ساعة رِفقة', style: RW.style(23, weight: FontWeight.w900))),
        const Icon(Icons.settings_suggest, color: RW.gold, size: 29),
      ])),
      Expanded(child: ListView(padding: const EdgeInsets.all(18), children: [
        WatchSectionTitle('واجهة الساعة'), const SizedBox(height: 9),
        WatchPanel(glow: true, child: Column(children: [
          SizedBox(height: 244, child: Center(child: Opacity(opacity: store.brightness,
            child: RifqaWatchFace(store: store, now: now)))),
          const SizedBox(height: 11),
          Row(children: [for (final pair in const [(0,'سينمائية'),(1,'كلاسيكية'),(2,'هادئة')])
            Expanded(child: Padding(padding: const EdgeInsets.all(3), child: ChoiceChip(
              label: Text(pair.$2), selected: store.face == pair.$1,
              selectedColor: RW.gold, backgroundColor: RW.green,
              labelStyle: RW.style(10, color: store.face == pair.$1 ? RW.black : RW.ivory),
              onSelected: (_) => store.change(() => store.face = pair.$1)))),
          ]),
          Text('السطوع هنا يخص معاينة واجهة الهاتف، ولا يغيّر سطوع ساعة خارجية.',
            style: RW.style(10, color: RW.muted), textAlign: TextAlign.center),
          Slider(value: store.brightness, min: .3, max: 1, divisions: 7,
            activeColor: RW.gold, onChanged: (v) => store.change(() => store.brightness = v)),
        ])),
        const SizedBox(height: 19),
        WatchSectionTitle('الوقت والتنسيق'), const SizedBox(height: 10),
        WatchPanel(child: Column(children: [
          _switch('نظام 24 ساعة', 'بدل العرض بنظام 12 ساعة', store.is24Hour,
            (v) => store.change(() => store.is24Hour = v)),
          _switch('توقيت مكة', 'عند الإيقاف يُعرض توقيت الجهاز الحالي', store.makkahTime,
            (v) => store.change(() => store.makkahTime = v)),
          const Divider(color: Colors.white24),
          Text('إزاحة ساعة المعاينة فقط', style: RW.style(13)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            IconButton.filledTonal(onPressed: () => store.change(() =>
              store.displayOffsetMinutes = (store.displayOffsetMinutes - 5).clamp(-720,720).toInt()),
              icon: const Icon(Icons.remove)),
            Text('${store.displayOffsetMinutes >= 0 ? '+' : ''}${store.displayOffsetMinutes} دقيقة',
              style: RW.style(15, color: RW.gold)),
            IconButton.filledTonal(onPressed: () => store.change(() =>
              store.displayOffsetMinutes = (store.displayOffsetMinutes + 5).clamp(-720,720).toInt()),
              icon: const Icon(Icons.add)),
            TextButton(onPressed: () => store.change(() => store.displayOffsetMinutes = 0),
              child: const Text('إعادة')),
          ]),
          Text('لا يتم تعديل ساعة الهاتف أو توقيت المنبّهات. جميع المنبّهات بتوقيت مكة.',
            style: RW.style(10, color: RW.muted)),
        ])),
        const SizedBox(height: 19),
        WatchSectionTitle('الراحة وإمكانية الوصول'), const SizedBox(height: 10),
        WatchPanel(child: Column(children: [
          _switch('خط كبير لكبار السن', 'أزرار ومعلومات أسهل في القراءة', store.largeText,
            (v) => store.change(() => store.largeText = v)),
          _switch('اهتزاز تجريبي', 'داخل الهاتف عند الضغط فقط', store.haptics,
            (v) => store.change(() => store.haptics = v)),
          Row(children: [
            Expanded(child: Text('قوة اهتزاز المعاينة', style: RW.style(13))),
            DropdownButton<int>(dropdownColor: RW.green, value: store.vibration,
              style: RW.style(12), underline: const SizedBox(),
              items: const [DropdownMenuItem(value:0,child:Text('بدون')),
                DropdownMenuItem(value:1,child:Text('خفيف')),
                DropdownMenuItem(value:2,child:Text('أقوى'))],
              onChanged: (v) { if (v != null) store.change(() => store.vibration = v); }),
            IconButton(icon: const Icon(Icons.vibration, color: RW.gold),
              onPressed: () {
                if (!store.haptics) return;
                if (store.vibration == 2) {
                  HapticFeedback.heavyImpact();
                } else if (store.vibration == 1) {
                  HapticFeedback.lightImpact();
                }
              }),
          ]),
          Text('الاهتزاز هنا للمعاينة على الهاتف، وليس تحكمًا في جهاز Wear OS.',
            style: RW.style(10, color: RW.muted)),
        ])),
        const SizedBox(height: 19),
        WatchSectionTitle('تنبيهات رحلتك'), const SizedBox(height: 10),
        WatchPanel(child: Column(children: [
          _switch('الوضع الهادئ', 'يوقف التنبيهات العادية المجدولة من رِفقة مع بقاء المهمة المهمة',
            store.quietMode, _setQuiet),
          const Divider(color: Colors.white24),
          Row(children: [
            Expanded(child: Text('تأجيل تذكير بضغطة', style: RW.style(13))),
            DropdownButton<int>(dropdownColor: RW.green, value: store.snoozeMinutes,
              style: RW.style(12), underline: const SizedBox(),
              items: const [5,10,15,30].map((v) => DropdownMenuItem(
                value: v, child: Text('$v دقيقة'))).toList(),
              onChanged: (v) { if (v != null) store.change(() => store.snoozeMinutes = v); }),
          ]),
          Text('جدولة إشعارات Android قد تتأخر حسب إدارة الطاقة وإذن الإشعارات.',
            style: RW.style(11, color: RW.muted)),
        ])),
        const SizedBox(height: 20),
      ])),
    ]));
  }
}
