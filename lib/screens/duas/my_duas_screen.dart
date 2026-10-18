import 'package:flutter/material.dart';
import '../../models/dua_model.dart';
import '../../services/duas/duas_repository.dart';
import 'dua_premium_theme.dart';
import 'add_dua_screen.dart';
import 'dua_details_screen.dart';

class MyDuasScreen extends StatelessWidget {
  const MyDuasScreen({super.key, required this.repository});
  final DuasRepository repository;
  Future<void> _delete(BuildContext context, Dua dua) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: DuaPremium.cream,
                title: const Text('حذف الدعاء؟'),
                content: Text('هل تريدين حذف «${dua.title}» من أدعيتك؟'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('إلغاء')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('حذف')),
                ]));
    if (confirmed == true) await repository.deleteUserDua(dua.id);
  }

  void _route(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: DuaPremium.cream,
          floatingActionButton: FloatingActionButton.extended(
              backgroundColor: DuaPremium.deep,
              foregroundColor: DuaPremium.gold,
              onPressed: () =>
                  _route(context, AddDuaScreen(repository: repository)),
              icon: const Icon(Icons.add_rounded),
              label: Text('دعاء جديد',
                  style: DuaPremium.type(12,
                      color: DuaPremium.gold, weight: FontWeight.w800))),
          body: ListenableBuilder(
              listenable: repository,
              builder: (context, _) {
                final list = repository.userDuas;
                return CustomScrollView(slivers: [
                  SliverToBoxAdapter(
                      child: DuaPhotoHero(
                          title: 'أدعيتي',
                          subtitle: 'مساحة خاصة لأدعيتك التي تكتبينها بنفسك',
                          image: 'assets/duas/hero_detail.jpg',
                          height: 247,
                          onBack: () => Navigator.pop(context))),
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(17, 17, 17, 17),
                          child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: DuaPremium.card(),
                              child: Row(children: [
                                const Icon(Icons.lock_outline_rounded,
                                    color: DuaPremium.green),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(
                                        'الأدعية هنا من كتابتك، ومنفصلة عن الأدعية الموثّقة في المكتبة.',
                                        style: DuaPremium.type(11,
                                            color: DuaPremium.ink))),
                              ])))),
                  if (list.isEmpty)
                    SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                            child: Padding(
                                padding: const EdgeInsets.all(26),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.auto_stories_outlined,
                                          size: 62, color: DuaPremium.gold),
                                      const SizedBox(height: 13),
                                      Text('دفتر أدعيتك لسه فاضي',
                                          style: DuaPremium.type(17,
                                              weight: FontWeight.w900)),
                                      const SizedBox(height: 7),
                                      Text(
                                          'اكتبي دعاءك الأول، وهتلاقيه محفوظ هنا.',
                                          textAlign: TextAlign.center,
                                          style: DuaPremium.type(11,
                                              color: DuaPremium.muted)),
                                    ]))))
                  else
                    SliverList.builder(
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final dua = list[i];
                          return Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            decoration: DuaPremium.card(),
                            child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => _route(
                                    context,
                                    DuaDetailsScreen(
                                        repository: repository, duaId: dua.id)),
                                child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(children: [
                                      Container(
                                          width: 45,
                                          height: 45,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFEDE8D7),
                                              borderRadius:
                                                  BorderRadius.circular(15)),
                                          child: Text(dua.category.emoji,
                                              style: const TextStyle(
                                                  fontSize: 23))),
                                      const SizedBox(width: 11),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(dua.title,
                                                style: DuaPremium.type(14,
                                                    weight: FontWeight.w900)),
                                            Text(dua.arabicText,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: DuaPremium.type(11,
                                                    color: DuaPremium.muted)),
                                          ])),
                                      PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'edit')
                                              _route(
                                                  context,
                                                  AddDuaScreen(
                                                      repository: repository,
                                                      dua: dua));
                                            if (value == 'delete')
                                              _delete(context, dua);
                                          },
                                          itemBuilder: (_) => const [
                                                PopupMenuItem(
                                                    value: 'edit',
                                                    child: Text('تعديل')),
                                                PopupMenuItem(
                                                    value: 'delete',
                                                    child: Text('حذف')),
                                              ]),
                                    ]))),
                          );
                        }),
                  const SliverToBoxAdapter(child: SizedBox(height: 95)),
                ]);
              }),
        ),
      );
}
