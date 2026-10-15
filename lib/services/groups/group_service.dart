import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  GroupService._();
  static final instance = GroupService._();
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  User get user {
    final u = auth.currentUser;
    if (u == null || u.isAnonymous || !u.emailVerified) {
      throw StateError('يجب تسجيل الدخول بحساب مؤكّد البريد أولاً');
    }
    return u;
  }

  String get _displayName {
    final u = user;
    return u.displayName ?? u.email ?? 'عضو';
  }

  CollectionReference<Map<String, dynamic>> get groups => db.collection('groups');
  CollectionReference<Map<String, dynamic>> get invites => db.collection('invites');

  // ---------------------------------------------------------------- groups
  Stream<QuerySnapshot<Map<String, dynamic>>> myGroups() =>
      groups.where('memberIds', arrayContains: user.uid).snapshots();

  /// يحدّث التوكن حتى تُقرأ حالة تأكيد البريد الأحدث في قواعد الأمان.
  Future<void> refreshAuth() async {
    final u = auth.currentUser;
    if (u == null) return;
    try {
      await u.reload();
      await auth.currentUser?.getIdToken(true);
    } catch (_) {}
  }

  Future<String> createGroup(String name) async {
    await refreshAuth();
    final u = user;
    final cleaned = name.trim();
    if (cleaned.length < 3 || cleaned.length > 70) {
      throw StateError('اسم المجموعة من 3 إلى 70 حرفًا');
    }
    final doc = groups.doc();
    await doc.set({
      'name': cleaned,
      'ownerId': u.uid,
      'adminIds': [u.uid],
      'memberIds': [u.uid],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // --------------------------------------------------------------- invites
  String _newCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<String> createInvite(String groupId) async {
    await refreshAuth();
    final u = user;
    final group = await groups.doc(groupId).get();
    final g = group.data();
    if (g == null || !(List.from(g['adminIds'] ?? []).contains(u.uid))) {
      throw StateError('إنشاء الدعوات متاح للمشرفين فقط');
    }
    for (var i = 0; i < 4; i++) {
      final code = _newCode();
      final inviteRef = invites.doc(code);
      final created = await db.runTransaction<bool>((t) async {
        final existing = await t.get(inviteRef);
        if (existing.exists) return false;
        t.set(inviteRef, {
          'groupId': groupId,
          'groupName': (g['name'] ?? '').toString(),
          'createdBy': u.uid,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(
            DateTime.now().toUtc().add(const Duration(hours: 24)),
          ),
        });
        return true;
      });
      if (created) return code;
    }
    throw StateError('تعذر إنشاء كود دعوة، حاولي مجددًا');
  }

  Future<void> revokeInvite(String code) async {
    final u = user;
    final inviteRef = invites.doc(code.trim().toUpperCase());
    final snapshot = await inviteRef.get();
    final data = snapshot.data();
    if (data == null) throw StateError('كود الدعوة غير موجود');
    final group = await groups.doc(data['groupId'] as String).get();
    if (!(List.from(group.data()?['adminIds'] ?? []).contains(u.uid))) {
      throw StateError('إلغاء الدعوة متاح للمشرفين فقط');
    }
    await inviteRef.update({'active': false});
  }

  // ----------------------------------------------------------- join / admin
  Future<String> requestJoin(String rawCode) async {
    await refreshAuth();
    final u = user;
    final code = rawCode.trim().toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    if (code.length != 12) {
      throw StateError('كود الدعوة يتكوّن من 12 خانة، تأكد من نسخه كاملًا');
    }
    DocumentSnapshot<Map<String, dynamic>> invite;
    try {
      invite = await invites.doc(code).get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw StateError(
            'تعذّر التحقق من الكود. تأكد من تأكيد بريدك الإلكتروني ثم أعد تسجيل الدخول');
      }
      rethrow;
    }
    final data = invite.data();
    if (data == null) throw StateError('كود الدعوة غير صحيح');
    if (data['active'] != true) throw StateError('تم إلغاء كود الدعوة هذا');
    if ((data['expiresAt'] as Timestamp).toDate().isBefore(DateTime.now())) {
      throw StateError('انتهت صلاحية كود الدعوة (24 ساعة)، اطلب كودًا جديدًا من المشرف');
    }
    final gid = data['groupId'] as String;
    final groupName = (data['groupName'] ?? 'مجموعة').toString();
    final requestRef = groups.doc(gid).collection('join_requests').doc(u.uid);
    final existing = await requestRef.get();
    if (existing.exists) {
      if (existing.data()?['status'] == 'pending') {
        throw StateError('طلبك قيد المراجعة من المشرف');
      }
      try {
        await requestRef.delete();
      } on FirebaseException {
        throw StateError('أنت بالفعل عضو في هذه المجموعة');
      }
    }
    try {
      await requestRef.set({
        'userId': u.uid,
        'userName': _displayName,
        'inviteCode': code,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw StateError(
            'تعذّر إرسال الطلب: تأكد أن الكود لم تنته صلاحيته وأنك لست عضوًا بالفعل');
      }
      rethrow;
    }
    // سجل محلي في حسابي لعرض حالة الطلب حتى موافقة المشرف
    try {
      await db.collection('users').doc(u.uid).collection('join_refs').doc(gid).set({
        'groupName': groupName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
    return gid;
  }

  // ------------------------------------------------- my pending join requests
  Stream<QuerySnapshot<Map<String, dynamic>>> myJoinRefs() =>
      db.collection('users').doc(user.uid).collection('join_refs').snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> myRequest(String gid) =>
      groups.doc(gid).collection('join_requests').doc(user.uid).snapshots();

  Future<void> clearJoinRef(String gid) =>
      db.collection('users').doc(user.uid).collection('join_refs').doc(gid).delete();

  Future<void> cancelJoin(String gid) async {
    final u = user;
    final batch = db.batch();
    batch.delete(groups.doc(gid).collection('join_requests').doc(u.uid));
    batch.delete(db.collection('users').doc(u.uid).collection('join_refs').doc(gid));
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingRequests(String gid) =>
      groups
          .doc(gid)
          .collection('join_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots();

  Future<void> approve(String gid, String uid) async {
    final u = user;
    final groupRef = groups.doc(gid);
    final requestRef = groupRef.collection('join_requests').doc(uid);
    await db.runTransaction((t) async {
      final gs = await t.get(groupRef);
      final rs = await t.get(requestRef);
      final group = gs.data();
      final req = rs.data();
      if (group == null ||
          req == null ||
          req['status'] != 'pending' ||
          !(List.from(group['adminIds'] ?? []).contains(u.uid))) {
        throw StateError('غير مسموح بالموافقة على هذا الطلب');
      }
      t.update(groupRef, {
        'memberIds': FieldValue.arrayUnion([uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      t.update(requestRef, {'status': 'approved'});
    });
  }

  Future<void> reject(String gid, String uid) async {
    user;
    await groups
        .doc(gid)
        .collection('join_requests')
        .doc(uid)
        .update({'status': 'rejected'});
  }

  // -------------------------------------------------------------- messages
  Stream<QuerySnapshot<Map<String, dynamic>>> messages(String gid) => groups
      .doc(gid)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(60)
      .snapshots();

  Future<void> sendMessage(String gid, String text) async {
    final u = user;
    final content = text.trim();
    if (content.isEmpty || content.length > 2000) return;
    await groups.doc(gid).collection('messages').add({
      'senderId': u.uid,
      'senderName': _displayName,
      'type': 'text',
      'text': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------- static location + SOS
  Future<void> sendLocation(String gid, double lat, double lng,
      {bool emergency = false}) async {
    final u = user;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      throw StateError('إحداثيات غير صحيحة');
    }
    if (emergency) {
      await groups.doc(gid).collection('alerts').add({
        'senderId': u.uid,
        'senderName': _displayName,
        'lat': lat,
        'lng': lng,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await groups.doc(gid).collection('messages').add({
        'senderId': u.uid,
        'senderName': _displayName,
        'type': 'location',
        'lat': lat,
        'lng': lng,
        'text': 'موقعي الحالي',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ---------------------------------------------------------------- alerts
  Stream<QuerySnapshot<Map<String, dynamic>>> alerts(String gid) => groups
      .doc(gid)
      .collection('alerts')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots();

  Future<void> resolveAlert(String gid, String alertId) async {
    final u = user;
    await groups.doc(gid).collection('alerts').doc(alertId).update({
      'status': 'resolved',
      'resolvedBy': u.uid,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // --------------------------------------------------------- live location
  DocumentReference<Map<String, dynamic>> _locRef(String gid) =>
      groups.doc(gid).collection('locations').doc(user.uid);

  Stream<QuerySnapshot<Map<String, dynamic>>> locations(String gid) =>
      groups.doc(gid).collection('locations').snapshots();

  /// [expiresAt] ثابت طوال جلسة المشاركة (بحد أقصى 8 ساعات).
  Future<void> publishLocation(
      String gid, double lat, double lng, DateTime expiresAt) async {
    final u = user;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return;
    await _locRef(gid).set({
      'userId': u.uid,
      'userName': _displayName,
      'lat': lat,
      'lng': lng,
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt.toUtc()),
    });
  }

  Future<void> stopSharing(String gid) => _locRef(gid).delete();

  // --------------------------------------------------------------- members
  Stream<DocumentSnapshot<Map<String, dynamic>>> group(String gid) =>
      groups.doc(gid).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> members(String gid) =>
      groups.doc(gid).collection('members').snapshots();

  /// يسجّل اسم العضو لعرضه في قائمة الأعضاء (يُستدعى عند فتح المحادثة).
  Future<void> ensureMemberDoc(String gid) async {
    final u = user;
    final ref = groups.doc(gid).collection('members').doc(u.uid);
    final snap = await ref.get();
    if (snap.exists && snap.data()?['userName'] == _displayName) return;
    await ref.set({
      'userName': _displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> promoteToAdmin(String gid, String uid) async {
    user;
    await groups.doc(gid).update({
      'adminIds': FieldValue.arrayUnion([uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _removeFromGroup(String gid, String uid) async {
    final g = groups.doc(gid);
    final batch = db.batch();
    batch.update(g, {
      'memberIds': FieldValue.arrayRemove([uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.delete(g.collection('members').doc(uid));
    batch.delete(g.collection('join_requests').doc(uid));
    batch.delete(g.collection('locations').doc(uid));
    await batch.commit();
  }

  Future<void> removeMember(String gid, String uid) async {
    user;
    await _removeFromGroup(gid, uid);
  }

  Future<void> leaveGroup(String gid) async {
    final u = user;
    await _removeFromGroup(gid, u.uid);
  }

  // --------------------------------------------------------- announcements
  Stream<QuerySnapshot<Map<String, dynamic>>> announcements(String gid) =>
      groups
          .doc(gid)
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots();

  Future<void> postAnnouncement(String gid, String text) async {
    final u = user;
    final t = text.trim();
    if (t.isEmpty || t.length > 500) {
      throw StateError('الإعلان من 1 إلى 500 حرف');
    }
    await groups.doc(gid).collection('announcements').add({
      'text': t,
      'senderId': u.uid,
      'senderName': _displayName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAnnouncement(String gid, String id) async {
    user;
    await groups.doc(gid).collection('announcements').doc(id).delete();
  }

  // ----------------------------------------------------------------- media
  Future<Uint8List> fetchMedia(String gid, String mediaId) async {
    final d = await groups.doc(gid).collection('media').doc(mediaId).get();
    final data = d.data()?['data'] as String?;
    if (data == null) throw StateError('الملف غير متاح');
    return base64Decode(data);
  }

  Future<void> sendImage(String gid, Uint8List bytes, {String caption = ''}) async {
    final u = user;
    if (bytes.length > 650 * 1024) {
      throw StateError('الصورة كبيرة، اختر صورة أصغر');
    }
    final mediaRef = groups.doc(gid).collection('media').doc();
    final msgRef = groups.doc(gid).collection('messages').doc();
    final batch = db.batch();
    batch.set(mediaRef, {
      'senderId': u.uid,
      'kind': 'image',
      'mime': 'image/jpeg',
      'data': base64Encode(bytes),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(msgRef, {
      'senderId': u.uid,
      'senderName': _displayName,
      'type': 'image',
      'text': caption.trim(),
      'mediaId': mediaRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> sendVoice(String gid, Uint8List bytes, int durationMs) async {
    final u = user;
    if (bytes.length > 440 * 1000) {
      throw StateError('التسجيل طويل، الحد الأقصى دقيقة واحدة');
    }
    final mediaRef = groups.doc(gid).collection('media').doc();
    final msgRef = groups.doc(gid).collection('messages').doc();
    final batch = db.batch();
    batch.set(mediaRef, {
      'senderId': u.uid,
      'kind': 'voice',
      'mime': 'audio/mp4',
      'data': base64Encode(bytes),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(msgRef, {
      'senderId': u.uid,
      'senderName': _displayName,
      'type': 'voice',
      'text': '',
      'mediaId': mediaRef.id,
      'durationMs': durationMs,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> deleteMessage(String gid, String mid, {String? mediaId}) async {
    user;
    final batch = db.batch();
    batch.delete(groups.doc(gid).collection('messages').doc(mid));
    if (mediaId != null && mediaId.isNotEmpty) {
      batch.delete(groups.doc(gid).collection('media').doc(mediaId));
    }
    await batch.commit();
  }
}