import 'package:flutter/material.dart';

/// Color system for Rifqa Madinah — forest green, gold, ivory.
const cinematicGreen = Color(0xFF063A2D);
const cinematicDeep = Color(0xFF041710);
const cinematicGold = Color(0xFFE6BE72);
const cinematicCream = Color(0xFFFFF7E5);
const cinematicMuted = Color(0xFFCDD4C8);
const cinematicAssets = 'assets/images/madinah_cinematic';

class CinematicImage extends StatelessWidget {
  const CinematicImage(this.path, {super.key, this.alignment = Alignment.center});
  final String path;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Image.asset(
        path,
        fit: BoxFit.cover,
        alignment: alignment,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: cinematicGreen,
          child: Center(child: Icon(Icons.mosque, color: cinematicGold, size: 72)),
        ),
      );
}

class CinematicPill extends StatelessWidget {
  const CinematicPill({super.key, required this.text, this.icon = Icons.view_in_ar_rounded});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: cinematicDeep.withOpacity(.78),
          border: Border.all(color: cinematicGold.withOpacity(.75)),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: cinematicGold, size: 17),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(color: cinematicCream, fontWeight: FontWeight.bold)),
          ]),
        ),
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
              ? const [Color(0xFFF9DFA3), Color(0xFFCF9D47)]
              : const [Color(0xFF0D5943), Color(0xFF063426)]),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: cinematicGold.withOpacity(.7)),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 18, offset: Offset(0, 6))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(19),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: TextStyle(color: gold ? cinematicGreen : cinematicCream,
                  fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                Icon(icon, color: gold ? cinematicGreen : cinematicGold, size: 18),
              ]),
            ),
          ),
        ),
      );
}

class CinematicHeading extends StatelessWidget {
  const CinematicHeading(this.text, {super.key, this.subtitle, this.center = true});
  final String text;
  final String? subtitle;
  final bool center;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(text, textAlign: center ? TextAlign.center : TextAlign.start,
            style: const TextStyle(fontSize: 31, height: 1.3,
              color: cinematicCream, fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Colors.black87, blurRadius: 16)])),
          if (subtitle != null) ...[
            const SizedBox(height: 9),
            Text(subtitle!, textAlign: center ? TextAlign.center : TextAlign.start,
              style: const TextStyle(fontSize: 15, height: 1.75, color: cinematicMuted,
                shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
          ],
        ],
      );
}

Route<T> cinematicRoute<T>(Widget screen) => PageRouteBuilder<T>(
  pageBuilder: (_, animation, __) => screen,
  transitionDuration: const Duration(milliseconds: 680),
  reverseTransitionDuration: const Duration(milliseconds: 320),
  transitionsBuilder: (_, animation, __, child) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    child: ScaleTransition(scale: Tween<double>(begin: 1.045, end: 1).animate(animation), child: child)),
);

/// This section uses artistic illustrative images rather than evidence of
/// historical events; no portrayal or synthesized voice of the Prophet ﷺ.
const cinematicIllustrationNote =
    'الصور مشاهد بصرية توضيحية، وليست توثيقًا فوتوغرافيًا لأحداث السيرة.';
