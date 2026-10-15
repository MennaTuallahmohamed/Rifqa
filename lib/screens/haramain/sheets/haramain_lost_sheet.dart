import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/haramain/haramain_map_demo_models.dart';
import '../theme/haramain_design.dart';
import 'haramain_poi_sheet.dart';

/// Lost mode — intentionally the simplest screen in the whole app.
///
/// Under stress a pilgrim reads three words and presses one button. So:
///  - one giant action per row, full width, 60px tall
///  - no nested navigation, no confirmations
///  - no information the pilgrim did not ask for
///
/// Every action is a callback so the host screen decides what it does; this
/// widget never navigates, dials, or shares on its own.
class HmLostModeSheet extends StatelessWidget {
  const HmLostModeSheet({
    super.key,
    required this.site,
    required this.hasMyGate,
    required this.hasMeetingPoint,
    required this.hasHotel,
    required this.hasCompanionPhone,
    required this.locationKnown,
    required this.onMyLocation,
    required this.onMyGate,
    required this.onMeetingPoint,
    required this.onHotel,
    required this.onCallCompanion,
    required this.onShowHelpCard,
    required this.onClose,
    required this.highContrast,
  });

  final HaramainSite site;
  final bool hasMyGate;
  final bool hasMeetingPoint;
  final bool hasHotel;
  final bool hasCompanionPhone;
  final bool locationKnown;
  final VoidCallback onMyLocation;
  final VoidCallback onMyGate;
  final VoidCallback onMeetingPoint;
  final VoidCallback onHotel;
  final VoidCallback onCallCompanion;
  final VoidCallback onShowHelpCard;
  final VoidCallback onClose;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: sheetTitle(
                'أنا تائه',
                subtitle: 'اختر ما تحتاجه فقط',
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'إغلاق',
            ),
          ],
        ),
        const SizedBox(height: 10),
        _BigAction(
          icon: Icons.my_location_rounded,
          label: 'موقعي',
          subtitle: locationKnown ? 'محدد الآن' : 'يحتاج إذن الموقع',
          onTap: onMyLocation,
          enabled: true,
          primary: true,
          highContrast: highContrast,
        ),
        _BigAction(
          icon: Icons.door_sliding_outlined,
          label: 'بابي',
          subtitle: hasMyGate ? 'محفوظ' : 'لم تحفظ بابًا بعد',
          onTap: onMyGate,
          enabled: hasMyGate,
          highContrast: highContrast,
        ),
        _BigAction(
          icon: Icons.groups_outlined,
          label: 'نقطة التجمع',
          subtitle: hasMeetingPoint ? 'محفوظة' : 'لم تحفظ نقطة',
          onTap: onMeetingPoint,
          enabled: hasMeetingPoint,
          highContrast: highContrast,
        ),
        _BigAction(
          icon: Icons.hotel_outlined,
          label: 'الفندق',
          subtitle: hasHotel ? 'محفوظ' : 'لم تحفظ فندقك',
          onTap: onHotel,
          enabled: hasHotel,
          highContrast: highContrast,
        ),
        const SizedBox(height: 8),
        _BigAction(
          icon: Icons.phone_rounded,
          label: 'اتصل برفيق',
          subtitle: hasCompanionPhone ? 'متاح' : 'لم تحفظ رقمًا',
          onTap: onCallCompanion,
          enabled: hasCompanionPhone,
          highContrast: highContrast,
        ),
        const SizedBox(height: 12),
        const HmDivider(height: 8),
        Text('أرقام مهمة', style: HmTheme.sectionLabel),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: HmTheme.secondaryButton(highContrast: highContrast),
                onPressed: () => _dial('997'),
                icon: const Icon(Icons.medical_services_outlined),
                label: const Text('الإسعاف 997'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: HmTheme.secondaryButton(highContrast: highContrast),
                onPressed: () => _dial('999'),
                icon: const Icon(Icons.local_police_outlined),
                label: const Text('الشرطة 999'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          style: HmTheme.primaryButton(highContrast: highContrast),
          onPressed: onShowHelpCard,
          icon: const Icon(Icons.badge_outlined),
          label: const Text('اعرض بطاقة المساعدة'),
        ),
      ],
    );
  }

  void _dial(String number) => launchUrl(Uri.parse('tel:$number'));
}

class _BigAction extends StatelessWidget {
  const _BigAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.enabled,
    required this.highContrast,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final bool highContrast;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final bg = !enabled
        ? const Color(0xFFF0F1F0)
        : primary
            ? HmTheme.emerald
            : Colors.white;
    final fg = !enabled
        ? HmTheme.muted
        : primary
            ? Colors.white
            : HmTheme.emerald;
    final labelColor = !enabled
        ? HmTheme.muted
        : primary
            ? Colors.white
            : HmTheme.ink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Material(
          color: bg,
          elevation: primary && enabled ? 6 : 1,
          shadowColor: const Color(0x22000000),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: enabled ? onTap : null,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: highContrast
                    ? Border.all(color: Colors.black, width: 2)
                    : Border.all(color: HmTheme.line),
              ),
              child: Row(
                children: [
                  Icon(icon, color: fg, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: labelColor,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: primary && enabled
                                ? Colors.white70
                                : HmTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left_rounded, color: fg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The bilingual help card a pilgrim shows to a stranger.
///
/// It is designed to be read at arm's length by someone who does not speak
/// Arabic, so the destination and the coordinates are the largest elements.
class HmHelpCardSheet extends StatelessWidget {
  const HmHelpCardSheet({
    super.key,
    required this.pilgrimName,
    required this.destination,
    required this.latitude,
    required this.longitude,
    required this.companionPhone,
    required this.onShare,
    this.accuracyMeters,
  });

  final String pilgrimName;
  final String destination;
  final double? latitude;
  final double? longitude;
  final String companionPhone;
  final VoidCallback onShare;
  final double? accuracyMeters;

  @override
  Widget build(BuildContext context) {
    final hasCoords = latitude != null && longitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sheetTitle(
          'بطاقة المساعدة',
          subtitle: 'اعرضها على من حولك أو شاركها',
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: HmTheme.gold, width: 2),
            boxShadow: HmTheme.shadowSoft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                pilgrimName.isEmpty ? 'حاج / معتمر' : pilgrimName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: HmTheme.ink,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'أنا تائه وأحتاج للمساعدة للوصول إلى:',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 6),
              Text(
                destination,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: HmTheme.emerald,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 18),
              const Divider(color: HmTheme.line),
              const SizedBox(height: 18),
              const Text(
                'I am lost and need help reaching:',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 6),
              Text(
                destination,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              if (hasCoords) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: HmTheme.ivory,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${latitude!.toStringAsFixed(5)}, '
                        '${longitude!.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (accuracyMeters != null)
                        Text(
                          'دقة الموقع ±${accuracyMeters!.round()} متر '
                          '(تقل داخل المباني)',
                          style: HmTheme.caption,
                        ),
                    ],
                  ),
                ),
              ],
              if (companionPhone.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.phone_rounded,
                        size: 18, color: HmTheme.emerald),
                    const SizedBox(width: 8),
                    Text(
                      'رفيقي: $companionPhone',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          style: HmTheme.primaryButton(),
          onPressed: onShare,
          icon: const Icon(Icons.share_rounded),
          label: const Text('مشاركة البطاقة'),
        ),
      ],
    );
  }
}