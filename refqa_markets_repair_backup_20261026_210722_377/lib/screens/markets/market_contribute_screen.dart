import 'package:flutter/material.dart';

import '../../services/markets/market_community_service.dart';
import 'widgets/rifqa_market_style.dart';

/// Add a market or a shop, with immediate publication on Firestore.
class MarketContributeScreen extends StatefulWidget {
  const MarketContributeScreen({super.key, this.initialTower = false,
    this.initialCity = 'makkah'});
  final bool initialTower;
  final String initialCity;

  @override
  State<MarketContributeScreen> createState() => _MarketContributeScreenState();
}

class _MarketContributeScreenState extends State<MarketContributeScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _market = TextEditingController();
  final _area = TextEditingController();
  final _unit = TextEditingController();
  final _note = TextEditingController();
  late String _city = widget.initialTower ? 'makkah' : widget.initialCity;
  late bool _tower = widget.initialTower;
  String _placeType = 'shop';
  String? _category;
  int _floor = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (_tower) {
      _market.text = 'مركز أبراج الساعة للتسوق';
      _area.text = 'برج الساعة، أمام المسجد الحرام';
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _market, _area, _unit, _note]) { c.dispose(); }
    super.dispose();
  }

  void _setTower(bool selected) {
    setState(() {
      _tower = selected;
      if (selected) {
        _city = 'makkah';
        _placeType = 'shop';
        _market.text = 'مركز أبراج الساعة للتسوق';
        _area.text = 'برج الساعة، أمام المسجد الحرام';
      } else {
        _floor = 0;
        _market.clear();
        _area.clear();
      }
    });
  }

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: MarketPalette.line)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: MarketPalette.emerald, width: 1.6)),
  );

  Future<void> _save() async {
    if (_saving || !_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await RefqaMarketsCommunityService.instance.publish(
        name: _name.text,
        city: _city,
        placeType: _placeType,
        category: _category!,
        marketId: _tower ? 'makkah_clock_towers' : '',
        marketName: _placeType == 'shop' ? _market.text : '',
        area: _area.text,
        floor: _tower ? _floor : 0,
        unit: _placeType == 'shop' ? _unit.text : '',
        note: _note.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', ''))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: MarketPalette.cream,
      appBar: AppBar(
        backgroundColor: MarketPalette.evergreen, foregroundColor: Colors.white,
        title: const Text('أضف مكان • عرّف غيرك'),
      ),
      body: SafeArea(child: Form(key: _key,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 40), children: [
          MarketSoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Row(children: [Icon(Icons.volunteer_activism_outlined,
                color: MarketPalette.emerald, size: 28), SizedBox(width: 10),
              Expanded(child: Text('معلومتك هتساعد الحجاج والمعتمرين',
                  style: TextStyle(fontSize: 15, color: MarketPalette.ink,
                      fontWeight: FontWeight.w900)))]),
            SizedBox(height: 9),
            Text('الإضافة بتظهر مباشرة بعلامة «مستخدم». لو 3 حسابات مختلفة '
                'بلغت إن معلوماتها خاطئة، هتختفي من البحث تلقائيًا. '
                'اكتبي مكان تعرفيه بنفسك، من غير تخمين.',
                style: TextStyle(height: 1.65, fontSize: 12,
                    color: MarketPalette.muted)),
          ])),
          const SizedBox(height: 18),
          const Text('نوع الإضافة', style: TextStyle(
            fontWeight: FontWeight.w900, color: MarketPalette.ink)),
          const SizedBox(height: 8),
          Wrap(spacing: 9, runSpacing: 7, children: [
            ChoiceChip(
              label: const Text('محل / مطعم'),
              avatar: const Icon(Icons.storefront_rounded, size: 18),
              selected: _placeType == 'shop',
              onSelected: (_) => setState(() => _placeType = 'shop'),
            ),
            ChoiceChip(
              label: const Text('سوق كامل'),
              avatar: const Icon(Icons.store_mall_directory_rounded, size: 18),
              selected: _placeType == 'market',
              onSelected: (_) {
                if (_tower) _setTower(false);
                setState(() => _placeType = 'market');
              },
            ),
          ]),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _city,
            isExpanded: true,
            decoration: _decoration('المدينة *'),
            items: const [
              DropdownMenuItem(value: 'makkah', child: Text('مكة المكرمة')),
              DropdownMenuItem(value: 'madinah', child: Text('المدينة المنورة')),
            ],
            onChanged: (v) {
              if (v == null) return;
              if (v == 'madinah' && _tower) _setTower(false);
              setState(() => _city = v);
            },
          ),
          if (_placeType == 'shop' && _city == 'makkah') ...[
            const SizedBox(height: 5),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeColor: MarketPalette.emerald,
              title: const Text('المحل داخل برج الساعة',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              subtitle: const Text('اختاري الدور من 1 إلى 7 لو معروف'),
              value: _tower,
              onChanged: _setTower,
            ),
          ],
          const SizedBox(height: 10),
          TextFormField(
            controller: _name, maxLength: 100,
            decoration: _decoration(_placeType == 'shop' ? 'اسم المحل *' : 'اسم السوق *',
                hint: _placeType == 'shop' ? 'مثال: محل عطور' : 'مثال: سوق الهدايا'),
            validator: (v) => (v ?? '').trim().length < 2
                ? 'اكتبي اسم المكان (حرفين على الأقل)' : null,
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _category, isExpanded: true,
            decoration: _decoration('نوع النشاط *'),
            items: RefqaMarketsCommunityService.categories
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _category = v),
            validator: (v) => v == null ? 'اختاري التصنيف' : null,
          ),
          if (_placeType == 'shop') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _market,
              readOnly: _tower,
              maxLength: 100,
              decoration: _decoration('اسم السوق / المول *',
                  hint: 'مثال: سوق الخليل'),
              validator: (v) => (v ?? '').trim().isEmpty
                  ? 'اكتبي اسم السوق اللي فيه المحل' : null,
            ),
          ],
          const SizedBox(height: 8),
          TextFormField(
            controller: _area, maxLength: 180,
            decoration: _decoration('وصف العنوان / المدخل *',
                hint: 'مثال: بجوار بوابة المول الرئيسية'),
            validator: (v) => (v ?? '').trim().length < 3
                ? 'اكتبي وصفًا واضحًا للموقع' : null,
          ),
          if (_tower && _placeType == 'shop') ...[
            const SizedBox(height: 9),
            DropdownButtonFormField<int>(
              value: _floor, isExpanded: true,
              decoration: _decoration('الدور في برج الساعة'),
              items: [
                const DropdownMenuItem(value: 0, child: Text('غير محدد')),
                ...List.generate(7, (i) => DropdownMenuItem(
                    value: i + 1, child: Text('الدور ${i + 1}'))),
              ],
              onChanged: (v) => setState(() => _floor = v ?? 0),
            ),
          ],
          if (_placeType == 'shop') ...[
            const SizedBox(height: 13),
            TextFormField(controller: _unit, maxLength: 40,
              decoration: _decoration('رقم المحل (اختياري)')),
          ],
          const SizedBox(height: 8),
          TextFormField(
            controller: _note, maxLength: 500, minLines: 3, maxLines: 5,
            decoration: _decoration('تفاصيل تساعد غيرك (اختياري)',
                hint: 'مثال: بالقرب من المصاعد أو أمام المطعم'),
          ),
          const SizedBox(height: 4),
          const Text('إضافة الصور غير مفعّلة في هذه النسخة حتى نختار تخزينًا آمنًا '
              'بدون تكاليف إضافية. الموقع هنا وصف نصي وليس دبوس GPS مؤكد.',
              style: TextStyle(fontSize: 11, height: 1.65,
                  color: MarketPalette.muted)),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: MarketPalette.emerald,
                foregroundColor: Colors.white, minimumSize: const Size.fromHeight(54)),
            icon: _saving ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2,
                    color: Colors.white)) : const Icon(Icons.send_rounded),
            label: Text(_saving ? 'جارٍ النشر...' : 'انشر المكان الآن'),
          ),
        ]),
      )),
    ),
  );
}
