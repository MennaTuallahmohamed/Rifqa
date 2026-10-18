import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/profile/rifqa_profile_store.dart';
import 'rifqa_profile_ui.dart';
import 'rifqa_trip_details_screen.dart';

class RifqaContactRow extends StatelessWidget {
  const RifqaContactRow(
      {super.key, required this.contact, this.onEdit, this.onDelete});
  final RifqaSavedContact contact;
  final VoidCallback? onEdit, onDelete;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: RpCard(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Row(children: [
                Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: Rp.mint,
                        borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.contact_phone_outlined,
                        color: Rp.green, size: 24)),
                const SizedBox(width: 11),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(contact.title,
                          style: Rp.style(13.5, weight: FontWeight.w900)),
                      if (contact.subtitle.trim().isNotEmpty)
                        Text(contact.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Rp.style(11, color: Rp.muted)),
                      Directionality(
                          textDirection: TextDirection.ltr,
                          child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(contact.phone,
                                  style: Rp.style(14,
                                      color: Rp.green,
                                      weight: FontWeight.w900)))),
                    ])),
                if (onEdit != null)
                  IconButton(
                      onPressed: onEdit,
                      tooltip: 'تعديل',
                      icon: const Icon(Icons.edit_outlined,
                          color: Rp.green, size: 20)),
                if (onDelete != null)
                  IconButton(
                      onPressed: onDelete,
                      tooltip: 'حذف',
                      icon: const Icon(Icons.delete_outline,
                          color: Rp.red, size: 20)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: FilledButton.icon(
                        onPressed: () => rpCall(context, contact.phone),
                        icon: const Icon(Icons.call_outlined, size: 18),
                        label: Text('اتصال',
                            style: Rp.style(12,
                                color: Colors.white, weight: FontWeight.w800)),
                        style: FilledButton.styleFrom(
                            backgroundColor: Rp.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))))),
                const SizedBox(width: 7),
                OutlinedButton.icon(
                    onPressed: () => rpCopy(context, contact.phone),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('نسخ'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Rp.green,
                        side: const BorderSide(color: Rp.edge),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)))),
                IconButton(
                    tooltip: 'مشاركة',
                    icon: const Icon(Icons.share_outlined, color: Rp.green),
                    onPressed: () =>
                        Share.share('${contact.title}: ${contact.phone}')),
              ]),
            ])),
      );
}

class RifqaSavedContactsScreen extends StatefulWidget {
  const RifqaSavedContactsScreen({super.key});
  @override
  State<RifqaSavedContactsScreen> createState() =>
      _RifqaSavedContactsScreenState();
}

class _RifqaSavedContactsScreenState extends State<RifqaSavedContactsScreen> {
  final store = RifqaProfileStore.instance;
  final search = TextEditingController();
  @override
  void initState() {
    super.initState();
    store.addListener(_refresh);
    store.load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    store.removeListener(_refresh);
    search.dispose();
    super.dispose();
  }

