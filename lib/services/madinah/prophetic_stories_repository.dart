import '../../models/madinah/prophetic_story.dart';

class PropheticStoriesRepository {
  final List<PropheticStory> _stories = const [
    PropheticStory(
      id: 'palm_trunk',
      title: 'حين حنَّ الجذع إليه ﷺ',
      subtitle: 'موقف صحيح من مسجد رسول الله ﷺ',
      category: PropheticStoryCategory.prophetMosque,
      contentType: PropheticStoryContentType.hadith,
      narrativeText:
          'كان المنبر قد صُنع، وانتقل النبي ﷺ إليه بعد أن كان يخطب عند جذع نخلة. وتروي السنة الصحيحة أن الجذع حنَّ، فأتاه النبي ﷺ ومسح عليه.',
      authenticText: 'فحنَّ الجذع، فأتاه فمسح يده عليه.',
      sourceName: 'صحيح البخاري',
      sourceReference: 'حديث 3583',
      sourceUrl: 'https://sunnah.com/bukhari:3583',
      editorialNote:
          'المقدمة صياغة تحريرية من رِفقة؛ النص المقتبس والمصدر معروضان منفصلين.',
      scenes: [
        PropheticStoryScene(
          id: 'palm_1',
          type: PropheticStorySceneType.opening,
          text: 'تخيّلي مكانًا شهد صوت النبي ﷺ وهو يخطب...',
          calm: true,
        ),
        PropheticStoryScene(
          id: 'palm_2',
          type: PropheticStorySceneType.narrative,
          text:
              'حين صُنع المنبر وانتقل إليه النبي ﷺ، حفظت لنا الرواية الصحيحة موقفًا مؤثرًا مع جذع النخلة الذي كان يخطب عنده.',
        ),
        PropheticStoryScene(
          id: 'palm_3',
          type: PropheticStorySceneType.authenticText,
          title: 'النص الموثق',
          text: 'فحنَّ الجذع، فأتاه فمسح يده عليه.',
          calm: true,
        ),
        PropheticStoryScene(
          id: 'palm_4',
          type: PropheticStorySceneType.reflection,
          text:
              'وقفة رِفقة: لا ننسب مشاعر أو حوارًا لم يرد في الرواية؛ نكتفي بما ثبت، ونترك للقلب أثره.',
        ),
      ],
      suggestedValues: ['المحبة', 'الرفق', 'الوفاء'],
      reflectionQuestion: 'ما المعنى الذي تريدين أن يبقى معك من هذا الموقف؟',
      readingMinutes: 2,
      relatedToMadinah: true,
      relatedToProphetMosque: true,
      priority: 10,
      reviewStatus: PropheticStoryReviewStatus.approved,
    ),
    PropheticStory(
      id: 'rawdah_hadith',
      title: 'روضة من رياض الجنة',
      subtitle: 'حديث صحيح في فضل موضع الروضة',
      category: PropheticStoryCategory.madinah,
      contentType: PropheticStoryContentType.hadith,
      narrativeText:
          'قبل أن تتحول الزيارة إلى قائمة مهام، تذكّري أن فضل هذا الموضع جاء في حديث صحيح. رِفقة يعرض النص كما ورد، ثم يختفي ليترك لكِ اللحظة.',
      authenticText: 'ما بين بيتي ومنبري روضة من رياض الجنة.',
      sourceName: 'صحيح البخاري',
      sourceReference: 'حديث 1888',
      sourceUrl: 'https://sunnah.com/bukhari/29/22',
      editorialNote:
          'أي كلام وجداني حول الحديث هو صياغة تحريرية من رِفقة وليس جزءًا من الحديث.',
      scenes: [
        PropheticStoryScene(
          id: 'rawdah_1',
          type: PropheticStorySceneType.opening,
          text: 'هذه المرة لا تحتاجين شاشة مزدحمة.',
          calm: true,
        ),
        PropheticStoryScene(
          id: 'rawdah_2',
          type: PropheticStorySceneType.authenticText,
          title: 'قال رسول الله ﷺ',
          text: 'ما بين بيتي ومنبري روضة من رياض الجنة.',
          calm: true,
        ),
        PropheticStoryScene(
          id: 'rawdah_3',
          type: PropheticStorySceneType.takeaway,
          text:
              'خذي من التطبيق ما يساعدك على الاستعداد، ثم اتركي الهاتف جانبًا عند حضور اللحظة.',
        ),
      ],
      suggestedValues: ['السكينة', 'الحضور', 'الرفق'],
      reflectionQuestion: 'كيف تريدين أن تدخلي هذه اللحظة بقلبك؟',
      readingMinutes: 1,
      relatedToMadinah: true,
      relatedToProphetMosque: true,
      priority: 9,
      reviewStatus: PropheticStoryReviewStatus.approved,
    ),

    // ──────────────────────────────────────────────────
    // الإضافات التالية (3 حكايات) أحاديث صحيحة تم التحقق من
    // نصها ورقمها ورابطها على sunnah.com مباشرة قبل إضافتها.
    // reviewStatus موضوعة approved بناءً على هذا التحقق، لكن
    // يُستحسن مراجعتها بأنفسكم مرة أخيرة قبل اعتمادها نهائيًا،
    // اتساقًا مع سياسة المراجعة التي بنيتِها لهذا المحتوى.
    // ──────────────────────────────────────────────────

    PropheticStory(
      id: 'mosque_sweeper',
      title: 'من كان يَقُمُّ المسجد ﷺ',
      subtitle: 'موقف صحيح في رعاية النبي ﷺ لمن لا يلتفت إليه الناس',
      category: PropheticStoryCategory.prophetMosque,
      contentType: PropheticStoryContentType.hadith,
      narrativeText:
          'في مسجد رسول الله ﷺ، كان هناك من يتولى كنسه وتنظيفه دون أن يلتفت إليه كثيرون. وحين غاب هذا الشخص أيامًا، كان رد فعل النبي ﷺ درسًا في الرحمة بمن لا يراهم الناس.',
      authenticText: 'أفلا آذنتموني به؟ دُلُّوني على قبره.',
      sourceName: 'صحيح البخاري',
      sourceReference: 'حديث 458',
      sourceUrl: 'https://sunnah.com/bukhari:458',
      editorialNote:
          'المقدمة صياغة تحريرية من رِفقة؛ النص المقتبس والمصدر معروضان منفصلين.',
      scenes: [
        PropheticStoryScene(
          id: 'sweep_1',
          type: PropheticStorySceneType.opening,
          text: 'تخيّلي من يخدم بيت الله كل يوم، دون أن يعرف أحدٌ اسمه...',
          calm: true,
        ),
        PropheticStoryScene(
          id: 'sweep_2',
          type: PropheticStorySceneType.narrative,
          text:
              'كان رجل أو امرأة يتولى كنس المسجد النبوي، فغاب يومًا عن النبي ﷺ، فسأل عنه. فقيل له: مات. فعاتبهم برفق على كتمان الخبر عنه.',
        ),
        PropheticStoryScene(
          id: 'sweep_3',
          type: PropheticStorySceneType.authenticText,
          title: 'قال رسول الله ﷺ',
          text: 'أفلا آذنتموني به؟ دُلُّوني على قبره.',
          calm: true,
        ),
        PropheticStoryScene(
          id: 'sweep_4',
          type: PropheticStorySceneType.reflection,
          text:
              'ثم ذهب ﷺ إلى قبره فصلّى عليه؛ فما كان أحدٌ في نظره صغيرًا لدرجة أن يُنسى.',
        ),
      ],
      suggestedValues: ['الرحمة', 'الوفاء', 'الالتفات لمن لا يُرى'],
      reflectionQuestion:
          'من حولك يقوم بعمل هادئ لا يلتفت إليه أحد، فهل تذكرينه اليوم بكلمة؟',
      readingMinutes: 2,
      relatedToMadinah: true,
      relatedToProphetMosque: true,
      priority: 7,
      reviewStatus: PropheticStoryReviewStatus.approved,
    ),

    PropheticStory(
      id: 'bedouin_gentleness',
      title: 'حين اختار النبي ﷺ الرفق',
      subtitle: 'موقف صحيح من مسجد النبي ﷺ',
      category: PropheticStoryCategory.prophetMosque,
      contentType: PropheticStoryContentType.hadith,
      narrativeText:
          'لم يكن يعرف بعد آداب المكان، ولم يمهله أحد ليتعلّم. وفي اللحظة التي استحقت فيها الأمر غضبًا، اختار النبي ﷺ أن يعلّم أمته الرفق أولًا.',
      authenticText:
          'دعوه، وهريقوا على بوله سجلًا من ماء، فإنما بُعثتم ميسِّرين، ولم تُبعثوا معسِّرين.',
      sourceName: 'صحيح البخاري',
      sourceReference: 'حديث 220',
      sourceUrl: 'https://sunnah.com/bukhari:220',
      editorialNote:
          'المقدمة صياغة تحريرية من رِفقة؛ النص المقتبس والمصدر معروضان منفصلين.',
      scenes: [
        PropheticStoryScene(
          id: 'bedouin_1',
          type: PropheticStorySceneType.opening,
          text: 'بدويٌّ جاء المدينة حديثًا، ولم يعرف بعد آداب المسجد...',
          calm: true,
        ),
        PropheticStoryScene(
          id: 'bedouin_2',
          type: PropheticStorySceneType.narrative,
          text:
              'قام أعرابي فبال في طائفة من المسجد، فهمّ به الناس غاضبين. فأوقفهم النبي ﷺ عنه، وطلب أن يُراق على الموضع ماء فحسب.',
        ),
        PropheticStoryScene(
          id: 'bedouin_3',
          type: PropheticStorySceneType.authenticText,
          title: 'قال رسول الله ﷺ',
          text:
              'دعوه، وهريقوا على بوله سجلًا من ماء، فإنما بُعثتم ميسِّرين، ولم تُبعثوا معسِّرين.',
          calm: true,
        ),
        PropheticStoryScene(
          id: 'bedouin_4',
          type: PropheticStorySceneType.reflection,
          text:
              'لم يرفع صوته، ولم يُخجل الرجل أمام الناس؛ بل علّم أمته الرفق في اللحظة ذاتها التي استحقت غضبًا.',
        ),
      ],
      suggestedValues: ['الرفق', 'الحلم', 'التيسير على الناس'],
      reflectionQuestion:
          'ما الموقف الذي تحتاجين فيه اليوم أن تختاري الرفق بدل الغضب؟',
      readingMinutes: 2,
      relatedToMadinah: true,
      relatedToProphetMosque: true,
      priority: 8,
      reviewStatus: PropheticStoryReviewStatus.approved,
    ),

    PropheticStory(
      id: 'ramadan_night_prayer',
      title: 'ليلة لم يخرج فيها النبي ﷺ',
      subtitle: 'حديث صحيح في رحمة النبي ﷺ بأمته',
      category: PropheticStoryCategory.prophetMosque,
      contentType: PropheticStoryContentType.hadith,
      narrativeText:
          'ليلة في رمضان، صلّى النبي ﷺ في المسجد، فاقتدى به من حوله. وليلة بعد ليلة، كثر من صلّى خلفه، حتى امتلأ المسجد بهم.',
      authenticText:
          'قد رأيت الذي صنعتم، ولم يمنعني من الخروج إليكم إلا أني خشيت أن تُفرض عليكم.',
      sourceName: 'صحيح البخاري',
      sourceReference: 'حديث 1129',
      sourceUrl: 'https://sunnah.com/bukhari:1129',
      editorialNote:
          'المقدمة صياغة تحريرية من رِفقة؛ النص المقتبس والمصدر معروضان منفصلين.',
      scenes: [
        PropheticStoryScene(
          id: 'qiyam_1',
          type: PropheticStorySceneType.opening,
          text: 'ليلة في رمضان، صلّى النبي ﷺ في المسجد وحده تقريبًا...',
          calm: true,
        ),
        PropheticStoryScene(
          id: 'qiyam_2',
          type: PropheticStorySceneType.narrative,
          text:
              'في الليلة التالية اقتدى به أكثر، ثم في الثالثة أو الرابعة امتلأ المسجد بهم. لكنه ﷺ لم يخرج إليهم تلك الليلة.',
        ),
        PropheticStoryScene(
          id: 'qiyam_3',
          type: PropheticStorySceneType.authenticText,
          title: 'فلمّا أصبح، قال ﷺ',
          text:
              'قد رأيت الذي صنعتم، ولم يمنعني من الخروج إليكم إلا أني خشيت أن تُفرض عليكم.',
          calm: true,
        ),
        PropheticStoryScene(
          id: 'qiyam_4',
          type: PropheticStorySceneType.takeaway,
          text:
              'خشي ﷺ أن يُثقل على أمته بما لا تطيق المداومة عليه، فاختار الرحمة بهم على حضوره بينهم.',
        ),
      ],
      suggestedValues: ['الرحمة', 'التيسير', 'التفكر بأمته'],
      reflectionQuestion:
          'كيف تنظرين إلى رحمةٍ اختارت التخفيف عنكِ، لا زيادة العبء عليكِ؟',
      readingMinutes: 2,
      relatedToMadinah: true,
      relatedToProphetMosque: true,
      priority: 6,
      reviewStatus: PropheticStoryReviewStatus.approved,
    ),
  ];

