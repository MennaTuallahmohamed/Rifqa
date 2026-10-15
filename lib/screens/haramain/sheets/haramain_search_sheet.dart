import 'package:flutter/material.dart';

import '../haramain_live_models.dart';
import '../theme/haramain_design.dart';
import '../widgets/haramain_trust.dart';
import 'haramain_poi_sheet.dart';
import 'haramain_sheet.dart';
import '../../../services/haramain/haramain_search_service.dart';

Future<HlPoi?> showHaramainSearchSheet(
  BuildContext context, {
  required List<HlPoi> pois,
  required List<String> recent,
  required void Function(String query) onQueryUsed,
}) {
  return showHaramainSheet<HlPoi>(context, (ctx) {
    return _SearchBody(pois: pois, recent: recent, onQueryUsed: onQueryUsed);
  });
}

class _SearchBody extends StatefulWidget {
  const _SearchBody({
    required this.pois,
    required this.recent,
    required this.onQueryUsed,
  });
  final List<HlPoi> pois;
  final List<String> recent;
  final void Function(String query) onQueryUsed;

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  final _ctl = TextEditingController();
  final _search = HaramainSearchService();
  final _focus = FocusNode();
  bool _accessibleOnly = false;

  @override
  void dispose() {
    _ctl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _ctl.text;
    final res = _search.search(
      widget.pois,
      q,
      accessibleOnly: _accessibleOnly,
    );
    final total = widget.pois.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sheetTitle(
          'إلى أين؟',
          subtitle: total == 0
              ? 'لا توجد نقاط مسجّلة في بيانات هذا الحرم بعد'
              : '$total نقطة في بيانات هذا الحرم',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ctl,
          focusNode: _focus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'باب 79، زمزم، دورة مياه، مصعد...',
            prefixIcon: const Icon(Icons.search_rounded, color: HmTheme.emerald),
            suffixIcon: q.isEmpty
                ? null
                : IconButton(
                    onPressed: () => setState(() => _ctl.clear()),
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: HmTheme.ivory,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (q.isEmpty && widget.recent.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('عمليات بحث سابقة',
              style: TextStyle(color: HmTheme.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final r in widget.recent.take(6))
                ActionChip(
                  label: Text(r),
                  onPressed: () {
                    _ctl.text = r;
                    setState(() {});
                  },
                ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilterChip(
                avatar: Icon(
                  Icons.accessible_rounded,
                  size: 17,
                  color: _accessibleOnly ? Colors.white : HmTheme.emerald,
                ),
                label: Text(_accessibleOnly ? 'الميسّرة فقط' : 'كل النقاط'),
                selected: _accessibleOnly,
                showCheckmark: false,
                selectedColor: HmTheme.emerald,
                backgroundColor: Colors.white,
                side: const BorderSide(color: HmTheme.line),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: _accessibleOnly ? Colors.white : HmTheme.ink,
                ),
                onSelected: (v) => setState(() => _accessibleOnly = v),
              ),
            ),
            if (res.isNotEmpty)
              Text(
                '${res.length} نتيجة',
                style: HmTheme.caption,
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (total == 0)
          const HmNotice(
            message:
                'لا توجد نقاط بإحداثيات في بيانات هذا الحرم بعد. يمكنك تثبيت '
                'أماكنك (بابك، فندقك، نقطة تجمع) بالضغط المطوّل على الخريطة.',
            icon: Icons.map_outlined,
          )
        else if (res.isEmpty)
          const HmNotice(
            message:
                'لا توجد نتائج مطابقة. جرّب كلمة أبسط مثل «باب» أو «مياه»، أو '
                'تحقّق من فلاتر الوصول.',
            icon: Icons.search_off_rounded,
          )
        else
          for (final p in res)
            _ResultTile(
              poi: p,
              onTap: () {
                widget.onQueryUsed(_ctl.text);
                Navigator.pop(context, p);
              },
            ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.poi, required this.onTap});

  final HlPoi poi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = poi;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HmTheme.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: p.category.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(p.category.icon, color: p.category.color, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          p.category.label,
                          if (p.subtitle.isNotEmpty) p.subtitle,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HmTheme.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                HmTrustBadge(trust: p.trust, isPin: p.isPin, dense: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
