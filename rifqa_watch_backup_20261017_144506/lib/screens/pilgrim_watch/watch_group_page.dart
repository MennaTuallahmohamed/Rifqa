import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'watch_ui.dart';

class RifqaWatchGroupPage extends StatefulWidget {
  const RifqaWatchGroupPage({super.key});
  @override State<RifqaWatchGroupPage> createState() => _RifqaWatchGroupPageState();
}

class _RifqaWatchGroupPageState extends State<RifqaWatchGroupPage> {
  Map<String, dynamic> trip = {};
  List<Map<String, dynamic>> saved = [];
  bool loaded = false;
  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final t = pref.getString('rifqa_profile_trip_v1');
      final c = pref.getString('rifqa_profile_contacts_v1');
      if (t != null) trip = Map<String, dynamic>.from(jsonDecode(t) as Map);
      if (c != null) saved = (jsonDecode(c) as List).whereType<Map>()
        .map((v) => Map<String, dynamic>.from(v)).toList();
    } catch (_) { /* Show setup instructions rather than fake trip information */ }
    if (mounted) setState(() => loaded = true);
  }

  String val(String field) => '${trip[field] ?? ''}'.trim();
  Future<void> _call(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تعذّر فتح تطبيق الاتصال.')));
    }
  }
  Widget _info(String title, String value, IconData icon) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
      Icon(icon, color: RW.gold, size: 20), const SizedBox(width: 12),
      Expanded(child: Text(title, style: RW.style(13))),
      SelectableText(value.isEmpty ? 'غير مضاف' : value,
        style: RW.style(13, color: value.isEmpty ? RW.muted : RW.lightGold)),
    ]));
  Widget _contact(String name, String number) => WatchPanel(child: Row(children: [
    const Icon(Icons.contact_phone, color: RW.gold), const SizedBox(width: 11),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, style: RW.style(14, weight: FontWeight.w800)),
      Text(number, style: RW.style(11, color: RW.muted)),
    ])),
    IconButton(tooltip: 'نسخ الرقم', onPressed: () => Clipboard.setData(ClipboardData(text: number)),
      icon: const Icon(Icons.copy, color: RW.gold)),
    IconButton(tooltip: 'اتصال', onPressed: () => _call(number),
      icon: const Icon(Icons.phone, color: RW.jade)),
  ]));

  @override Widget build(BuildContext context) {
    final contacts = <(String, String)>[
      if (val('hotelPhone').isNotEmpty) ('استقبال الفندق',val('hotelPhone')),
      if (val('guidePhone').isNotEmpty) ('مرشد الرحلة',val('guidePhone')),
      if (val('groupLeaderPhone').isNotEmpty) ('مشرف الرحلة',val('groupLeaderPhone')),
      if (val('emergencyPhone').isNotEmpty) ('مرافق للطوارئ',val('emergencyPhone')),
      for (final c in saved) if ('${c['phone'] ?? ''}'.trim().isNotEmpty)
        ('${c['title'] ?? 'جهة الاتصال'}','${c['phone']}'),
    ];
    return WatchGradientScaffold(topPhoto: true, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10), child: Row(children: [
        IconButton(onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_forward, color: RW.ivory)),
        Expanded(child: Text('مجموعتي وغرفتي', style: RW.style(23, weight: FontWeight.w900))),
        const Icon(Icons.groups, color: RW.gold, size: 29),
      ])),
      Expanded(child: loaded ? ListView(padding: const EdgeInsets.all(18), children: [
        WatchPanel(glow: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('بطاقة رحلتي', style: RW.style(20, weight: FontWeight.w900, color: RW.lightGold)),
          const SizedBox(height: 15),
          _info('اسم الرحلة', val('tripName'), Icons.tour),
          _info('الفندق', val('hotelName'), Icons.hotel),
          _info('البرج / المبنى', val('building'), Icons.apartment),
          _info('الدور', val('floor'), Icons.layers),
          _info('رقم الغرفة', val('roomNumber'), Icons.meeting_room),
          const SizedBox(height: 8),
          Text('البيانات من «حسابي» على نفس الجهاز فقط.',
            style: RW.style(10, color: RW.muted)),
        ])),
        const SizedBox(height: 20),
        WatchSectionTitle('أرقام المرافقين والفندق'),
        const SizedBox(height: 9),
        if (contacts.isEmpty) WatchPanel(child: Text(
          'أضيفي الفندق والمشرف وأهلك من صفحة «حسابي»؛ الأرقام هتظهر هنا تلقائيًا.',
          style: RW.style(13))),
        for (final contact in contacts) ...[
          _contact(contact.$1,contact.$2), const SizedBox(height: 8),
        ],
        const SizedBox(height: 18),
        WatchPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('لو تايهة أو محتاجة مساعدة', style: RW.style(17, color: RW.lightGold)),
          const SizedBox(height: 8),
          Text('اتصلي بالمرافق، أو افتحي SOS من رِفقة. رقم الطوارئ الموحدة 911 حيث تتوفر الخدمة في السعودية.',
            style: RW.style(12)),
          const SizedBox(height: 12),
          WatchPrimaryButton(label: 'فتح الاتصال بالطوارئ 911',
            gold: false, icon: Icons.phone_forwarded,
            onTap: () async {
              final allow = await showDialog<bool>(context: context,
                builder: (c) => AlertDialog(title: const Text('الاتصال بالطوارئ'),
                  content: const Text('هل تريدين فتح الاتصال برقم 911؟ لن يتم الاتصال دون تأكيدك في الهاتف.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(c,false), child: const Text('إلغاء')),
                    TextButton(onPressed: () => Navigator.pop(c,true), child: const Text('فتح الاتصال'))]));
              if (allow == true) await _call('911');
            }),
        ])),
        const SizedBox(height: 22),
      ]) : const Center(child: CircularProgressIndicator(color: RW.gold))),
    ]));
  }
}
