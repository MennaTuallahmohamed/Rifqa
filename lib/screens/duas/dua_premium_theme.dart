import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/dua_model.dart';

/// Rifqa's premium visual system. Presentation only; does not change any data.
abstract final class DuaPremium {
  static const Color deep = Color(0xFF063D30);
  static const Color green = Color(0xFF075844);
  static const Color gold = Color(0xFFDDB86C);
  static const Color cream = Color(0xFFFBF6ED);
  static const Color paper = Color(0xFFFFFCF7);
  static const Color ink = Color(0xFF133D34);
  static const Color muted = Color(0xFF819086);
  static const Color line = Color(0xFFE9DDCB);

  static TextStyle type(double size,
          {FontWeight weight = FontWeight.w500,
          Color color = ink,
          double height = 1.45}) =>
      GoogleFonts.cairo(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  static BoxDecoration card({double radius = 24, Color color = paper}) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: line.withOpacity(.78)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0E3B2914), blurRadius: 17, offset: Offset(0, 7))
        ],
      );

  static String imageFor(DuaCategory category) {
    switch (category.name) {
      case 'tawaf':
        return 'assets/duas/tile_tawaf.jpg';
      case 'sai':
        return 'assets/duas/tile_sai.jpg';
      case 'travel':
        return 'assets/duas/tile_travel.jpg';
      case 'mosque':
        return 'assets/duas/tile_mosque.jpg';
      case 'hajj':
        return 'assets/duas/tile_hajj.jpg';
      case 'umrah':
        return 'assets/duas/tile_umrah.jpg';
      default:
        return 'assets/duas/tile_general.jpg';
    }
  }
}

class DuaPhotoHero extends StatelessWidget {
  const DuaPhotoHero(
      {super.key,
      required this.title,
      required this.subtitle,
      this.image = 'assets/duas/hero_kaaba.jpg',
      this.height = 264,
      this.onBack,
      this.onAction,
      this.actionIcon = Icons.bookmark_border_rounded});
  final String title, subtitle, image;
  final double height;
  final VoidCallback? onBack, onAction;
  final IconData actionIcon;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(fit: StackFit.expand, children: [
        Image.asset(image, fit: BoxFit.cover),
        const DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x85031914), Color(0x15031914), Color(0xED062B23)],
          stops: [0, .36, 1],
        ))),
        Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 16,
            right: 16,
            child: Row(children: [
              if (onBack != null)
                DuaCircleAction(
                    icon: Icons.arrow_forward_rounded, onTap: onBack!)
              else
                const SizedBox(width: 44),
              const Spacer(),
              if (onAction != null)
                DuaCircleAction(icon: actionIcon, onTap: onAction!),
            ])),
        Positioned(
            bottom: 28,
            left: 16,
            right: 16,
            child: Column(children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: DuaPremium.type(31,
                      weight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.25)),
              const SizedBox(height: 5),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: DuaPremium.type(12.5, color: const Color(0xFFF7E9CE))),
            ])),
      ]),
    );
  }
}

class DuaCircleAction extends StatelessWidget {
  const DuaCircleAction(
      {super.key,
      required this.icon,
      required this.onTap,
      this.fill = DuaPremium.deep,
      this.color = DuaPremium.gold});
  final IconData icon;
  final VoidCallback onTap;
  final Color fill, color;
  @override
  Widget build(BuildContext context) => Material(
        color: fill.withOpacity(.93),
        shape: const CircleBorder(),
        child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, color: color, size: 22))),
      );
}

class DuaSectionHeading extends StatelessWidget {
  const DuaSectionHeading(
      {super.key, required this.title, this.subtitle, this.action, this.onTap});
  final String title;
  final String? subtitle, action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 4,
            height: 25,
            decoration: BoxDecoration(
                color: DuaPremium.gold,
                borderRadius: BorderRadius.circular(5))),
        const SizedBox(width: 9),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: DuaPremium.type(18, weight: FontWeight.w900)),
          if (subtitle != null)
            Text(subtitle!,
                style: DuaPremium.type(10.5, color: DuaPremium.muted)),
        ])),
        if (action != null)
          TextButton(
              onPressed: onTap,
              child: Text(action!,
                  style: DuaPremium.type(11,
                      weight: FontWeight.w800, color: DuaPremium.green))),
      ]);
}

class DuaPill extends StatelessWidget {
  const DuaPill(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap,
      this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Material(
        color: selected ? DuaPremium.deep : const Color(0xFFF3EBDD),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onTap,
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[
                    Icon(icon,
                        size: 15,
                        color: selected ? DuaPremium.gold : DuaPremium.ink),
                    const SizedBox(width: 6)
                  ],
                  Text(label,
                      style: DuaPremium.type(11,
                          weight: FontWeight.w700,
                          color: selected ? Colors.white : DuaPremium.ink)),
                ]))),
      );
}

class DuaPrimaryButton extends StatelessWidget {
  const DuaPrimaryButton(
      {super.key,
      required this.label,
      required this.onTap,
      this.icon = Icons.arrow_back_rounded});
  final String label;
  final VoidCallback? onTap;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton.icon(
            onPressed: onTap,
            icon: Icon(icon, color: DuaPremium.gold),
            style: FilledButton.styleFrom(
                backgroundColor: DuaPremium.deep,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18))),
            label: Text(label,
                style: DuaPremium.type(14,
                    weight: FontWeight.w800, color: Colors.white))),
      );
}
