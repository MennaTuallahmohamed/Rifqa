import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../models/haramain/haramain_map_demo_models.dart';
import '../../../services/haramain/haramain_connectivity_service.dart';
import '../theme/haramain_design.dart';

/// Slim, premium top bar: site identity + search entry.
///
/// It never covers the map: it is a floating rounded surface with the app bar
/// and search field collapsed into one compact card.
class HmMapHeader extends StatelessWidget {
  const HmMapHeader({
    super.key,
    required this.site,
    required this.onBack,
    required this.onSearch,
    required this.onSwitchSite,
    this.gpsLabel,
    this.gpsHealthy = false,
    this.onGpsTap,
    this.online = true,
  });

  final HaramainSite site;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onSwitchSite;
  final String? gpsLabel;
  final bool gpsHealthy;
  final VoidCallback? onGpsTap;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            elevation: 8,
            shadowColor: const Color(0x33000000),
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onSearch,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 14, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      color: HmTheme.ink,
                      tooltip: 'رجوع',
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: HmTheme.emeraldSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        site.emoji,
                        style: const TextStyle(fontSize: 21),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: onSwitchSite,
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    site.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: HmTheme.ink,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.expand_more_rounded,
                                  size: 20,
                                  color: HmTheme.muted,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: onSearch,
                            child: Text(
                              'ابحث عن خدمة أو مكان...',
                              style: TextStyle(
                                fontSize: 13,
                                color: HmTheme.muted.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.search_rounded, color: HmTheme.emerald),
                  ],
                ),
              ),
            ),
          ),
          if (gpsLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _GpsPill(
                label: gpsLabel!,
                healthy: gpsHealthy,
                onTap: onGpsTap,
              ),
            ),
        ],
      ),
    );
  }
}

class _GpsPill extends StatelessWidget {
  const _GpsPill({required this.label, required this.healthy, this.onTap});

  final String label;
  final bool healthy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = healthy ? HmTheme.emeraldSoft : HmTheme.warnSoft;
    final fg = healthy ? HmTheme.emerald : HmTheme.warn;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gps_fixed_rounded, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrollable quick-service strip.
///
/// Selecting a service either highlights its POIs on the map or opens the
/// nearest list, depending on data availability. It never promises navigation.
class HmQuickServices extends StatelessWidget {
  const HmQuickServices({
    super.key,
    required this.services,
    required this.onSelect,
    this.active,
    this.highContrast = false,
  });

  final List<String> services;
  final void Function(String label, IconData icon) onSelect;
  final String? active;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final service = services[index];
          final isActive = service == active;
          return _ServiceTile(
            label: service,
            icon: _iconFor(service),
            active: isActive,
            highContrast: highContrast,
            onTap: () => onSelect(service, _iconFor(service)),
          );
        },
      ),
    );
  }

  static IconData _iconFor(String label) {
    if (label.contains('باب')) return Icons.door_front_door_outlined;
    if (label.contains('مياه')) return Icons.water_drop_outlined;
    if (label.contains('دورات')) return Icons.wc_rounded;
    if (label.contains('وصول') || label.contains('همم')) {
      return Icons.accessible_rounded;
    }
    if (label.contains('مصعد')) return Icons.elevator_outlined;
    if (label.contains('نساء')) return Icons.woman_rounded;
    if (label.contains('إسعاف')) return Icons.medical_services_outlined;
    if (label.contains('تجمع')) return Icons.groups_outlined;
    if (label.contains('استعلام') || label.contains('إرشاد')) {
      return Icons.info_outline_rounded;
    }
    return Icons.place_outlined;
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    required this.highContrast,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? HmTheme.emerald
        : highContrast
            ? Colors.white
            : Colors.white;
    final fg = active ? Colors.white : HmTheme.emerald;
    return SizedBox(
      width: 86,
      child: Material(
        elevation: 4,
        shadowColor: const Color(0x22000000),
        color: bg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: highContrast && !active
                    ? Colors.black
                    : active
                        ? HmTheme.emerald
                        : Colors.transparent,
                width: highContrast && !active ? 2 : 0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 26),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : HmTheme.ink,
                    height: 1.2,
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

/// Category filter chips for the map.
class HmCategoryFilter extends StatelessWidget {
  const HmCategoryFilter({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.onSelect,
    this.highContrast = false,
  });

  final List<(String, IconData)> labels;
  final int? activeIndex;
  final void Function(int index) onSelect;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = activeIndex == index;
          final (label, icon) = labels[index];
          return FilterChip(
            avatar: Icon(
              icon,
              size: 17,
              color: selected ? Colors.white : HmTheme.emerald,
            ),
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            selectedColor: HmTheme.emerald,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: highContrast && !selected
                  ? Colors.black
                  : selected
                      ? HmTheme.emerald
                      : HmTheme.line,
              width: highContrast && !selected ? 2 : 1,
            ),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: selected ? Colors.white : HmTheme.ink,
            ),
            onSelected: (_) => onSelect(index),
          );
        },
      ),
    );
  }
}

