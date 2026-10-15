import 'package:flutter/material.dart';

import '../theme/haramain_design.dart';
import '../haramain_live_models.dart';

/// Visual truth about how much we know about a piece of data.
///
/// This widget is the single place where the app tells the pilgrim whether
/// something is verified, so the language can never drift between screens.
/// It is intentionally loud for unverified data: exploration data must never
/// look like an instruction to walk somewhere.
class HmTrustBadge extends StatelessWidget {
  const HmTrustBadge({
    super.key,
    required this.trust,
    this.isPin = false,
    this.dense = true,
  });

  final HlTrust trust;
  final bool isPin;
  final bool dense;

  String get _label {
    if (isPin) return 'حدّدته أنت';
    return switch (trust) {
      HlTrust.verifiedPoi => 'موقع موثّق',
      HlTrust.verifiedAccess => 'اتصال موثّق',
      HlTrust.verifiedRoute => 'مسار موثّق',
      HlTrust.unverified => 'غير موثّق — للاستكشاف فقط',
    };
  }

  IconData get _icon {
    if (isPin) return Icons.push_pin_outlined;
    return switch (trust) {
      HlTrust.verifiedPoi => Icons.verified_rounded,
      HlTrust.verifiedAccess => Icons.accessible_rounded,
      HlTrust.verifiedRoute => Icons.route_rounded,
      HlTrust.unverified => Icons.help_outline_rounded,
    };
  }

  Color get _color {
    if (isPin) return HmTheme.info;
    return switch (trust) {
      HlTrust.verifiedPoi || HlTrust.verifiedAccess || HlTrust.verifiedRoute =>
        HmTheme.emerald,
      HlTrust.unverified => HmTheme.warn,
    };
  }

  @override
  Widget build(BuildContext context) => HmChip(
        label: _label,
        icon: _icon,
        color: _color,
        dense: dense,
      );
}

/// Row of badges for a POI: verification + accessibility + floor + women-only.
class HmTrustBadgeRow extends StatelessWidget {
  const HmTrustBadgeRow({
    super.key,
    required this.poi,
    this.dense = true,
  });

  final HlPoi poi;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        HmTrustBadge(trust: poi.trust, isPin: poi.isPin, dense: dense),
        // Accessibility is only ever shown when the data actually says so.
        // We never infer it from the category or from proximity.
        if (poi.wheelchair)
          HmChip(
            label: 'ميسّر للكرسي المتحرك',
            icon: Icons.accessible_rounded,
            color: HmTheme.info,
            dense: dense,
          ),
        if (poi.womenOnly)
          HmChip(
            label: 'للنساء',
            icon: Icons.woman_rounded,
            color: Color(0xFF8E5BB0),
            dense: dense,
          ),
        if (poi.floor > 0)
          HmChip(
            label: 'الدور ${poi.floor}',
            icon: Icons.layers_rounded,
            color: HmTheme.muted,
            dense: dense,
          ),
        // A verified POI is explicitly NOT a verified route.
        if (poi.verified && poi.trust != HlTrust.verifiedRoute)
          HmChip(
            label: 'لا يوجد مسار موثّق للملاحة',
            icon: Icons.block_rounded,
            color: HmTheme.warn,
            dense: dense,
          ),
      ],
    );
  }
}

/// Explains, in one honest sentence, what can and cannot be done with a POI.
class HmNavigationAvailability extends StatelessWidget {
  const HmNavigationAvailability({
    super.key,
    required this.poi,
    required this.navigationPossible,
    required this.locationKnown,
    this.highContrast = false,
  });

  final HlPoi poi;
  final bool navigationPossible;
  final bool locationKnown;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final (String msg, IconData icon, Color color, Color bg) = _resolve();

    return HmNotice(
      message: msg,
      icon: icon,
      color: color,
      background: bg,
      highContrast: highContrast,
    );
  }

  (String, IconData, Color, Color) _resolve() {
    if (poi.isPin) {
      return (
        'هذا مكان حددته أنت. نعرضه على الخريطة فقط، ولا نحسب له مسارًا داخليًا.',
        Icons.push_pin_outlined,
        HmTheme.info,
        const Color(0xFFE8F0FE),
      );
    }
    if (!poi.verified) {
      return (
        'بيانات هذه النقطة غير موثّقة. تصلح للاستكشاف على الخريطة فقط، ولا '
        'يمكن الاعتماد عليها للوصول إليه. اتبع اللوحات الإرشادية في المسجد.',
        Icons.help_outline_rounded,
        HmTheme.warn,
        HmTheme.warnSoft,
      );
    }
    if (!locationKnown) {
      return (
        'النقطة موثّقة، لكننا بحاجة إلى تحديد موقعك أولًا حتى نتحقق من وجود '
        'مسار موثّق يوصلك إليها.',
        Icons.my_location_rounded,
        HmTheme.warn,
        HmTheme.warnSoft,
      );
    }
    if (!navigationPossible) {
      return (
        'لا يوجد مسار مشي داخلي موثّق لهذه الوجهة في بيانات هذا الحرم. '
        'لا يمكن تشغيل التوجيه الآن — هذا مقصود، لأننا لا نخترع مسارات.',
        Icons.block_rounded,
        HmTheme.warn,
        HmTheme.warnSoft,
      );
    }
    return (
      'يمكن عرض معاينة المسار الموثّق لهذه الوجهة.',
      Icons.route_rounded,
      HmTheme.emerald,
      HmTheme.emeraldSoft,
    );
  }
}