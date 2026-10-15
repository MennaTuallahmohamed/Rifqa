import '../../models/markets/market_place.dart';

class MarketsRepository {
  const MarketsRepository();

  List<MarketPlace> get all {
    return const [
      // =========================================================
      // MAKKAH
      // =========================================================

      MarketPlace(
        id: 'makkah_abraj_al_bait',
        name: 'أبراج البيت مول',
        city: MarketCity.makkah,
        category: MarketCategory.mall,
        shortDescription:
            'مركز تسوق بجوار المسجد الحرام داخل مجمع أبراج البيت.',
        description:
            'وجهة تسوق قريبة جدًا من المسجد الحرام، تضم متاجر للملابس '
            'والعطور والمجوهرات والإلكترونيات والهدايا والمنتجات الإسلامية، '
            'إضافة إلى المطاعم والمقاهي.',
        address: 'مجمع أبراج البيت، مقابل المسجد الحرام، مكة المكرمة',
        latitude: 21.41875,
        longitude: 39.82556,
        openingHours: 'مفتوح 24 ساعة',
        tags: [
          'هدايا',
          'عطور',
          'ملابس',
          'مجوهرات',
          'مطاعم',
          'قريب من الحرم',
        ],
        isPopular: true,
        isRecommended: true,
        hasFood: true,
        verificationStatus: MarketVerificationStatus.verified,
      ),

      MarketPlace(
        id: 'makkah_mall',
        name: 'مكة مول',
        city: MarketCity.makkah,
        category: MarketCategory.mall,
        shortDescription:
            'مول حديث يضم علامات تجارية ومتاجر ومطاعم وخيارات ترفيه.',
        description:
            'من مراكز التسوق الحديثة المعروفة في مكة، ويضم متاجر للأزياء '
            'والعطور والإلكترونيات والمنزل والمجوهرات والساعات، '
            'إضافة إلى المطاعم والمقاهي.',
        address: 'طريق الملك عبدالله، حي الجامعة، مكة المكرمة',
        latitude: 21.39108,
        longitude: 39.88461,
        openingHours: '9:30 ص - 12:00 ص',
        phone: '+966920000262',
        website: 'https://centers.cenomi.com/sa-ar/malls/makkah-mall/',
        tags: [
          'ملابس',
          'عطور',
          'مطاعم',
          'مجوهرات',
          'إلكترونيات',
          'عائلات',
        ],
        isPopular: true,
        isRecommended: true,
        hasFood: true,
        hasWheelchairAccess: true,
        accessibilityVerified: true,
        verificationStatus: MarketVerificationStatus.verified,
      ),

      MarketPlace(
        id: 'makkah_diyafa_mall',
        name: 'الضيافة مول',
        city: MarketCity.makkah,
        category: MarketCategory.mall,
        shortDescription:
            'مركز تسوق في حي الزاهر يضم متاجر ومطاعم واحتياجات متنوعة.',
        description:
            'وجهة تسوق في مكة تضم متاجر للأزياء والأحذية والإكسسوارات '
            'والاحتياجات المنزلية، بالإضافة إلى المقاهي والمطاعم '
            'وسوبر ماركت للاحتياجات اليومية.',
        address: 'شارع الحجون، حي الزاهر، مكة المكرمة',
        openingHours: '8:00 ص - 2:00 ص',
        website: 'https://soukaldiyafa.com/',
        tags: [
          'ملابس',
          'عطور',
          'مطاعم',
          'احتياجات يومية',
          'سوبر ماركت',
        ],
        isPopular: true,
        hasFood: true,
        verificationStatus: MarketVerificationStatus.verified,
      ),

      MarketPlace(
        id: 'makkah_otaibiyah_market',
        name: 'سوق العتيبية',
        city: MarketCity.makkah,
        category: MarketCategory.traditionalMarket,
        shortDescription:
            'سوق شعبي قديم في مكة للملابس والعطور والهدايا والمنتجات المتنوعة.',
        description:
            'من الأسواق التقليدية المعروفة في مكة. تتنوع منتجاته بين '
            'الملابس والأقمشة والعطور والبخور والذهب والمجوهرات '
            'والتمور والمكسرات والحلويات والهدايا التقليدية.',
        address: 'حي العتيبية، شارع الحجون، مكة المكرمة',
        tags: [
          'سوق شعبي',
          'ملابس',
          'عطور',
          'بخور',
          'ذهب',
          'تمور',
          'هدايا',
        ],
        isPopular: true,
        isRecommended: true,
        verificationStatus: MarketVerificationStatus.verified,
      ),

      MarketPlace(
        id: 'makkah_dates_market',
        name: 'سوق تمور مكة',
        city: MarketCity.makkah,
        category: MarketCategory.dates,
        shortDescription:
            'سوق متخصص في التمور ومشتقاتها ومناسب لشراء الهدايا.',
        description:
            'سوق متخصص في أنواع مختلفة من التمور ومشتقاتها، '
            'مع منتجات موسمية مثل العسل، ويعد خيارًا لشراء '
            'التمور للاستخدام الشخصي أو كهدايا.',
        address: 'العزيزية، مكة المكرمة',
        openingHours: '6:30 ص - 12:00 ص',
        tags: [
          'تمور',
          'عسل',
          'هدايا',
          'منتجات غذائية',
        ],
        isRecommended: true,
        isPopular: true,
        verificationStatus: MarketVerificationStatus.verified,
      ),

      MarketPlace(
        id: 'makkah_alkhalil_market',
        name: 'سوق الخليل - جبل عمر',
        city: MarketCity.makkah,
        category: MarketCategory.mall,
        shortDescription:
            'وجهة تسوق ضمن مشروع جبل عمر وقريبة من المسجد الحرام.',
        description:
            'سوق ضمن مشروع جبل عمر يوفر خيارات تسوق للزوار والمعتمرين، '
            'ومنها الهدايا والمنتجات التي يحتاجها زوار مكة.',
        address: 'الشبيكة، مكة المكرمة',
        tags: [
          'هدايا',
          'تذكارات',
          'قريب من الحرم',
          'تسوق',
        ],
        isRecommended: true,
        verificationStatus: MarketVerificationStatus.verified,
      ),

      MarketPlace(
        id: 'makkah_hijaz_mall',
        name: 'الحجاز مول',
        city: MarketCity.makkah,
        category: MarketCategory.mall,
        shortDescription:
            'مركز تسوق في حي النزهة يضم متاجر وخيارات ترفيه.',
        description:
            'وجهة تسوق في مكة توفر مجموعة من المتاجر '
            'والخيارات الترفيهية للزوار والعائلات.',
        address: 'حي النزهة، مكة المكرمة',
        tags: [
          'تسوق',
          'ملابس',
          'عائلات',
        ],
        isPopular: true,
        verificationStatus: MarketVerificationStatus.verified,
      ),

      // =========================================================
      // MADINAH
      // =========================================================

      MarketPlace(
        id: 'madinah_al_noor_mall',
        name: 'النور مول',
        city: MarketCity.madinah,
        category: MarketCategory.mall,
        shortDescription:
            'مول كبير يضم علامات محلية وعالمية ومطاعم وهدايا.',
        description:
            'مركز تجاري في المدينة المنورة يضم مجموعة واسعة من '
            'العلامات المحلية والعالمية والمتاجر والمطاعم والمقاهي، '
            'بالإضافة إلى متاجر للهدايا.',
        address:
            'طريق الملك عبدالله، حي العيون، قرب المحكمة الإدارية، المدينة المنورة',
        latitude: 24.49605,
        longitude: 39.59532,
        openingHours: '10:00 ص - 11:00 م',
        tags: [
          'ملابس',
          'هدايا',
          'مطاعم',
          'مقاهي',
          'عائلات',
        ],
        isPopular: true,
        isRecommended: true,
        hasFood: true,
        verificationStatus: MarketVerificationStatus.verified,
      ),

      MarketPlace(
        id: 'madinah_rashid_mega_mall',
        name: 'الراشد ميجا مول',
        city: MarketCity.madinah,
        category: MarketCategory.mall,
        shortDescription:
            'مركز تسوق وترفيه كبير يضم متاجر ومطاعم وعلامات متنوعة.',
        description:
            'من مراكز التسوق المعروفة في المدينة المنورة، ويضم '
            'علامات محلية وعالمية وخيارات للتسوق والترفيه والمطاعم.',
        address:
            'طريق الملك عبدالله - الطريق الدائري الثاني، شرق المدينة المنورة',
        latitude: 24.48790,
        longitude: 39.64855,
        openingHours:
            'السبت - الخميس: 9:00 ص - 1:00 ص | الجمعة: 1:00 م - 1:00 ص',
        tags: [
          'ملابس',
          'مطاعم',
          'ترفيه',
          'عائلات',
          'علامات تجارية',
        ],
        isPopular: true,
        isRecommended: true,
        hasFood: true,
        hasParking: true,
        verificationStatus: MarketVerificationStatus.verified,
      ),

      MarketPlace(
        id: 'madinah_suwaiqah_market',
        name: 'سوق سويقة وورش العينية',
        city: MarketCity.madinah,
        category: MarketCategory.traditionalMarket,
        shortDescription:
            'سوق تراثي للحرف والمنتجات اليدوية المرتبطة بثقافة المدينة.',
        description:
            'وجهة تراثية تعرض منتجات وحرفًا يدوية، وتدعم الأسر المنتجة '
            'والحرفيات، مع منتجات مرتبطة بتاريخ وثقافة المدينة المنورة.',
        address:
            'الحي التراثي، حديقة الملك فهد المركزية، المدينة المنورة',
        openingHours:
            'السبت - الخميس: 5:00 م - 11:00 م',
        tags: [
          'حرف يدوية',
          'هدايا',
          'تراث',
          'منتجات محلية',
          'أسر منتجة',
        ],
        isPopular: true,
        isRecommended: true,
        verificationStatus: MarketVerificationStatus.verified,
      ),

      MarketPlace(
        id: 'madinah_quba_boulevard',
        name: 'قباء بوليفارد',
        city: MarketCity.madinah,
        category: MarketCategory.food,
        shortDescription:
            'وجهة على طريق قباء تضم مجموعة متنوعة من المطاعم والمقاهي.',
        description:
            'وجهة للزوار والسكان على طريق قباء، تتميز بمجموعة '
            'من المطاعم والمقاهي وجلسات داخلية وخارجية.',
        address:
            'طريق قباء باتجاه الجنوب، المدينة المنورة',
        tags: [
          'مطاعم',
          'مقاهي',
          'جلسات',
          'عائلات',
          'طريق قباء',
        ],
        isPopular: true,
        hasFood: true,
        verificationStatus: MarketVerificationStatus.verified,
      ),

      MarketPlace(
        id: 'madinah_boulevard',
        name: 'المدينة بوليفارد',
        city: MarketCity.madinah,
        category: MarketCategory.mall,
        shortDescription:
            'وجهة حديثة تضم التسوق والمطاعم والمقاهي والمساحات العامة.',
        description:
            'وجهة حديثة في المدينة المنورة تضم مرافق سياحية '
            'ومراكز تسوق ومقاهي ومطاعم ومساحات للفعاليات والجلوس.',
        address:
            'حي الراية، طريق الملك عبدالله، مقابل النور مول، المدينة المنورة',
        tags: [
          'تسوق',
          'مطاعم',
          'مقاهي',
          'ترفيه',
          'عائلات',
        ],
        isRecommended: true,
        hasFood: true,
        verificationStatus: MarketVerificationStatus.verified,
      ),
    ];
  }

