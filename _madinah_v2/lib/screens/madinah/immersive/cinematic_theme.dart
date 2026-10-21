import 'package:flutter/material.dart';

/// Rifqa / Madinah visual identity. The photos are local offline assets.
const cinematicGreen = Color(0xFF073F31);
const cinematicDeep = Color(0xFF031C15);
const cinematicGold = Color(0xFFE6BD71);
const cinematicCream = Color(0xFFFFF7E8);
const cinematicMuted = Color(0xFFE0DFD5);
const cinematicAssets = 'assets/images/madinah_cinematic';
const cinematicIllustrationNote =
    'الصور مشاهد توضيحية وليست إعادة بناء تاريخية موثقة للأحداث.';

/// Never hide a missing picture behind an empty green rectangle. Show exact
/// diagnostic asset path so the user can fix it, even in a release APK.
class CinematicImage extends StatelessWidget {
  const CinematicImage(this.path, {super.key, this.alignment = Alignment.center,
      this.fit = BoxFit.cover});
  final String path;
  final Alignment alignment;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) => Image.asset(
      path,
      width: size.maxWidth.isFinite ? size.maxWidth : null,
      height: size.maxHeight.isFinite ? size.maxHeight : null,
      fit: fit,
      alignment: alignment,
      gaplessPlayback: true,
      errorBuilder: (context, error, trace) => ColoredBox(
        color: cinematicGreen,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.broken_image_outlined, color: cinematicGold, size: 36),
            const SizedBox(height: 7),
            const Text('الصورة غير موجودة في الـAssets',
              style: TextStyle(color: cinematicCream, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
            const SizedBox(height: 7),
            Text(path, textAlign: TextAlign.center, maxLines: 3,
              style: const TextStyle(color: cinematicGold, fontSize: 10)),
          ])),
        ),
      ),
    ),
  );
}

class CinematicPill extends StatelessWidget {
  const CinematicPill({super.key, required this.text,
    this.icon = Icons.view_in_ar_rounded});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: cinematicDeep.withOpacity(.79),
      border: Border.all(color: cinematicGold.withOpacity(.75)),
      borderRadius: BorderRadius.circular(40),
    ),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: cinematicGold, size: 17),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: cinematicCream,
          fontSize: 13, fontWeight: FontWeight.w700)),
      ])),
  );
}

class CinematicButton extends StatelessWidget {
  const CinematicButton({super.key, required this.label, required this.onPressed,
    this.icon = Icons.arrow_back_ios_new_rounded, this.gold = true});
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool gold;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: gold
        ? const [Color(0xFFF9E1AC), Color(0xFFE2B15C)]
        : const [Color(0xFF116A50), Color(0xFF064331)]),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: cinematicGold.withOpacity(.75)),
      boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 16,
        offset: Offset(0, 7))],
    ),
    child: Material(color: Colors.transparent, child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onPressed,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 14),
        child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: gold ? cinematicGreen : cinematicCream,
              fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(width: 10),
            Icon(icon, size: 19, color: gold ? cinematicGreen : cinematicGold),
          ])),
    )),
  );
}

class CinematicHeading extends StatelessWidget {
  const CinematicHeading(this.text, {super.key, this.subtitle, this.center = true,
    this.size = 31});
  final String text;
  final String? subtitle;
  final bool center;
  final double size;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
    children: [
      Text(text, textAlign: center ? TextAlign.center : TextAlign.start,
        style: TextStyle(fontSize: size, height: 1.27, color: cinematicCream,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 18)])),
      if (subtitle != null) ...[
        const SizedBox(height: 10),
        Text(subtitle!, textAlign: center ? TextAlign.center : TextAlign.start,
          style: const TextStyle(color: cinematicMuted, fontSize: 15,
            height: 1.7, shadows: [Shadow(color: Colors.black87, blurRadius: 12)])),
      ],
    ],
  );
}

Route<T> cinematicRoute<T>(Widget page) => PageRouteBuilder<T>(
  pageBuilder: (context, a, b) => page,
  transitionDuration: const Duration(milliseconds: 850),
  reverseTransitionDuration: const Duration(milliseconds: 350),
  transitionsBuilder: (context, animation, secondary, child) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, .035), end: Offset.zero)
        .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ),
);
