import '../../models/madinah/salawat_item.dart';

class SalawatRepository {
  final List<SalawatItem> _items = const [
    SalawatItem(
      id: 'quran_33_56',
      title: 'أمر القرآن بالصلاة والسلام عليه ﷺ',
      text:
          'يَا أَيُّهَا الَّذِينَ آمَنُوا صَلُّوا عَلَيْهِ وَسَلِّمُوا تَسْلِيمًا',
      subtitle: 'من سورة الأحزاب',
      type: SalawatType.quranicCommand,
      sourceName: 'القرآن الكريم',
      sourceReference: 'الأحزاب 33:56',
      sourceUrl: 'https://quran.com/33/56',
      meaning:
          'تذكير قرآني بالصلاة والسلام على النبي ﷺ. هذا القسم لا يحوّل العبادة إلى نقاط أو منافسة.',
      priority: 10,
      featured: true,
      preferredDisplayMode: SalawatDisplayMode.calm,
      reviewStatus: SalawatReviewStatus.approved,
    ),
    SalawatItem(
      id: 'ibrahimiyyah',
      title: 'الصلاة الإبراهيمية',
      text:
          'اللهم صل على محمد وعلى آل محمد كما صليت على إبراهيم وعلى آل إبراهيم إنك حميد مجيد، اللهم بارك على محمد وعلى آل محمد كما باركت على إبراهيم وعلى آل إبراهيم إنك حميد مجيد.',
      subtitle: 'صيغة مأثورة صحيحة',
      type: SalawatType.authenticFormula,
      sourceName: 'صحيح البخاري',
      sourceReference: 'حديث 3370',
      sourceUrl: 'https://sunnah.com/bukhari/60/44',
      editorialNote: 'النص من الصيغة الواردة في الحديث.',
      priority: 9,
      featured: true,
      preferredDisplayMode: SalawatDisplayMode.largeReader,
      reviewStatus: SalawatReviewStatus.approved,
    ),
  ];

  List<SalawatItem> get allItems => List.unmodifiable(_items);

  List<SalawatItem> get publishedItems {
    final result = _items.where(canPublishItem).toList();
    result.sort((a, b) => b.priority.compareTo(a.priority));
    return result;
  }

  List<SalawatItem> get featuredItems =>
      publishedItems.where((item) => item.featured).toList();

  List<SalawatItem> get authenticItems =>
      publishedItems.where((item) => item.isAuthenticFormula).toList();

  List<SalawatItem> get quranicItems =>
      publishedItems.where((item) => item.isQuranic).toList();

  List<SalawatItem> get generalItems =>
      publishedItems.where((item) => item.isGeneralFormula).toList();

  SalawatItem? itemById(String id) {
    for (final item in publishedItems) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<SalawatItem> get pendingReviewItems =>
      _items.where((item) => !canPublishItem(item)).toList();

  int get pendingReviewCount => pendingReviewItems.length;

  bool canPublishItem(SalawatItem item) {
    if (!item.isApproved ||
        item.title.trim().isEmpty ||
        item.text.trim().isEmpty) {
      return false;
    }
    if (item.isAuthenticFormula && (!item.hasSource || !item.hasReference)) {
      return false;
    }
    return true;
  }
}