  List<PropheticStory> get allStories => List.unmodifiable(_stories);

  List<PropheticStory> get publishedStories {
    final result = _stories.where(canPublishStory).toList();
    result.sort((a, b) => b.priority.compareTo(a.priority));
    return result;
  }

  List<PropheticStory> get featuredStories =>
      publishedStories.where((story) => story.priority > 0).toList();

  List<PropheticStory> get madinahStories =>
      publishedStories.where((story) => story.relatedToMadinah).toList();

  List<PropheticStory> get prophetMosqueStories =>
      publishedStories.where((story) => story.relatedToProphetMosque).toList();

  List<PropheticStory> byCategory(PropheticStoryCategory category) =>
      publishedStories.where((story) => story.category == category).toList();

  PropheticStory? storyById(String id) {
    for (final story in publishedStories) {
      if (story.id == id) return story;
    }
    return null;
  }

  List<PropheticStory> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return publishedStories;
    return publishedStories.where((story) {
      return [
        story.title,
        story.subtitle,
        story.narrativeText,
        story.category.label,
        ...story.suggestedValues,
      ].join(' ').toLowerCase().contains(q);
    }).toList();
  }

  List<PropheticStory> get pendingReviewStories =>
      _stories.where((story) => !canPublishStory(story)).toList();

  int get pendingReviewCount => pendingReviewStories.length;

  bool canPublishStory(PropheticStory story) {
    if (!story.isApproved || story.title.trim().isEmpty) return false;
    if (story.narrativeText.trim().isEmpty) return false;
    if (story.contentType == PropheticStoryContentType.hadith &&
        !story.isFullyReferenced) {
      return false;
    }
    return true;
  }
}