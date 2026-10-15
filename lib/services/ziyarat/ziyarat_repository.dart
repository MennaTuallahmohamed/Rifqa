import '../../models/ziyarat/ziyarat_place.dart';

/// ============================================================
/// RIFQA — ZIYARAT REPOSITORY
/// ============================================================
///
/// مصدر بيانات المزارات داخل التطبيق.
///
/// ملاحظات مهمة:
/// 1) المحتوى الحالي من Prototype المزارات المقدم للمشروع.
/// 2) المحتوى الديني يحتاج مراجعة نهائية قبل Production.
/// 3) لا توجد إحداثيات مخترعة أو تقريبية.
/// 4) أي مزار بلا إحداثيات موثقة يظل latitude/longitude = null.
/// ============================================================

class ZiyaratRepository {
  const ZiyaratRepository();

  List<ZiyaratPlace> get all => _places;

  List<ZiyaratPlace> get makkah =>
      _places.where((place) => place.city == ZiyaratCity.makkah).toList();

  List<ZiyaratPlace> get madinah =>
      _places.where((place) => place.city == ZiyaratCity.madinah).toList();

  ZiyaratPlace? byId(String id) {
    for (final place in _places) {
      if (place.id == id) return place;
    }
    return null;
  }

  List<ZiyaratPlace> byCategory(ZiyaratCategory category) {
    return _places.where((place) => place.category == category).toList();
  }

  List<ZiyaratPlace> search(
    String query, {
    ZiyaratCity? city,
    ZiyaratCategory? category,
  }) {
    final normalized = query.trim().toLowerCase();

    return _places.where((place) {
      if (city != null && place.city != city) return false;

      if (category != null && place.category != category) {
        return false;
      }

      if (normalized.isEmpty) return true;

      return place.name.toLowerCase().contains(normalized) ||
          place.shortDescription.toLowerCase().contains(normalized) ||
          place.story.toLowerCase().contains(normalized) ||
          place.significance.toLowerCase().contains(normalized);
    }).toList();
  }
}

