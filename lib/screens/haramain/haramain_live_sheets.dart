import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'haramain_guide_content.dart';
import 'haramain_live_models.dart';
import '../../models/haramain/haramain_map_demo_models.dart';
import 'haramain_geo.dart';
import 'haramain_live_store.dart';
import '../../services/haramain/haramain_voice_service.dart';

const _emerald = Color(0xFF075B4A);

Future<T?> _sheet<T>(BuildContext c, Widget Function(BuildContext) b) =>
    showModalBottomSheet<T>(
      context: c,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              18, 0, 18, 16 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(child: b(ctx)),
        ),
      ),
    );

Widget _h(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(t,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
    );

void _call(String n) => launchUrl(Uri.parse('tel:$n'));

// ═══════════ البحث ═══════════
Future<HlPoi?> showSearchSheet(BuildContext c, {required List<HlPoi> pois}) {
  final ctl = TextEditingController();
  return _sheet<HlPoi>(c, (ctx) => StatefulBuilder(builder: (ctx, set) {
        final res = pois.where((p) => p.matches(ctl.text)).take(30).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: ctl,
            autofocus: true,
            onChanged: (_) => set(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث: باب 79، دورة مياه، مصعد...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 8),
          if (pois.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                  'لا توجد نقاط موثّقة لهذا الحرم بعد. يمكنك تثبيت أماكنك (فندقي، بابي...) من زر «مواقعي».'),
            ),
          for (final p in res)
            ListTile(
              leading: Text(p.emoji, style: const TextStyle(fontSize: 26)),
              title: Text(p.title),
              subtitle: Text(p.subtitle.isEmpty ? p.category.label : p.subtitle),
              trailing: p.verified
                  ? const Icon(Icons.verified_rounded, color: _emerald, size: 20)
                  : null,
              onTap: () => Navigator.pop(ctx, p),
            ),
        ]);
      }));
}

// ═══════════ اختيار الأقرب ═══════════
Future<HlPoi?> showNearestSheet(BuildContext c,
    {required String title, required List<(HlPoi, double)> items}) {
  return _sheet<HlPoi>(c, (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _h(title),
          const Text('المسافة بخط مستقيم من موقعك الحالي.',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
          for (final it in items)
            ListTile(
              leading: Text(it.$1.emoji, style: const TextStyle(fontSize: 28)),
              title: Text(it.$1.title),
              subtitle: Text(
                  '${HmGeo.meters(it.$2)} · نحو ${(it.$2 / 60).ceil().clamp(1, 999)} دقيقة'),
              trailing: const Icon(Icons.directions_walk_rounded),
              onTap: () => Navigator.pop(ctx, it.$1),
            ),
        ],
      ));
}

// ═══════════ المرشد ═══════════
Future<void> showGuideSheet(
  BuildContext c, {
  required HaramainSite site,
  required HaramainLiveStore store,
  required HaramainVoiceService voice,
  required bool Function(String poiId) hasPoi,
  required void Function(String poiId) onShow,
}) {
  final steps = hlGuideFor(site);
  return _sheet<void>(c, (ctx) => StatefulBuilder(builder: (ctx, set) {
        final i = (store.guide[site.name] ?? 0).clamp(0, steps.length - 1).toInt();
        final s = steps[i];
        void go(int n) {
          store.setGuide(site, n.clamp(0, steps.length - 1).toInt());
          set(() {});
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _h(site == HaramainSite.makkah ? 'رحلة العمرة' : 'زيارة المسجد النبوي'),
          LinearProgressIndicator(value: (i + 1) / steps.length, minHeight: 6),
          const SizedBox(height: 4),
          Text('الخطوة ${i + 1} من ${steps.length}',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 12),
          Text('${s.emoji} ${s.title}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(s.desc, style: const TextStyle(fontSize: 15, height: 1.6)),
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
                  label: const Text('على الخريطة')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: i > 0 ? () => go(i - 1) : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('السابق'))),
            const SizedBox(width: 10),
            Expanded(
                child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _emerald),
                    onPressed: i < steps.length - 1 ? () => go(i + 1) : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('التالي'))),
          ]),
        ]);
      }));
}

