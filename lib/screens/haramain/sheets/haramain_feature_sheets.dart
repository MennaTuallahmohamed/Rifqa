import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/haramain/haramain_map_demo_models.dart';
import '../../../services/haramain/haramain_verified_repository.dart';
import '../../../services/haramain/haramain_voice_service.dart';
import '../haramain_geo.dart';
import '../haramain_guide_content.dart';
import '../haramain_live_models.dart';
import '../haramain_live_store.dart';
import '../theme/haramain_ui.dart';
import 'haramain_sheet.dart';

void haramainCall(String n) => launchUrl(Uri.parse('tel:$n'));

Future<HlPoi?> showNearestPoiSheet(
  BuildContext c, {
  required String title,
  required List<(HlPoi, double)> items,
}) {
  return showHaramainSheet<HlPoi>(
    c,
    (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        haramainSheetTitle(title),
        const Text(
          'المسافة بخط مستقيم من موقعك، وليست مسار مشي موثّق.',
          style: TextStyle(fontSize: 12, color: HmUi.muted),
        ),
        for (final it in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(it.$1.category.icon, color: it.$1.category.color),
            title: Text(it.$1.title),
            subtitle: Text(
                '${HmGeo.meters(it.$2)} · ${it.$1.verified ? 'نقطة موثّقة' : 'غير موثّقة للملاحة'}'),
            onTap: () => Navigator.pop(ctx, it.$1),
          ),
      ],
    ),
  );
}

Future<void> showGuideSheet(
  BuildContext c, {
  required HaramainSite site,
  required HaramainLiveStore store,
  required HaramainVoiceService voice,
  required bool Function(String poiId) hasPoi,
  required void Function(String poiId) onShow,
}) {
  final steps = hlGuideFor(site);
  return showHaramainSheet<void>(c, (ctx) => StatefulBuilder(builder: (ctx, set) {
        final i =
            (store.guide[site.name] ?? 0).clamp(0, steps.length - 1).toInt();
        final s = steps[i];
        void go(int n) {
          store.setGuide(site, n.clamp(0, steps.length - 1).toInt());
          set(() {});
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            haramainSheetTitle(site == HaramainSite.makkah
                ? 'سياق العمرة'
                : 'سياق المسجد النبوي'),
            LinearProgressIndicator(
              value: (i + 1) / steps.length,
              minHeight: 6,
              color: HmUi.emerald,
              backgroundColor: HmUi.line,
            ),
            const SizedBox(height: 8),
            Text('الخطوة ${i + 1} من ${steps.length}',
                style: const TextStyle(color: HmUi.muted, fontSize: 12)),
            const SizedBox(height: 10),
            Text(s.title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(s.desc, style: const TextStyle(fontSize: 15, height: 1.6)),
            const SizedBox(height: 8),
            const Text(
              'هذا مرشد سياقي وليس مسار ملاحة. لا يُفتح طريق إلا إذا توفّر مسار موثّق.',
              style: TextStyle(fontSize: 12, color: HmUi.warn),
            ),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.tonalIcon(
                  onPressed: () => voice.speak(s.say),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('استمع')),
              if (s.poiId != null && hasPoi(s.poiId!))
                FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onShow(s.poiId!);
                    },
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('اعرض على الخريطة')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: i > 0 ? () => go(i - 1) : null,
                      child: const Text('السابق'))),
              const SizedBox(width: 10),
              Expanded(
                  child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: HmUi.emerald),
                      onPressed: i < steps.length - 1 ? () => go(i + 1) : null,
                      child: const Text('التالي'))),
            ]),
          ],
        );
      }));
}