const List<ZiyaratPlace> _places = [
  // ============================================================
  // MAKKAH
  // ============================================================

  ZiyaratPlace(
    id: 'kaaba_haram',
    name: 'الكعبة المشرفة والمسجد الحرام',
    city: ZiyaratCity.makkah,
    category: ZiyaratCategory.landmark,
    icon: '🕋',
    shortDescription:
        'بيت الله الحرام وقبلة المسلمين، وفي المسجد الحرام تؤدى أعمال الطواف.',
    story:
        'رفع إبراهيم وإسماعيل عليهما السلام قواعد البيت، وهما يقولان: ربنا تقبل منا. وأمر الله إبراهيم أن يؤذن في الناس بالحج، فصار البيت مقصدًا للمسلمين من كل مكان.',
    significance:
        'المسجد الحرام قبلة المسلمين في صلاتهم، وورد في المادة المرجعية فضل الصلاة فيه.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'الطواف',
        description:
            'الطواف سبعة أشواط بدءًا من الحجر الأسود.',
      ),
      ZiyaratVisitorGuidance(
        title: 'ركعتا الطواف',
        description:
            'صلاة ركعتين خلف مقام إبراهيم إن تيسر.',
      ),
      ZiyaratVisitorGuidance(
        title: 'الذكر والدعاء',
        description:
            'الدعاء والذكر وقراءة القرآن.',
      ),
      ZiyaratVisitorGuidance(
        title: 'الرفق',
        description:
            'الخشوع وعدم إيذاء الناس في الزحام.',
      ),
    ],
    warnings: [
      'تجنب إيذاء الآخرين أو التدافع في الزحام.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.quran,
        text:
            '﴿إِنَّ أَوَّلَ بَيْتٍ وُضِعَ لِلنَّاسِ لَلَّذِي بِبَكَّةَ مُبَارَكًا وَهُدًى لِلْعَالَمِينَ﴾',
        source: 'القرآن الكريم',
        reference: 'آل عمران: 96',
      ),
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.quran,
        text:
            '﴿وَإِذْ يَرْفَعُ إِبْرَاهِيمُ الْقَوَاعِدَ مِنَ الْبَيْتِ وَإِسْمَاعِيلُ رَبَّنَا تَقَبَّلْ مِنَّا﴾',
        source: 'القرآن الكريم',
        reference: 'البقرة: 127',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'safa_marwa',
    name: 'الصفا والمروة',
    city: ZiyaratCity.makkah,
    category: ZiyaratCategory.landmark,
    icon: '⛰️',
    shortDescription:
        'من شعائر الله، وبينهما يؤدي الحاج والمعتمر السعي.',
    story:
        'ترك إبراهيم عليه السلام هاجر وابنها إسماعيل في الوادي بأمر الله. ولما عطش إسماعيل سعت هاجر بين الصفا والمروة سبع مرات تبحث عن الماء، ثم أكرمها الله بماء زمزم.',
    significance:
        'السعي بين الصفا والمروة شعيرة من شعائر الله، وتذكر قصته بصبر هاجر وتوكلها على الله.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'بداية السعي',
        description:
            'يبدأ السعي من الصفا وينتهي بالمروة.',
      ),
      ZiyaratVisitorGuidance(
        title: 'عدد الأشواط',
        description: 'السعي سبعة أشواط.',
      ),
      ZiyaratVisitorGuidance(
        title: 'الذكر',
        description:
            'الذكر والدعاء أثناء السعي.',
      ),
    ],
    warnings: [
      'مراعاة الآخرين وتجنب التدافع أثناء الزحام.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.quran,
        text:
            '﴿إِنَّ الصَّفَا وَالْمَرْوَةَ مِنْ شَعَائِرِ اللَّهِ﴾',
        source: 'القرآن الكريم',
        reference: 'البقرة: 158',
      ),
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text:
            'وردت قصة هاجر وسعيها بحثًا عن الماء في حديث ابن عباس رضي الله عنهما.',
        source: 'صحيح البخاري',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'zamzam',
    name: 'بئر زمزم',
    city: ZiyaratCity.makkah,
    category: ZiyaratCategory.well,
    icon: '💧',
    shortDescription:
        'الماء المبارك المرتبط بقصة هاجر وإسماعيل عليهما السلام.',
    story:
        'ترتبط زمزم بقصة هاجر وابنها إسماعيل عليه السلام، حين أكرمهما الله بالماء في وادي مكة.',
    significance:
        'ورد في السنة وصف زمزم بأنها مباركة وأنها طعام طُعم.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'الشرب',
        description:
            'الشرب من ماء زمزم بنية صادقة.',
      ),
      ZiyaratVisitorGuidance(
        title: 'الدعاء',
        description:
            'الدعاء بخير الدنيا والآخرة.',
      ),
      ZiyaratVisitorGuidance(
        title: 'عدم الإسراف',
        description:
            'الاقتصاد في الشرب وعدم الإسراف.',
      ),
    ],
    warnings: [
      'مراعاة الآخرين عند أماكن توزيع المياه.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text: '«إنها مباركة، إنها طعام طُعم»',
        source: 'صحيح مسلم',
      ),
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text: '«ماء زمزم لما شُرب له»',
        source: 'وفق المادة المرجعية',
        note:
            'ذكرت المادة المرجعية أن جمعًا من أهل العلم حسّن الحديث؛ يحتاج مراجعة نهائية قبل النشر.',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'hira',
    name: 'غار حراء – جبل النور',
    city: ZiyaratCity.makkah,
    category: ZiyaratCategory.mountain,
    icon: '🌙',
    shortDescription:
        'المكان المرتبط ببداية نزول الوحي على النبي ﷺ.',
    story:
        'كان النبي ﷺ يتعبد في غار حراء قبل البعثة، وهناك جاءه جبريل عليه السلام بأول الوحي وقال له: اقرأ. ثم رجع النبي ﷺ إلى خديجة رضي الله عنها يرجف فؤاده فثبّتته.',
    significance:
        'أهمية المكان تاريخية لارتباطه ببداية نزول الوحي وبداية الرسالة.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'الاعتبار',
        description:
            'التعرف على قصة بدء الوحي والتأمل في أحداث السيرة.',
      ),
    ],
    warnings: [
      'ليس صعود غار حراء من مناسك الحج أو العمرة.',
      'لا يُشرع قصد الغار بصلاة أو عبادة مخصوصة وفق المادة المرجعية.',
      'الصعود قد يكون شاقًا، خاصة في الحرارة.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.quran,
        text:
            '﴿اقْرَأْ بِاسْمِ رَبِّكَ الَّذِي خَلَقَ﴾',
        source: 'القرآن الكريم',
        reference: 'العلق: 1',
      ),
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text:
            'قصة بدء الوحي ومجيء جبريل عليه السلام للنبي ﷺ في غار حراء.',
        source: 'صحيح البخاري',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'maqam_ibrahim',
    name: 'مقام إبراهيم',
    city: ZiyaratCity.makkah,
    category: ZiyaratCategory.landmark,
    icon: '🪨',
    shortDescription:
        'معلم مرتبط بإبراهيم عليه السلام وبناء الكعبة.',
    story:
        'بحسب المادة المرجعية، هو الحجر الذي وقف عليه إبراهيم عليه السلام عندما ارتفع بناء الكعبة.',
    significance:
        'ورد في القرآن الأمر باتخاذ مقام إبراهيم مصلى، وصلى النبي ﷺ ركعتي الطواف خلفه.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'ركعتا الطواف',
        description:
            'صلاة ركعتي الطواف خلف المقام إن تيسر، وإلا ففي أي مكان مناسب بالمسجد.',
      ),
    ],
    warnings: [
      'عدم التزاحم عند المقام.',
      'عدم التمسح بالمقام.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.quran,
        text:
            '﴿وَاتَّخِذُوا مِنْ مَقَامِ إِبْرَاهِيمَ مُصَلًّى﴾',
        source: 'القرآن الكريم',
        reference: 'البقرة: 125',
      ),
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text:
            'ورد في المادة المرجعية أن النبي ﷺ صلى ركعتي الطواف خلف المقام.',
        source: 'صحيح مسلم',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'black_stone_hijr',
    name: 'الحجر الأسود وحِجر إسماعيل',
    city: ZiyaratCity.makkah,
    category: ZiyaratCategory.landmark,
    icon: '⚫',
    shortDescription:
        'من أبرز معالم الكعبة، والحجر الأسود هو موضع بداية الطواف ونهايته.',
    story:
        'الحجر الأسود في ركن الكعبة، وهو بداية الطواف ونهايته. أما الحِجر فهو محاط بجدار على هيئة نصف دائرة، وتذكر المادة المرجعية أن جزءًا منه من الكعبة الأصلية.',
    significance:
        'استلام الحجر الأسود اتباع لسنة النبي ﷺ عند التيسر دون إيذاء الناس.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'الحجر الأسود',
        description:
            'استلامه أو تقبيله إن تيسر دون أذى، وإلا الإشارة إليه مع التكبير.',
      ),
      ZiyaratVisitorGuidance(
        title: 'الحِجر',
        description:
            'الصلاة في الحِجر إن تيسر دون مزاحمة.',
      ),
    ],
    warnings: [
      'عدم التزاحم الشديد للوصول إلى الحجر الأسود.',
      'الحجر لا يضر ولا ينفع بذاته.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text:
            'قال عمر رضي الله عنه: «إني أعلم أنك حجر لا تضر ولا تنفع، ولولا أني رأيت النبي ﷺ يقبّلك ما قبّلتك».',
        source: 'متفق عليه',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'thawr',
    name: 'جبل ثور وغار الهجرة',
    city: ZiyaratCity.makkah,
    category: ZiyaratCategory.mountain,
    icon: '🌄',
    shortDescription:
        'المكان المرتبط بهجرة النبي ﷺ وأبي بكر الصديق رضي الله عنه.',
    story:
        'اختبأ النبي ﷺ وأبو بكر الصديق رضي الله عنه في غار ثور ثلاث ليال أثناء الهجرة، وتذكر المادة المرجعية قول النبي ﷺ لأبي بكر: ما ظنك باثنين الله ثالثهما؟',
    significance:
        'يذكّر المكان بأحداث الهجرة ومعاني التوكل على الله والصحبة والثبات.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'قصة الهجرة',
        description:
            'التعرف على أحداث الهجرة والتأمل في معانيها.',
      ),
    ],
    warnings: [
      'ليس صعود غار ثور من مناسك الحج أو العمرة.',
      'لا يُشرع قصد الغار بصلاة مخصوصة وفق المادة المرجعية.',
      'الصعود شاق ويحتاج مراعاة الحالة الصحية والطقس.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.quran,
        text:
            '﴿إِذْ يَقُولُ لِصَاحِبِهِ لَا تَحْزَنْ إِنَّ اللَّهَ مَعَنَا﴾',
        source: 'القرآن الكريم',
        reference: 'التوبة: 40',
      ),
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text:
            'وردت قصة وجود النبي ﷺ وأبي بكر رضي الله عنه في الغار أثناء الهجرة.',
        source: 'متفق عليه',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'taneem',
    name: 'مسجد التنعيم – مسجد عائشة',
    city: ZiyaratCity.makkah,
    category: ZiyaratCategory.mosque,
    icon: '🕌',
    shortDescription:
        'موضع من الحِلّ قريب من مكة ارتبط بإحرام عائشة رضي الله عنها للعمرة.',
    story:
        'اعتمرت عائشة رضي الله عنها من التنعيم بأمر النبي ﷺ بعد حجة الوداع، فاشتهر الموضع لمن كان في مكة وأراد الإحرام بعمرة من الحِلّ.',
    significance:
        'يرتبط المكان بقصة إحرام عائشة رضي الله عنها للعمرة من التنعيم.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'الإحرام',
        description:
            'من أراد العمرة وهو داخل مكة يخرج إلى الحِلّ للإحرام وفق أحكام النسك.',
      ),
      ZiyaratVisitorGuidance(
        title: 'التلبية',
        description:
            'ثم يبدأ التلبية ويتوجه لأداء العمرة.',
      ),
    ],
    warnings: [
      'تفاصيل أحكام الإحرام تعرض في قسم العمرة الموثق داخل التطبيق.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text:
            'قال النبي ﷺ لعبد الرحمن بن أبي بكر: «أردف أختك عائشة فأعمرها من التنعيم».',
        source: 'متفق عليه',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'arafat',
    name: 'عرفات وجبل الرحمة',
    city: ZiyaratCity.makkah,
    category: ZiyaratCategory.hajjSite,
    icon: '⛰️',
    shortDescription:
        'المشعر الذي يقع فيه ركن الوقوف بعرفة في يوم التاسع من ذي الحجة.',
    story:
        'وقف النبي ﷺ بعرفة في حجة الوداع وخطب بالناس، وتذكر المادة المرجعية قوله إن عرفة كلها موقف.',
    significance:
        'الوقوف بعرفة ركن الحج الأعظم.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'أثناء الحج',
        description:
            'الوقوف بعرفة في وقته الشرعي وفق دليل الحج.',
      ),
      ZiyaratVisitorGuidance(
        title: 'الدعاء',
        description:
            'الإكثار من الدعاء والذكر والتضرع إلى الله.',
      ),
    ],
    warnings: [
      'لا فضل خاص للصعود على جبل الرحمة؛ عرفة كلها موقف وفق المادة المرجعية.',
      'تفاصيل أحكام الوقوف تُعرض في قسم الحج الموثق.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text: '«الحج عرفة»',
        source: 'رواه أحمد وأصحاب السنن – وفق المادة المرجعية',
      ),
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text:
            '«ما من يوم أكثر من أن يعتق الله فيه عبدًا من النار من يوم عرفة»',
        source: 'صحيح مسلم',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'namirah',
    name: 'مسجد نمرة',
    city: ZiyaratCity.makkah,
    category: ZiyaratCategory.mosque,
    icon: '🕌',
    shortDescription:
        'مسجد يرتبط بأحداث يوم عرفة وخطبة حجة الوداع.',
    story:
        'تذكر المادة المرجعية أن النبي ﷺ نزل بنمرة حتى زالت الشمس، ثم خطب وصلى الظهر والعصر قبل الوقوف بعرفة.',
    significance:
        'يرتبط المسجد بأحداث حجة النبي ﷺ ويوم عرفة.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'أثناء الحج',
        description:
            'اتباع إرشادات الحج الرسمية ودليل النسك.',
      ),
      ZiyaratVisitorGuidance(
        title: 'حدود عرفة',
        description:
            'التأكد من دخول حدود عرفة عند أداء الوقوف.',
      ),
    ],
    warnings: [
      'تذكر المادة المرجعية أن جزءًا من المسجد خارج حدود عرفة.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text:
            '«فضُربت له قبة بنمرة، فنزل بها حتى إذا زالت الشمس...»',
        source: 'حديث جابر – صحيح مسلم',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'muzdalifah',
    name: 'مزدلفة والمشعر الحرام',
    city: ZiyaratCity.makkah,
    category: ZiyaratCategory.hajjSite,
    icon: '🌌',
    shortDescription:
        'من مشاعر الحج، ويتوجه إليها الحجاج بعد الإفاضة من عرفات.',
    story:
        'بعد غروب شمس عرفة دفع النبي ﷺ إلى مزدلفة، فصلى وبات بها، ثم ذكر الله ودعا عند المشعر الحرام وفق المادة المرجعية.',
    significance:
        'ذكر المشعر الحرام في القرآن، وترتبط مزدلفة بأعمال الحج.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'النسك',
        description:
            'اتباع خطوات المبيت والذكر من دليل الحج داخل التطبيق.',
      ),
      ZiyaratVisitorGuidance(
        title: 'التنظيم',
        description:
            'اتباع تعليمات الجهات المنظمة للحشود.',
      ),
    ],
    warnings: [
      'تفاصيل أحكام المبيت والرخص تُراجع في دليل الحج الموثق.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.quran,
        text:
            '﴿فَإِذَا أَفَضْتُمْ مِنْ عَرَفَاتٍ فَاذْكُرُوا اللَّهَ عِنْدَ الْمَشْعَرِ الْحَرَامِ﴾',
        source: 'القرآن الكريم',
        reference: 'البقرة: 198',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'mina',
    name: 'منى',
    city: ZiyaratCity.makkah,
    category: ZiyaratCategory.hajjSite,
    icon: '⛺',
    shortDescription:
        'من مشاعر الحج وتقام فيها أعمال من يوم النحر وأيام التشريق.',
    story:
        'نزل النبي ﷺ منى في الحج، وترتبط بها أعمال يوم النحر وأيام التشريق.',
    significance:
        'منى مشعر من مشاعر الحج وتقام فيها أعمال أساسية من النسك.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'مناسك الحج',
        description:
            'اتباع خطوات النسك الخاصة بمنى من دليل الحج.',
      ),
      ZiyaratVisitorGuidance(
        title: 'ذكر الله',
        description:
            'الإكثار من ذكر الله في أيام التشريق.',
      ),
    ],
    warnings: [
      'أحكام المبيت والرمي والهدي لها تفاصيل تعرض في قسم الحج.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.quran,
        text:
            '﴿وَاذْكُرُوا اللَّهَ فِي أَيَّامٍ مَعْدُودَاتٍ﴾',
        source: 'القرآن الكريم',
        reference: 'البقرة: 203',
      ),
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text: '«أيام أكل وشرب وذكر لله»',
        source: 'صحيح مسلم – وفق المادة المرجعية',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'jamarat',
    name: 'الجمرات الثلاث',
    city: ZiyaratCity.makkah,
    category: ZiyaratCategory.hajjSite,
    icon: '🪨',
    shortDescription:
        'موقع أداء رمي الجمرات ضمن مناسك الحج.',
    story:
        'يرمي الحاج الجمرات في أوقاتها المحددة ضمن أعمال الحج، اقتداءً بهدي النبي ﷺ.',
    significance:
        'الرمي عبادة وطاعة لله وذكر له.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'الرمي',
        description:
            'اتباع ترتيب وعدد وأوقات الرمي كما هو موضح في دليل الحج.',
      ),
      ZiyaratVisitorGuidance(
        title: 'الرفق',
        description:
            'الرفق بالناس والالتزام بتعليمات التفويج.',
      ),
    ],
    warnings: [
      'لا تعتمد صفحة المزار وحدها لأحكام الرمي؛ راجع قسم الحج.',
      'السلامة وتعليمات الجهات الرسمية لها الأولوية.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text:
            '«إنما جُعل رمي الجمار والسعي بين الصفا والمروة لإقامة ذكر الله»',
        source: 'أبو داود والترمذي – وفق المادة المرجعية',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  // ============================================================
  // MADINAH
  // ============================================================

  ZiyaratPlace(
    id: 'prophets_mosque_rawdah',
    name: 'المسجد النبوي والروضة الشريفة',
    city: ZiyaratCity.madinah,
    category: ZiyaratCategory.mosque,
    icon: '🕌',
    shortDescription:
        'مسجد النبي ﷺ، وفيه الروضة الشريفة.',
    story:
      'بعد الهجرة، بنى النبي ﷺ المسجد مع أصحابه، فصار قلب المجتمع الجديد: موضعًا للصلاة والتعلّم ولقاء المهاجرين والأنصار. لم تكن جدرانه وحدها ما صنع أثره؛ بل القلوب التي اجتمعت فيه، ومنه انطلقت ملامح حياة المدينة.',
    significance:
        'ورد في السنة فضل الصلاة في المسجد النبوي، كما ورد الحديث في فضل الروضة.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'الصلاة',
        description:
            'الصلاة في المسجد والمحافظة على السكينة.',
      ),
      ZiyaratVisitorGuidance(
        title: 'الروضة',
        description:
            'الصلاة في الروضة إن تيسر وفق التنظيم الرسمي ودون مزاحمة.',
      ),
      ZiyaratVisitorGuidance(
        title: 'السلام',
        description:
            'السلام على النبي ﷺ وصاحبيه بأدب وصوت منخفض.',
      ),
    ],
    warnings: [
      'عدم مزاحمة أو إيذاء الآخرين.',
      'لا يُطاف بالقبر.',
      'لا يُدعى غير الله.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text:
            '«ما بين بيتي ومنبري روضة من رياض الجنة»',
        source: 'متفق عليه',
      ),
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text:
            'ورد في المادة المرجعية فضل الصلاة في المسجد النبوي على الصلاة فيما سواه إلا المسجد الحرام.',
        source: 'متفق عليه',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'quba',
    name: 'مسجد قباء',
    city: ZiyaratCity.madinah,
    category: ZiyaratCategory.mosque,
    icon: '🌴',
    shortDescription:
        'مسجد تاريخي ارتبط ببدايات الهجرة النبوية إلى المدينة.',
    story:
      'في طريق الهجرة، نزل النبي ﷺ بقباء، وارتبط المكان ببداية مسجد قباء الذي تصفه المادة المرجعية بأنه أول مسجد بُني في الإسلام. بعد مشقة الطريق، كان تأسيس موضع للصلاة بدايةً لمرحلة جديدة، وكان النبي ﷺ يأتي المسجد ويزوره.',
    significance:
        'ورد في المادة المرجعية فضل التطهر ثم إتيان مسجد قباء والصلاة فيه.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'الوضوء',
        description:
            'التطهر في مكان الإقامة قبل الذهاب وفق ما ورد في الحديث المذكور بالمادة.',
      ),
      ZiyaratVisitorGuidance(
        title: 'الصلاة',
        description:
            'الصلاة في المسجد.',
      ),
      ZiyaratVisitorGuidance(
        title: 'السيرة',
        description:
            'التأمل في بدايات الهجرة وبناء مجتمع المدينة.',
      ),
    ],
    warnings: [
      'عدم تخصيص أعمال أخرى للمكان دون دليل.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.quran,
        text:
            '﴿لَمَسْجِدٌ أُسِّسَ عَلَى التَّقْوَى مِنْ أَوَّلِ يَوْمٍ أَحَقُّ أَنْ تَقُومَ فِيهِ﴾',
        source: 'القرآن الكريم',
        reference: 'التوبة: 108',
        note:
            'الإسناد التفسيري للآية إلى الموضع يحتاج مراجعة المحتوى النهائية.',
      ),
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text:
            'ورد أن النبي ﷺ كان يأتي مسجد قباء كل سبت ماشيًا وراكبًا.',
        source: 'متفق عليه – وفق المادة المرجعية',
      ),
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text:
            '«من تطهّر في بيته ثم أتى مسجد قباء فصلّى فيه صلاة كان له كأجر عمرة»',
        source: 'رواه ابن ماجه – وفق المادة المرجعية',
        note:
            'يحتاج توثيق الدرجة واللفظ النهائي قبل Production.',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'uhud',
    name: 'جبل أُحد وشهداؤه',
    city: ZiyaratCity.madinah,
    category: ZiyaratCategory.mountain,
    icon: '🏔️',
    shortDescription:
        'موقع مرتبط بغزوة أُحد وأحداث مهمة من السيرة النبوية.',
    story:
      'عند أُحد وقعت الغزوة في السنة الثالثة للهجرة، وفقد المسلمون عددًا من الصحابة، منهم حمزة بن عبد المطلب رضي الله عنه. يجتمع في ذكرى المكان ألم الفقد ودروس الصبر والطاعة، وتبقى محبة النبي ﷺ لأُحد حاضرة في قوله: «أُحُد جبل يحبنا ونحبه».',
    significance:
        'ترتبط بالمكان دروس من السيرة في الصبر والطاعة وعاقبة التنازع.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'السلام',
        description:
            'السلام على الشهداء والدعاء لهم.',
      ),
      ZiyaratVisitorGuidance(
        title: 'الاعتبار',
        description:
            'التعرف على أحداث الغزوة والتأمل في دروسها.',
      ),
    ],
    warnings: [
      'عدم التبرك بالتراب أو الحجارة.',
      'عدم طلب الحاجات من الموتى.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text: '«أُحُد جبل يحبنا ونحبه»',
        source: 'صحيح البخاري',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'qiblatain',
    name: 'مسجد القبلتين',
    city: ZiyaratCity.madinah,
    category: ZiyaratCategory.mosque,
    icon: '🧭',
    shortDescription:
        'مسجد مشهور في المدينة مرتبط في المادة المرجعية بقصة تحويل القبلة.',
    story:
        'ترتبط شهرة المسجد بقصة تحويل القبلة من بيت المقدس إلى الكعبة واستجابة المسلمين لأمر الله.',
    significance:
        'يذكّر المكان بحادثة تحويل القبلة والطاعة والاستجابة لأمر الله.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'الصلاة',
        description:
            'الصلاة في المسجد كغيره من المساجد.',
      ),
      ZiyaratVisitorGuidance(
        title: 'القصة',
        description:
            'التعرف على قصة تحويل القبلة والتأمل في معانيها.',
      ),
    ],
    warnings: [
      'لا نضيف فضلًا مخصوصًا لزيارة المسجد دون دليل موثق.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.quran,
        text:
            '﴿فَوَلِّ وَجْهَكَ شَطْرَ الْمَسْجِدِ الْحَرَامِ﴾',
        source: 'القرآن الكريم',
        reference: 'البقرة: 144',
      ),
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.history,
        text:
            'ربط المسجد الحالي بحادثة تحويل القبلة وارد في المادة المرجعية المقدمة للمشروع.',
        source: 'Prototype المزارات',
        note:
            'يحتاج الربط التاريخي الدقيق مراجعة مستقلة قبل النشر.',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'baqi',
    name: 'البقيع',
    city: ZiyaratCity.madinah,
    category: ZiyaratCategory.historical,
    icon: '🌿',
    shortDescription:
        'مقبرة تاريخية في المدينة دُفن فيها عدد كبير من الصحابة وأهل المدينة.',
    story:
        'تذكر المادة المرجعية أن النبي ﷺ كان يخرج إلى البقيع ويدعو لأهله، وأن عددًا كبيرًا من الصحابة دُفنوا فيه.',
    significance:
        'زيارة القبور تذكّر بالآخرة، ويُدعى فيها للموتى.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'السلام',
        description:
            'السلام على أهل القبور والدعاء لهم.',
      ),
      ZiyaratVisitorGuidance(
        title: 'الاعتبار',
        description:
            'تذكر الآخرة والاتعاظ.',
      ),
    ],
    warnings: [
      'عدم التبرك بالتراب أو القبور.',
      'عدم طلب الحاجات من الأموات.',
      'عدم الطواف بالقبور.',
      'الالتزام بتعليمات الزيارة الرسمية.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text:
            '«السلام عليكم دار قوم مؤمنين، وإنا إن شاء الله بكم لاحقون»',
        source: 'صحيح مسلم – وفق المادة المرجعية',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),

  ZiyaratPlace(
    id: 'bir_rumah',
    name: 'بئر رومة',
    city: ZiyaratCity.madinah,
    category: ZiyaratCategory.well,
    icon: '💧',
    shortDescription:
        'بئر تاريخية ترتبط بقصة وقف عثمان بن عفان رضي الله عنه.',
    story:
        'تذكر المادة المرجعية أن بئر رومة كان يُباع ماؤها، فاشتراها عثمان بن عفان رضي الله عنه وجعلها للمسلمين.',
    significance:
        'تُذكر قصتها مثالًا على الصدقة الجارية والوقف النافع.',
    visitorGuidance: [
      ZiyaratVisitorGuidance(
        title: 'قصة الوقف',
        description:
            'التعرف على قصة عثمان رضي الله عنه وأثر الوقف.',
      ),
      ZiyaratVisitorGuidance(
        title: 'الاعتبار',
        description:
            'التفكر في أثر الصدقة الجارية.',
      ),
      ZiyaratVisitorGuidance(
        title: 'الدعاء',
        description:
            'الدعاء لعثمان رضي الله عنه.',
      ),
    ],
    warnings: [
      'لا نعرض عبادة مخصوصة مرتبطة بالبئر دون دليل.',
    ],
    evidence: [
      ZiyaratEvidence(
        type: ZiyaratEvidenceType.hadith,
        text:
            '«من يشتري بئر رومة فيكون دلوه كدلاء المسلمين؟»',
        source:
            'الترمذي والنسائي – وفق المادة المرجعية',
        note:
            'يحتاج اللفظ والتخريج والدرجة إلى مراجعة نهائية قبل Production.',
      ),
    ],
    verificationStatus: ZiyaratVerificationStatus.needsReview,
  ),
];