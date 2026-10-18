import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/pilgrim_watch/watch_store.dart';

class RW {
  RW._();
  static const black = Color(0xFF06130F);
  static const green = Color(0xFF063E31);
  static const green2 = Color(0xFF0E6A50);
  static const jade = Color(0xFF3CCB98);
  static const gold = Color(0xFFE2B961);
  static const lightGold = Color(0xFFFFE9AB);
  static const ivory = Color(0xFFF9F3E8);
  static const muted = Color(0xFFB1B8A8);
  static const ink = Color(0xFF173B31);
  static TextStyle style(double size, {Color color = ivory, FontWeight weight = FontWeight.w600,
    double height = 1.35}) => GoogleFonts.cairo(fontSize: size, color: color,
      fontWeight: weight, height: height);
}

class WatchGradientScaffold extends StatelessWidget {
  const WatchGradientScaffold({super.key, required this.child, this.topPhoto = false});
  final Widget child;
  final bool topPhoto;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl, child: Scaffold(
    backgroundColor: RW.black,
    body: Stack(children: [
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [RW.green.withOpacity( .82), RW.black, const Color(0xFF09271F)])))),
      if (topPhoto) Positioned(top: 0, left: 0, right: 0, height: 260,
        child: ShaderMask(shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.transparent]).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: Image.asset('assets/rifqa_watch/makkah.jpg', fit: BoxFit.cover))),
      SafeArea(child: child),
    ]),
  ));
}

class WatchPanel extends StatelessWidget {
  const WatchPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16),
    this.glow = false, this.color});
  final Widget child;
  final EdgeInsets padding;
  final bool glow;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? const Color(0xEA09291F),
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: glow ? RW.gold.withOpacity( .8)
          : RW.gold.withOpacity( .22), width: glow ? 1.3 : .8),
      boxShadow: glow ? [BoxShadow(color: RW.gold.withOpacity( .09), blurRadius: 22)] : null,
    ), child: child);
}

class WatchSectionTitle extends StatelessWidget {
  const WatchSectionTitle(this.text, {super.key, this.trailing, this.icon});
  final String text;
  final Widget? trailing;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 3, height: 25, margin: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(color: RW.gold, borderRadius: BorderRadius.circular(6))),
    if (icon != null) ...[Icon(icon, color: RW.gold, size: 20), const SizedBox(width: 7)],
    Expanded(child: Text(text, style: RW.style(19, weight: FontWeight.w800))),
    if (trailing != null) trailing!,
  ]);
}

class WatchAction extends StatelessWidget {
  const WatchAction({super.key, required this.icon, required this.title,
    this.caption, required this.onTap, this.accent = RW.gold});
  final IconData icon;
  final String title;
  final String? caption;
  final VoidCallback onTap;
  final Color accent;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xAA092F24),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RW.gold.withOpacity( .19))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: accent, size: 26), const SizedBox(height: 9),
          Text(title, style: RW.style(13, weight: FontWeight.w800), textAlign: TextAlign.center),
          if (caption != null) Text(caption!, style: RW.style(10, color: RW.muted),
            maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ]))));
}

class WatchPrimaryButton extends StatelessWidget {
  const WatchPrimaryButton({super.key, required this.label, this.icon = Icons.arrow_back_ios_new_rounded,
    required this.onTap, this.gold = true});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool gold;
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity, height: 54,
    child: FilledButton.icon(onPressed: onTap, icon: Icon(icon, size: 20),
      label: Text(label, style: RW.style(15, color: gold ? RW.black : Colors.white,
        weight: FontWeight.w900)),
      style: FilledButton.styleFrom(backgroundColor: gold ? RW.gold : RW.green2,
        foregroundColor: gold ? RW.black : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))));
}

/// Interactive face on the phone, not the screen of a paired watch.
class RifqaWatchFace extends StatelessWidget {
  const RifqaWatchFace({super.key, required this.store, required this.now, this.onTap});
  final RifqaWatchStore store;
  final DateTime now;
  final VoidCallback? onTap;
  String _time() {
    final hour = store.is24Hour ? now.hour : ((now.hour + 11) % 12 + 1);
    final minute = now.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute';
  }
  @override
  Widget build(BuildContext context) {
    final face = store.face;
    return LayoutBuilder(builder: (context, constraint) {
      final size = math.min(constraint.maxWidth, 310.0);
      return InkWell(onTap: onTap, customBorder: const CircleBorder(),
        child: Container(width: size, height: size,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [RW.gold, Color(0xFF65532D), RW.lightGold, RW.gold]),
            boxShadow: [BoxShadow(color: RW.gold.withOpacity( .24), blurRadius: 35)]),
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle, color: RW.black),
            padding: const EdgeInsets.all(7),
            child: ClipOval(child: Stack(fit: StackFit.expand, children: [
              if (face == 0) Image.asset('assets/rifqa_watch/makkah.jpg', fit: BoxFit.cover),
              if (face == 1) Container(decoration: const BoxDecoration(gradient:
                RadialGradient(colors: [Color(0xFF20624C), RW.black], radius: .82))),
              if (face == 2) Container(color: const Color(0xFF050B0A)),
              DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(
                center: Alignment.center, radius: .95,
                colors: [Colors.black.withOpacity( .1), Colors.black.withOpacity( .72)]))),
              CustomPaint(painter: _WatchDialPainter()),
              Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.nightlight_round, color: RW.gold, size: 19),
                Text(store.makkahTime ? 'بتوقيت مكة المكرمة' : 'بتوقيت الجهاز',
                  style: RW.style(10, color: RW.lightGold)),
                const SizedBox(height: 9),
                FittedBox(child: Text(_time(), style: TextStyle(fontSize: size * .17,
                  color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -2))),
                if (!store.is24Hour) Text(now.hour >= 12 ? 'مساءً' : 'صباحًا',
                  style: RW.style(11, color: RW.lightGold)),
                const SizedBox(height: 4),
                Text('${now.day}/${now.month}/${now.year}', style: RW.style(11, color: RW.muted)),
                const SizedBox(height: 12),
                const Icon(Icons.mosque_rounded, size: 27, color: RW.gold),
                Text('رِفقة معك في كل خطوة', style: RW.style(10)),
              ])),
              Positioned(bottom: 13, left: 0, right: 0, child: Center(
                child: Text('اضغطي لتغيير الواجهة', style: RW.style(8, color: RW.muted)))),
            ])),
          ),
        ));
    });
  }
}

class _WatchDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 12;
    for (var i = 0; i < 60; i++) {
      final angle = (i * 6 - 90) * math.pi / 180;
      final major = i % 5 == 0;
      final from = radius - (major ? 13 : 5);
      final to = radius;
      canvas.drawLine(center + Offset(math.cos(angle) * from, math.sin(angle) * from),
        center + Offset(math.cos(angle) * to, math.sin(angle) * to),
        Paint()..color = RW.gold.withOpacity( major ? .9 : .3)
          ..strokeWidth = major ? 1.3 : .6);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}