Future<void> showCounterSheet(
  BuildContext c, {
  required HaramainSite site,
  required HaramainLiveStore store,
  required HaramainVoiceService voice,
  required bool voiceOn,
}) {
  String tHint(int v) => v == 0
      ? 'ابدأ من الحجر الأسود والكعبة عن يسارك.'
      : v >= 7
          ? 'أتممت سبعة أشواط. صلِّ ركعتين خلف المقام إن تيسر.'
          : 'الشوط ${v + 1}: بين اليماني والحجر الأسود قل: ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار.';
  String sHint(int v) => v == 0
      ? 'ابدأ من الصفا متجهًا إلى المروة.'
      : v >= 7
          ? 'أتممت السعي عند المروة.'
          : 'الشوط ${v + 1}: ${(v + 1).isOdd ? "من الصفا إلى المروة" : "من المروة إلى الصفا"}.';

  Widget card(String t, int v, void Function(int) set, String hint, String doneSay) =>
      Expanded(
        child: Card(
          elevation: 0,
          color: const Color(0xFFF4F7F5),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              Text(t, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('$v / 7',
                  style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.w800)),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton.filledTonal(
                    onPressed: v > 0 ? () => set(v - 1) : null,
                    icon: const Icon(Icons.remove)),
                const SizedBox(width: 12),
                IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: HmUi.emerald),
                    iconSize: 30,
                    onPressed: v < 7
                        ? () {
                            HapticFeedback.heavyImpact();
                            set(v + 1);
                            if (v + 1 == 7 && voiceOn) voice.speak(doneSay);
                          }
                        : null,
                    icon: const Icon(Icons.add)),
              ]),
              const SizedBox(height: 6),
              Text(hint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12)),
            ]),
          ),
        ),
      );

  return showHaramainSheet<void>(
      c,
      (ctx) => ListenableBuilder(
            listenable: store,
            builder: (ctx, _) {
              if (site != HaramainSite.makkah) {
                return Column(children: [
                  haramainSheetTitle('العدّاد'),
                  const Text(
                      'العدّاد خاص بالمسجد الحرام. في المسجد النبوي استخدم المرشد أو شاشة المدينة/الروضة.'),
                ]);
              }
              return Column(children: [
                haramainSheetTitle('عدّاد الطواف والسعي'),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  card('الطواف', store.tawaf, store.setTawaf, tHint(store.tawaf),
                      'أتممت الطواف. صلِّ ركعتين خلف مقام إبراهيم إن تيسر.'),
                  card('السعي', store.sai, store.setSai, sHint(store.sai),
                      'أتممت السعي. تقبل الله منك.'),
                ]),
                TextButton.icon(
                    onPressed: () {
                      store.setTawaf(0);
                      store.setSai(0);
                    },
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('تصفير العدّادين')),
              ]);
            },
          ));
}

Future<void> showPinsSheet(
  BuildContext c, {
  required HaramainSite site,
  required HaramainLiveStore store,
  required LatLng? me,
  required void Function(HlPin) onSelect,
}) {
  return showHaramainSheet<void>(
      c,
      (ctx) => ListenableBuilder(
            listenable: store,
            builder: (ctx, _) {
              final pins = store.pinsFor(site);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  haramainSheetTitle('أماكني'),
                  const Text(
                      'تُحفظ على جهازك. يمكن مزامنتها لاحقًا عبر الحساب دون مشاركة موقع مستمر.',
                      style: TextStyle(color: HmUi.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final k in HlPinKind.values
                        .where((k) => k != HlPinKind.custom))
                      ActionChip(
                        avatar: Icon(k.icon, size: 18),
                        label: Text(k.label),
                        onPressed: me == null
                            ? null
                            : () {
                                HapticFeedback.mediumImpact();
                                store.addPin(site, k, me);
                              },
                      ),
                  ]),
                  if (me == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                          'فعّل الموقع أو اضغط مطولًا على الخريطة لتثبيت مكان.'),
                    ),
                  const Divider(height: 24),
                  if (pins.isEmpty) const Text('لا توجد مواقع محفوظة بعد.'),
                  for (final p in pins)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(p.kind.icon, color: HmUi.emerald),
                      title: Text(p.label),
                      subtitle: me == null
                          ? Text(p.kind.label)
                          : Text(
                              '${HmGeo.meters(HmGeo.distance(me, p.position))} منك'),
                      onTap: () {
                        Navigator.pop(ctx);
                        onSelect(p);
                      },
                      trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => store.removePin(p.id)),
                    ),
                ],
              );
            },
          ));
}

