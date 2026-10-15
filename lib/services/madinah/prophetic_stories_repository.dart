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
