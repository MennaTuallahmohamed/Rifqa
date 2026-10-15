import 'haramain_verified_repository.dart';

class HaramainNavigationService {
  HaramainNavigationService(this.repository);

  final HaramainVerifiedRepository repository;

  bool get canNavigateMakkah =>
      repository.isMakkahLoaded &&
      repository.isProductionNavigationEnabled;

  List<Map<String, dynamic>> get verifiedRoutes {
    if (!repository.isMakkahLoaded) return const [];
    return repository.navigationRoutes;
  }

  bool canNavigateWith(Map<String, dynamic> route) {
    if (!repository.isMakkahLoaded) return false;
    return repository.canUseForNavigation(route);
  }
}
