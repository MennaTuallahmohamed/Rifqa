import 'package:flutter/material.dart';

class MarketFilters extends StatelessWidget {
  const MarketFilters({
    super.key,
    required this.nearMe,
    required this.openNow,
    required this.accessibleOnly,
    required this.onNearMeChanged,
    required this.onOpenNowChanged,
    required this.onAccessibleChanged,
  });

  final bool nearMe;
  final bool openNow;
  final bool accessibleOnly;

  final ValueChanged<bool> onNearMeChanged;
  final ValueChanged<bool> onOpenNowChanged;
  final ValueChanged<bool> onAccessibleChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _FilterButton(
            icon: Icons.near_me_rounded,
            label: 'الأقرب لي',
            selected: nearMe,
            onTap: () => onNearMeChanged(!nearMe),
          ),
          const SizedBox(width: 8),
          _FilterButton(
            icon: Icons.schedule_rounded,
            label: 'مفتوح الآن',
            selected: openNow,
            onTap: () => onOpenNowChanged(!openNow),
          ),
          const SizedBox(width: 8),
          _FilterButton(
            icon: Icons.accessible_rounded,
            label: 'سهولة الوصول',
            selected: accessibleOnly,
            onTap: () => onAccessibleChanged(!accessibleOnly),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
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
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: selected ? _green : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _gold : _border,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? _greenDark.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? _gold : _green,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: _gold,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}