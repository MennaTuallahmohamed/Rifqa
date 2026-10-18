import 'package:flutter/material.dart';
import 'umrah_data.dart';

abstract final class UGold {
  static const deep = Color(0xFF063C31);
  static const green = Color(0xFF075B48);
  static const cream = Color(0xFFFCF8F0);
  static const gold = Color(0xFFD5B674);
  static const ink = Color(0xFF193D33);
}

class UPhoto extends StatelessWidget {
  const UPhoto({super.key, required this.asset, this.alignment = Alignment.center});
  final String asset;
  final Alignment alignment;
  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    fit: BoxFit.cover,
    alignment: alignment,
    errorBuilder: (_, __, ___) => const DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(
        colors: [UGold.deep, UGold.green],
        begin: Alignment.topRight, end: Alignment.bottomLeft)),
    ),
  );
}

class UPremiumHero extends StatelessWidget {
  const UPremiumHero({super.key, required this.done});
  final int done;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
    child: SizedBox(
      height: 336 + MediaQuery.paddingOf(context).top,
      child: Stack(fit: StackFit.expand, children: [
        const UPhoto(asset: 'assets/umrah/umrah_hero.jpg'),
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xD407332B), Color(0x99052824), Color(0xEC052C25)],
        ))),
        Positioned.fill(child: SafeArea(bottom: false, child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('دليل العمرة', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 5),
                const Text('رحلة روحانية، خطوة بخطوة', style: TextStyle(fontSize: 15, color: Color(0xFFFFE5AA))),
                const SizedBox(height: 12),
                Container(width: 64, height: 2, color: UGold.gold),
                const SizedBox(height: 12),
                const Text('من النية إلى التحلل، معك في كل خطوة', style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.6)),
              ])),
              SizedBox(width: 83, height: 83, child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(child: CircularProgressIndicator(value: done / 7, strokeWidth: 6, backgroundColor: Colors.white30, valueColor: const AlwaysStoppedAnimation(UGold.gold))),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$done/7', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 21)),
                  const Text('مكتملة', style: TextStyle(color: Colors.white70, fontSize: 9)),
                ])
              ])),
            ]),
            const Spacer(),
            Wrap(spacing: 7, runSpacing: 8, children: const [
              _HPill('الإحرام', Icons.checkroom_rounded),
              _HPill('الطواف', Icons.view_in_ar_rounded),
              _HPill('السعي', Icons.directions_walk_rounded),
              _HPill('التحلل', Icons.content_cut_rounded),
            ])
          ])))),
      ]),
    ),
  );
}
class _HPill extends StatelessWidget {
  const _HPill(this.text, this.icon);
  final String text; final IconData icon;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(color: const Color(0x440A4033), borderRadius: BorderRadius.circular(30), border: Border.all(color: UGold.gold.withValues(alpha: .8))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: UGold.gold), const SizedBox(width: 5), Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))]),
  );
}

class UPremiumSectionTitle extends StatelessWidget {
  const UPremiumSectionTitle(this.title, {super.key});
  final String title;
  @override Widget build(BuildContext context) => Row(children: [
    Container(width: 3, height: 20, decoration: BoxDecoration(color: UGold.gold, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(color: UGold.ink, fontWeight: FontWeight.w900, fontSize: 19)),
  ]);
}

class UPremiumStepCover extends StatelessWidget {
  const UPremiumStepCover({super.key, required this.index, required this.step});
  final int index;
  final UStep step;
  @override Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: SizedBox(height: 190, child: Stack(fit: StackFit.expand, children: [
      UPhoto(asset: 'assets/umrah/step_${index + 1}.jpg'),
      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.centerLeft, end: Alignment.centerRight,
        colors: [Color(0xC907382E), Color(0x0007382E)]))),
      Positioned(left: 15, bottom: 18, right: 115, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.auto_awesome_rounded, color: UGold.gold, size: 20),
        const SizedBox(height: 8),
        Text(step.title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(step.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4)),
      ])),
    ])),
  );
}

class UPremiumToolTile extends StatelessWidget {
  const UPremiumToolTile({super.key, required this.title, required this.icon, required this.onTap, required this.index});
  final String title; final IconData icon; final VoidCallback onTap; final int index;
  @override Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFFEFA), borderRadius: BorderRadius.circular(21),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(21), child: Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(21), border: Border.all(color: const Color(0xFFE7DCCA))),
      padding: const EdgeInsets.all(8), child: Column(children: [
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Stack(fit: StackFit.expand, children: [
          UPhoto(asset: 'assets/umrah/umrah_scene_${(index % 5) + 1}.jpg'),
          const DecoratedBox(decoration: BoxDecoration(color: Color(0x38043A2D))),
          Center(child: Container(width: 47, height: 47, decoration: BoxDecoration(color: UGold.deep.withValues(alpha: .90), borderRadius: BorderRadius.circular(15), border: Border.all(color: UGold.gold)), child: Icon(icon, color: UGold.gold, size: 26))),
        ]))),
        const SizedBox(height: 8),
        Text(title, maxLines: 1, style: const TextStyle(color: UGold.ink, fontWeight: FontWeight.w800, fontSize: 12.5)),
        const SizedBox(height: 2),
      ]),
    )),
  );
}
