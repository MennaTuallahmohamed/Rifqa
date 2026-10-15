import 'package:flutter/material.dart';

import '../../../models/dua_model.dart';

class NowDuaBanner extends StatelessWidget {
  const NowDuaBanner({
    super.key,
    required this.dua,
    required this.stage,
    required this.onTap,
    this.subtitle,
  });

  final Dua dua;
  final RitualStage stage;
  final VoidCallback onTap;
  final String? subtitle;

  String get _stageText {
    return switch (stage) {
      RitualStage.none => 'مناسب الآن',
      RitualStage.preTravel => 'قبل السفر',
      RitualStage.ihram => 'أثناء الإحرام',
      RitualStage.enteringHaram => 'عند دخول الحرم',
      RitualStage.tawaf => 'أثناء الطواف',
      RitualStage.afterTawaf => 'بعد الطواف',
      RitualStage.sai => 'أثناء السعي',
      RitualStage.arafah => 'يوم عرفة',
      RitualStage.muzdalifah => 'في مزدلفة',
      RitualStage.jamarat => 'عند الجمرات',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colors.primaryContainer,
            colors.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 17),
                          SizedBox(width: 5),
                          Text(
                            'الدعاء المناسب دلوقتي',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _stageText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  dua.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  dua.arabicText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.9,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      dua.sourceType.isDocumented
                          ? Icons.verified_rounded
                          : Icons.info_outline_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        dua.sourceType.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Icon(Icons.arrow_back_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
