import '../../models/madinah/prophetic_story.dart';
import '../../models/madinah/salawat_item.dart';

import 'prophetic_stories_repository.dart';
import 'salawat_repository.dart';

class MadinahContentRepository {
  final PropheticStoriesRepository storiesRepository;
  final SalawatRepository salawatRepository;

  MadinahContentRepository({
    PropheticStoriesRepository? storiesRepository,
    SalawatRepository? salawatRepository,
  })  : storiesRepository = storiesRepository ?? PropheticStoriesRepository(),
        salawatRepository = salawatRepository ?? SalawatRepository();

  // ============================================================
  // PROPHETIC STORIES ﷺ
  // ============================================================

  List<PropheticStory> get propheticStories {
    return storiesRepository.publishedStories;
  }

  List<PropheticStory> get featuredStories {
    return storiesRepository.featuredStories;
  }

  List<PropheticStory> get madinahStories {
    return storiesRepository.madinahStories;
  }

  List<PropheticStory> get prophetMosqueStories {
    return storiesRepository.prophetMosqueStories;
  }

  PropheticStory? storyById(
    String id,
  ) {
    return storiesRepository.storyById(id);
  }

  List<PropheticStory> storiesByCategory(
    PropheticStoryCategory category,
  ) {
    return storiesRepository.byCategory(
      category,
    );
  }

  // ============================================================
  // SALAWAT ﷺ
  // ============================================================

  List<SalawatItem> get salawat {
    return salawatRepository.publishedItems;
  }

  List<SalawatItem> get featuredSalawat {
    return salawatRepository.featuredItems;
  }

  List<SalawatItem> get authenticSalawat {
    return salawatRepository.authenticItems;
  }

  SalawatItem? salawatById(
    String id,
  ) {
    return salawatRepository.itemById(id);
  }

  // ============================================================
  // CONTENT SAFETY
  // ============================================================

  /// عدد العناصر التي ما زالت تحت المراجعة.
  ///
  /// يفيدنا لاحقًا في لوحة الإدارة فقط.
  int get pendingReviewCount {
    return storiesRepository.pendingReviewCount +
        salawatRepository.pendingReviewCount;
  }

  bool get hasPendingReview {
    return pendingReviewCount > 0;
  }
}
