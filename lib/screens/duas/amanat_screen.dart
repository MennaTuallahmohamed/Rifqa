import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/dua_request_model.dart';
import '../../services/duas/duas_repository.dart';
import 'dua_premium_theme.dart';

class AmanatScreen extends StatelessWidget {
  const AmanatScreen({super.key, required this.repository});
  final DuasRepository repository;

  Future<void> _edit(BuildContext context, {DuaRequest? existing}) async {
    final name = TextEditingController(text: existing?.personName ?? '');
    final request = TextEditingController(text: existing?.request ?? '');
    final note = TextEditingController(text: existing?.note ?? '');
    final form = GlobalKey<FormState>();
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: DuaPremium.cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(29))),
      builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
              padding: EdgeInsets.fromLTRB(
                  19, 19, 19, MediaQuery.viewInsetsOf(ctx).bottom + 19),
              child: SingleChildScrollView(
                  child: Form(
                      key: form,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                                width: 40,
                                height: 4,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: DuaPremium.line,
                                    borderRadius: BorderRadius.circular(5))),
                            const SizedBox(height: 13),
                            Text(
                                existing == null
                                    ? 'أمانة دعاء جديدة'
                                    : 'تعديل أمانة الدعاء',
                                style: DuaPremium.type(20,
                                    weight: FontWeight.w900)),
                            Text('احتفظي بمن طلب منك الدعاء له',
                                style: DuaPremium.type(11,
                                    color: DuaPremium.muted)),
                            const SizedBox(height: 19),
                            TextFormField(
                                controller: name,
                                decoration: _decoration('الاسم'),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'اكتبي الاسم'
                                    : null),
                            const SizedBox(height: 11),
                            TextFormField(
                                controller: request,
                                minLines: 3,
                                maxLines: 6,
                                decoration: _decoration('طلب الدعاء'),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'اكتبي طلب الدعاء'
                                    : null),
                            const SizedBox(height: 11),
                            TextField(
                                controller: note,
                                decoration: _decoration('ملاحظة اختيارية')),
                            const SizedBox(height: 19),
                            DuaPrimaryButton(
                                label: 'حفظ الأمانة',
                                icon: Icons.favorite_rounded,
                                onTap: () {
                                  if (form.currentState!.validate())
                                    Navigator.pop(ctx, true);
                                }),
                          ]))))),
    );
    if (save == true) {
      try {
        if (existing == null) {
          await repository.addAmanah(
              personName: name.text, request: request.text, note: note.text);
        } else {
          await repository.updateAmanah(existing.id,
              personName: name.text, request: request.text, note: note.text);
        }
      } catch (_) {
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('تعذر حفظ الأمانة')));
      }
    }
    name.dispose();
    request.dispose();
    note.dispose();
  }

  InputDecoration _decoration(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: DuaPremium.paper,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DuaPremium.line)));

  Future<void> _delete(BuildContext context, DuaRequest item) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: DuaPremium.cream,
                title: const Text('حذف أمانة الدعاء؟'),
                content: Text('حذف طلب الدعاء الخاص بـ ${item.personName}؟'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('إلغاء')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('حذف')),
                ]));
    if (yes == true) await repository.deleteAmanah(item.id);
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: DuaPremium.cream,
          floatingActionButton: FloatingActionButton.extended(
              backgroundColor: DuaPremium.deep,
              foregroundColor: DuaPremium.gold,
              onPressed: () => _edit(context),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text('إضافة شخص',
                  style: DuaPremium.type(12, color: DuaPremium.gold))),
          body: ListenableBuilder(
              listenable: repository,
              builder: (context, _) {
                final items = repository.amanat;
                final total = items.length;
                final completed = repository.completedAmanatCount;
                return CustomScrollView(slivers: [
                  SliverToBoxAdapter(
                      child: DuaPhotoHero(
                          title: 'أمانة الدعاء',
                          subtitle: 'أسماء في قلبك، ودعوات تحملينها معك',
                          image: 'assets/duas/hero_detail.jpg',
                          height: 257,
                          onBack: () => Navigator.pop(context))),
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: DuaPremium.card(radius: 25),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      const Icon(
                                          Icons.volunteer_activism_rounded,
                                          color: DuaPremium.green,
                                          size: 26),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Text(
                                              'معاك ${total - completed} أمانة لسه مستنياك',
                                              style: DuaPremium.type(14,
                                                  weight: FontWeight.w900))),
                                    ]),
                                    const SizedBox(height: 8),
                                    Text('$completed من $total تم الدعاء لهم',
                                        style: DuaPremium.type(11,
                                            color: DuaPremium.muted)),
                                    const SizedBox(height: 13),
                                    ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                            minHeight: 9,
                                            value: total == 0
                                                ? 0
                                                : completed / total,
                                            backgroundColor: DuaPremium.line,
                                            color: DuaPremium.green)),
                                  ])))),
                  if (items.isEmpty)
                    SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                            child: Padding(
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.favorite_border_rounded,
                                          size: 62, color: DuaPremium.gold),
                                      Text('مين طلب منك تدعيله؟',
                                          style: DuaPremium.type(18,
                                              weight: FontWeight.w900)),
                                      Text(
                                          'سجلي الاسم وطلب الدعاء، وعلّمي عليه بعد ما تدعيله.',
                                          textAlign: TextAlign.center,
                                          style: DuaPremium.type(11.5,
                                              color: DuaPremium.muted)),
                                    ]))))
                  else
                    SliverList.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          return Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 11),
                              decoration: DuaPremium.card(),
                              child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                            onTap: () async {
                                              await repository
                                                  .toggleAmanahDone(item.id);
                                              HapticFeedback.selectionClick();
                                            },
                                            child: Icon(
                                                item.isPrayed
                                                    ? Icons.check_circle_rounded
                                                    : Icons
                                                        .radio_button_unchecked_rounded,
                                                size: 33,
                                                color: DuaPremium.green)),
                                        const SizedBox(width: 11),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              Text(item.personName,
                                                  style: DuaPremium.type(14,
                                                      weight: FontWeight.w900)),
                                              Text(item.request,
                                                  style: DuaPremium.type(12,
                                                      height: 1.7),
                                                  maxLines: 4,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                              if (item.note.isNotEmpty)
                                                Text(item.note,
                                                    style: DuaPremium.type(10.5,
                                                        color:
                                                            DuaPremium.muted)),
                                              if (item.isPrayed)
                                                Text('تم الدعاء ✓',
                                                    style: DuaPremium.type(11,
                                                        color: DuaPremium.green,
                                                        weight:
                                                            FontWeight.w900)),
                                            ])),
                                        PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit')
                                                _edit(context, existing: item);
                                              if (value == 'delete')
                                                _delete(context, item);
                                            },
                                            itemBuilder: (_) => const [
                                                  PopupMenuItem(
                                                      value: 'edit',
                                                      child: Text('تعديل')),
                                                  PopupMenuItem(
                                                      value: 'delete',
                                                      child: Text('حذف')),
                                                ]),
                                      ])));
                        }),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ]);
              }),
        ),
      );
}
