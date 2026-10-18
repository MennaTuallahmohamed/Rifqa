import 'package:flutter/material.dart';
import '../../services/pilgrim_watch/watch_store.dart';
import '../../services/pilgrim_watch/watch_notifications.dart';
import 'watch_ui.dart';

class RifqaWatchAlarmsPage extends StatefulWidget {
  const RifqaWatchAlarmsPage({super.key});
  @override State<RifqaWatchAlarmsPage> createState() => _RifqaWatchAlarmsPageState();
}

class _RifqaWatchAlarmsPageState extends State<RifqaWatchAlarmsPage> {
  final store = RifqaWatchStore.instance;
  bool busy = false;
  static const days = ['الإثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت','الأحد'];

  @override void initState() { super.initState(); store.addListener(_updated); store.load(); }
  @override void dispose() { store.removeListener(_updated); super.dispose(); }
  void _updated() { if (mounted) setState(() {}); }

  Future<void> _write(PilgrimWatchAlarm alarm) async {
    setState(() => busy = true);
    try {
      var next = alarm;
      if (alarm.enabled) {
        final authorized = await RifqaWatchNotifications.instance.askPermission();
        if (!authorized) {
          next = alarm.copyWith(enabled: false);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('الإشعارات غير مسموحة: حفظنا المنبّه متوقفًا. فعّلي إذن الإشعارات ثم شغّليه.')));
        }
      }
      await store.putAlarm(next);
      await RifqaWatchNotifications.instance.schedule(next, quietMode: store.quietMode);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(next.enabled ? 'تم جدولة التذكير بتوقيت مكة' : 'تم حفظ التذكير متوقفًا')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تعذرت جدولة الإشعار: $e')));
      await store.putAlarm(alarm.copyWith(enabled: false));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _editor([PilgrimWatchAlarm? initial]) async {
    final ctrl = TextEditingController(text: initial?.title ?? '');
    var time = TimeOfDay(hour: initial?.hour ?? 8, minute: initial?.minute ?? 0);
    var selectedDays = List<int>.from(initial?.days ?? [1,2,3,4,5,6,7]);
    var advance = initial?.earlyMinutes ?? 10;
    var important = initial?.important ?? false;
    var kind = initial?.kind ?? 'custom';
    try {
      final result = await showModalBottomSheet<PilgrimWatchAlarm>(
        context: context, isScrollControlled: true, backgroundColor: RW.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (modalContext) => StatefulBuilder(builder: (context, update) =>
          Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Text(initial == null ? 'منبّه ذكي جديد' : 'تعديل المنبّه',
                style: RW.style(24, weight: FontWeight.w900))),
              const SizedBox(height: 16),
              TextField(controller: ctrl, maxLength: 60, style: RW.style(16),
                decoration: _field('اسم التذكير: مثل موعد الباص')),
              Wrap(spacing: 6, children: [
                for (final tpl in const [
                  ('التحرك للفوج', 'group'), ('مياه زمزم', 'water'),
                  ('تناول الدواء', 'medicine'), ('موعد الصلاة', 'prayer'),
                ]) ActionChip(
                  label: Text(tpl.$1, style: RW.style(11, color: RW.ink)),
                  onPressed: () => update(() { ctrl.text = tpl.$1; kind = tpl.$2; })),
              ]),
              const SizedBox(height: 12),
              WatchPanel(child: Row(children: [
                const Icon(Icons.schedule, color: RW.gold, size: 28),
                const SizedBox(width: 10),
                Expanded(child: Text('الوقت بتوقيت مكة', style: RW.style(15))),
                TextButton(onPressed: () async {
                  final picked = await showTimePicker(context: context, initialTime: time);
                  if (picked != null) update(() => time = picked);
                }, child: Text(time.format(context), style: RW.style(18, color: RW.lightGold))),
              ])),
              const SizedBox(height: 12),
              Text('أيام التكرار', style: RW.style(14)),
              Wrap(spacing: 6, runSpacing: 5, children: [for (var i = 0; i < 7; i++)
                FilterChip(label: Text(days[i]), selected: selectedDays.contains(i+1),
                  onSelected: (value) => update(() {
                    value ? selectedDays.add(i+1) : selectedDays.remove(i+1);
                  }), selectedColor: RW.gold,
                  labelStyle: RW.style(11, color: selectedDays.contains(i+1) ? RW.black : RW.ivory),
                  backgroundColor: RW.green, checkmarkColor: RW.black),
              ]),
              const SizedBox(height: 12),
              Text('تنبيه للاستعداد قبل الموعد', style: RW.style(14)),
              Wrap(spacing: 7, children: [for (final m in [0, 5, 10, 15, 30])
                ChoiceChip(label: Text(m == 0 ? 'بدون' : '$m دقيقة'), selected: advance == m,
                  onSelected: (_) => update(() => advance = m),
                  selectedColor: RW.gold, backgroundColor: RW.green,
                  labelStyle: RW.style(11, color: advance == m ? RW.black : RW.ivory)),
              ]),
              SwitchListTile.adaptive(value: important,
                onChanged: (v) => update(() => important = v),
                title: Text('تنبيه مهم', style: RW.style(14)),
                subtitle: Text('يظل مجدولًا عند تفعيل هدوء التنبيهات العادية',
                  style: RW.style(10, color: RW.muted)), activeTrackColor: RW.gold),
              const SizedBox(height: 12),
              WatchPrimaryButton(label: 'حفظ المنبّه', icon: Icons.check_circle,
                onTap: () {
                  if (ctrl.text.trim().isEmpty || selectedDays.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('أدخلي اسمًا واختاري يومًا واحدًا على الأقل')));
                    return;
                  }
                  final id = initial?.id ?? (store.alarms.isEmpty ? 101
                    : store.alarms.map((e) => e.id).reduce((a,b) => a > b ? a : b)+1);
                  Navigator.pop(context, PilgrimWatchAlarm(
                    id: id, title: ctrl.text.trim(), hour: time.hour, minute: time.minute,
                    days: selectedDays, earlyMinutes: advance, important: important,
                    kind: kind));
                }),
            ])))),
      );
      if (result != null) await _write(result);
    } finally { ctrl.dispose(); }
  }

  InputDecoration _field(String hint) => InputDecoration(
    hintText: hint, hintStyle: RW.style(13, color: RW.muted),
    filled: true, fillColor: RW.green,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: RW.gold)));

  Future<void> _snooze(PilgrimWatchAlarm alarm) async {
    try {
      final allow = await RifqaWatchNotifications.instance.askPermission();
      if (!allow) throw StateError('إذن إشعارات الجهاز غير متاح');
      await RifqaWatchNotifications.instance.postpone(alarm, store.snoozeMinutes);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تمت جدولة تذكير آخر بعد ${store.snoozeMinutes} دقيقة تقريبًا')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تعذّر التأجيل: $e')));
    }
  }

  Future<void> _delete(PilgrimWatchAlarm alarm) async {
    await RifqaWatchNotifications.instance.cancelAlarm(alarm);
    await store.removeAlarm(alarm.id);
  }

  @override Widget build(BuildContext context) => WatchGradientScaffold(topPhoto: true,
    child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 10), child: Row(children: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_forward, color: RW.ivory)),
        Expanded(child: Text('منبّه رِفقة الذكي', style: RW.style(23, weight: FontWeight.w900))),
        const Icon(Icons.notifications_active, color: RW.gold, size: 30),
      ])),
      Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 18), children: [
        const SizedBox(height: 18),
        WatchPanel(glow: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('أكثر من مجرد منبّه', style: RW.style(18, weight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text('اختاري المهمة ووقت الاستعداد وأيام التكرار. الإشعارات تتجدول بتوقيت مكة بعد السماح بها.',
            style: RW.style(12, color: RW.muted)),
          const SizedBox(height: 8),
          Text('التذكير ليس إنذارًا مضمونًا بالدقيقة، ولا بديلًا عن منبّه الهاتف الأساسي.',
            style: RW.style(10, color: RW.lightGold)),
        ])),
        const SizedBox(height: 22),
        WatchSectionTitle('منبّهاتي', trailing: Text('${store.alarms.length}',
          style: RW.style(15, color: RW.gold))),
        const SizedBox(height: 12),
        if (store.alarms.isEmpty) WatchPanel(child: Column(children: [
          const Icon(Icons.alarm_add_rounded, size: 42, color: RW.gold),
          const SizedBox(height: 8),
          Text('لسه ما عندكيش منبّهات', style: RW.style(16)),
          Text('ابدئي بتنبيه وقت الباص أو الدواء أو الشرب', style: RW.style(11, color: RW.muted)),
        ])),
        for (final alarm in store.alarms) ...[
          WatchPanel(child: Column(children: [
            Row(children: [
              Icon(alarm.important ? Icons.priority_high_rounded : Icons.notifications_none,
                color: alarm.important ? RW.gold : RW.jade),
              const SizedBox(width: 9),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(alarm.title, style: RW.style(17, weight: FontWeight.w800)),
                Text('${alarm.hour.toString().padLeft(2,'0')}:${alarm.minute.toString().padLeft(2,'0')} — مكة',
                  style: RW.style(20, color: RW.lightGold, weight: FontWeight.w900)),
              ])),
              Switch.adaptive(value: alarm.enabled && !busy, activeTrackColor: RW.gold,
                onChanged: busy ? null : (v) => _write(alarm.copyWith(enabled: v))),
            ]),
            Text('${alarm.days.map((d) => days[d-1]).join(' • ')}  ·  قبلها ${alarm.earlyMinutes} دقيقة',
              style: RW.style(11, color: RW.muted)),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton.icon(onPressed: () => _editor(alarm), icon: const Icon(Icons.edit, size: 16),
                label: const Text('تعديل')),
              TextButton.icon(onPressed: () => _snooze(alarm),
                icon: const Icon(Icons.snooze, size: 16), label: const Text('تذكير لاحق')),
              TextButton.icon(onPressed: () => _delete(alarm),
                icon: const Icon(Icons.delete_outline, size: 16), label: const Text('حذف')),
            ]),
          ])), const SizedBox(height: 9),
        ],
        const SizedBox(height: 16),
        WatchPrimaryButton(label: 'إضافة منبّه جديد', icon: Icons.add_alarm,
          onTap: busy ? () {} : () => _editor()),
        const SizedBox(height: 24),
      ])),
    ]));
}
