import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/profile/rifqa_profile_store.dart';
import 'rifqa_profile_ui.dart';
import 'rifqa_saved_contacts_screen.dart';
import 'rifqa_trip_details_screen.dart';

/// الأرقام السعودية مستمدة من الخطة الوطنية للترقيم (CST).
/// مصدر: https://www.cst.gov.sa/about/Numbering
class _OfficialNumber {
  const _OfficialNumber(this.name, this.number, this.description, this.icon);
  final String name, number, description;
  final IconData icon;
}

const _officialNumbers = <_OfficialNumber>[
  _OfficialNumber('الإسعاف / الهلال الأحمر', '997', 'الحوادث والطوارئ الطبية', Icons.medical_services_outlined),
  _OfficialNumber('الدفاع المدني', '998', 'الحرائق والإنقاذ والحوادث', Icons.fire_truck_outlined),
  _OfficialNumber('الشرطة / الدوريات الأمنية', '999', 'البلاغات والحالات الأمنية', Icons.local_police_outlined),
  _OfficialNumber('وزارة الصحة', '937', 'الاستشارات الصحية والاستفسارات', Icons.health_and_safety_outlined),
];

class RifqaEmergencyNumbersScreen extends StatefulWidget {
  const RifqaEmergencyNumbersScreen({super.key});
  @override
  State<RifqaEmergencyNumbersScreen> createState() => _RifqaEmergencyNumbersScreenState();
}

class _RifqaEmergencyNumbersScreenState extends State<RifqaEmergencyNumbersScreen> {
  final store = RifqaProfileStore.instance;
  @override
  void initState() {
    super.initState();
    store.addListener(_refresh);
    store.load();
  }
  void _refresh() { if (mounted) setState(() {}); }
  @override
  void dispose() { store.removeListener(_refresh); super.dispose(); }