// ═══════════ عدّاد الطواف والسعي ═══════════
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
              Text(t, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text('$v / 7',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton.filledTonal(
                    onPressed: v > 0 ? () => set(v - 1) : null,
                    icon: const Icon(Icons.remove)),
                const SizedBox(width: 12),
                IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: _emerald),
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
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ]),
          ),
        ),
      );

  return _sheet<void>(c, (ctx) => ListenableBuilder(
        listenable: store,
        builder: (ctx, _) {
          if (site != HaramainSite.makkah) {
            return Column(children: [
              _h('🔢 العدّاد'),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                    'العدّاد خاص بالمسجد الحرام. في المسجد النبوي استخدم «المرشد» لمتابعة زيارتك.'),
              ),
            ]);
          }
          return Column(children: [
            _h('🔢 عدّاد الطواف والسعي'),
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

// ═══════════ مواقعي المحفوظة ═══════════
Future<void> showPinsSheet(
  BuildContext c, {
  required HaramainSite site,
  required HaramainLiveStore store,
  required LatLng? me,
  required void Function(HlPin) onSelect,
}) {
  return _sheet<void>(c, (ctx) => ListenableBuilder(
        listenable: store,
        builder: (ctx, _) {
          final pins = store.pinsFor(site);
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _h('📌 مواقعي المحفوظة'),
            const Text('ثبّت مكانك الحالي (GPS) كـ:',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final k in HlPinKind.values.where((k) => k != HlPinKind.custom))
                ActionChip(
                  avatar: Text(k.emoji),
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
                padding: EdgeInsets.only(top: 6),
                child: Text('انتظر تحديد موقعك (GPS) أو اضغط مطولًا على الخريطة لتثبيت أي مكان.',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ),
            const Divider(height: 24),
            if (pins.isEmpty) const Text('لا توجد مواقع محفوظة بعد.'),
            for (final p in pins)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(p.kind.emoji, style: const TextStyle(fontSize: 26)),
                title: Text(p.label),
                subtitle: me == null
                    ? null
                    : Text('${HmGeo.meters(HmGeo.distance(me, p.position))} منك'),
                onTap: () {
                  Navigator.pop(ctx);
                  onSelect(p);
                },
                trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => store.removePin(p.id)),
              ),
          ]);
        },
      ));
}

// ═══════════ أنا تائه ═══════════
Future<void> showLostSheet(
  BuildContext c, {
  required HaramainSite site,
  required HaramainLiveStore store,
  required LatLng? me,
  required double? accuracy,
  required List<HlPoi> pois,
}) {
  const options = [
    ('🚪', 'أرى رقم باب'),
    ('🕋', 'أنا عند المطاف'),
    ('☀️', 'أنا في الساحات'),
    ('🏃', 'أنا بالقرب من المسعى'),
    ('🕌', 'أنا داخل المسجد'),
    ('❓', 'لا أرى شيئًا مميزًا'),
  ];
  String? pick;
  final gate = TextEditingController();

  String message() {
    final b = StringBuffer('🆘 أحتاج مساعدة، أنا تائه في ${site.title}.\n');
    if (store.name.isNotEmpty) b.writeln('الاسم: ${store.name}');
    if (pick != null) {
      b.writeln(pick == 'أرى رقم باب' && gate.text.trim().isNotEmpty
          ? 'أرى باب رقم: ${gate.text.trim()}'
          : pick);
    }
    if (me != null) {
      b.writeln(
          'موقعي: https://maps.google.com/?q=${me.latitude.toStringAsFixed(6)},${me.longitude.toStringAsFixed(6)}');
      if (accuracy != null) {
        b.writeln('دقة الموقع ±${accuracy.round()} متر (تقل الدقة داخل المبنى).');
      }
      final near = [...pois]
        ..sort((a, b2) => HmGeo.distance(me, a.position)
            .compareTo(HmGeo.distance(me, b2.position)));
      for (final p in near.take(2)) {
        b.writeln('أقرب نقطة معروفة: ${p.title}');
      }
    } else {
      b.writeln('لم يتحدد موقعي (GPS).');
    }
    final meet = store.pinsFor(site).where((p) => p.kind == HlPinKind.meeting);
    if (meet.isNotEmpty) b.writeln('نقطة التجمع محفوظة عندي على الخريطة.');
    if (store.hotel.isNotEmpty) b.writeln('فندقي: ${store.hotel}');
    b.write('أرجو التواصل معي.');
    return b.toString();
  }

  return _sheet<void>(c, (ctx) => StatefulBuilder(builder: (ctx, set) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _h('🆘 أنا تائه'),
          const Text('اختر ما تراه حولك، ثم شارك رسالة بموقعك مع من يبحث عنك.',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          for (final o in options)
            Card(
              elevation: 0,
              color: pick == o.$2 ? const Color(0xFFE3F1EC) : const Color(0xFFF6F7F6),
              child: ListTile(
                leading: Text(o.$1, style: const TextStyle(fontSize: 24)),
                title: Text(o.$2),
                trailing: pick == o.$2
                    ? const Icon(Icons.check_circle_rounded, color: _emerald)
                    : null,
                onTap: () => set(() => pick = o.$2),
              ),
            ),
          if (pick == 'أرى رقم باب')
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextField(
                controller: gate,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'رقم الباب', border: OutlineInputBorder()),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: _emerald, minimumSize: const Size.fromHeight(50)),
              onPressed: () => Share.share(message()),
              icon: const Icon(Icons.share_rounded),
              label: const Text('شارك رسالة «أنا تائه»')),
          const SizedBox(height: 8),
          FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red, minimumSize: const Size.fromHeight(50)),
              onPressed: () => _call('997'),
              icon: const Icon(Icons.call_rounded),
              label: const Text('اتصل بالإسعاف 997')),
        ]);
      }));
}

