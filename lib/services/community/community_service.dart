import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// No Firebase Storage or Cloud Functions required. Small JPEG previews are
/// stored in Firestore; large/full-resolution photo hosting is out of scope.
class CommunityService {
  CommunityService._();
  static final instance = CommunityService._();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // No private credentials in the app. A trusted external Worker handles FCM.
  // Empty means in-app/foreground alerts still work, but closed-app push is off.
  static const _communityPushUrl = String.fromEnvironment(
    'RIFQA_COMMUNITY_PUSH_URL', defaultValue: '');

  Future<void> _dispatchPush(String? target) async {
    if (target == null || target.isEmpty ||
        _communityPushUrl.isEmpty || kIsWeb) return;
    HttpClient? client;
    try {
      final idToken = await member.getIdToken();
      if (idToken == null || idToken.isEmpty) return;
      final parts = target.split('/');
      if (parts.length != 2) return;
      client = HttpClient()..connectionTimeout = const Duration(seconds: 7);
      final req = await client.postUrl(Uri.parse(_communityPushUrl))
          .timeout(const Duration(seconds: 8));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'recipientId': parts[0],
        'notificationId': parts[1],
      }));
      final response = await req.close().timeout(const Duration(seconds: 12));
      final content = await utf8.decoder.bind(response).join()
          .timeout(const Duration(seconds: 12));
      debugPrint('[Rifqa Community Push] ${response.statusCode}: $content');
    } catch (error) {
      debugPrint('[Rifqa Community Push] delivery failed: $error');
    } finally {
      client?.close(force: true);
    }
  }


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
    final uid = member.uid;
    final ref = posts.doc(postId).collection('likes').doc(uid);
    if (liked) {
      await ref.delete();
      return;
    }
    final post = await posts.doc(postId).get();
    final owner = post.data()?['authorId']?.toString();
    if (owner == null) throw StateError('المنشور غير متاح');
    final batch = db.batch();
    batch.set(ref, {'createdAt': FieldValue.serverTimestamp()});
    batch.delete(posts.doc(postId).collection('dislikes').doc(uid));
    final pushed = _queueActivity(batch, recipientId: owner, postId: postId,
        commentId: '', kind: 'post_like', senderName: _actorName);
    await batch.commit();
    unawaited(_dispatchPush(pushed));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> commentLikes(
      String postId, String commentId) => posts.doc(postId)
      .collection('comments').doc(commentId).collection('likes').snapshots();

  /// Notifications are written in the same batch as their linked event.
  /// Firestore rules verify the event, sender and recipient before accepting it.
  String? _queueActivity(WriteBatch batch, {
    required String recipientId,
    required String postId,
    required String commentId,
    required String kind,
    required String senderName,
    String body = '',
    String replyTo = '',
  }) {
    final actor = member;
    if (recipientId == actor.uid || recipientId.isEmpty) return null;
    final ref = db.collection('users').doc(recipientId)
        .collection('community_notifications').doc();
    batch.set(ref, {
      'kind': kind,
      'postId': postId,
      'commentId': commentId,
      'replyTo': replyTo,
      'recipientId': recipientId,
      'senderId': actor.uid,
      'senderName': senderName.length > 80
          ? senderName.substring(0, 80) : senderName,
      'body': body,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return '$recipientId/${ref.id}';
  }

  String get _actorName {
    final u = member;
    final name = (u.displayName?.trim().isNotEmpty == true
        ? u.displayName!.trim()
        : u.email?.split('@').first ?? 'عضو رفقة');
    return name.length > 80 ? name.substring(0, 80) : name;
  }

  Future<void> toggleCommentLike(
      String postId, String commentId, bool liked) async {
    final uid = member.uid;
    final commentRef = posts.doc(postId).collection('comments').doc(commentId);
    final likeRef = commentRef.collection('likes').doc(uid);
    if (liked) {
      await likeRef.delete();
      return;
    }
    final comment = await commentRef.get();
    final owner = comment.data()?['authorId']?.toString();
    if (owner == null) throw StateError('التعليق غير متاح');
    final batch = db.batch();
    batch.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
    final pushed = _queueActivity(batch, recipientId: owner, postId: postId,
        commentId: commentId, kind: 'comment_like', senderName: _actorName);
    await batch.commit();
    unawaited(_dispatchPush(pushed));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> dislikes(String id) =>
      posts.doc(id).collection('dislikes').snapshots();

  Future<void> toggleDislike(String postId, bool disliked) async {
    final uid = member.uid;
    final dislikeRef = posts.doc(postId).collection('dislikes').doc(uid);
    final likeRef = posts.doc(postId).collection('likes').doc(uid);
    final batch = db.batch();
    String? pushed;
    if (disliked) {
      batch.delete(dislikeRef);
    } else {
      final post = await posts.doc(postId).get();
      final owner = post.data()?['authorId']?.toString();
      if (owner == null) throw StateError('المنشور غير متاح');
      batch.set(dislikeRef, {'createdAt': FieldValue.serverTimestamp()});
      batch.delete(likeRef);
      pushed = _queueActivity(batch, recipientId: owner, postId: postId,
          commentId: '', kind: 'post_dislike', senderName: _actorName);
    }
    await batch.commit();
    unawaited(_dispatchPush(pushed));
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

  /// Visible author can receive a standard friend request without a code.
  /// Friendship is created only if they accept in FriendsScreen.
  Future<String> requestFriendFromPost({
    required String postId,
    required String targetUid,
  }) async {
    final u = member;
    if (targetUid == u.uid) throw StateError('هذا منشورك.');
    final post = await posts.doc(postId).get();
    final data = post.data();
    if (data == null || data['authorId'] != targetUid || data['isHidden'] == true) {
      throw StateError('المنشور غير متاح.');
    }
    final existing = await db.collection('users').doc(u.uid)
        .collection('friends').doc(targetUid).get();
    if (existing.exists) throw StateError('أنتم أصدقاء بالفعل.');
    final name = (u.displayName?.trim().isNotEmpty == true
        ? u.displayName!.trim()
        : u.email?.split('@').first ?? 'عضو رفقة');
    final otherName = (data['authorName'] ?? 'عضو رفقة').toString();
    final requestRef = db.collection('friend_requests').doc('${u.uid}_$targetUid');
    try {
      final batch = db.batch();
      batch.set(requestRef, {
        'fromUid': u.uid,
        'fromName': name.length > 120 ? name.substring(0, 120) : name,
        'toUid': targetUid,
        'toName': otherName.length > 120 ? otherName.substring(0, 120) : otherName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      final pushed = _queueActivity(batch, recipientId: targetUid, postId: postId,
          commentId: '', kind: 'friend_request', senderName: _actorName);
      await batch.commit();
      unawaited(_dispatchPush(pushed));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw StateError('قد يكون طلب الصداقة أُرسل بالفعل. راجعي طلباتك.');
      }
      rethrow;
    }
    return 'تم إرسال طلب صداقة إلى $otherName';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> myReplyNotifications() {
    final uid = member.uid;
    return db.collection('users').doc(uid)
        .collection('community_notifications')
        .orderBy('createdAt', descending: true).limit(40).snapshots();
  }

  Future<void> markReplyRead(String notificationId) async {
    await db.collection('users').doc(member.uid)
        .collection('community_notifications').doc(notificationId)
        .update({'read': true});
  }

  Future<void> addComment(String postId, String raw,
      {String? parentCommentId}) async {
    final u = member;
    final body = raw.trim();
    if (body.isEmpty || body.length > 500) {
      throw StateError('التعليق يجب أن يكون من 1 إلى 500 حرف.');
    }
    final postRef = posts.doc(postId);
    final post = await postRef.get();
    final ownerUid = post.data()?['authorId']?.toString();
    if (ownerUid == null || post.data()?['isHidden'] == true) {
      throw StateError('المنشور لم يعد متاحًا.');
    }
    final replyTo = parentCommentId ?? '';
    String? parentOwner;
    if (replyTo.isNotEmpty) {
      final parent = await postRef.collection('comments').doc(replyTo).get();
      parentOwner = parent.data()?['authorId']?.toString();
      if (parentOwner == null ||
          (parent.data()?['parentCommentId']?.toString().isNotEmpty ?? false)) {
        throw StateError('التعليق الأصلي لم يعد متاحًا.');
      }
    }
    final commentRef = postRef.collection('comments').doc();
    final batch = db.batch();
    batch.set(commentRef, {
      'authorId': u.uid,
      'authorName': _actorName,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      if (replyTo.isNotEmpty) 'parentCommentId': replyTo,
    });
    // One notification to the post owner, and one to the replied-to author.
    // When both are the same person, one notification is enough.
    final pushedOwner = _queueActivity(batch, recipientId: ownerUid, postId: postId,
        commentId: commentRef.id, kind: 'comment',
        senderName: _actorName, body: body, replyTo: replyTo);
    String? pushedParent;
    if (replyTo.isNotEmpty && parentOwner != ownerUid) {
      pushedParent = _queueActivity(batch, recipientId: parentOwner!, postId: postId,
          commentId: commentRef.id, kind: 'reply',
          senderName: _actorName, body: body, replyTo: replyTo);
    }
    await batch.commit();
    unawaited(_dispatchPush(pushedOwner));
    unawaited(_dispatchPush(pushedParent));
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
