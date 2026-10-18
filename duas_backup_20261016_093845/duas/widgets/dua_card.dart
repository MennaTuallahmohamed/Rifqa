import 'package:flutter/material.dart';

import '../../../models/dua_model.dart';

/// شارة المصدر: بتفرّق بصريًا بين الموثّق والعام والمستخدم والـAI.
class DuaSourceBadge extends StatelessWidget {
  const DuaSourceBadge(this.type, {super.key});
  final DuaSourceType type;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg, icon) = switch (type) {
      DuaSourceType.quran || DuaSourceType.hadith || DuaSourceType.mathur => (
          cs.primaryContainer,
          cs.onPrimaryContainer,
          Icons.verified_outlined
        ),
      DuaSourceType.generalPermissible => (
          cs.secondaryContainer,
          cs.onSecondaryContainer,
          Icons.info_outline
        ),
      DuaSourceType.userCreated => (
          cs.tertiaryContainer,
          cs.onTertiaryContainer,
          Icons.edit_note
        ),
      DuaSourceType.aiAssisted => (
          cs.errorContainer,
          cs.onErrorContainer,
          Icons.auto_awesome
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 4),
        Text(type.label,
            style: TextStyle(
                fontSize: 11.5, color: fg, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class DuaCard extends StatelessWidget {
  const DuaCard({
    super.key,
    required this.dua,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  final Dua dua;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dua.title,
                        style: t.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      dua.arabicText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.bodyLarge?.copyWith(height: 1.9),
                    ),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      DuaSourceBadge(dua.sourceType),
                      if (dua.repeatCount > 1)
                        Chip(
                          label: Text('×${dua.repeatCount}'),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                    ]),
                  ]),
            ),
            IconButton(
              tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
              onPressed: onFavorite,
              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.redAccent : null),
            ),
          ]),
        ),
      ),
    );
  }
}
