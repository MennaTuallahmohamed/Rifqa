import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'market_community_service.dart';

/// Crowdsourced locations are never labelled as independently verified.
class ClockTowerStore {
  const ClockTowerStore({
    required this.id,
    required this.name,
    required this.category,
    required this.note,
    required this.community,
    this.englishName = '',
    this.floor,
    this.unit = '',
    this.sourceUrl = '',
    this.floorVerified = false,
    this.reports = 0,
    this.helpful = 0,
    this.contribution,
  });

  final String id, name, category, note, englishName, unit, sourceUrl;
  final int? floor;
  final bool community, floorVerified;
  final int reports, helpful;
  final RefqaMarketContribution? contribution;

  String get floorLabel => floor == null ? 'الدور غير معروف' : 'الدور $floor';
  String get confidenceLabel {
    if (community) return 'أضافه مستخدم · لم يتم التحقق ميدانيًا';
    if (floor == null) return 'الدور غير محدد بالدليل';
    return floorVerified ? 'الدور له مصدر منشور' : 'الموقع يحتاج تأكيدًا';
  }

  factory ClockTowerStore.fromSeed(Map<String, dynamic> json) {
    final rawFloor = json['floor_index'];
    return ClockTowerStore(
      id: (json['id'] ?? '').toString(),
      name: (json['name_ar'] ?? '').toString(),
      englishName: (json['name_en'] ?? '').toString(),
      category: (json['category_ar'] ?? 'أخرى').toString(),
      note: (json['location_note_ar'] ?? '').toString(),
      floor: rawFloor is int && rawFloor >= 1 && rawFloor <= 7 ? rawFloor : null,
      unit: (json['unit_number'] ?? '').toString(),
      sourceUrl: (json['floor_evidence_url'] ?? json['source_url'] ?? '').toString(),
      floorVerified: json['floor_use_for_navigation'] == true,
      community: false,
    );
  }

  factory ClockTowerStore.fromContribution(RefqaMarketContribution p) =>
      ClockTowerStore(
        id: 'cm:${p.id}',
        name: p.name,
        category: p.category,
        note: p.note.isNotEmpty ? p.note : p.area,
        community: true,
        floor: p.floor > 0 ? p.floor : null,
        unit: p.unit,
        reports: p.reportCount,
        helpful: p.helpfulCount,
        contribution: p,
      );

  factory ClockTowerStore.fromCommunity(
      QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final json = document.data();
    return ClockTowerStore(
      id: document.id,
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? 'أخرى').toString(),
      note: (json['note'] ?? '').toString(),
      floor: json['floor'] as int?,
      unit: (json['unit'] ?? '').toString(),
      reports: (json['reportCount'] as num?)?.toInt() ?? 0,
      community: true,
    );
  }
}

class ClockTowerDirectoryService {
  ClockTowerDirectoryService._();
  static final instance = ClockTowerDirectoryService._();

  static const categories = <String>[
    'مطاعم',
    'كافيهات وحلويات',
    'تجميل',
    'عطور',
    'ملابس',
    'هدايا',
    'ذهب وساعات',
    'صيدليات وخدمات',
    'أخرى',
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CollectionReference<Map<String, dynamic>> get _places =>
      _firestore.collection('clock_tower_places');

  Future<List<ClockTowerStore>> loadSeed() async {
    final text = await rootBundle.loadString(
        'assets/markets/clock_tower_directory.json');
    final data = jsonDecode(text) as Map<String, dynamic>;
    return (data['places'] as List<dynamic>)
        .map((p) => ClockTowerStore.fromSeed(
            Map<String, dynamic>.from(p as Map)))
        .where((store) => store.name.isNotEmpty)
        .toList(growable: false);
  }

  /// The public query MUST constrain status, matching Firestore rules.
  Stream<List<ClockTowerStore>> livePlaces() => _places
      .where('status', isEqualTo: 'visible')
      .limit(500)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map(ClockTowerStore.fromCommunity)
          .toList(growable: false));

  Future<User> _verifiedUser() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('سجّلي الدخول بحسابك أولاً للمشاركة في الدليل.');
    }
    await user.reload();
    final current = _auth.currentUser;
    if (current == null || !current.emailVerified) {
      throw StateError('لازم تأكيد البريد الإلكتروني قبل إضافة محل أو الإبلاغ.');
    }
    return current;
  }

  Future<void> addStore({
    required String name,
    required String category,
    required int floor,
    required String unit,
    required String note,
  }) async {
    final user = await _verifiedUser();
    final title = name.trim();
    final placeUnit = unit.trim();
    final description = note.trim();
    if (title.length < 2 || title.length > 100 ||
        !categories.contains(category) ||
        floor < 1 || floor > 7 ||
        placeUnit.length > 40 || description.length > 500) {
      throw StateError('راجعي اسم المحل والدور وتصنيفه وباقي البيانات.');
    }
    await _places.add({
      'name': title,
      'category': category,
      'floor': floor,
      'unit': placeUnit,
      'note': description,
      'authorUid': user.uid,
      'status': 'visible',
      'reportCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Atomic unique-user report. On the third distinct report, the place
  /// changes to 'hidden' and disappears from all public directory queries.
  /// Firestore rules enforce BOTH writes and reject fabricated votes.
  Future<int> reportWrongInfo(String storeId) async {
    final user = await _verifiedUser();
    final storeRef = _places.doc(storeId);
    final reportRef = storeRef.collection('reports').doc(user.uid);
    return _firestore.runTransaction<int>((transaction) async {
      final storeSnapshot = await transaction.get(storeRef);
      final reportSnapshot = await transaction.get(reportRef);
      final store = storeSnapshot.data();
      if (store == null || store['status'] != 'visible') {
        throw StateError('هذا المحل لم يعد ظاهرًا في الدليل.');
      }
      if (store['authorUid'] == user.uid) {
        throw StateError('لا يمكنك الإبلاغ عن المحل الذي أضفتِه.');
      }
      if (reportSnapshot.exists) {
        throw StateError('تم تسجيل بلاغك عن هذا المحل من قبل.');
      }
      final nextCount = ((store['reportCount'] as num?)?.toInt() ?? 0) + 1;
      transaction.set(reportRef, {
        'reporterUid': user.uid,
        'reason': 'wrong_information',
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(storeRef, {
        'reportCount': nextCount,
        'status': nextCount >= 3 ? 'hidden' : 'visible',
      });
      return nextCount;
    });
  }
}
