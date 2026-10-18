import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Rifqa Chat visual system — UI only, no Firebase state or writes.
abstract final class RifqaChat {
  static const emerald = Color(0xFF005440);
  static const deep = Color(0xFF053B31);
  static const ivory = Color(0xFFFBF7EF);
  static const cream = Color(0xFFF4ECDC);
  static const paper = Color(0xFFFFFCF7);
  static const gold = Color(0xFFC7A35B);
  static const ink = Color(0xFF182E26);
  static const muted = Color(0xFF7A837C);
  static const border = Color(0xFFE9E0D0);
  static const lightGreen = Color(0xFFE6F1EA);

  static List<BoxShadow> get shadow => [
        BoxShadow(
            color: const Color(0xFF143D2C).withValues(alpha: .065),
            blurRadius: 16,
            offset: const Offset(0, 5)),
      ];
}

class RifqaChatBackdrop extends StatelessWidget {
  const RifqaChatBackdrop({super.key, this.child});
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: RifqaChat.ivory),
      CustomPaint(painter: RifqaChatPatternPainter()),
      if (child != null) child!,
    ]);
  }
}

class RifqaChatPatternPainter extends CustomPainter {
  const RifqaChatPatternPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .55
      ..color = const Color(0xFFB6A57F).withValues(alpha: .16);
    const spacing = 43.0;
    for (var y = -spacing; y < size.height + spacing; y += spacing) {
      for (var x = -spacing; x < size.width + spacing; x += spacing) {
        final p = Path()
          ..moveTo(x + spacing / 2, y)
          ..lineTo(x + spacing, y + spacing / 2)
          ..lineTo(x + spacing / 2, y + spacing)
          ..lineTo(x, y + spacing / 2)
          ..close();
        canvas.drawPath(p, paint);
        canvas.drawCircle(Offset(x + spacing / 2, y + spacing / 2), 8, paint);
      }
    }
    final fade = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x80FBF7EF), Color(0xEEFBF7EF)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, fade);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RifqaChatAvatar extends StatelessWidget {
  const RifqaChatAvatar(
      {super.key, required this.name, this.size = 50, this.icon});
  final String name;
  final double size;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final first = name.trim().isEmpty
        ? 'ر'
        : String.fromCharCode(name.trim().runes.first);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
            colors: [Color(0xFF145B47), Color(0xFF397D63)]),
        border: Border.all(color: RifqaChat.gold, width: 1.7),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, color: const Color(0xFFFFE6B3), size: size * .48)
          : Text(first,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: size * .41)),
    );
  }
}

/// صورة حقيقية محلية للحرم بدلاً من الدائرة الافتراضية.
class RifqaPhotoAvatar extends StatelessWidget {
  final double size;
  final int variant;
  final bool showRing;
  const RifqaPhotoAvatar(
      {super.key, this.size = 52, this.variant = 0, this.showRing = true});
  static const paths = [
    'assets/images/rifqa_group_kaaba.jpg',
    'assets/images/rifqa_group_makkah.jpg',
    'assets/images/rifqa_group_mosque.jpg',
    'assets/images/rifqa_group_tower.jpg',
    'assets/images/rifqa_group_courtyard.jpg',
  ];
  @override
  Widget build(BuildContext context) {
    return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(showRing ? 2 : 0),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: RifqaChat.gold, width: showRing ? 1.5 : 0)),
        child: ClipOval(
            child: Image.asset(paths[variant.abs() % paths.length],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                    color: RifqaChat.emerald,
                    child:
                        Icon(Icons.mosque_rounded, color: RifqaChat.gold)))));
  }
}

class RifqaCinematicBanner extends StatelessWidget {
  final double height;
  final String title;
  final String subtitle;
  const RifqaCinematicBanner(
      {super.key,
      this.height = 166,
      required this.title,
      required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: RifqaChat.gold, width: 1.4),
          boxShadow: RifqaChat.shadow),
      child: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/images/rifqa_chat_banner.jpg', fit: BoxFit.cover),
        const DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
              Color(0xF705332C),
              Color(0xDB053F30),
              Color(0x2005332C)
            ],
                    stops: [
              0,
              .55,
              1
            ]))),
        Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Color(0xFFFFE5AE),
                          fontSize: 19,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white, height: 1.55, fontSize: 12.5))
                ])),
      ]));
}

class RifqaChatHeader extends StatelessWidget {
  const RifqaChatHeader(
      {super.key,
      required this.title,
      this.subtitle = '',
      this.leading,
      this.trailing});
  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: RifqaChat.paper,
          border: const Border(bottom: BorderSide(color: RifqaChat.border)),
          boxShadow: RifqaChat.shadow,
        ),
        child: Row(children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: RifqaChat.deep)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 11, color: RifqaChat.muted)),
              ])),
          if (trailing != null) trailing!,
        ]),
      );
}