/// The vertical stack of circular map controls on the leading edge.
class HmMapControls extends StatelessWidget {
  const HmMapControls({
    super.key,
    required this.satellite,
    required this.tilt,
    required this.followMode,
    required this.onSatellite,
    required this.onTilt,
    required this.onLocate,
    required this.onNorth,
    required this.onSettings,
    required this.onLayers,
  });

  final bool satellite;
  final bool tilt;
  final bool followMode;
  final VoidCallback onSatellite;
  final VoidCallback onTilt;
  final VoidCallback onLocate;
  final VoidCallback onNorth;
  final VoidCallback onSettings;
  final VoidCallback onLayers;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HmMapButton(
          icon: satellite
              ? Icons.satellite_alt_rounded
              : Icons.map_outlined,
          onPressed: onSatellite,
          active: satellite,
          tooltip: satellite ? 'عرض أقمار صناعية' : 'عرض شارع',
        ),
        const SizedBox(height: 10),
        HmMapButton(
          icon: Icons.navigation_rounded,
          onPressed: onLocate,
          active: followMode,
          tooltip: 'موقعي',
        ),
        const SizedBox(height: 10),
        HmMapButton(
          icon: Icons.explore_rounded,
          onPressed: onNorth,
          tooltip: 'اتجاه الشمال',
        ),
        const SizedBox(height: 10),
        HmMapButton(
          icon: Icons.view_in_ar_rounded,
          onPressed: onTilt,
          active: tilt,
          tooltip: 'مائلة ثلاثية الأبعاد',
        ),
        const SizedBox(height: 10),
        HmMapButton(
          icon: Icons.tune_rounded,
          onPressed: onLayers,
          tooltip: 'الفلاتر',
        ),
        const SizedBox(height: 10),
        HmMapButton(
          icon: Icons.settings_outlined,
          onPressed: onSettings,
          tooltip: 'الإعدادات وإمكانية الوصول',
        ),
      ],
    );
  }
}

/// Honest connectivity banner.
///
/// It states exactly what is and is not available offline. The packaged POI,
/// pin and preference data works offline; the map tiles do not.
class HmConnectivityBanner extends StatelessWidget {
  const HmConnectivityBanner({
    super.key,
    required this.connectivity,
    this.onRetry,
  });

  final HaramainConnectivity connectivity;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (connectivity == HaramainConnectivity.online) {
      return const SizedBox.shrink();
    }

    final isOffline = connectivity == HaramainConnectivity.offline;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Material(
        elevation: 3,
        color: isOffline ? HmTheme.warnSoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(
                isOffline
                    ? Icons.wifi_off_rounded
                    : Icons.wifi_tethering_rounded,
                size: 20,
                color: isOffline ? HmTheme.warn : HmTheme.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isOffline
                      ? 'الاتصال ضعيف. بياناتك المحفوظة وبحثك وخرائط المسارات '
                          'المعبّأة ما زالت تعمل، لكن بلاطات الخريطة لا تُحمّل الآن.'
                      : 'جارٍ التحقق من الاتصال لعرض الخريطة...',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: isOffline ? HmTheme.ink : HmTheme.muted,
                  ),
                ),
              ),
              if (isOffline && onRetry != null)
                IconButton(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  color: HmTheme.warn,
                  tooltip: 'إعادة المحاولة',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small compact helper that shows the straight-line distance to a POI with an
/// explicit note that it is not a walking distance.
class HmStraightLineDistance extends StatelessWidget {
  const HmStraightLineDistance({super.key, required this.meters});
  final double meters;

  @override
  Widget build(BuildContext context) {
    final label = meters < 1000
        ? '${meters.round()} م'
        : '${(meters / 1000).toStringAsFixed(1)} كم';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.straighten_rounded, size: 14, color: HmTheme.muted),
        const SizedBox(width: 4),
        Text(
          '$label (بخط مستقيم)',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: HmTheme.muted,
          ),
        ),
      ],
    );
  }
}