import 'package:flutter/material.dart';

import '../../../models/markets/market_place.dart';

class MarketCitySelector extends StatelessWidget {
  const MarketCitySelector({
    super.key,
    required this.selectedCity,
    required this.onChanged,
  });

  final MarketCity selectedCity;
  final ValueChanged<MarketCity> onChanged;

  static const Color _green = Color(0xFF176B52);
  static const Color _greenDark = Color(0xFF0D4D3B);
  static const Color _gold = Color(0xFFD5AE5B);
  static const Color _background = Color(0xFFFAF7F0);
  static const Color _ink = Color(0xFF17322A);
  static const Color _muted = Color(0xFF6B7B74);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'أين تريدين التسوق؟',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'اختاري المدينة لعرض الأسواق والأماكن المناسبة لك',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: _muted,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(
              child: _CityCard(
                title: 'مكة المكرمة',
                subtitle: 'تسوق قريب من الحرم ومكة',
                emoji: '🕋',
                selected: selectedCity == MarketCity.makkah,
                onTap: () {
                  onChanged(MarketCity.makkah);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CityCard(
                title: 'المدينة المنورة',
                subtitle: 'أسواق المدينة والهدايا والتمور',
                emoji: '🕌',
                selected: selectedCity == MarketCity.madinah,
                onTap: () {
                  onChanged(MarketCity.madinah);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CityCard extends StatelessWidget {
  const _CityCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  static const Color _green = Color(0xFF176B52);
  static const Color _greenDark = Color(0xFF0D4D3B);
  static const Color _gold = Color(0xFFD5AE5B);
  static const Color _background = Color(0xFFFAF7F0);
  static const Color _ink = Color(0xFF17322A);
  static const Color _muted = Color(0xFF6B7B74);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? _green : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? _gold : const Color(0xFFEDE7D6),
          width: selected ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? _greenDark.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: selected ? 18 : 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 18,
            ),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.14)
                        : _background,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? _gold.withValues(alpha: 0.8)
                          : _gold.withValues(alpha: 0.35),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji,
                    style: const TextStyle(
                      fontSize: 30,
                    ),
                  ),
                ),

                const SizedBox(height: 13),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.78)
                        : _muted,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 13),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 32,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? _gold
                        : _green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.location_on_outlined,
                        size: 16,
                        color: selected ? _greenDark : _green,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        selected ? 'تم الاختيار' : 'اختيار',
                        style: const TextStyle(
                          color: _greenDark,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}