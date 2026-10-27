import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// No Firebase Storage or Cloud Functions required. Small JPEG previews are
/// stored in Firestore; large/full-resolution photo hosting is out of scope.
class CommunityService {
  CommunityService._();
  static final instance = CommunityService._();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  static const categories = ['الحرمين', 'الحج', 'العمرة', 'الأسواق'];
  static const kinds = ['سؤال', 'نصيحة', 'معلومة'];
  static const int maxPhotoBytes = 240000;

  User get member {
    final u = auth.currentUser;
    if (u == null || u.isAnonymous || !u.emailVerified) {
      throw StateError('سجّلي الدخول بحساب تم تأكيد بريده الإلكتروني لاستخدام المجتمع.');
    }
    return u;
  }

  CollectionReference<Map<String, dynamic>> get posts =>
      db.collection('community_posts');

  Stream<QuerySnapshot<Map<String, dynamic>>> latest() =>
      posts.orderBy('createdAt', descending: true).limit(40).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> likes(String id) =>
      posts.doc(id).collection('likes').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> comments(String id) => posts
      .doc(id)
      .collection('comments')
      .orderBy('createdAt', descending: false)
      .limit(100)
      .snapshots();

  Future<void> createPost({
    required String text,
    required String category,
    required String kind,
    String location = '',
    Uint8List? photo,
  }) async {
    final u = member;
    final body = text.trim();
    if (body.isEmpty || body.length > 1500) {
      throw StateError('اكتبي منشورًا من 1 إلى 1500 حرف.');
    }
    if (!categories.contains(category) || !kinds.contains(kind)) {
      throw StateError('اختاري القسم ونوع المنشور.');
    }
    if (location.trim().length > 80) {
      throw StateError('الموقع يجب ألا يتجاوز 80 حرفًا.');
    }
    if (photo != null && photo.lengthInBytes > maxPhotoBytes) {
      throw StateError('الصورة كبيرة. اختاري صورة أصغر (240 كيلوبايت كحد أقصى).');
    }
    final rawName = (u.displayName?.trim().isNotEmpty == true
        ? u.displayName!.trim()
        : u.email?.split('@').first ?? 'عضو رفقة');
    final authorName = rawName.length > 80 ? rawName.substring(0, 80) : rawName;
    await posts.add({
      'authorId': u.uid,
      'authorName': authorName,
      'body': body,
      'category': category,
      'kind': kind,
      'location': location.trim(),
      if (photo != null) 'imageBase64': base64Encode(photo),
      'createdAt': FieldValue.serverTimestamp(),
      'spamReporters': <String>[],
      'isHidden': false,
    });
  }

  Future<void> toggleLike(String postId, bool liked) async {
    final ref = posts.doc(postId).collection('likes').doc(member.uid);
    if (liked) {
      await ref.delete();
    } else {
      final batch = db.batch();
      batch.set(ref, {'createdAt': FieldValue.serverTimestamp()});
      batch.delete(posts.doc(postId).collection('dislikes').doc(member.uid));
      await batch.commit();
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> dislikes(String id) =>
      posts.doc(id).collection('dislikes').snapshots();

  Future<void> toggleDislike(String postId, bool disliked) async {
    final uid = member.uid;
    final dislikeRef = posts.doc(postId).collection('dislikes').doc(uid);
    final likeRef = posts.doc(postId).collection('likes').doc(uid);
    final batch = db.batch();
    if (disliked) {
      batch.delete(dislikeRef);
    } else {
      batch.set(dislikeRef, {'createdAt': FieldValue.serverTimestamp()});
      // An account must not simultaneously Like and Dislike a post.
      batch.delete(likeRef);
    }
    await batch.commit();
  }

  /// Return number of distinct accounts reporting spam (1..4).
  /// Transaction guarantees the 4th distinct report hides the post immediately.
  /// Firestore rules independently enforce single-vote progression.
  Future<int> reportSpam(String postId) async {
    final u = member;
    final ref = posts.doc(postId);
    return db.runTransaction<int>((tx) async {
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      if (data == null) throw StateError('المنشور غير موجود.');
      if (data['authorId'] == u.uid) {
        throw StateError('لا يمكنك الإبلاغ عن منشورك.');
      }
      if (data['isHidden'] == true) {
        throw StateError('المنشور مخفي بالفعل.');
      }
      final ids = (data['spamReporters'] as List?)
              ?.whereType<String>()
              .toList() ??
          <String>[];
      if (ids.contains(u.uid)) {
        throw StateError('تم تسجيل بلاغ Spam من حسابك بالفعل.');
      }
      if (ids.length >= 4) {
        throw StateError('تم إخفاء المنشور بالفعل.');
      }
      ids.add(u.uid);
      tx.update(ref, {
        'spamReporters': ids,
        'isHidden': ids.length >= 4,
      });
      return ids.length;
    });
  }

  Future<void> addComment(String postId, String raw) async {
    final u = member;
    final body = raw.trim();
    if (body.isEmpty || body.length > 500) {
      throw StateError('التعليق يجب أن يكون من 1 إلى 500 حرف.');
    }
    final rawName = (u.displayName?.trim().isNotEmpty == true
        ? u.displayName!.trim()
        : u.email?.split('@').first ?? 'عضو رفقة');
    final authorName = rawName.length > 80 ? rawName.substring(0, 80) : rawName;
    await posts.doc(postId).collection('comments').add({
      'authorId': u.uid,
      'authorName': authorName,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteOwnPost(String id, String authorId) async {
    if (member.uid != authorId) throw StateError('لا يمكن حذف منشور آخر.');
    await posts.doc(id).delete();
  }

  Future<void> report(String id, String reason) async {
    if (!['محتوى غير مناسب', 'إساءة أو تنمر', 'معلومات مضللة', 'إعلان مزعج']
        .contains(reason)) {
      throw StateError('سبب الإبلاغ غير صالح.');
    }
    await posts.doc(id).collection('reports').doc(member.uid).set({
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
