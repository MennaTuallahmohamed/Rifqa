import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/dua_model.dart';
import '../../services/duas/duas_repository.dart';
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
  int _count = 0;

  static const _langNames = {
    'en': 'English',
    'ur': 'اردو',
    'id': 'Indonesia',
    'tr': 'Türkçe',
  };

  Future<void> _copy(Dua d) async {
    await Clipboard.setData(ClipboardData(text: d.copyText));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('تم نسخ الدعاء')));
  }

  void _tap(Dua d) {
    setState(() => _count++);
    if (d.repeatCount > 1 && _count == d.repeatCount) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListenableBuilder(
        listenable: widget.repository,
        builder: (context, _) {
          final repo = widget.repository;
          final dua = repo.byId(widget.duaId);
          if (dua == null) {
            return const Scaffold(
                body: Center(child: Text('الدعاء غير موجود')));
          }
          final t = Theme.of(context);
          final fav = repo.isFavorite(dua.id);
          final disclaimer = dua.sourceType.disclaimer;

          return Scaffold(
            appBar: AppBar(
              title: Text(dua.title, style: const TextStyle(fontSize: 18)),
              actions: [
                IconButton(
                  tooltip: 'نسخ',
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () => _copy(dua),
                ),
                IconButton(
                  tooltip: fav ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
                  icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
                      color: fav ? Colors.redAccent : null),
                  onPressed: () => repo.toggleFavorite(dua.id),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(spacing: 8, runSpacing: 6, children: [
                  DuaSourceBadge(dua.sourceType),
                  Chip(
                    label: Text(dua.category.label),
                    visualDensity: VisualDensity.compact,
                  ),
                ]),
                const SizedBox(height: 12),

                // النص العربي
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 24),
                    child: SelectableText(
                      dua.arabicText,
                      textAlign: TextAlign.center,
                      style: t.textTheme.headlineSmall?.copyWith(
                        fontSize: 24 * repo.fontScale,
                        height: 2.1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // التحكم في حجم الخط
                Row(children: [
                  const Icon(Icons.text_decrease, size: 20),
                  Expanded(
                    child: Slider(
                      min: 0.8,
                      max: 2.0,
                      divisions: 12,
                      value: repo.fontScale.clamp(0.8, 2.0),
                      onChanged: (v) => repo.setFontScale(v, persist: false),
                      onChangeEnd: (v) => repo.setFontScale(v),
                    ),
                  ),
                  const Icon(Icons.text_increase, size: 20),
                ]),

                // العداد
                _counter(dua, t),

                // النطق
                if (dua.transliteration != null) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('عرض النطق بالحروف اللاتينية'),
                    value: repo.showTransliteration,
                    onChanged: repo.setShowTransliteration,
                  ),
                  if (repo.showTransliteration)
                    _section('النطق', dua.transliteration!, t, ltr: true),
                ],

                // المعنى
                if (dua.translations.isNotEmpty) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('عرض المعنى'),
                    value: repo.showTranslation,
                    onChanged: repo.setShowTranslation,
                  ),
                  if (repo.showTranslation)
                    for (final e in dua.translations.entries)
                      _section(
                          'المعنى (${_langNames[e.key] ?? e.key})', e.value, t,
                          ltr: e.key != 'ur'),
                ],

                // المصدر
                _sourceCard(dua, t),

                if (disclaimer != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(disclaimer,
                                  style: t.textTheme.bodySmall)),
                        ]),
                  ),

                if (kDebugMode && dua.needsReview)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      '⚠️ [Debug فقط] هذا المحتوى يحتاج مراجعة شرعية قبل الإطلاق.',
                      style: t.textTheme.bodySmall
                          ?.copyWith(color: t.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _counter(Dua d, ThemeData t) {
    final target = d.repeatCount;
    final done = target > 1 && _count >= target;
    return Card(
      color: done ? t.colorScheme.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _tap(d),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Text(
              target > 1 ? '$_count / $target' : '$_count',
              style: t.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(done ? 'تم العدد المطلوب ✓' : 'اضغط للعدّ',
                  style: t.textTheme.bodyMedium),
            ),
            IconButton(
              tooltip: 'تصفير',
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => _count = 0),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _section(String title, String body, ThemeData t, {bool ltr = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: t.textTheme.labelLarge
                    ?.copyWith(color: t.colorScheme.primary)),
            const SizedBox(height: 6),
            Directionality(
              textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
              child: Align(
                alignment: ltr ? Alignment.centerLeft : Alignment.centerRight,
                child: Text(body,
                    style: t.textTheme.bodyMedium?.copyWith(height: 1.7)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _sourceCard(Dua d, ThemeData t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('المصدر',
              style: t.textTheme.labelLarge
                  ?.copyWith(color: t.colorScheme.primary)),
          const SizedBox(height: 6),
          Text(d.reference,
              style: t.textTheme.bodyMedium?.copyWith(height: 1.7)),
          if (d.grade != null) ...[
            const SizedBox(height: 6),
            Text('الدرجة: ${d.grade}', style: t.textTheme.bodyMedium),
          ],
          if (d.note != null) ...[
            const SizedBox(height: 8),
            Text('ملاحظة: ${d.note}',
                style: t.textTheme.bodySmall?.copyWith(height: 1.6)),
          ],
        ]),
      ),
    );
  }
}
