/// Curated offline replies for Ask Rifqa.
/// These are general guides, NOT fatwas or live location results.
/// Religious entries need qualified editorial review before public release.
class RifqaKnowledgeItem {
  const RifqaKnowledgeItem({
    required this.id,
    required this.questions,
    required this.answer,
    required this.category,
    this.requiresReview = false,
  });

  final String id;
  final List<String> questions;
  final String answer;
  final String category;
  final bool requiresReview;
}

class RifqaKnowledge {
  RifqaKnowledge._();

  static const items = <RifqaKnowledgeItem>[
    RifqaKnowledgeItem(
      id: 'lost',
      category: 'safety',
      questions: [
        'انا تايه',
        'انا تايهة',
        'انا تائه',
        'انا تائهة',
        'انا ضايع',
        'انا ضايعة',
        'تهت',
        'مش لاقية اصحابي'
      ],
      answer:
          'لو إنت تائه، قف في مكان آمن وواضح بعيد عن الزحام واطلب مساعدة موظف أو رجل أمن. افتح زر «أنا تائه» في رفقة، واختار مشاركة موقعك مع مجموعتك بعد التأكيد. التطبيق لا يرسل أي استغاثة تلقائيًا.',
    ),
    RifqaKnowledgeItem(
      id: 'group_share',
      category: 'app',
      questions: [
        'ازاي ابعت موقعي',
        'مشاركة موقعي مع الجروب',
        'ازاي اشارك موقعي',
        'ازاي اشارك موقعي مع المجموعة'
      ],
      answer:
          'افتح «رفقتي»، واختار مجموعتك، واضغط «موقعي» لإرسال موقع ثابت. للمشاركة المباشرة اضغط «مشاركة مباشرة» وحدد المدة. لازم تسمح للتطبيق باستخدام الموقع، وتقدر توقف المشاركة وقت ما تحب.',
    ),
    RifqaKnowledgeItem(
      id: 'groups',
      category: 'app',
      questions: [
        'ازاي اعمل جروب',
        'ازاي انشئ مجموعة',
        'كيفية انشاء مجموعة',
        'ازاي انضم لمجموعة'
      ],
      answer:
          'من تبويب «رفقتي» تقدر تنشئ مجموعة جديدة، أو تختار «انضم بكود». لو معاك كود دعوة، اكتب الكود واستنى موافقة مشرف المجموعة.',
    ),
    RifqaKnowledgeItem(
      id: 'friend',
      category: 'app',
      questions: ['ازاي اضيف صديق', 'ازاي ابعت طلب صداقة', 'ازاي اكلم صاحبي'],
      answer:
          'ادخل قسم الأصدقاء في «رفقتي»، شارك كود صداقتك أو أدخل كود الشخص الآخر. بعد قبول طلب الصداقة، افتح المحادثة الخاصة من قائمة الأصدقاء.',
    ),
    RifqaKnowledgeItem(
      id: 'toilets',
      category: 'maps',
      questions: [
        'فين اقرب حمام',
        'فين اقرب دورة مياه',
        'اين اقرب دورة مياه',
        'اقرب حمام',
        'اقرب دورة مياه'
      ],
      answer:
          'افتح خريطة رفقة، واختار تصنيف «دورات المياه». تحديد الأقرب بدقة يحتاج موقعك الفعلي وبيانات مكان موثوقة؛ مش هحدد مكانًا من غير التحقق من الخريطة.',
    ),
    RifqaKnowledgeItem(
      id: 'water',
      category: 'maps',
      questions: ['فين مياه زمزم', 'فين اقرب مياه', 'اين الماء', 'اين زمزم'],
      answer:
          'افتح خريطة الحرم واختار تصنيف المياه أو زمزم إن كان متاحًا. تأكد من العلامات الإرشادية في الموقع، لأن أماكن الخدمات قد تتغير.',
    ),
    RifqaKnowledgeItem(
      id: 'gate',
      category: 'maps',
      questions: ['فين بابي', 'فين بوابتي', 'عايز ارجع للبوابة', 'اين بابي'],
      answer:
          'لو حفظت باب الدخول داخل خريطة رفقة، افتح الخريطة واختر «بابي». لو مفيش باب محفوظ، اسأل أحد موظفي الإرشاد عن البوابة الصحيحة.',
    ),
    RifqaKnowledgeItem(
      id: 'hotel',
      category: 'maps',
      questions: ['فين الفندق', 'ازاي ارجع الفندق', 'اين فندقي'],
      answer:
          'لو عنوان الفندق محفوظ في بيانات الرحلة، استخدمه لفتح تطبيق الخرائط. لو مش محفوظ، ارجع لكارت الفندق أو تواصل مع مرافقك. ما تعتمدش على اتجاهات غير مؤكدة.',
    ),
    RifqaKnowledgeItem(
      id: 'accessible',
      category: 'maps',
      questions: [
        'محتاج كرسي متحرك',
        'فين مصعد',
        'طريق مناسب للكرسي المتحرك',
        'فين اقرب مصعد'
      ],
      answer:
          'في خريطة الحرم ابحث عن تصنيفات المصاعد والخدمات الميسّرة. لا تعتمد على مسار للكرسي المتحرك إلا لو موثّق أنه مناسب، واستعن بموظفي الموقع عند الحاجة.',
    ),
    RifqaKnowledgeItem(
      id: 'medical',
      category: 'safety',
      questions: [
        'محتاج اسعاف',
        'محتاج مساعدة طبية',
        'في حالة طوارئ صحية اعمل ايه'
      ],
      answer:
          'لو في حالة طبية طارئة اطلب مساعدة الطوارئ المحلية أو أقرب نقطة إسعاف فورًا، واطلب مساعدة رجال الأمن أو الموظفين. رفقة لا تشخّص الأمراض ولا تضمن وصول الإسعاف.',
    ),
    RifqaKnowledgeItem(
      id: 'umrah_overview',
      category: 'rituals',
      requiresReview: true,
      questions: [
        'ايه خطوات العمرة',
        'ما هي خطوات العمرة',
        'خطوات العمرة',
        'ازاي اعمل عمرة'
      ],
      answer:
          'خطوات العمرة باختصار: 1. الإحرام من الميقات والنية والتلبية. 2. الطواف بالكعبة سبعة أشواط. 3. السعي بين الصفا والمروة سبعة أشواط. 4. الحلق أو التقصير. راجع دليلًا رسميًا أو مرشد حملتك للتفاصيل والأحكام الخاصة بحالتك.',
    ),
    RifqaKnowledgeItem(
      id: 'ihram',
      category: 'rituals',
      requiresReview: true,
      questions: ['يعني ايه احرام', 'ايه هو الاحرام', 'كيف احرم للعمرة'],
      answer:
          'الإحرام هو الدخول في النسك بالنية، وله أحكام تتعلق بالميقات ومحظورات الإحرام. قبل السفر راجع دليل مناسك موثوقًا، واسأل مرشد حملتك عن تفاصيل حالتك.',
    ),
    RifqaKnowledgeItem(
      id: 'tawaf',
      category: 'rituals',
      requiresReview: true,
      questions: ['يعني ايه الطواف', 'كم شوط في الطواف', 'عدد اشواط الطواف'],
      answer:
          'الطواف في العمرة سبعة أشواط حول الكعبة. اتبع إرشادات تنظيم الحشود داخل الحرم، وراجع المرشد المختص فيما يتعلق بالأحكام أو الحالات الخاصة.',
    ),
    RifqaKnowledgeItem(
      id: 'sai',
      category: 'rituals',
      requiresReview: true,
      questions: ['كم شوط في السعي', 'عدد اشواط السعي', 'ايه هو السعي'],
      answer:
          'السعي في العمرة سبعة أشواط بين الصفا والمروة؛ الذهاب من الصفا إلى المروة شوط، والرجوع شوط آخر. اسأل مرشدًا مؤهلًا عن الأحكام المتعلقة بحالتك.',
    ),
    RifqaKnowledgeItem(
      id: 'fatwa',
      category: 'rituals',
      questions: ['عايز فتوى', 'عندي سؤال فقهي خاص', 'نسيت شوط اعمل ايه'],
      answer:
          'الأسئلة الفقهية الخاصة ممكن تختلف حسب تفاصيل الحالة. الأفضل مراجعة جهة إفتاء معتمدة أو مرشد حملة مؤهل، بدل الاعتماد على إجابة آلية.',
    ),
  ];

  static String normalize(String text) => text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll(RegExp(r'[^\u0621-\u064A0-9a-z ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  /// Exact semantic templates only: fuzzy substring rules are intentionally
  /// avoided so negated or compound questions don't get an unsafe canned reply.
  static RifqaKnowledgeItem? find(String question) {
    final query = normalize(question);
    if (query.isEmpty) return null;
    for (final entry in items) {
      for (final phrase in entry.questions) {
        if (query == normalize(phrase)) return entry;
      }
    }
    return null;
  }

  static Iterable<String> get suggestions sync* {
    for (final entry in items) {
      yield entry.questions.first;
    }
  }
}
