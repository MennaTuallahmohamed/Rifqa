import 'package:flutter/material.dart';

import '../../../services/markets/rifqa_markets_catalog.dart';

class MarketPalette {
  static const evergreen = Color(0xFF063E32);
  static const emerald = Color(0xFF116B55);
  static const gold = Color(0xFFD6AD61);
  static const cream = Color(0xFFF9F5EC);
  static const ink = Color(0xFF193B30);
  static const muted = Color(0xFF7A8179);
  static const line = Color(0xFFEAE2D4);
  static const pale = Color(0xFFEBF5EF);
}

class MarketPhoto extends StatelessWidget {
  const MarketPhoto({super.key, required this.image, this.radius = 16, this.fit = BoxFit.cover});
  final String image;
  final double radius;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Image.asset(image, fit: fit, width: double.infinity, height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: MarketPalette.pale,
        child: const Center(child: Icon(Icons.storefront_rounded, size: 36, color: MarketPalette.emerald)),
      )),
  );
}

class MarketPill extends StatelessWidget {
  const MarketPill({super.key, required this.label, this.icon, this.filled = false, this.onTap});
  final String label;
  final IconData? icon;
  final bool filled;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: filled ? MarketPalette.evergreen : const Color(0xFFFAF7F0),
    borderRadius: BorderRadius.circular(30),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 15, color: filled ? MarketPalette.gold : MarketPalette.emerald), const SizedBox(width: 5)],
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
              color: filled ? Colors.white : MarketPalette.ink)),
        ]),
      ),
    ),
  );
}

class MarketFavoritesButton extends StatelessWidget {
  const MarketFavoritesButton({super.key, required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withOpacity(.96), shape: const CircleBorder(),
    child: IconButton(
      constraints: const BoxConstraints.tightFor(width: 39, height: 39),
      onPressed: onTap,
      icon: Icon(selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 22, color: selected ? const Color(0xFFCD6E64) : MarketPalette.evergreen),
    ),
  );
}

class MarketSoftCard extends StatelessWidget {
  const MarketSoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: MarketPalette.line),
      boxShadow: const [BoxShadow(color: Color(0x0C3A2C16), blurRadius: 17, offset: Offset(0, 6))],
    ), child: child,
  );
}

String marketPhotoForCategory(String key) => switch (key) {
  'تمور' => 'assets/markets/images/dates.jpg',
  'هدايا' => 'assets/markets/images/gifts.jpg',
  'عطور' => 'assets/markets/images/perfumes.jpg',
  'عبايات' => 'assets/markets/images/clothing.jpg',
  'جملة' => 'assets/markets/images/aziziyah.jpg',
  'شعبي' => 'assets/markets/images/madinah_market.jpg',
  _ => 'assets/markets/images/madinah_mall.jpg',
};

String marketVisualCaption(RifqaMarket market) => 'صورة تصميمية توضيحية • يُرجى التأكد من واجهة المكان';
