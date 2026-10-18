import 'package:flutter/material.dart';
import '../../../models/dua_model.dart';
import '../dua_premium_theme.dart';

class NowDuaBanner extends StatelessWidget {
  const NowDuaBanner(
      {super.key,
      required this.dua,
      required this.stage,
      required this.onTap,
      this.subtitle});
  final Dua dua;
  final RitualStage stage;
  final VoidCallback onTap;
  final String? subtitle;
  String get _stageText => switch (stage) {
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
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: DuaPremium.card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(DuaPremium.imageFor(dua.category),
                          width: 91, height: 122, fit: BoxFit.cover)),
                  const SizedBox(width: 13),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('الدعاء المناسب دلوقتي • $_stageText',
                            style: DuaPremium.type(10,
                                color: DuaPremium.green,
                                weight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        Text(dua.title,
                            style:
                                DuaPremium.type(15, weight: FontWeight.w900)),
                        Text(dua.arabicText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: DuaPremium.type(11.5, height: 1.8)),
                        if (subtitle != null)
                          Text(subtitle!,
                              style: DuaPremium.type(10.5,
                                  color: DuaPremium.muted)),
                        const SizedBox(height: 6),
                        Text(dua.sourceType.label,
                            style:
                                DuaPremium.type(10, color: DuaPremium.green)),
                      ])),
                ]))),
      ));
}
