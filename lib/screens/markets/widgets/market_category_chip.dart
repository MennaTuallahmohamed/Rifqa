import 'package:flutter/material.dart';

import '../../../models/markets/market_place.dart';

class MarketCategoryChip extends StatelessWidget {
  const MarketCategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final MarketCategory category;
  final bool selected;
  final VoidCallback onTap;

  static const Color _green = Color(0xFF176B52);
  static const Color _greenDark = Color(0xFF0D4D3B);
  static const Color _gold = Color(0xFFD5AE5B);
  static const Color _ink = Color(0xFF17322A);
  static const Color _muted = Color(0xFF6B7B74);
  static const Color _border = Color(0xFFEDE7D6);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: selected ? _green : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? _gold : _border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? _greenDark.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _emoji(category),
                style: const TextStyle(
                  fontSize: 19,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                _name(category),
                style: TextStyle(
                  color: selected ? Colors.white : _ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: _gold,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _name(MarketCategory category) {
    switch (category) {
      case MarketCategory.mall:
        return 'المولات';

      case MarketCategory.traditionalMarket:
        return 'الأسواق الشعبية';

      case MarketCategory.gifts:
        return 'الهدايا';

      case MarketCategory.dates:
        return 'التمور';

      case MarketCategory.perfumes:
        return 'العطور والبخور';

      case MarketCategory.abayas:
        return 'العبايات والملابس';

      case MarketCategory.gold:
        return 'الذهب';

      case MarketCategory.food:
        return 'الطعام';

      case MarketCategory.pharmacy:
        return 'الصيدليات';

      case MarketCategory.supermarket:
        return 'السوبر ماركت';

      case MarketCategory.hajjUmrahSupplies:
        return 'مستلزمات النسك';

      case MarketCategory.other:
        return 'أخرى';
    }
  }

  static String _emoji(MarketCategory category) {
    switch (category) {
      case MarketCategory.mall:
        return '🏬';

      case MarketCategory.traditionalMarket:
        return '🛍️';

      case MarketCategory.gifts:
        return '🎁';

      case MarketCategory.dates:
        return '🌴';

      case MarketCategory.perfumes:
        return '🌸';

      case MarketCategory.abayas:
        return '👗';

      case MarketCategory.gold:
        return '💎';

      case MarketCategory.food:
        return '🍽️';

      case MarketCategory.pharmacy:
        return '💊';

      case MarketCategory.supermarket:
        return '🛒';

      case MarketCategory.hajjUmrahSupplies:
        return '🕌';

      case MarketCategory.other:
        return '📍';
    }
  }
}

// =============================================================
// All Categories
// =============================================================

class MarketCategoriesBar extends StatelessWidget {
  const MarketCategoriesBar({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
    this.showAllButton = true,
  });

  final MarketCategory? selectedCategory;
  final ValueChanged<MarketCategory?> onChanged;
  final bool showAllButton;

  static const Color _green = Color(0xFF176B52);
  static const Color _gold = Color(0xFFD5AE5B);
  static const Color _ink = Color(0xFF17322A);
  static const Color _border = Color(0xFFEDE7D6);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          if (showAllButton) ...[
            _AllCategoryChip(
              selected: selectedCategory == null,
              onTap: () {
                onChanged(null);
              },
            ),
            const SizedBox(width: 8),
          ],

          for (final category in MarketCategory.values) ...[
            MarketCategoryChip(
              category: category,
              selected: selectedCategory == category,
              onTap: () {
                if (selectedCategory == category) {
                  onChanged(null);
                } else {
                  onChanged(category);
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _AllCategoryChip extends StatelessWidget {
  const _AllCategoryChip({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  static const Color _green = Color(0xFF176B52);
  static const Color _greenDark = Color(0xFF0D4D3B);
  static const Color _gold = Color(0xFFD5AE5B);
  static const Color _ink = Color(0xFF17322A);
  static const Color _border = Color(0xFFEDE7D6);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: selected ? _green : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? _gold : _border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? _greenDark.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '✨',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 7),
              Text(
                'الكل',
                style: TextStyle(
                  color: selected ? Colors.white : _ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}