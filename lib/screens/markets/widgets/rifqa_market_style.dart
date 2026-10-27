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
  const MarketPhoto({super.key, required this.image, this.radius = 16});
  final String image;
  final double radius;

  (Color, Color, IconData, String) get _visual {
    final key = image.split('/').last.replaceAll('.jpg', '');
    return switch (key) {
      'clocks' => (
          const Color(0xFF125B50),
          const Color(0xFF082F36),
          Icons.access_time_filled_rounded,
          'أبراج الساعة'
        ),
      'hero_makkah' || 'city_makkah' => (
          const Color(0xFF80663C),
          const Color(0xFF3B3329),
          Icons.mosque_rounded,
          'مكة المكرمة'
        ),
      'hero_madinah' || 'city_madinah' => (
          const Color(0xFF47775E),
          const Color(0xFF183D3A),
          Icons.mosque_rounded,
          'المدينة المنورة'
        ),
      'dates' || 'madinah_dates' => (
          const Color(0xFF8A6A37),
          const Color(0xFF493A2D),
          Icons.spa_rounded,
          'تمور'
        ),
      'perfumes' => (
          const Color(0xFF815875),
          const Color(0xFF40324C),
          Icons.local_florist_rounded,
          'عطور وبخور'
        ),
      'clothing' => (
          const Color(0xFF64718C),
          const Color(0xFF303A55),
          Icons.checkroom_rounded,
          'ملابس وعبايات'
        ),
      'gifts' => (
          const Color(0xFFAF795E),
          const Color(0xFF634342),
          Icons.card_giftcard_rounded,
          'هدايا'
        ),
      'souq_gold' => (
          const Color(0xFFAA8546),
          const Color(0xFF54412A),
          Icons.diamond_rounded,
          'ذهب ومجوهرات'
        ),
      'aziziyah' => (
          const Color(0xFF557779),
          const Color(0xFF294A4B),
          Icons.storefront_rounded,
          'سوق شعبي'
        ),
      'safwa' || 'khalil' || 'makkah_mall' || 'madinah_mall' => (
          const Color(0xFF4F786C),
          const Color(0xFF253E3B),
          Icons.store_mall_directory_rounded,
          'مركز تجاري'
        ),
      _ => (
          const Color(0xFF5C796A),
          const Color(0xFF2C443D),
          Icons.storefront_rounded,
          'وجهة تسوق'
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final visual = _visual;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 125 || constraints.maxHeight < 95;
          final iconSize =
              (constraints.maxWidth * .31).clamp(25.0, 68.0).toDouble();
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [visual.$1, visual.$2],
                  ),
                ),
              ),
              Positioned(
                top: -constraints.maxHeight * .42,
                right: -constraints.maxWidth * .12,
                child: Container(
                  width: constraints.maxHeight * 1.15,
                  height: constraints.maxHeight * 1.15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0x30F1D49C),
                      width: constraints.maxHeight * .075,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -constraints.maxWidth * .15,
                bottom: -constraints.maxHeight * .56,
                child: Container(
                  width: constraints.maxHeight * 1.2,
                  height: constraints.maxHeight * 1.2,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x18FFFFFF),
                  ),
                ),
              ),
              Align(
                alignment:
                    compact ? Alignment.center : const Alignment(0, -.12),
                child: Icon(
                  visual.$3,
                  size: iconSize,
                  color: const Color(0xFFF7E9C9),
                  shadows: const [
                    Shadow(color: Color(0x44000000), blurRadius: 12),
                  ],
                ),
              ),
              if (!compact)
                Align(
                  alignment: const Alignment(0, .66),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      visual.$4,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .93),
                        fontSize: constraints.maxWidth < 180 ? 9 : 13,
                        fontWeight: FontWeight.w800,
                        shadows: const [
                          Shadow(color: Color(0x66000000), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class MarketPill extends StatelessWidget {
  const MarketPill(
      {super.key,
      required this.label,
      this.icon,
      this.filled = false,
      this.onTap});
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
              if (icon != null) ...[
                Icon(icon,
                    size: 15,
                    color: filled ? MarketPalette.gold : MarketPalette.emerald),
                const SizedBox(width: 5)
              ],
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: filled ? Colors.white : MarketPalette.ink)),
            ]),
          ),
        ),
      );
}

class MarketFavoritesButton extends StatelessWidget {
  const MarketFavoritesButton(
      {super.key, required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withOpacity(.96),
        shape: const CircleBorder(),
        child: IconButton(
          constraints: const BoxConstraints.tightFor(width: 39, height: 39),
          onPressed: onTap,
          icon: Icon(
              selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 22,
              color:
                  selected ? const Color(0xFFCD6E64) : MarketPalette.evergreen),
        ),
      );
}

class MarketSoftCard extends StatelessWidget {
  const MarketSoftCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: MarketPalette.line),
          boxShadow: const [
            BoxShadow(
                color: Color(0x083A2C16), blurRadius: 12, offset: Offset(0, 4))
          ],
        ),
        child: child,
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

String marketVisualCaption(RifqaMarket market) =>
    'صورة تصميمية توضيحية • يُرجى التأكد من واجهة المكان';