  List<MarketPlace> get makkah {
    return all
        .where(
          (market) => market.city == MarketCity.makkah,
        )
        .toList();
  }

  List<MarketPlace> get madinah {
    return all
        .where(
          (market) => market.city == MarketCity.madinah,
        )
        .toList();
  }

  List<MarketPlace> byCity(MarketCity city) {
    return all
        .where(
          (market) => market.city == city,
        )
        .toList();
  }

  List<MarketPlace> byCategory(
    MarketCategory category,
  ) {
    return all
        .where(
          (market) => market.category == category,
        )
        .toList();
  }

  List<MarketPlace> byCityAndCategory({
    required MarketCity city,
    required MarketCategory category,
  }) {
    return all
        .where(
          (market) =>
              market.city == city &&
              market.category == category,
        )
        .toList();
  }

  List<MarketPlace> recommended(
    MarketCity city,
  ) {
    return all
        .where(
          (market) =>
              market.city == city &&
              market.isRecommended,
        )
        .toList();
  }

  List<MarketPlace> popular(
    MarketCity city,
  ) {
    return all
        .where(
          (market) =>
              market.city == city &&
              market.isPopular,
        )
        .toList();
  }

  List<MarketPlace> search({
    required MarketCity city,
    required String query,
  }) {
    final normalizedQuery =
        query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return byCity(city);
    }

    return all.where((market) {
      if (market.city != city) {
        return false;
      }

      final searchableText = [
        market.name,
        market.shortDescription,
        market.description,
        market.address ?? '',
        market.categoryName,
        ...market.tags,
      ].join(' ').toLowerCase();

      return searchableText.contains(
        normalizedQuery,
      );
    }).toList();
  }

  MarketPlace? findById(String id) {
    for (final market in all) {
      if (market.id == id) {
        return market;
      }
    }

    return null;
  }

  List<MarketPlace> withCoordinates(
    MarketCity city,
  ) {
    return all
        .where(
          (market) =>
              market.city == city &&
              market.hasCoordinates,
        )
        .toList();
  }

  int categoryCount({
    required MarketCity city,
    required MarketCategory category,
  }) {
    return all
        .where(
          (market) =>
              market.city == city &&
              market.category == category,
        )
        .length;
  }
}