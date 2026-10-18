import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/dua_model.dart';
import '../../services/duas/duas_repository.dart';
import 'dua_premium_theme.dart';
import 'dua_audio_screen.dart';
import 'dua_prayer_mode_screen.dart';
import 'widgets/dua_card.dart';

class DuaDetailsScreen extends StatefulWidget {
  const DuaDetailsScreen(
      {super.key, required this.repository, required this.duaId});
  final DuasRepository repository;
  final String duaId;
  @override
  State<DuaDetailsScreen> createState() => _DuaDetailsScreenState();
}

class _DuaDetailsScreenState extends State<DuaDetailsScreen> {
  int _tab = 0;
  int _counter = 0;
  final List<String> _tabs = const ['النص', 'المعنى', 'المصدر'];
  void _copy(Dua dua) async {
    await Clipboard.setData(ClipboardData(text: dua.copyText));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم نسخ الدعاء')));
  }

  void _count(Dua d) {
    if (d.repeatCount > 1 && _counter >= d.repeatCount) return;
    setState(() => _counter++);
    if (d.repeatCount > 1 && _counter == d.repeatCount) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _showFontSize(DuasRepository repo) {
    showModalBottomSheet<void>(
        context: context,
        backgroundColor: DuaPremium.cream,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('حجم خط الدعاء',
                      style: DuaPremium.type(18, weight: FontWeight.w900)),
                  ListenableBuilder(
                      listenable: repo,
                      builder: (ctx, _) => Slider(
                          activeColor: DuaPremium.green,
                          min: .8,
                          max: 2,
                          divisions: 12,
                          value: repo.fontScale.clamp(.8, 2),
                          onChanged: (value) =>
                              repo.setFontScale(value, persist: false),
                          onChangeEnd: repo.setFontScale)),
                  const SizedBox(height: 8),
                ]))));
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: ListenableBuilder(
            listenable: widget.repository,
            builder: (context, _) {
              final repo = widget.repository;
              final dua = repo.byId(widget.duaId);
              if (dua == null)
                return const Scaffold(
                    body: Center(child: Text('الدعاء غير موجود')));
              final favorite = repo.isFavorite(dua.id);
              return Scaffold(
                backgroundColor: DuaPremium.cream,
                body: Stack(children: [
                  CustomScrollView(slivers: [
                    SliverToBoxAdapter(
                        child: DuaPhotoHero(
                            title: dua.title,
                            subtitle:
                                '${dua.category.label} • ${dua.sourceType.label}',
                            image: DuaPremium.imageFor(dua.category),
                            height: 253,
                            onBack: () => Navigator.pop(context),
                            actionIcon: favorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            onAction: () => repo.toggleFavorite(dua.id))),
                    SliverToBoxAdapter(
                        child: Transform.translate(
                            offset: const Offset(0, -17),
                            child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                decoration: DuaPremium.card(radius: 28),
                                child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        15, 16, 15, 20),
                                    child: Column(children: [
                                      Row(children: [
                                        DuaSourceBadge(dua.sourceType),
                                        const Spacer(),
                                        Text('تأمل الدعاء ومعناه ومصدره',
                                            style: DuaPremium.type(10.5,
                                                color: DuaPremium.muted)),
                                      ]),
                                      const SizedBox(height: 20),
                                      Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFF3EBDD),
                                              borderRadius:
                                                  BorderRadius.circular(23)),
                                          child: Row(children: [
                                            for (int i = 0;
                                                i < _tabs.length;
                                                i++)
                                              Expanded(
                                                child: Material(
                                                    color: i == _tab
                                                        ? DuaPremium.deep
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            18),
                                                    child: InkWell(
                                                        onTap: () => setState(
                                                            () => _tab = i),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                18),
                                                        child: Padding(
                                                            padding: const EdgeInsets.symmetric(
                                                                vertical: 8),
                                                            child: Text(_tabs[i],
                                                                textAlign: TextAlign
                                                                    .center,
                                                                style: DuaPremium.type(12, weight: FontWeight.w800, color: i == _tab ? Colors.white : DuaPremium.ink))))),
                                              ),
                                          ])),
                                      const SizedBox(height: 19),
                                      if (_tab == 0)
                                        _textTab(dua, repo)
                                      else if (_tab == 1)
                                        _meaningTab(dua)
                                      else
                                        _sourceTab(dua),
                                    ]))))),
                    SliverToBoxAdapter(
                        child: Padding(
                            padding: const EdgeInsets.fromLTRB(15, 2, 15, 15),
                            child: Container(
                                padding: const EdgeInsets.all(13),
                                decoration: DuaPremium.card(),
                                child: Row(children: [
                                  Icon(Icons.touch_app_rounded,
                                      color: DuaPremium.green),
                                  const SizedBox(width: 9),
                                  Expanded(
                                      child: Text(
                                          dua.repeatCount > 1
                                              ? 'عداد الذكر: $_counter / ${dua.repeatCount}'
                                              : 'يمكنك استخدام العداد أثناء الدعاء',
                                          style: DuaPremium.type(11.5,
                                              weight: FontWeight.w700))),
                                  IconButton(
                                      onPressed: () =>
                                          setState(() => _counter = 0),
                                      icon: const Icon(Icons.refresh_rounded,
                                          color: DuaPremium.muted)),
                                  FilledButton(
                                      onPressed: () => _count(dua),
                                      style: FilledButton.styleFrom(
                                          backgroundColor: DuaPremium.deep),
                                      child: Text('تسبيح',
                                          style: DuaPremium.type(11,
                                              color: Colors.white))),
                                ])))),
                    SliverToBoxAdapter(
                        child: Padding(
                            padding: const EdgeInsets.fromLTRB(15, 0, 15, 130),
                            child: DuaPrimaryButton(
                                label: 'فتح وضع الدعاء',
                                icon: Icons.fullscreen_rounded,
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                        builder: (_) => DuaPrayerModeScreen(
                                            repository: repo,
                                            duas: [dua],
                                            initialIndex: 0)))))),
                  ]),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                        top: false,
                        child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                            decoration: const BoxDecoration(
                                color: DuaPremium.paper,
                                boxShadow: [
                                  BoxShadow(
                                      color: Color(0x18000000),
                                      blurRadius: 18,
                                      offset: Offset(0, -4))
                                ],
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(26))),
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _bottomAction(Icons.bookmark_rounded, 'حفظ',
                                      () => repo.toggleFavorite(dua.id),
                                      active: favorite),
                                  _bottomAction(Icons.share_outlined, 'مشاركة',
                                      () => Share.share(dua.copyText)),
                                  _bottomAction(Icons.copy_all_rounded, 'نسخ',
                                      () => _copy(dua)),
                                  _bottomAction(Icons.text_fields_rounded,
                                      'حجم الخط', () => _showFontSize(repo)),
                                  _bottomAction(
                                      Icons.play_circle_rounded,
                                      'استماع',
                                      () => Navigator.push(
                                          context,
                                          MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  DuaAudioScreen(dua: dua)))),
                                ]))),
                  ),
                ]),
              );
            }),
      );

  Widget _textTab(Dua dua, DuasRepository repo) => Column(children: [
        Text('﷽', style: DuaPremium.type(25, color: DuaPremium.gold)),
        const SizedBox(height: 10),
        SelectableText(dua.arabicText,
            textAlign: TextAlign.center,
            style: DuaPremium.type(24 * repo.fontScale,
                weight: FontWeight.w700, height: 2.0)),
        const SizedBox(height: 18),
        SizedBox(
            width: 150,
            child: Row(children: [
              Expanded(child: Container(height: 1, color: DuaPremium.gold)),
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.auto_awesome_rounded,
                      color: DuaPremium.gold, size: 15)),
              Expanded(child: Container(height: 1, color: DuaPremium.gold)),
            ])),
        if (dua.note != null && dua.note!.isNotEmpty) ...[
          const SizedBox(height: 17),
          _note('ملاحظة', dua.note!),
        ],
      ]);

  Widget _meaningTab(Dua dua) {
    return Column(children: [
      const Icon(Icons.menu_book_outlined, color: DuaPremium.green, size: 29),
      const SizedBox(height: 11),
      if (dua.translations.isEmpty)
        Text('لا توجد ترجمة معتمدة لهذا الدعاء حاليًا.',
            textAlign: TextAlign.center,
            style: DuaPremium.type(13, color: DuaPremium.muted))
      else
        for (final item in dua.translations.entries) ...[
          _note('المعنى (${item.key})', item.value),
          const SizedBox(height: 12),
        ],
      if (dua.transliteration != null && dua.transliteration!.isNotEmpty)
        _note('النطق بالحروف اللاتينية', dua.transliteration!),
    ]);
  }

  Widget _sourceTab(Dua dua) => Column(children: [
        const Icon(Icons.verified_outlined, color: DuaPremium.green, size: 30),
        const SizedBox(height: 10),
        _note(
            'المصدر',
            dua.reference.isNotEmpty
                ? dua.reference
                : 'لم يحدَّد مصدر لهذا الدعاء'),
        if (dua.grade != null) ...[
          const SizedBox(height: 12),
          _note('الدرجة', dua.grade!)
        ],
        if (dua.sourceType.disclaimer != null) ...[
          const SizedBox(height: 12),
          _note('تنبيه', dua.sourceType.disclaimer!),
        ],
        if (kDebugMode && dua.needsReview) ...[
          const SizedBox(height: 12),
          _note('مراجعة علمية مطلوبة',
              'هذا النص عليه علامة مراجعة في بيانات التطبيق؛ لا يُنشر باعتباره مُراجَعًا بعد.'),
        ],
      ]);
  Widget _note(String title, String text) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: const Color(0xFFF8EEDC),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: DuaPremium.type(12,
                weight: FontWeight.w900, color: DuaPremium.green)),
        const SizedBox(height: 6),
        SelectableText(text, style: DuaPremium.type(12.5, height: 1.9)),
      ]));
  Widget _bottomAction(IconData icon, String title, VoidCallback tap,
          {bool active = false}) =>
      InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon,
                    color: active ? DuaPremium.gold : DuaPremium.green,
                    size: 22),
                Text(title, style: DuaPremium.type(9, weight: FontWeight.w700)),
              ])));
}
