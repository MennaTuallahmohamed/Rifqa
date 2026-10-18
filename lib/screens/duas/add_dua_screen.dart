import 'package:flutter/material.dart';
import '../../models/dua_model.dart';
import '../../services/duas/duas_repository.dart';
import 'dua_premium_theme.dart';

class AddDuaScreen extends StatefulWidget {
  const AddDuaScreen({super.key, required this.repository, this.dua});
  final DuasRepository repository;
  final Dua? dua;
  @override
  State<AddDuaScreen> createState() => _AddDuaScreenState();
}

class _AddDuaScreenState extends State<AddDuaScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _body;
  late DuaCategory _category;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.dua?.title ?? '');
    _body = TextEditingController(text: widget.dua?.arabicText ?? '');
    _category = widget.dua?.category ?? DuaCategory.general;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      if (widget.dua == null) {
        await widget.repository.addUserDua(
            title: _title.text.trim(),
            arabicText: _body.text.trim(),
            category: _category);
      } else {
        await widget.repository.updateUserDua(widget.dua!.id,
            title: _title.text.trim(),
            arabicText: _body.text.trim(),
            category: _category);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذّر الحفظ، حاولي مرة أخرى')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: DuaPremium.cream,
          body: Form(
              key: _form,
              child: CustomScrollView(slivers: [
                SliverToBoxAdapter(
                    child: DuaPhotoHero(
                        title: widget.dua == null
                            ? 'دعاء من قلبك'
                            : 'تعديل الدعاء',
                        subtitle: 'سجّلي دعاءً يبقى معك في الرحلة',
                        image: 'assets/duas/hero_detail.jpg',
                        height: 237,
                        onBack: () => Navigator.pop(context))),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(15, 15, 15, 26),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: DuaPremium.card(),
                                  child: Text(
                                      'هذا دعاء شخصي، لا يظهر باعتباره نصًا مأثورًا أو حديثًا نبويًا.',
                                      style: DuaPremium.type(11.5))),
                              const SizedBox(height: 20),
                              Text('عنوان الدعاء',
                                  style: DuaPremium.type(14,
                                      weight: FontWeight.w900)),
                              const SizedBox(height: 7),
                              TextFormField(
                                  controller: _title,
                                  style: DuaPremium.type(13),
                                  decoration: _input('مثال: دعاء لأهلي',
                                      Icons.edit_note_rounded),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'اكتبي عنوانًا للدعاء'
                                          : null),
                              const SizedBox(height: 20),
                              Text('نص الدعاء',
                                  style: DuaPremium.type(14,
                                      weight: FontWeight.w900)),
                              const SizedBox(height: 7),
                              TextFormField(
                                  controller: _body,
                                  minLines: 6,
                                  maxLines: 13,
                                  style: DuaPremium.type(14, height: 1.8),
                                  decoration: _input('اكتبي دعاءك هنا...',
                                      Icons.volunteer_activism_outlined),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'اكتبي نص الدعاء'
                                          : null),
                              const SizedBox(height: 20),
                              Text('التصنيف',
                                  style: DuaPremium.type(14,
                                      weight: FontWeight.w900)),
                              const SizedBox(height: 9),
                              Wrap(spacing: 8, runSpacing: 9, children: [
                                for (final c in DuaCategory.values)
                                  DuaPill(
                                      label: '${c.emoji} ${c.label}',
                                      selected: _category == c,
                                      onTap: () =>
                                          setState(() => _category = c)),
                              ]),
                              const SizedBox(height: 28),
                              DuaPrimaryButton(
                                  label: _saving
                                      ? 'جارٍ الحفظ...'
                                      : (widget.dua == null
                                          ? 'احفظي في أدعيتك'
                                          : 'حفظ التعديلات'),
                                  onTap: _saving ? null : _save,
                                  icon: Icons.bookmark_add_rounded),
                            ]))),
              ])),
        ),
      );
  InputDecoration _input(String hint, IconData icon) => InputDecoration(
      filled: true,
      fillColor: DuaPremium.paper,
      hintText: hint,
      hintStyle: DuaPremium.type(11, color: DuaPremium.muted),
      prefixIcon: Icon(icon, color: DuaPremium.green),
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: DuaPremium.line)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: DuaPremium.line)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: DuaPremium.green, width: 1.5)));
}