Future<void> showLostSheet(
  BuildContext c, {
  required HaramainSite site,
  required HaramainLiveStore store,
  required LatLng? me,
  required double? accuracy,
  required List<HlPoi> pois,
  required VoidCallback onMyLocation,
  required VoidCallback onMyGate,
  required VoidCallback onMeeting,
  required VoidCallback onHotel,
  required VoidCallback onHelpCard,
}) {
  return showHaramainSheet<void>(
    c,
    (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        haramainSheetTitle('أنا تائه'),
        const Text(
          'خطوات بسيطة. لا تشارك موقعك المستمر دون موافقة صريحة.',
          style: TextStyle(color: HmUi.muted),
        ),
        const SizedBox(height: 12),
        _lostBtn(ctx, Icons.my_location_rounded, 'موقعي', onMyLocation),
        _lostBtn(ctx, Icons.door_sliding_outlined, 'بابي', onMyGate),
        _lostBtn(ctx, Icons.groups_outlined, 'نقطة التجمع', onMeeting),
        _lostBtn(ctx, Icons.hotel_outlined, 'الفندق', onHotel),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(
              backgroundColor: HmUi.emerald,
              minimumSize: const Size.fromHeight(50)),
          onPressed: store.leader.trim().isEmpty
              ? null
              : () => haramainCall(store.leader.trim()),
          icon: const Icon(Icons.phone_rounded),
          label: const Text('اتصل برفيق'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => haramainCall('997'),
          icon: const Icon(Icons.emergency_outlined),
          label: const Text('الإسعاف 997'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => haramainCall('999'),
          icon: const Icon(Icons.local_police_outlined),
          label: const Text('الشرطة 999'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () {
            Navigator.pop(ctx);
            onHelpCard();
          },
          icon: const Icon(Icons.badge_outlined),
          label: const Text('اعرض بطاقة المساعدة'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            final dest = store.pinOf(site, HlPinKind.meeting)?.label ??
                store.pinOf(site, HlPinKind.myGate)?.label ??
                store.hotel;
            final msg = StringBuffer()
              ..writeln('أنا تائه وأحتاج للمساعدة للوصول إلى ${dest.isEmpty ? site.title : dest}.')
              ..writeln(
                  'I am lost and need help reaching ${dest.isEmpty ? site.title : dest}.');
            if (store.name.isNotEmpty) msg.writeln('الاسم / Name: ${store.name}');
            if (me != null) {
              msg.writeln(
                  'https://maps.google.com/?q=${me.latitude.toStringAsFixed(6)},${me.longitude.toStringAsFixed(6)}');
              if (accuracy != null) {
                msg.writeln('دقة الموقع ±${accuracy.round()} م');
              }
            }
            Share.share(msg.toString());
          },
          icon: const Icon(Icons.share_rounded),
          label: const Text('شارك رسالة موقعي'),
        ),
      ],
    ),
  );
}

Widget _lostBtn(
    BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: HmUi.ivory,
      leading: Icon(icon, color: HmUi.emerald),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.chevron_left_rounded),
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
    ),
  );
}

