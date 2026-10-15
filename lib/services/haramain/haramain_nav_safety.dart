import 'package:maplibre_gl/maplibre_gl.dart';

import '../../screens/haramain/haramain_live_models.dart';
import '../../screens/haramain/haramain_data_service.dart';
import '../../models/haramain/accessibility_profile.dart';
import '../../models/haramain/haramain_map_demo_models.dart';
import 'haramain_verified_repository.dart';
import 'haramain_navigation_service.dart';

/// Production navigation is allowed only for an explicit VERIFIED_ROUTE
/// graph edge set that is flagged navigationAllowed, and only when the
/// packaged verified dataset does not disable production navigation.
class HaramainNavSafety {
  HaramainNavSafety({
    required this.data,
    required this.verified,
    required this.navigation,
  });

  final HaramainDataService data;
  final HaramainVerifiedRepository verified;
  final HaramainNavigationService navigation;

  bool get productionNavigationGloballyEnabled {
    if (!verified.isMakkahLoaded) return true;
    return navigation.canNavigateMakkah;
  }

  bool hasVerifiedNetwork(HaramainSite site) => data.hasVerifiedNetwork(site);

  /// A verified POI is never enough. Wheelchair mode requires an accessible
  /// verified route; we never infer accessibility.
  HlRoute? verifiedRouteTo({
    required HaramainSite site,
    required LatLng from,
    required HlPoi dest,
    required AccessibilityProfile profile,
  }) {
    if (dest.isPin) return null;
    if (!productionNavigationGloballyEnabled &&
        site == HaramainSite.makkah) {
      return null;
    }
    final route = data.route(
      site,
      from,
      dest,
      accessible: profile.wheelchairMode,
    );
    if (route == null) return null;
    if (profile.wheelchairMode && !route.accessible) return null;
    return route;
  }

  bool canStartNavigation(HlRoute? route) => route != null;
}
