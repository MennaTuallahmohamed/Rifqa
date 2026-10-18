import 'package:flutter/material.dart';

import '../../services/profile/rifqa_profile_store.dart';
import 'rifqa_profile_ui.dart';

class RifqaTripDetailsScreen extends StatefulWidget {
  const RifqaTripDetailsScreen({super.key});
  @override
  State<RifqaTripDetailsScreen> createState() => _RifqaTripDetailsScreenState();
}

class _RifqaTripDetailsScreenState extends State<RifqaTripDetailsScreen> {
  final _store = RifqaProfileStore.instance;
  final Map<String, TextEditingController> _c = {};
  bool _busy = false;
  bool _initialized = false;

  TextEditingController c(String k) => _c.putIfAbsent(k, TextEditingController.new);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _store.load();
    if (!mounted) return;
    final t = _store.trip;
    final m = t.toJson();
    for (final e in m.entries) {
      c(e.key).text = e.value;
    }
    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    for (final controller in _c.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    for (final k in ['hotelPhone', 'guidePhone', 'groupLeaderPhone', 'emergencyPhone', 'embassyPhone']) {
      if (c(k).text.trim().isNotEmpty && !rpValidPhone(c(k).text)) {
        rpToast(context, 'راجعي الرقم المكتوب في خانة ${_phoneLabel(k)}'); return;
      }
    }
    setState(() => _busy = true);
    String value(String k) => c(k).text.trim();
    try {
      await _store.saveTrip(RifqaTripInfo(
        tripName: value('tripName'), hotelName: value('hotelName'),
        roomNumber: value('roomNumber'), floor: value('floor'),
        building: value('building'), hotelAddress: value('hotelAddress'),
        hotelPhone: value('hotelPhone'), guideName: value('guideName'),
        guidePhone: value('guidePhone'), groupLeaderPhone: value('groupLeaderPhone'),
        emergencyName: value('emergencyName'), emergencyPhone: value('emergencyPhone'),
        embassyName: value('embassyName'), embassyPhone: value('embassyPhone'),
      ));
      if (mounted) {
        rpToast(context, 'اتحفظت بيانات رحلتك على الجهاز 💚');
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) rpToast(context, 'تعذر الحفظ. جرّبي مرة تانية.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _phoneLabel(String k) {
    switch (k) {
      case 'hotelPhone': return 'هاتف الفندق';
      case 'guidePhone': return 'هاتف المرشد';
      case 'groupLeaderPhone': return 'هاتف مشرف الرحلة';
      case 'emergencyPhone': return 'جهة الطوارئ الشخصية';
      default: return 'السفارة';
    }
  }

  Widget field(String key, String label, String hint, {IconData? icon, bool phone = false}) =>
      RpFormField(controller: c(key), label: label, hint: hint, icon: icon, phone: phone);

  @override
  Widget build(BuildContext context) => rpTextScale(context, Scaffold(
    backgroundColor: Rp.cream,
    body: !_initialized
        ? const Center(child: CircularProgressIndicator(color: Rp.green))
        : Column(children: [
            Expanded(child: CustomScrollView(slivers: [
              const SliverToBoxAdapter(child: RpPhotoHeader(
                title: 'بيانات رحلتي', subtitle: 'فندقك وغرفتك وأرقام المرافقين في مكان واحد', height: 222)),
              SliverPadding(padding: const EdgeInsets.fromLTRB(17, 20, 17, 12),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  const RpSectionTitle('الرحلة والإقامة', icon: Icons.hotel_rounded),
                  RpCard(child: Column(children: [
                    field('tripName', 'اسم الرحلة أو المجموعة', 'مثال: مجموعة عمرة رِفقة', icon: Icons.groups_rounded),
                    field('hotelName', 'اسم الفندق', 'اسم الفندق في مكة أو المدينة', icon: Icons.apartment_rounded),
                    field('building', 'المبنى أو البرج', 'مثال: برج A / برج الصفوة', icon: Icons.location_city_rounded),
                    Row(children: [
                      Expanded(child: field('roomNumber', 'رقم الغرفة', 'مثال: 1207', icon: Icons.meeting_room_rounded)),
                      const SizedBox(width: 10),
                      Expanded(child: field('floor', 'رقم الدور', 'مثال: 12', icon: Icons.layers_rounded)),
                    ]),
                    field('hotelAddress', 'وصف عنوان الفندق (اختياري)', 'اسم الشارع أو معلم قريب', icon: Icons.place_outlined),
                    field('hotelPhone', 'رقم استقبال الفندق', '966... أو رقم الاستقبال', icon: Icons.call_rounded, phone: true),
                  ])),
                  const SizedBox(height: 18),
                  const RpSectionTitle('المشرف والمرافقون', icon: Icons.people_alt_outlined),
                  RpCard(child: Column(children: [
                    field('guideName', 'اسم المرشد', 'اسم مرشد الرحلة', icon: Icons.person_outline_rounded),
                    field('guidePhone', 'رقم المرشد', 'رقم هاتف المرشد', icon: Icons.call_rounded, phone: true),
                    field('groupLeaderPhone', 'رقم مشرف الرحلة', 'رقم مشرف المجموعة', icon: Icons.support_agent_rounded, phone: true),
                    field('emergencyName', 'اسم شخص من العائلة للطوارئ', 'اسم قريبك', icon: Icons.favorite_outline_rounded),
                    field('emergencyPhone', 'رقم الشخص للطوارئ', 'رقم قريبك مع كود الدولة', icon: Icons.call_rounded, phone: true),
                  ])),
                  const SizedBox(height: 18),
                  const RpSectionTitle('السفارة أو القنصلية (اختياري)', icon: Icons.account_balance_rounded),
                  RpCard(child: Column(children: [
                    field('embassyName', 'اسم السفارة / القنصلية', 'مثال: قنصلية بلدي', icon: Icons.account_balance_outlined),
                    field('embassyPhone', 'رقم التواصل الرسمي', 'أضيفي الرقم بعد التأكد منه', icon: Icons.call_rounded, phone: true),
                  ])),
                  const SizedBox(height: 16),
                  RpCard(color: Rp.mint, child: Row(children: [
                    const Icon(Icons.shield_outlined, color: Rp.green, size: 25),
                    const SizedBox(width: 10),
                    Expanded(child: Text('بيانات الغرفة والأرقام دي محفوظة محليًا على جهازك فقط؛ مش بتترفع لفirebase. تجنّبي كتابة معلومات شديدة الحساسية.',
                      style: Rp.style(11.5, color: Rp.green))),
                  ])),
                  const SizedBox(height: 80),
                ]))),
            ])),
            SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(17, 8, 17, 14),
              child: RpPrimaryButton(label: _busy ? 'جارٍ الحفظ...' : 'حفظ بيانات الرحلة',
                onPressed: _busy ? null : _save, icon: Icons.save_outlined))),
          ]),
  ));

}