  Future<void> _edit([RifqaSavedContact? old]) async {
    final title = TextEditingController(text: old?.title ?? '');
    final phone = TextEditingController(text: old?.phone ?? '');
    final note = TextEditingController(text: old?.subtitle ?? '');
    final result = await showDialog<RifqaSavedContact>(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: Rp.cream,
              title: Text(old == null ? 'إضافة رقم مهم' : 'تعديل الرقم',
                  style: Rp.style(17, weight: FontWeight.w900)),
              content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                RpFormField(
                    controller: title,
                    label: 'اسم جهة الاتصال',
                    hint: 'مثال: شركة السياحة'),
                RpFormField(
                    controller: phone,
                    label: 'رقم الهاتف',
                    hint: 'يفضل الرقم مع كود الدولة',
                    phone: true),
                RpFormField(
                    controller: note,
                    label: 'ملاحظة (اختياري)',
                    hint: 'اسم الشخص أو وصف'),
              ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إلغاء')),
                FilledButton(
                    onPressed: () {
                      if (title.text.trim().isEmpty ||
                          !rpValidPhone(phone.text)) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('اكتبي اسمًا ورقم هاتف صالحًا.')));
                        return;
                      }
                      Navigator.pop(
                          ctx,
                          RifqaSavedContact(
                            id: old?.id ??
                                'custom_${DateTime.now().microsecondsSinceEpoch}',
                            title: title.text.trim(),
                            phone: phone.text.trim(),
                            subtitle: note.text.trim(),
                          ));
                    },
                    style: FilledButton.styleFrom(backgroundColor: Rp.green),
                    child: const Text('حفظ')),
              ],
            ));
    // Don't dispose controllers synchronously while the dialog exit animation is running.
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      title.dispose();
      phone.dispose();
      note.dispose();
    });
    if (result != null) {
      try {
        await store.upsertContact(result);
      } catch (_) {
        if (mounted) rpToast(context, 'تعذر حفظ جهة الاتصال.');
      }
    }
  }

  Future<void> _delete(RifqaSavedContact value) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('حذف جهة الاتصال؟'),
              content: Text('حذف ${value.title} من أرقامك المحفوظة؟'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('إلغاء')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('حذف'))
              ],
            ));
    if (yes == true) {
      try {
        await store.removeContact(value.id);
      } catch (_) {
        if (mounted) rpToast(context, 'تعذر حذف الرقم.');
      }
    }
  }

  bool matches(RifqaSavedContact c) {
    final q = search.text.trim().toLowerCase();
    return q.isEmpty ||
        c.title.toLowerCase().contains(q) ||
        c.subtitle.toLowerCase().contains(q) ||
        c.phone.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final fromTrip = store.tripContacts.where(matches).toList();
    final custom = store.contacts.where(matches).toList();
    return rpTextScale(
        context,
        Scaffold(
          backgroundColor: Rp.cream,
          floatingActionButton: FloatingActionButton.extended(
              backgroundColor: Rp.green,
              foregroundColor: Colors.white,
              onPressed: () => _edit(),
              icon: const Icon(Icons.add_call_rounded),
              label: Text('أضف رقم',
                  style: Rp.style(12.5,
                      color: Colors.white, weight: FontWeight.w800))),
          body: CustomScrollView(slivers: [
            const SliverToBoxAdapter(
                child: RpPhotoHeader(
                    title: 'أرقامي المحفوظة',
                    subtitle: 'جهاتك المهمة معاكِ حتى بدون إنترنت',
                    image: 'assets/rifqa_profile/madinah.jpg',
                    height: 230)),
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(17, 20, 17, 110),
                sliver: SliverList(
                    delegate: SliverChildListDelegate([
                  RpCard(
                      color: Rp.mint,
                      child: Row(children: [
                        const Icon(Icons.offline_pin_rounded, color: Rp.green),
                        const SizedBox(width: 9),
                        Expanded(
                            child: Text(
                                'الأرقام التي تحفظيها متاحة محليًا بدون إنترنت، لكن الاتصال نفسه يحتاج شبكة هاتف.',
                                style: Rp.style(11.5, color: Rp.green))),
                      ])),
                  const SizedBox(height: 17),
                  TextField(
                      controller: search,
                      onChanged: (_) => setState(() {}),
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                          hintText: 'ابحثي عن جهة أو رقم...',
                          prefixIcon: const Icon(Icons.search, color: Rp.green),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Rp.edge),
                              borderRadius: BorderRadius.circular(17)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Rp.green),
                              borderRadius: BorderRadius.circular(17)))),
                  if (fromTrip.isNotEmpty || search.text.trim().isEmpty) ...[
                    const SizedBox(height: 20),
                    const RpSectionTitle('أرقام رحلتك',
                        icon: Icons.hotel_outlined),
                    for (final c in fromTrip) RifqaContactRow(contact: c),
                    if (fromTrip.isEmpty)
                      RpEmpty(
                          title: 'لسه ما أضفتيش أرقام الرحلة',
                          subtitle:
                              'رقم الفندق والمشرف والعائلة هيظهروا هنا بعد حفظ بيانات الرحلة.'),
                    const SizedBox(height: 9),
                    OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const RifqaTripDetailsScreen())),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('تعديل بيانات الرحلة'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Rp.green,
                            side: const BorderSide(color: Rp.edge),
                            minimumSize: const Size.fromHeight(45))),
                  ],
                  const SizedBox(height: 20),
                  const RpSectionTitle('جهاتي الإضافية',
                      icon: Icons.contact_page_outlined),
                  for (final c in custom)
                    RifqaContactRow(
                        contact: c,
                        onEdit: () => _edit(c),
                        onDelete: () => _delete(c)),
                  if (custom.isEmpty)
                    RpEmpty(
                        title: 'مفيش أرقام إضافية',
                        subtitle: search.text.isEmpty
                            ? 'اضغطي «أضف رقم» لحفظ رقم شركة السياحة أو أي جهة أخرى.'
                            : 'لم نجد جهة بهذا الاسم أو الرقم.'),
                ]))),
          ]),
        ));
  }
}
