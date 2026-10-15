import 'package:flutter/material.dart';

/// Rifqa Haramain design language.
///
/// Premium, calm, map-first. Ivory surfaces, Rifqa emerald, restrained gold.
/// Every component here is deliberately large-target and high-contrast friendly,
/// because this is used under stress, in crowds, often by older pilgrims.
abstract final class HmTheme {
  static const emerald = Color(0xFF0B6B54);
  static const emeraldDeep = Color(0xFF063F35);
  static const emeraldSoft = Color(0xFFE5F2EE);
  static const gold = Color(0xFFC29B40);
  static const goldSoft = Color(0xFFF5ECD3);
  static const ivory = Color(0xFFF7F4ED);
  static const ink = Color(0xFF14231E);
  static const muted = Color(0xFF66756F);
  static const line = Color(0xFFE1E7E3);
  static const danger = Color(0xFFC0392B);
  static const dangerSoft = Color(0xFFFBE4E0);
  static const warn = Color(0xFFB4761A);
  static const warnSoft = Color(0xFFFFF3E0);
  static const info = Color(0xFF2F6FDE);

  /// Minimum comfortable touch target.
  static const double tapTarget = 48;

  static const double radius = 20;
  static const double sheetRadius = 28;

  /// Soft, subtle elevation. Never heavy drop shadows.
  static const List<BoxShadow> shadowSoft = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> shadowSheet = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 28,
      offset: Offset(0, -6),
    ),
  ];

  /// The primary button style used across Haramain.
  static ButtonStyle primaryButton({
    double height = 52,
    Color? background,
    bool highContrast = false,
  }) {
    return FilledButton.styleFrom(
      backgroundColor: highContrast ? Colors.black : (background ?? emerald),
      foregroundColor: Colors.white,
      minimumSize: Size.fromHeight(height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );
  }

  static ButtonStyle secondaryButton({double height = 48, bool highContrast = false}) {
    return OutlinedButton.styleFrom(
      foregroundColor: highContrast ? Colors.black : emerald,
      minimumSize: Size.fromHeight(height),
      side: BorderSide(
        color: highContrast ? Colors.black : line,
        width: highContrast ? 2 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
    );
  }

  static TextStyle get h1 => const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        color: ink,
        height: 1.25,
      );

  static TextStyle get h2 => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: ink,
        height: 1.3,
      );

  static TextStyle get h3 => const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: ink,
        height: 1.35,
      );

  static TextStyle get body => const TextStyle(
        fontSize: 15,
        color: ink,
        height: 1.6,
      );

  static TextStyle get caption => const TextStyle(
        fontSize: 12.5,
        color: muted,
        height: 1.5,
      );

  /// Section label above a group of controls.
  static TextStyle get sectionLabel => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: muted,
        letterSpacing: 0.2,
      );
}

/// A rounded surface card with restrained shadow.
class HmCard extends StatelessWidget {
  const HmCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.onTap,
    this.borderColor,
    this.radius = HmTheme.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final decorated = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
        boxShadow: HmTheme.shadowSoft,
      ),
      child: child,
    );
    if (onTap == null) return decorated;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: decorated,
      ),
    );
  }
}

/// Small status pill. Used for verification state, connectivity, accessibility.
class HmChip extends StatelessWidget {
  const HmChip({
    super.key,
    required this.label,
    this.icon,
    this.color = HmTheme.emerald,
    this.background,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final Color? background;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width informational notice (verified / unverified / offline).
class HmNotice extends StatelessWidget {
  const HmNotice({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.color = HmTheme.warn,
    this.background = HmTheme.warnSoft,
    this.action,
    this.highContrast = false,
  });

  final String message;
  final IconData icon;
  final Color color;
  final Color background;
  final Widget? action;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highContrast ? Colors.black : color.withValues(alpha: 0.35),
          width: highContrast ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: highContrast ? Colors.black : color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: highContrast ? Colors.black : HmTheme.ink,
              ),
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

/// Circular floating map control with large hit area.
class HmMapButton extends StatelessWidget {
  const HmMapButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.active = false,
    this.tooltip,
    this.danger = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;
  final String? tooltip;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final bg = danger
        ? HmTheme.danger
        : active
            ? HmTheme.emerald
            : Colors.white;
    final fg = (active || danger) ? Colors.white : const Color(0xFF26312D);

    final button = Material(
      elevation: 6,
      shadowColor: const Color(0x33000000),
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: HmTheme.tapTarget,
          height: HmTheme.tapTarget,
          child: Icon(icon, color: fg, size: 23),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Divider respecting the ivory palette.
class HmDivider extends StatelessWidget {
  const HmDivider({super.key, this.height = 20});
  final double height;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: height / 2),
        child: const Divider(height: 1, color: HmTheme.line),
      );
}

/// Section heading with an optional trailing action.
class HmSectionHeader extends StatelessWidget {
  const HmSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 19, color: HmTheme.emerald),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: HmTheme.h3),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!, style: HmTheme.caption),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}