Future<void> showHelpCardSheet(
  BuildContext c, {
  required HaramainSite site,
  required HaramainLiveStore store,
}) {
  final dest = store.pinOf(site, HlPinKind.meeting)?.label ??
      store.pinOf(site, HlPinKind.myGate)?.label ??
      (store.hotel.isEmpty ? site.title : store.hotel);
  return showHaramainSheet<void>(
    c,
    (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        haramainSheetTitle('بطاقة المساعدة'),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: HmUi.ivory,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: HmUi.gold, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                store.name.isEmpty ? 'حاج / معتمر' : store.name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'أنا تائه وأحتاج للمساعدة للوصول إلى:',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              Text(dest,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: HmUi.emerald)),
              const SizedBox(height: 16),
              const Text(
                'I am lost and need help reaching:',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              Text(dest,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              if (store.leader.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('رفيق / Companion: ${store.leader}'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => Share.share(
            'أنا تائه وأحتاج للمساعدة للوصول إلى $dest\nI am lost and need help reaching $dest',
          ),
          icon: const Icon(Icons.share_outlined),
          label: const Text('مشاركة البطاقة'),
        ),
      ],
    ),
  );
}

Future<void> showCardSheet(BuildContext c, {required HaramainLiveStore store}) {
  final n = TextEditingController(text: store.name);
  final ho = TextEditingController(text: store.hotel);
  final l = TextEditingController(text: store.leader);
  final m = TextEditingController(text: store.medical);
  void save() => store.saveCard(n: n.text, h: ho.text, l: l.text, m: m.text);
  Widget f(String lbl, TextEditingController ctl,
          {TextInputType? kb, int lines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: TextField(
          controller: ctl,
          keyboardType: kb,
          maxLines: lines,
          onChanged: (_) => save(),
          decoration: InputDecoration(
            labelText: lbl,
            filled: true,
            fillColor: HmUi.ivory,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );

  return showHaramainSheet<void>(
      c,
      (ctx) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              haramainSheetTitle('أرقام مهمة وبطاقتي'),
              FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(50)),
                  onPressed: () => haramainCall('997'),
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('الإسعاف 997')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () => haramainCall('999'),
                        icon: const Icon(Icons.local_police_rounded),
                        label: const Text('الشرطة 999'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () {
                          if (l.text.trim().isNotEmpty) {
                            haramainCall(l.text.trim());
                          }
                        },
                        icon: const Icon(Icons.phone_rounded),
                        label: const Text('رفيق'))),
              ]),
              const Divider(height: 28),
              const Text('تُحفظ على جهازك فقط',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              f('الاسم', n),
              f('الفندق ورقم الغرفة', ho),
              f('هاتف الرفيق / مسؤول الحملة', l, kb: TextInputType.phone),
              f('معلومات صحية', m, lines: 3),
            ],
          )).whenComplete(() {
    save();
    for (final x in [n, ho, l, m]) {
      x.dispose();
    }
  });
}

Future<void> showSettingsSheet(BuildContext c,
    {required HaramainLiveStore store, required VoidCallback onChanged}) {
  return showHaramainSheet<void>(
      c,
      (ctx) => ListenableBuilder(
            listenable: store,
            builder: (ctx, _) {
              final p = store.profile;
              Widget sw(String t, String sub, bool v, void Function(bool) f) =>
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle:
                        Text(sub, style: const TextStyle(fontSize: 12)),
                    value: v,
                    activeThumbColor: HmUi.emerald,
                    onChanged: (x) {
                      f(x);
                      onChanged();
                    },
                  );
              return Column(children: [
                haramainSheetTitle('إمكانية الوصول'),
                sw(
                    'وضع الكرسي المتحرك',
                    'يُستخدم مسار موثّق ميسّر فقط إن وُجد. لا يُستنتج التيسير.',
                    p.wheelchairMode,
                    (v) => store.setProfile(p.copyWith(wheelchairMode: v))),
                sw('خط أكبر', 'تكبير النصوص', p.largeText,
                    (v) => store.setProfile(p.copyWith(largeText: v))),
                sw('تباين عالٍ', 'حدود أوضح', p.highContrast,
                    (v) => store.setProfile(p.copyWith(highContrast: v))),
                sw(
                    'تقليل التعقيد البصري',
                    'إخفاء الطبقات الثانوية على الخريطة',
                    p.reduceVisualComplexity,
                    (v) => store
                        .setProfile(p.copyWith(reduceVisualComplexity: v))),
                sw('التوجيه الصوتي', 'نطق عربي عند الحاجة فقط', p.voiceGuidance,
                    (v) => store.setProfile(p.copyWith(voiceGuidance: v))),
              ]);
            },
          ));
}