  Widget _officialCard(_OfficialNumber n) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: RpCard(padding: const EdgeInsets.all(12), child: Row(children: [
      Container(width: 47, height: 47, decoration: BoxDecoration(color: Rp.cream, borderRadius: BorderRadius.circular(14)),
        child: Icon(n.icon, color: Rp.green, size: 24)),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(n.name, maxLines: 2, style: Rp.style(12.5, weight: FontWeight.w900)),
        Text(n.description, maxLines: 2, style: Rp.style(10, color: Rp.muted)),
        Text(n.number, textDirection: TextDirection.ltr, style: Rp.style(20, color: Rp.red, weight: FontWeight.w900)),
      ])),
      IconButton(tooltip: 'نسخ الرقم', onPressed: () => rpCopy(context, n.number),
        icon: const Icon(Icons.content_copy_rounded, color: Rp.green, size: 20)),
      const SizedBox(width: 2),
      Material(color: Rp.green, shape: const CircleBorder(), child: InkWell(
        onTap: () => rpCall(context, n.number), customBorder: const CircleBorder(),
        child: const SizedBox(width: 45, height: 45, child: Icon(Icons.call_rounded, color: Colors.white)))),
    ])),
  );

  @override
  Widget build(BuildContext context) {
    final trip = store.trip;
    return rpTextScale(context, Scaffold(
      backgroundColor: Rp.cream,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: RpPhotoHeader(title: 'الأرقام المهمة', subtitle: 'مساعدة واتصال سريع داخل السعودية',
          image: 'assets/rifqa_profile/makkah.jpg', height: 235,
          trailing: IconButton.filledTonal(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RifqaSavedContactsScreen())),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .2), foregroundColor: Colors.white),
            icon: const Icon(Icons.contacts_rounded)),
        )),
        SliverPadding(padding: const EdgeInsets.fromLTRB(17, 18, 17, 35),
          sliver: SliverList(delegate: SliverChildListDelegate([
            RpCard(padding: const EdgeInsets.all(14), color: Rp.softRed,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.emergency_rounded, color: Rp.red, size: 27),
                  const SizedBox(width: 9),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('في حالة الطوارئ', style: Rp.style(16, color: Rp.red, weight: FontWeight.w900)),
                    Text('اتصلي فورًا بالجهة المختصة.', style: Rp.style(10.5, color: Rp.muted)),
                  ])),
                ]),
                const SizedBox(height: 13),
                Row(children: [
                  Expanded(child: Text('911', textDirection: TextDirection.ltr, style: Rp.style(39, color: Rp.green, weight: FontWeight.w900))),
                  FilledButton.icon(
                    onPressed: () => rpCall(context, '911'),
                    icon: const Icon(Icons.call_rounded, size: 22),
                    label: Text('اتصال الطوارئ', style: Rp.style(13, color: Colors.white, weight: FontWeight.w900)),
                    style: FilledButton.styleFrom(backgroundColor: Rp.green,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  ),
                ]),
                Text('العمليات الأمنية الموحدة 911 في المناطق التي تغطيها الخدمة. عند تعذر الاتصال جرّبي رقم الجهة المختصة أدناه.',
                  style: Rp.style(10.5, color: Rp.ink)),
              ])),
            const SizedBox(height: 12),
            RpCard(color: Rp.mint, padding: const EdgeInsets.all(12), child: Row(children: [
              const Icon(Icons.verified_user_outlined, size: 22, color: Rp.green),
              const SizedBox(width: 9),
              Expanded(child: Text('الأرقام الرسمية الأساسية محفوظة داخل التطبيق وتظهر دون إنترنت. الاتصال يحتاج شبكة هاتف.',
                style: Rp.style(11, color: Rp.green))),
            ])),
            const SizedBox(height: 17),
            const RpSectionTitle('الطوارئ والخدمات الصحية', icon: Icons.local_hospital_outlined),
            for (final n in _officialNumbers) _officialCard(n),
            const SizedBox(height: 8),
            RpPrimaryButton(label: 'مشاركة قائمة الأرقام الرسمية', icon: Icons.share_outlined,
              onPressed: () => Share.share('أرقام مهمة داخل السعودية:\n'
                'العمليات الأمنية الموحدة: 911\nالإسعاف: 997\nالدفاع المدني: 998\nالشرطة: 999\nوزارة الصحة: 937')),
            const SizedBox(height: 20),
            const RpSectionTitle('إقامتي واتصالات رحلتي', icon: Icons.hotel_rounded),
            RpCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.meeting_room_rounded, color: Rp.green, size: 24),
                const SizedBox(width: 9),
                Expanded(child: Text('رقم غرفتي', style: Rp.style(15, weight: FontWeight.w900))),
                Text(trip.roomNumber.isEmpty ? 'لم يُسجَّل بعد' : trip.roomNumber,
                  style: Rp.style(17, color: Rp.green, weight: FontWeight.w900)),
              ]),
              if (trip.hotelName.trim().isNotEmpty || trip.floor.trim().isNotEmpty || trip.building.trim().isNotEmpty) ...[
                const SizedBox(height: 5),
                Text([trip.hotelName, if (trip.building.isNotEmpty) 'البرج: ${trip.building}',
                  if (trip.floor.isNotEmpty) 'الدور: ${trip.floor}'].where((s) => s.isNotEmpty).join(' • '),
                  style: Rp.style(11.5, color: Rp.muted)),
              ],
              const SizedBox(height: 13),
              for (final c in store.tripContacts) ...[
                const Divider(height: 16, color: Rp.edge),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.title, style: Rp.style(12.5, weight: FontWeight.w800)),
                    Text(c.phone, textDirection: TextDirection.ltr, style: Rp.style(12, color: Rp.green)),
                  ])),
                  IconButton(onPressed: () => rpCopy(context, c.phone), tooltip: 'نسخ',
                    icon: const Icon(Icons.copy_outlined, color: Rp.green)),
                  IconButton.filledTonal(onPressed: () => rpCall(context, c.phone),
                    icon: const Icon(Icons.call_rounded, color: Rp.green)),
                ]),
              ],
              const SizedBox(height: 13),
              OutlinedButton.icon(onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RifqaTripDetailsScreen())),
                icon: const Icon(Icons.edit_note_rounded), label: const Text('إضافة / تعديل بيانات الغرفة والرحلة'),
                style: OutlinedButton.styleFrom(foregroundColor: Rp.green,
                  side: const BorderSide(color: Rp.edge), minimumSize: const Size.fromHeight(45))),
            ])),
            const SizedBox(height: 15),
            RpMenuRow(icon: Icons.contact_phone_outlined, title: 'كل أرقامي المحفوظة',
              subtitle: 'العائلة والفندق والمشرف وشركة السياحة',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RifqaSavedContactsScreen()))),
            const SizedBox(height: 14),
            Text('المصدر: هيئة الاتصالات والفضاء والتقنية السعودية – الخطة الوطنية للترقيم. راجعي تعليمات الجهات المختصة في موقعك.',
              textAlign: TextAlign.center, style: Rp.style(10, color: Rp.muted)),
          ]))),
      ]),
    ));
  }
}