// ═══════════ طوارئ وبطاقتي ═══════════
Future<void> showCardSheet(BuildContext c, {required HaramainLiveStore store}) {
  final n = TextEditingController(text: store.name);
  final ho = TextEditingController(text: store.hotel);
  final l = TextEditingController(text: store.leader);
  final m = TextEditingController(text: store.medical);
  void save() =>
      store.saveCard(n: n.text, h: ho.text, l: l.text, m: m.text);
  Widget f(String lbl, TextEditingController ctl,
          {TextInputType? kb, int lines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: TextField(
          controller: ctl,
          keyboardType: kb,
          maxLines: lines,
          onChanged: (_) => save(),
          decoration:
              InputDecoration(labelText: lbl, border: const OutlineInputBorder()),
        ),
      );

  return _sheet<void>(c, (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _h('🆘 طوارئ وبطاقتي'),
          FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red, minimumSize: const Size.fromHeight(50)),
              onPressed: () => _call('997'),
              icon: const Icon(Icons.call_rounded),
              label: const Text('الإسعاف 997')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => _call('999'),
                    icon: const Icon(Icons.local_police_rounded),
                    label: const Text('الشرطة 999'))),
            const SizedBox(width: 8),
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: () {
                      if (l.text.trim().isNotEmpty) _call(l.text.trim());
                    },
                    icon: const Icon(Icons.phone_rounded),
                    label: const Text('مسؤول الحملة'))),
          ]),
          const Divider(height: 28),
          const Text('بطاقتي (تُحفظ على جهازك فقط)',
              style: TextStyle(fontWeight: FontWeight.w800)),
          f('الاسم', n),
          f('اسم الفندق ورقم الغرفة', ho),
          f('هاتف مسؤول الحملة / قريب', l, kb: TextInputType.phone),
          f('معلومات صحية (أمراض، حساسية، أدوية)', m, lines: 3),
        ],
      )).whenComplete(() {
    save();
    for (final x in [n, ho, l, m]) {
      x.dispose();
    }
  });
}

// ═══════════ الإعدادات وإمكانية الوصول ═══════════
Future<void> showSettingsSheet(BuildContext c,
    {required HaramainLiveStore store, required VoidCallback onChanged}) {
  return _sheet<void>(c, (ctx) => ListenableBuilder(
        listenable: store,
        builder: (ctx, _) {
          final p = store.profile;
          Widget sw(String t, String sub, bool v, void Function(bool) f) =>
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
                value: v,
                activeThumbColor: _emerald,
                onChanged: (x) {
                  f(x);
                  onChanged();
                },
              );
          return Column(children: [
            _h('⚙️ الإعدادات'),
            sw('وضع الكرسي المتحرك', 'يختار المسارات الميسّرة فقط عند توفرها',
                p.wheelchairMode,
                (v) => store.setProfile(p.copyWith(wheelchairMode: v))),
            sw('خط كبير', 'تكبير النصوص في كل الشاشة', p.largeText,
                (v) => store.setProfile(p.copyWith(largeText: v))),
            sw('تباين عالٍ', 'ألوان وحدود أوضح للوحات', p.highContrast,
                (v) => store.setProfile(p.copyWith(highContrast: v))),
            sw('التوجيه الصوتي', 'نطق التعليمات بالعربية', p.voiceGuidance,
                (v) => store.setProfile(p.copyWith(voiceGuidance: v))),
          ]);
        },
      ));
}
