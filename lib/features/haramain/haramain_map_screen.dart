import 'package:flutter/material.dart';

/// RIFQA — First concept Haramain landing map.
/// Artistic map and pins are illustrative; NOT real-world geocoded navigation.
const _green = Color(0xFF09533D);
const _gold = Color(0xFFB88A36);
const _cream = Color(0xFFF9F6EF);
const _ink = Color(0xFF172C27);

class HaramainMapScreen extends StatefulWidget {
  const HaramainMapScreen({super.key});
  @override
  State<HaramainMapScreen> createState() => _HaramainMapScreenState();
}

class _HaramainMapScreenState extends State<HaramainMapScreen> {
  bool showLayers = false;
  double zoom = 1;

  void _info(String title, String text) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: _green)),
              const SizedBox(height: 12),
              Text(text, style: const TextStyle(height: 1.8, fontSize: 15)),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _green),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً'),
              )),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final mapHeight = (screen.height * .48).clamp(355.0, 560.0);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _cream,
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            _header(context),
            Expanded(child: Stack(children: [
              SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  SizedBox(height: mapHeight, child: _map()),
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: _content(),
                  ),
                ]),
              ),
            ])),
            _bottomNav(),
          ]),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Container(
    height: 72,
    padding: const EdgeInsets.symmetric(horizontal: 22),
    decoration: const BoxDecoration(color: _cream),
    child: Row(children: [
      _squareButton(Icons.chevron_right_rounded, () => Navigator.maybePop(context), size: 50),
      const Expanded(child: Text('خريطة الحرمين', textAlign: TextAlign.center,
        style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: _ink))),
      _squareButton(Icons.search_rounded, () => _info('البحث', 'البحث في المواقع والبوابات يحتاج إلى بيانات أماكن معتمدة وربط محرك بحث.'), size: 50),
    ]),
  );

  Widget _map() => Stack(fit: StackFit.expand, children: [
    ClipRect(child: Transform.scale(
      scale: zoom,
      child: Image.asset('assets/haramain/saudi_map_art.png', fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE7E8D8),
          child: const Center(child: Text('أضف صورة خريطة الحرمين إلى assets')))),
    )),
    Positioned(left: 16, top: 135, child: Column(children: [
      _squareButton(Icons.layers_outlined, () => setState(() => showLayers = !showLayers)),
      const SizedBox(height: 10),
      _squareButton(Icons.my_location, () => _info('موقعي', 'تحديد الموقع الحقيقي يتطلب إذن الموقع وربطه بخدمة تحديد المواقع. العلامة الموجودة على الخريطة حالياً توضيحية.')),
      const SizedBox(height: 10),
      _squareButton(Icons.add, () => setState(() => zoom = (zoom + .15).clamp(1, 1.7))),
      _squareButton(Icons.remove, () => setState(() => zoom = (zoom - .15).clamp(1, 1.7))),
    ])),
    if (showLayers) Positioned(left: 76, top: 135, child: Material(
      borderRadius: BorderRadius.circular(16), elevation: 6,
      child: const Padding(padding: EdgeInsets.all(14), child: Text('الخريطة الفنية — طبقة توضيحية')),
    )),
    Positioned(bottom: 8, left: 8, right: 8, child: Row(children: [
      _quick(Icons.location_on_outlined, 'موقعي', () => _info('موقعي', 'سيتوفر الموقع الدقيق بعد ربط خدمة الموقع وإذن المستخدم.')),
      _quick(Icons.help_outline_rounded, 'أنا تائه', () => _info('أنا تائه', 'في النسخة الكاملة: مشاركة الموقع مع المشرف وطلب المساعدة. لا يتم إرسال أي تنبيه حالياً.')),
      _quick(Icons.share_outlined, 'مشاركة الموقع', () => _info('مشاركة الموقع', 'سيتم تفعيل المشاركة بعد ربط صلاحيات الموقع وأداة المشاركة.')),
      _quick(Icons.door_front_door_outlined, 'أقرب بوابة', () => _info('أقرب بوابة', 'تحتاج الميزة إلى قاعدة بيانات بوابات موثقة وموقع المستخدم الحقيقي.')),
      _quick(Icons.groups_2_outlined, 'نقطة التجمع', () => _info('نقطة التجمع', 'يمكن ربط نقطة التجمع الخاصة بالمجموعة من Firestore.')),
    ])),
  ]);

  Widget _squareButton(IconData icon, VoidCallback tap, {double size = 47}) => Material(
    color: const Color(0xFFFDFBF6), elevation: 2,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(onTap: tap, borderRadius: BorderRadius.circular(16),
      child: SizedBox(width: size, height: size, child: Icon(icon, color: _ink, size: 27))),
  );

  Widget _quick(IconData icon, String label, VoidCallback tap) => Expanded(
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(elevation: 3, color: const Color(0xFFFFFCF6), borderRadius: BorderRadius.circular(14),
        child: InkWell(onTap: tap, borderRadius: BorderRadius.circular(14),
          child: SizedBox(height: 73, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: label == 'موقعي' ? _green : _gold, size: 23),
            const SizedBox(height: 7),
            FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
          ]))),
      ),
    ),
  );

  Widget _content() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    decoration: const BoxDecoration(color: _cream,
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 12)]),
    child: Column(children: [
      Container(width: 42, height: 5, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(9))),
      const SizedBox(height: 19),
      Row(children: [
        const Icon(Icons.map_outlined, color: _ink), const SizedBox(width: 8),
        const Expanded(child: Text('الوجهات الرئيسية', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900))),
        GestureDetector(onTap: () => _info('كل الوجهات', 'يمكن إضافة المزيد من المواقع المعتمدة لاحقاً.'),
          child: const Text('عرض الكل  ‹', style: TextStyle(color: Colors.black54))),
      ]),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _mosqueCard(true)),
        const SizedBox(width: 10),
        Expanded(child: _mosqueCard(false)),
      ]),
      const SizedBox(height: 17),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFFDE8E6), borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFFFBDB8))),
        child: Row(children: [
          const Icon(Icons.emergency_outlined, color: Color(0xFFC32329), size: 31),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('طلب مساعدة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFFA91F25))),
            Text('للحالات الطارئة أو عند الشعور بالخطر', style: TextStyle(fontSize: 11)),
          ])),
          TextButton.icon(onPressed: () => _info('طلب مساعدة', 'لم يتم ربط طلبات الطوارئ بخدمة فعلية بعد. عند وجود خطر حقيقي استخدم خدمات الطوارئ الرسمية.'),
            icon: const Icon(Icons.call, color: Color(0xFFC32329)),
            label: const Text('اتصال فوري', style: TextStyle(color: Color(0xFFC32329), fontWeight: FontWeight.w800))),
        ]),
      ),
    ]),
  );

  Widget _mosqueCard(bool haram) {
    final title = haram ? 'المسجد الحرام' : 'المسجد النبوي';
    final city = haram ? 'مكة المكرمة' : 'المدينة المنورة';
    final photo = haram ? 'haram_thumb.png' : 'nabawi_thumb.png';
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFEDE9E3)),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 7),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight,
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: _ink))),
            Text(city, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ])),
          const SizedBox(width: 6),
          ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.asset('assets/haramain/$photo', width: 76, height: 95, fit: BoxFit.cover)),
        ]),
        const SizedBox(height: 12),
        Text(haram ? 'الكعبة المشرفة • ساحات واسعة' : 'الروضة الشريفة • أبواب المسجد',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black54, fontSize: 11)),
        const SizedBox(height: 12),
        SizedBox(height: 41, child: FilledButton.icon(
          onPressed: () => _info(title, 'الصفحة التفصيلية ستحتوي على البوابات والمرافق والصور. التوجيه الحقيقي يتطلب خرائط ومواقع موثوقة.'),
          style: FilledButton.styleFrom(backgroundColor: _green, padding: const EdgeInsets.symmetric(horizontal: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
          icon: const Icon(Icons.near_me_outlined, size: 16),
          label: const FittedBox(fit: BoxFit.scaleDown, child: Text('عرض الاتجاهات', style: TextStyle(fontWeight: FontWeight.w800))),
        )),
        const SizedBox(height: 10),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.directions_car_outlined, size: 13, color: Colors.black54),
          SizedBox(width: 4),
          Text('وقت الوصول حسب المسار', style: TextStyle(fontSize: 10, color: Colors.black54)),
        ]),
      ]),
    );
  }

  Widget _bottomNav() => Container(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
    decoration: const BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      boxShadow: [BoxShadow(color: Color(0x15000000), blurRadius: 12)]),
    child: Row(children: [
      _nav(Icons.home_outlined, 'الرئيسية', false),
      _nav(Icons.auto_stories_outlined, 'العمرة', false),
      _nav(Icons.map_rounded, 'الخريطة', true),
      _nav(Icons.warning_amber_rounded, 'أنا تائه', false),
    ]),
  );

  Widget _nav(IconData icon, String label, bool selected) => Expanded(
    child: InkWell(onTap: selected ? null : () => _info(label, 'اربط هذا التبويب بمسار التنقل الموجود في تطبيق رفقة.'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(color: selected ? const Color(0xFFECF1ED) : Colors.transparent, borderRadius: BorderRadius.circular(18)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: selected ? _green : Colors.black54),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: selected ? _green : Colors.black54,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600, fontSize: 11)),
        ]),
      ),
    ),
  );
}
