import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/haramain_design.dart';
import '../widgets/haramain_map_overlays.dart';
import '../widgets/haramain_trust.dart';
import '../haramain_live_models.dart';

/// Bottom sheet contract for the Haramain module.
///
/// All sheets share the same look: rounded ivory sheet, safe area, keyboard
/// aware, and a clear drag handle.
Future<T?> showHaramainModal<T>(
  BuildContext context,
  Widget Function(BuildContext) builder, {
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(HmTheme.sheetRadius)),
    ),
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(child: builder(ctx)),
      ),
    ),
  );
}

Widget sheetTitle(String text, {String? subtitle}) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: HmTheme.h2),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subtitle, style: HmTheme.caption),
            ),
        ],
      ),
    );

/// Result of the POI details sheet, so the caller decides what to do next.
class HmPoiAction {
  const HmPoiAction(this.kind);
  final HmPoiActionKind kind;

  static const showOnMap = HmPoiAction(HmPoiActionKind.showOnMap);
}

enum HmPoiActionKind {
  showOnMap,
  save,
  share,
  meetingPoint,
  takeMeThere,
  saveAsMyGate,
  delete,
  speak,
}

/// The single POI details surface.
///
/// It deliberately separates three kinds of information:
///  - VERIFIED data (green chips) — real, sourced
///  - EXPLORATION data (amber chip) — for looking, not for walking
///  - MISSING data — shown as "unknown", never guessed
///
/// Actions that require a verified route are disabled (not hidden) when no
/// verified route exists, so the pilgrim understands *why*.
class HmPoiDetailsSheet extends StatelessWidget {
  const HmPoiDetailsSheet({
    super.key,
    required this.poi,
    required this.navigationPossible,
    required this.locationKnown,
    required this.straightLineMeters,
    required this.isSavedAsMyGate,
    required this.onAction,
    required this.highContrast,
    required this.wheelchairMode,
  });

  final HlPoi poi;
  final bool navigationPossible;
  final bool locationKnown;
  final double? straightLineMeters;
  final bool isSavedAsMyGate;
  final void Function(HmPoiAction action) onAction;
  final bool highContrast;
  final bool wheelchairMode;

  @override
  Widget build(BuildContext context) {
    final canNavigate = navigationPossible &&
        locationKnown &&
        poi.verified &&
        !poi.isPin &&
        (!wheelchairMode || poi.wheelchair);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: poi.category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(poi.emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(poi.title, style: HmTheme.h2),
                  const SizedBox(height: 2),
                  Text(poi.category.label, style: HmTheme.caption),
                  if (poi.subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(poi.subtitle, style: HmTheme.body),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onAction(const HmPoiAction(HmPoiActionKind.speak));
              },
              icon: const Icon(Icons.volume_up_rounded),
              color: HmTheme.emerald,
              tooltip: 'اقرأ بصوت',
            ),
          ],
        ),
        const SizedBox(height: 14),
        HmTrustBadgeRow(poi: poi),
        if (straightLineMeters != null) ...[
          const SizedBox(height: 12),
          HmStraightLineDistance(meters: straightLineMeters!),
        ],
        const SizedBox(height: 14),
        HmNavigationAvailability(
          poi: poi,
          navigationPossible: navigationPossible,
          locationKnown: locationKnown,
          highContrast: highContrast,
        ),
        const SizedBox(height: 18),
        _actions(context, canNavigate),
      ],
    );
  }

  Widget _actions(BuildContext context, bool canNavigate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary navigation action — enabled ONLY when a verified route can
        // actually exist for this destination.
        FilledButton.icon(
          style: HmTheme.primaryButton(highContrast: highContrast),
          onPressed: canNavigate
              ? () => onAction(const HmPoiAction(HmPoiActionKind.takeMeThere))
              : null,
          icon: const Icon(Icons.directions_walk_rounded),
          label: const Text('ودّيني إلى هنا'),
        ),
        if (!canNavigate)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              'التوجيه معطّل هنا — لا نعرض طريقًا غير موثّق.',
              style: TextStyle(
                fontSize: 12,
                color: highContrast ? Colors.black : HmTheme.muted,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.push_pin_outlined,
                label: 'احفظ المكان',
                onTap: () => onAction(const HmPoiAction(HmPoiActionKind.save)),
                highContrast: highContrast,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.groups_outlined,
                label: 'نقطة تجمع',
                onTap: () =>
                    onAction(const HmPoiAction(HmPoiActionKind.meetingPoint)),
                highContrast: highContrast,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.share_outlined,
                label: 'مشاركة',
                onTap: () => onAction(const HmPoiAction(HmPoiActionKind.share)),
                highContrast: highContrast,
              ),
            ),
          ],
        ),
        if (poi.category == HlCategory.gate) ...[
          const SizedBox(height: 10),
          if (isSavedAsMyGate)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: HmTheme.emeraldSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: HmTheme.emerald, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'هذا باب دخولك المحفوظ.',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            )
          else
            OutlinedButton.icon(
              style: HmTheme.secondaryButton(highContrast: highContrast),
              onPressed: () =>
                  onAction(const HmPoiAction(HmPoiActionKind.saveAsMyGate)),
              icon: const Icon(Icons.door_sliding_outlined),
              label: const Text('احفظ باب دخولي'),
            ),
        ],
        if (poi.isPin) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: HmTheme.secondaryButton(highContrast: highContrast),
            onPressed: () => onAction(const HmPoiAction(HmPoiActionKind.delete)),
            icon: const Icon(Icons.delete_outline_rounded, color: HmTheme.danger),
            label: const Text('احذف هذا المكان',
                style: TextStyle(color: HmTheme.danger)),
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.highContrast,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highContrast ? Colors.white : HmTheme.ivory,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: highContrast
                ? Border.all(color: Colors.black, width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: HmTheme.emerald, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: HmTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formats a POI for a share message, including its verification state so the
/// recipient is never misled.
String buildPoiShareText(HlPoi poi, {String? siteName}) {
  final buffer = StringBuffer()
    ..writeln(poi.title)
    ..write('${siteName ?? ''} — ${poi.category.label}');
  if (!poi.isPin) {
    buffer.write(poi.verified ? ' — نقطة موثّقة' : ' — غير موثّقة للاستكشاف');
  }
  buffer.writeln(
    'https://www.google.com/maps/search/?api=1&query='
    '${poi.position.latitude},${poi.position.longitude}',
  );
  return buffer.toString();
}

/// Triggered from the POI sheet when the user picks "share".
Future<void> sharePoi(HlPoi poi, {String? siteName}) =>
    Share.share(buildPoiShareText(poi, siteName: siteName));