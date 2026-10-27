import 'package:flutter/material.dart';

import '../../services/markets/clock_tower_directory_service.dart';
import 'widgets/rifqa_market_style.dart';

class ClockTowerAddStoreScreen extends StatefulWidget {
  const ClockTowerAddStoreScreen({super.key});

  @override
  State<ClockTowerAddStoreScreen> createState() =>
      _ClockTowerAddStoreScreenState();
}

class _ClockTowerAddStoreScreenState extends State<ClockTowerAddStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _unit = TextEditingController();
  final _note = TextEditingController();
  String? _category;
  int? _floor;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await ClockTowerDirectoryService.instance.addStore(
        name: _name.text,
        category: _category!,
        floor: _floor!,
        unit: _unit.text,
        note: _note.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: MarketPalette.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: MarketPalette.emerald, width: 1.4),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
  );

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: MarketPalette.cream,
      appBar: AppBar(
        title: const Text('ساعد غيرك • أضف محلًا'),
        backgroundColor: MarketPalette.evergreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            MarketSoftCard(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(children: [
                  Icon(Icons.volunteer_activism_outlined,
                      color: MarketPalette.emerald, size: 25),
                  SizedBox(width: 10),
                  Text('ساهم بمعلومة مفيدة',
                      style: TextStyle(fontSize: 17,
                          fontWeight: FontWeight.w900, color: MarketPalette.ink)),
                ]),
                SizedBox(height: 8),
                Text('المحل هيظهر في دليل برج الساعة فور الإضافة. '
                    'لو 3 أشخاص بحسابات مختلفة بلغوا أنه معلومة خاطئة، '
                    'هيتخفى تلقائيًا من نتائج البحث.',
                    style: TextStyle(height: 1.7,
                        color: MarketPalette.muted, fontSize: 12)),
              ],
            )),
            const SizedBox(height: 18),
            TextFormField(
              controller: _name,
              maxLength: 100,
              decoration: _decoration('اسم المحل *', hint: 'مثال: سيفورا'),
              validator: (v) => (v ?? '').trim().length < 2
                  ? 'اكتبي اسم المحل' : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: _decoration('التصنيف *'),
              isExpanded: true,
              items: ClockTowerDirectoryService.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'اختاري التصنيف' : null,
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<int>(
              value: _floor,
              decoration: _decoration('الدور في برج الساعة *'),
              items: List.generate(7, (i) => DropdownMenuItem(
                value: i + 1, child: Text('الدور ${i + 1}'))),
              onChanged: (v) => setState(() => _floor = v),
              validator: (v) => v == null ? 'اختاري الدور' : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _unit,
              maxLength: 40,
              decoration: _decoration('رقم المحل (اختياري)',
                  hint: 'مثال: AA-208'),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _note,
              maxLength: 500,
              minLines: 3,
              maxLines: 5,
              decoration: _decoration('وصف مكان المحل (اختياري)',
                  hint: 'مثال: بجوار المصعد، مقابل الكافيه'),
            ),
            const SizedBox(height: 16),
            const Text('تظهر الإضافات باعتبارها معلومات من المستخدمين، '
                'وليست مواقع معتمدة من إدارة برج الساعة.',
                style: TextStyle(fontSize: 11,
                    color: MarketPalette.muted, height: 1.6)),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: MarketPalette.emerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: _saving
                  ? const SizedBox(width: 17, height: 17,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_location_alt_outlined),
              label: Text(_saving ? 'جاري النشر...' : 'انشر المحل الآن'),
            ),
          ]),
        ),
      )),
    ),
  );
}
