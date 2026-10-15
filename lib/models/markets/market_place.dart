enum MarketCity {
  makkah,
  madinah,
}

enum MarketCategory {
  mall,
  traditionalMarket,
  gifts,
  dates,
  perfumes,
  abayas,
  gold,
  food,
  pharmacy,
  supermarket,
  hajjUmrahSupplies,
  other,
}

enum MarketVerificationStatus {
  verified,
  needsReview,
}

class MarketPlace {
  const MarketPlace({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    required this.shortDescription,
    required this.description,
    required this.verificationStatus,
    this.imageUrl,
    this.gallery = const [],
    this.latitude,
    this.longitude,
    this.address,
    this.openingHours,
    this.phone,
    this.website,
    this.tags = const [],
    this.isPopular = false,
    this.isRecommended = false,
    this.hasFood = false,
    this.hasParking = false,
    this.hasWheelchairAccess = false,
    this.accessibilityVerified = false,
  });

  // =========================================================
  // Basic Information
  // =========================================================

  final String id;
  final String name;
  final MarketCity city;
  final MarketCategory category;

  final String shortDescription;
  final String description;

  // =========================================================
  // Images
  // =========================================================

  final String? imageUrl;
  final List<String> gallery;

  // =========================================================
  // Location
  // =========================================================

  final double? latitude;
  final double? longitude;
  final String? address;

  // =========================================================
  // Contact / Opening
  // =========================================================

  final String? openingHours;
  final String? phone;
  final String? website;

  // =========================================================
  // Shopping Information
  // =========================================================

  final List<String> tags;

  final bool isPopular;
  final bool isRecommended;

  // =========================================================
  // Facilities
  // =========================================================

  final bool hasFood;
  final bool hasParking;

  final bool hasWheelchairAccess;

  /// True only when accessibility information
  /// comes from a trusted/verified source.
  final bool accessibilityVerified;

  // =========================================================
  // Verification
  // =========================================================

  final MarketVerificationStatus verificationStatus;

  // =========================================================
  // Helpers
  // =========================================================

  bool get hasCoordinates {
    return verificationStatus == MarketVerificationStatus.verified &&
        latitude != null &&
        longitude != null;
  }

  bool get hasContactInfo {
    return phone != null || website != null;
  }

  bool get needsReview {
    return verificationStatus == MarketVerificationStatus.needsReview;
  }

  String get cityName {
    switch (city) {
      case MarketCity.makkah:
        return 'مكة المكرمة';

      case MarketCity.madinah:
        return 'المدينة المنورة';
    }
  }

  String get categoryName {
    switch (category) {
      case MarketCategory.mall:
        return 'مول';

      case MarketCategory.traditionalMarket:
        return 'سوق شعبي';

      case MarketCategory.gifts:
        return 'هدايا وتذكارات';

      case MarketCategory.dates:
        return 'تمور';

      case MarketCategory.perfumes:
        return 'عطور وبخور';

      case MarketCategory.abayas:
        return 'ملابس وعبايات';

      case MarketCategory.gold:
        return 'ذهب ومجوهرات';

      case MarketCategory.food:
        return 'مطاعم وطعام';

      case MarketCategory.pharmacy:
        return 'صيدليات';

      case MarketCategory.supermarket:
        return 'سوبر ماركت';

      case MarketCategory.hajjUmrahSupplies:
        return 'مستلزمات الحج والعمرة';

      case MarketCategory.other:
        return 'تسوق';
    }
  }

  String get categoryEmoji {
    switch (category) {
      case MarketCategory.mall:
        return '🏬';

      case MarketCategory.traditionalMarket:
        return '🛍️';

      case MarketCategory.gifts:
        return '🎁';

      case MarketCategory.dates:
        return '🌴';

      case MarketCategory.perfumes:
        return '🌸';

      case MarketCategory.abayas:
        return '👗';

      case MarketCategory.gold:
        return '💎';

      case MarketCategory.food:
        return '🍽️';

      case MarketCategory.pharmacy:
        return '💊';

      case MarketCategory.supermarket:
        return '🛒';

      case MarketCategory.hajjUmrahSupplies:
        return '🕌';

      case MarketCategory.other:
        return '📍';
    }
  }
}