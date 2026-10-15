import 'package:flutter/material.dart';

import '../haramain_geo.dart';
import '../haramain_live_models.dart';
import '../theme/haramain_design.dart';
import '../widgets/haramain_trust.dart';
import 'haramain_poi_sheet.dart';

/// Route preview for a VERIFIED route only.
///
/// If [route] is null this sheet does not show a distance, a duration, a line
/// on the map, or a Start button. It states plainly that verified indoor
/// navigation is unavailable, and it does NOT substitute a straight line.
class HmRoutePreviewSheet extends StatelessWidget {
  const HmRoutePreviewSheet({
    super.key,
    required this.destination,
    required this.route,
    required this.onStart,
    required this.onCancel,
    required this.highContrast,
    required this.wheelchairMode,
    required this.voiceOn,
    required this.onToggleVoice,
    required this.locationKnown,
  });

  final HlPoi destination;
  final HlRoute? route;
  final VoidCallback onStart;
  final VoidCallback onCancel;
  final bool highContrast;
  final bool wheelchairMode;
  final bool voiceOn;
  final VoidCallback onToggleVoice;
  final bool locationKnown;

  @override
  Widget build(BuildContext context) {
    final r = route;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: sheetTitle(
                'إلى ${destination.title}',
                subtitle: destination.category.label,
              ),
            ),
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'إغلاق',
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (r == null)
          _noVerifiedRoute(context)
        else
          _verifiedRoute(context, r),
      ],
    );
  }

  Widget _noVerifiedRoute(BuildContext context) {
    final String reason;
    final IconData icon;
    if (!locationKnown) {
      reason =
          'نحتاج أولًا إلى تحديد موقعك عبر الـGPS حتى نتحقق من وجود مسار موثّق '
          'يوصلك إلى هذه الوجهة.';
      icon = Icons.my_location_rounded;
    } else if (!destination.verified) {
      reason =
          'بيانات هذه الوجهة غير موثّقة، ولا توجد شبكة مسارات موثّقة داخل هذا '
          'الحرم. لا نعرض طريقًا تقديريًا عمدًا، لأن نظام الملاحة يجب أن يكون '
          'صادقًا. اتبع اللوحات الإرشادية أو اسأل أحد العاملين.';
      icon = Icons.help_outline_rounded;
    } else {
      reason =
          'لا يوجد مسار مشي داخلي موثّق لهذه الوجهة في بيانات هذا الحرم حتى الآن. '
          'التوجيه الداخلي معطّل، وهذا قرار متعمّد لحماية الحجاج والمعتمرين.';
      icon = Icons.block_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HmNotice(
          message: 'الملاحة الداخلية غير متاحة لهذه الوجهة',
          icon: Icons.no_transfer_rounded,
          color: HmTheme.warn,
          background: HmTheme.warnSoft,
          highContrast: highContrast,
        ),
        const SizedBox(height: 12),
        HmNotice(
          message: reason,
          icon: icon,
          color: HmTheme.muted,
          background: HmTheme.ivory,
          highContrast: highContrast,
        ),
        const SizedBox(height: 12),
        HmTrustBadgeRow(poi: destination),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: HmTheme.primaryButton(highContrast: highContrast),
          onPressed: onCancel,
          icon: const Icon(Icons.check_rounded),
          label: const Text('فهمت، عد إلى الخريطة'),
        ),
      ],
    );
  }

  Widget _verifiedRoute(BuildContext context, HlRoute r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Distance and duration are derived from the verified geometry itself,
        // using the walk speed of the accessibility profile. They are labelled
        // as estimates, never as guarantees.
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${r.minutes}',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 1,
                color: HmTheme.emerald,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 4, right: 6),
              child: Text(
                'دقيقة تقريبًا',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                HmGeo.meters(r.meters),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: HmTheme.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const HmChip(
              label: 'مسار موثّق',
              icon: Icons.route_rounded,
              color: HmTheme.emerald,
            ),
            if (r.accessible)
              const HmChip(
                label: 'مناسب للكرسي المتحرك',
                icon: Icons.accessible_rounded,
                color: HmTheme.info,
              ),
            const HmChip(
              label: 'المدة تقديرية',
              icon: Icons.schedule_rounded,
              color: HmTheme.muted,
            ),
          ],
        ),
        if (wheelchairMode)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: HmNotice(
              message:
                  'وضع الكرسي المتحرك مفعّل. لن يبدأ التوجيه إلا بمسار ميسّر موثّق.',
              icon: Icons.accessible_rounded,
              color: HmTheme.info,
              background: const Color(0xFFE8F0FE),
              highContrast: highContrast,
            ),
          ),
        const SizedBox(height: 14),
        Text('خطوات المسار', style: HmTheme.sectionLabel),
        const SizedBox(height: 8),
        for (final step in r.steps)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: HmTheme.emeraldSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step.turn.icon,
                    size: 19,
                    color: HmTheme.emerald,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.text,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (step.meters > 0)
                        Text(
                          'لمسافة ${HmGeo.meters(step.meters)} تقريبًا',
                          style: HmTheme.caption,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: HmTheme.secondaryButton(highContrast: highContrast),
                onPressed: onToggleVoice,
                icon: Icon(
                  voiceOn
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                ),
                label: Text(voiceOn ? 'الصوت مفعّل' : 'الصوت مكتوم'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                style: HmTheme.primaryButton(highContrast: highContrast),
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('ابدأ التوجيه'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onCancel,
          child: const Text('إلغاء'),
        ),
      ],
    );
  }
}