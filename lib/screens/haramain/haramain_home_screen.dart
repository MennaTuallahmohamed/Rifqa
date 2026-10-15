import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../models/haramain/haramain_map_demo_models.dart';
import '../../services/haramain/haramain_connectivity_service.dart';
import 'theme/haramain_design.dart';
import 'widgets/haramain_map_overlays.dart';
import 'haramain_live_screen.dart';

/// The Haramain entrance.
///
/// Two destinations, each opening its own map immediately. Under each
/// destination we show only things we can actually stand behind:
///  - the saved gate / meeting point / hotel, if the pilgrim saved one
///  - whether accessibility mode is on
///  - whether the bundled data + verified route data is present
///
/// We deliberately show NO crowd status, NO "live" prayer times and NO
/// occupancy numbers, because there is no verified source for them in this
/// project and inventing them would be dishonest.
class HmHomeScreen extends StatelessWidget {
  const HmHomeScreen({
    super.key,
    required this.siteStatus,
    required this.connectivity,
    this.onBack,
  });

  /// Per-site facts the controller already knows, passed in so this widget
  /// stays purely presentational.
  final Map<HaramainSite, HmSiteStatus> siteStatus;
  final HaramainConnectivityService connectivity;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: HmTheme.ivory,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: connectivity,
            builder: (context, _) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _header(context)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final site = HaramainSite.values[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index ==
                                      HaramainSite.values.length - 1
                                  ? 0
                                  : 16,
                            ),
                            child: _SiteCard(
                              site: site,
                              status: siteStatus[site] ?? HmSiteStatus.unknown,
                              onTap: () => _open(context, site),
                            ),
                          );
                        },
                        childCount: HaramainSite.values.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, HaramainSite site) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HaramainLiveScreen(),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final offline = connectivity.current == HaramainConnectivity.offline;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  tooltip: 'رجوع',
                )
              else
                const SizedBox(width: 48),
              const Spacer(),
              Text(
                'رِفقة',
                style: HmTheme.h1.copyWith(color: HmTheme.emerald),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'الحرمين',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: HmTheme.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'خريطة تفاعلية حقيقية للحرمين، مع بحث ذكي وخدمات موثّقة.',
            style: HmTheme.body,
          ),
          if (offline) ...[
            const SizedBox(height: 12),
            HmConnectivityBanner(
              connectivity: connectivity.current,
              onRetry: connectivity.probeNow,
            ),
          ],
        ],
      ),
    );
  }
}

/// Everything the entry screen can truthfully say about a site.
class HmSiteStatus {
  const HmSiteStatus({
    this.savedGateLabel,
    this.meetingPointLabel,
    this.hotelLabel,
    this.accessibilityMode = false,
    this.verifiedPoiCount = 0,
    this.hasVerifiedRoutes = false,
    this.pinsCount = 0,
  });

  static const unknown = HmSiteStatus();

  final String? savedGateLabel;
  final String? meetingPointLabel;
  final String? hotelLabel;
  final bool accessibilityMode;
  final int verifiedPoiCount;
  final bool hasVerifiedRoutes;
  final int pinsCount;

  bool get hasSavedGate => (savedGateLabel ?? '').isNotEmpty;
  bool get hasMeetingPoint => (meetingPointLabel ?? '').isNotEmpty;
  bool get hasHotel => (hotelLabel ?? '').isNotEmpty;
  bool get hasAnyPersonalData =>
      hasSavedGate || hasMeetingPoint || hasHotel || pinsCount > 0;
}

class _SiteCard extends StatelessWidget {
  const _SiteCard({
    required this.site,
    required this.status,
    required this.onTap,
  });

  final HaramainSite site;
  final HmSiteStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMakkah = site == HaramainSite.makkah;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: HmTheme.shadowSoft,
          ),
          child: Column(
            children: [
              // ── Identity band ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  gradient: LinearGradient(
                    colors: isMakkah
                        ? const [Color(0xFF0B6B54), Color(0xFF053A31)]
                        : const [Color(0xFF14624F), Color(0xFF07352C)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: HmTheme.gold.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Text(
                        site.emoji,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            site.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            site.city,
                            style: const TextStyle(
                              color: Color(0xFFD8E9E5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ],
                ),
              ),

              // ── Honest status rows ──
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (status.hasAnyPersonalData) ...[
                      if (status.hasSavedGate)
                        _StatusRow(
                          icon: Icons.door_sliding_outlined,
                          label: 'باب دخولك',
                          value: status.savedGateLabel!,
                          saved: true,
                        ),
                      if (status.hasMeetingPoint)
                        _StatusRow(
                          icon: Icons.groups_outlined,
                          label: 'نقطة التجمع',
                          value: status.meetingPointLabel!,
                          saved: true,
                        ),
                      if (status.hasHotel)
                        _StatusRow(
                          icon: Icons.hotel_outlined,
                          label: 'فندقك',
                          value: status.hotelLabel!,
                          saved: true,
                        ),
                      const SizedBox(height: 10),
                    ] else
                      Text(
                        'لم تحفظ أي مكان بعد. افتح الخريطة واحفظ باب دخولك '
                        'أو نقطة تجمعك لتصل إليها بسرعة.',
                        style: HmTheme.caption,
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (status.accessibilityMode)
                          const HmChip(
                            label: 'وضع الكرسي المتحرك مفعّل',
                            icon: Icons.accessible_rounded,
                            color: HmTheme.info,
                          ),
                        if (status.verifiedPoiCount > 0)
                          HmChip(
                            label: '${status.verifiedPoiCount} نقطة موثّقة',
                            icon: Icons.verified_rounded,
                            color: HmTheme.emerald,
                          )
                        else
                          const HmChip(
                            label: 'لا توجد نقاط موثّقة بعد',
                            icon: Icons.help_outline_rounded,
                            color: HmTheme.warn,
                          ),
                        HmChip(
                          label: status.hasVerifiedRoutes
                              ? 'توجيه داخلي متاح'
                              : 'التوجيه الداخلي غير متاح',
                          icon: status.hasVerifiedRoutes
                              ? Icons.route_rounded
                              : Icons.block_rounded,
                          color: status.hasVerifiedRoutes
                              ? HmTheme.emerald
                              : HmTheme.warn,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      style: HmTheme.primaryButton(height: 48),
                      onPressed: onTap,
                      icon: const Icon(Icons.map_rounded),
                      label: const Text('افتح الخريطة'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.saved,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: HmTheme.emerald),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HmTheme.caption,
            ),
          ),
          if (saved)
            const Icon(Icons.check_circle_rounded,
                size: 16, color: HmTheme.emerald),
        ],
      ),
    );
  }
}

/// Small helper used by the map screen to build a LatLng from the site centre.
LatLng siteCenter(HaramainSite site) => site.center;