Future<void> showVerifiedFactsSheet(
  BuildContext c, {
  required HaramainSite site,
  required HaramainVerifiedRepository verified,
}) {
  final loaded = site == HaramainSite.makkah && verified.isMakkahLoaded;
  return showHaramainSheet<void>(
    c,
    (ctx) {
      if (!loaded) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            haramainSheetTitle('بيانات موثّقة'),
            const Text(
              'لا توجد مجموعة إحداثيات موثّقة للمسجد النبوي في هذه النسخة. معلومات التيسير الرسمية متاحة حاليًا للمسجد الحرام كنصوص دون إسقاط على الخريطة.',
            ),
          ],
        );
      }
      final gates = verified.accessibleGates;
      final women = verified.womenServiceAccessGates;
      final prayer = verified.accessiblePrayerAreas;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          haramainSheetTitle('حقائق موثّقة — دون إحداثيات'),
          const Text(
            'مصدر رسمي. لا تُعرض كنقاط ملاحة لأن الإحداثيات غير مضمّنة.',
            style: TextStyle(color: HmUi.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          const Text('أبواب ميسّرة',
              style: TextStyle(fontWeight: FontWeight.w800)),
          Text('أبواب ${gates.map((g) => g['gateNumber']).join('، ')}'),
          const SizedBox(height: 10),
          const Text('مداخل خدمات النساء',
              style: TextStyle(fontWeight: FontWeight.w800)),
          Text('أبواب ${women.map((g) => g['gateNumber']).join('، ')}'),
          const SizedBox(height: 10),
          const Text('مصليات ميسّرة (وصف مكاني)',
              style: TextStyle(fontWeight: FontWeight.w800)),
          for (final a in prayer.take(8))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• ${a['locationDescriptionAr'] ?? a['areaAr'] ?? ''}'),
            ),
        ],
      );
    },
  );
}

Future<HlPinKind?> showSavePinKindSheet(BuildContext c) {
  return showHaramainSheet<HlPinKind>(
    c,
    (ctx) => Column(
      children: [
        haramainSheetTitle('ثبّت هذا المكان كـ'),
        for (final k in HlPinKind.values)
          ListTile(
            leading: Icon(k.icon, color: HmUi.emerald),
            title: Text(k.label),
            onTap: () => Navigator.pop(ctx, k),
          ),
      ],
    ),
  );
}

Future<void> showAssistantSheet(
  BuildContext c, {
  required void Function(String query) onSubmit,
}) {
  final ctl = TextEditingController();
  return showHaramainSheet<void>(
      c,
      (ctx) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              haramainSheetTitle('رِفقة، ساعديني'),
              const Text(
                'مساعد سياقي داخل التطبيق — ليس محادثة ذكاء اصطناعي مفتوحة.',
                style: TextStyle(color: HmUi.muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final q in const [
                  'أين أقرب دورة مياه؟',
                  'أين بابي؟',
                  'أريد نقطة التجمع',
                  'أنا تائه',
                  'أحتاج طريق مناسب للكرسي المتحرك',
                  'أين المياه؟',
                ])
                  ActionChip(
                    label: Text(q),
                    onPressed: () {
                      Navigator.pop(ctx);
                      onSubmit(q);
                    },
                  ),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: ctl,
                decoration: InputDecoration(
                  hintText: 'اكتب طلبًا قصيرًا...',
                  filled: true,
                  fillColor: HmUi.ivory,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: HmUi.emerald),
                onPressed: () {
                  final t = ctl.text.trim();
                  Navigator.pop(ctx);
                  if (t.isNotEmpty) onSubmit(t);
                },
                child: const Text('تنفيذ'),
              ),
            ],
          )).whenComplete(ctl.dispose);
}
