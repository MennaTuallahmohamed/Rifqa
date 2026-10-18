import 'package:flutter/material.dart';
import '../../../models/dua_model.dart';
import '../dua_premium_theme.dart';

class DuaShareCard extends StatelessWidget {
  const DuaShareCard({super.key, required this.dua, this.showSource = true});
  final Dua dua;
  final bool showSource;
  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 4 / 5,
        child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: DuaPremium.cream,
                borderRadius: BorderRadius.circular(27),
                border: Border.all(color: DuaPremium.gold, width: 1.3)),
            child: Column(children: [
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: DuaPremium.deep,
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.auto_stories_rounded,
                        color: DuaPremium.gold, size: 22)),
                const SizedBox(width: 9),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('رِفقة',
                          style: DuaPremium.type(18, weight: FontWeight.w900)),
                      Text('رفيقك في الرحلة',
                          style: DuaPremium.type(10, color: DuaPremium.muted)),
                    ])),
                const Icon(Icons.favorite_border_rounded,
                    color: DuaPremium.green),
              ]),
              const Spacer(),
              Text(dua.title,
                  textAlign: TextAlign.center,
                  style: DuaPremium.type(17, weight: FontWeight.w900)),
              const SizedBox(height: 13),
              Flexible(
                  child: SingleChildScrollView(
                      child: SelectableText(dua.arabicText,
                          textAlign: TextAlign.center,
                          style: DuaPremium.type(21,
                              height: 2, weight: FontWeight.w700)))),
              const Spacer(),
              if (showSource && dua.reference.isNotEmpty) ...[
                const Divider(color: DuaPremium.line),
                Text(dua.reference,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: DuaPremium.type(9.5, color: DuaPremium.muted)),
              ],
              const SizedBox(height: 6),
              Text('${dua.category.emoji} ${dua.category.label}',
                  style: DuaPremium.type(11,
                      weight: FontWeight.w900, color: DuaPremium.green)),
            ])),
      );
}
