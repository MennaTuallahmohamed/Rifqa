import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A clear Arabic message instead of a raw Firebase PERMISSION_DENIED stack.
String refqaMarketErrorMessage(Object error) {
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'تعذّر الحفظ بسبب صلاحيات Firebase. تأكدي من نشر قواعد الأسواق على مشروع رفقة، وأن بريد الحساب مؤكد.';
    }
    if (error.code == 'unavailable') {
      return 'الاتصال بخدمة الأسواق غير متاح حاليًا. تأكدي من الإنترنت ثم أعيدي المحاولة.';
    }
    return error.message ?? 'تعذّر تنفيذ العملية. جرّبي مرة أخرى.';
  }
  if (error is StateError) return error.message;
  return 'تعذّر تنفيذ العملية، جرّبي مجددًا.';
}

/// Community-submitted shops and markets. These are NOT official listings.
/// The canonical source of visibility/report counts is Firestore; a local UI
/// counter is never trusted for moderation.
class RefqaMarketContribution {
  const RefqaMarketContribution({
    required this.id,
    required this.name,
    required this.city,
    required this.placeType,
    required this.category,
    required this.marketName,
    required this.marketId,
    required this.area,
    required this.floor,
    required this.unit,
    required this.note,
    required this.authorUid,
    required this.reportCount,
    required this.helpfulCount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String city;
  final String placeType;
  final String category;
  final String marketName;
  final String marketId;
  final String area;
  final int floor;
  final String unit;
  final String note;
  final String authorUid;
  final int reportCount;
  final int helpfulCount;
  final DateTime? createdAt;

  bool get clockTower => marketId == 'makkah_clock_towers';
  String get cityLabel => city == 'madinah' ? 'المدينة المنورة' : 'مكة المكرمة';
  String get floorLabel => floor > 0 ? 'الدور $floor' : 'الدور غير محدد';
  String get typeLabel => placeType == 'market' ? 'سوق' : 'محل';

  factory RefqaMarketContribution.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final x = doc.data();
    return RefqaMarketContribution(
      id: doc.id,
      name: (x['name'] ?? '').toString(),
      city: (x['city'] ?? 'makkah').toString(),
      placeType: (x['placeType'] ?? 'shop').toString(),
      category: (x['category'] ?? 'أخرى').toString(),
      marketName: (x['marketName'] ?? '').toString(),
      marketId: (x['marketId'] ?? '').toString(),
      area: (x['area'] ?? '').toString(),
      floor: (x['floor'] as num?)?.toInt() ?? 0,
      unit: (x['unit'] ?? '').toString(),
      note: (x['note'] ?? '').toString(),
      authorUid: (x['authorUid'] ?? '').toString(),
      reportCount: (x['reportCount'] as num?)?.toInt() ?? 0,
      helpfulCount: (x['helpfulCount'] as num?)?.toInt() ?? 0,
      createdAt: (x['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class RefqaMarketsCommunityService {
  RefqaMarketsCommunityService._();
  static final instance = RefqaMarketsCommunityService._();

  static const categories = <String>[
    'مطاعم', 'كافيهات وحلويات', 'تجميل', 'عطور', 'ملابس',
    'هدايا', 'ذهب وساعات', 'صيدليات وخدمات', 'أسواق شعبية', 'أخرى',
  ];

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CollectionReference<Map<String, dynamic>> get _places =>
      _db.collection('rifqa_market_contributions');

  /// Every public list query is restricted to visible records, to match rules.
  Stream<List<RefqaMarketContribution>> visiblePlaces() => _places
      .where('status', isEqualTo: 'visible')
      .limit(400)
      .snapshots()
      .map((event) => event.docs
          .map(RefqaMarketContribution.fromDoc)
          .toList(growable: false));

  Future<User> _verifiedUser() async {
    var current = _auth.currentUser;
    if (current == null || current.isAnonymous) {
      throw StateError('لازم تسجلي الدخول بحسابك قبل المشاركة.');
    }
    await current.reload();
    current = _auth.currentUser;
    if (current == null || !current.emailVerified) {
      throw StateError('أكدي البريد الإلكتروني أولًا علشان تضيفي أو تبلّغي.');
    }
    return current;
  }

  Future<void> publish({
    required String name,
    required String city,
    required String placeType,
    required String category,
    required String marketId,
    required String marketName,
    required String area,
    required int floor,
    required String unit,
    required String note,
  }) async {
    final user = await _verifiedUser();
    final title = name.trim();
    final market = marketName.trim();
    final location = area.trim();
    final description = note.trim();
    final number = unit.trim();
    if (title.length < 2 || title.length > 100 ||
        (city != 'makkah' && city != 'madinah') ||
        (placeType != 'market' && placeType != 'shop') ||
        !categories.contains(category) ||
        (placeType == 'shop' && market.isEmpty) ||
        market.length > 100 || marketId.length > 80 ||
        location.length < 3 || location.length > 180 ||
        floor < 0 || floor > 7 ||
        (marketId != 'makkah_clock_towers' && floor != 0) ||
        number.length > 40 || description.length > 500) {
      throw StateError('راجعي اسم المكان ونوعه وموقعه والتصنيف والدور.');
    }
    await _places.add({
      'name': title,
      'city': city,
      'placeType': placeType,
      'category': category,
      'marketId': marketId,
      'marketName': market,
      'area': location,
      'floor': floor,
      'unit': number,
      'note': description,
      'authorUid': user.uid,
      'status': 'visible',
      'reportCount': 0,
      'helpfulCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// A unique verified user can report once. Each report is an atomic
  /// transaction: a third report changes visibility to hidden server-side.
  Future<int> reportWrong(RefqaMarketContribution place) async {
    final user = await _verifiedUser();
    if (user.uid == place.authorUid) {
      throw StateError('مينفعش تبلّغي عن إضافة كتبتيها بنفسك.');
    }
    final ref = _places.doc(place.id);
    final vote = ref.collection('reports').doc(user.uid);
    return _db.runTransaction<int>((t) async {
      final snap = await t.get(ref);
      final previous = await t.get(vote);
      final data = snap.data();
      if (data == null || data['status'] != 'visible') {
        throw StateError('الإضافة لم تعد ظاهرة في الدليل.');
      }
      if (previous.exists) throw StateError('بلغتِ عن المعلومة دي قبل كده.');
      if (data['authorUid'] == user.uid) {
        throw StateError('مينفعش تبلّغي عن إضافتك.');
      }
      final count = ((data['reportCount'] as num?)?.toInt() ?? 0) + 1;
      t.set(vote, {
        'reporterUid': user.uid,
        'reason': 'wrong_information',
        'createdAt': FieldValue.serverTimestamp(),
      });
      t.update(ref, {
        'reportCount': count,
        'status': count >= 3 ? 'hidden' : 'visible',
      });
      return count;
    });
  }

  Future<int> markHelpful(RefqaMarketContribution place) async {
    final user = await _verifiedUser();
    if (user.uid == place.authorUid) {
      throw StateError('الإضافة الخاصة بيكي مش محتاجة تقييم منك.');
    }
    final ref = _places.doc(place.id);
    final vote = ref.collection('helpful').doc(user.uid);
    return _db.runTransaction<int>((t) async {
      final snap = await t.get(ref);
      final previous = await t.get(vote);
      final data = snap.data();
      if (data == null || data['status'] != 'visible') {
        throw StateError('الإضافة لم تعد متاحة.');
      }
      if (previous.exists) throw StateError('سجلتي إن المعلومة مفيدة بالفعل.');
      if (data['authorUid'] == user.uid) {
        throw StateError('لا يمكن تقييم إضافتك الشخصية.');
      }
      final count = ((data['helpfulCount'] as num?)?.toInt() ?? 0) + 1;
      t.set(vote, {
        'voterUid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      t.update(ref, {'helpfulCount': count});
      return count;
    });
  }
}
