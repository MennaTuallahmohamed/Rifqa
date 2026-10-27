import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Group invitations by an existing 8-character friend code.
/// An invite never gives administrative privileges and cannot add
/// someone to a group without their explicit acceptance.
class GroupFriendInviteService {
  GroupFriendInviteService._();
  static final instance = GroupFriendInviteService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User get _user {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous || !user.emailVerified) {
      throw StateError('يلزم تسجيل الدخول بحساب مؤكد البريد أولاً');
    }
    return user;
  }

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('group_friend_invites');

  Stream<QuerySnapshot<Map<String, dynamic>>> myInvitations() =>
      _requests.where('toUid', isEqualTo: _user.uid).snapshots();

  Future<String> inviteByFriendCode(String groupId, String rawCode) async {
    final me = _user;
    final code = rawCode.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^[A-HJ-NP-Z2-9]{8}$').hasMatch(code)) {
      throw StateError('كود الصديق يتكون من 8 حروف أو أرقام');
    }

    final friend = await _db.collection('friend_codes').doc(code).get();
    final fd = friend.data();
    if (fd == null || fd['uid'] is! String) {
      throw StateError('كود الصديق غير صحيح');
    }
    final friendUid = fd['uid'] as String;
    if (friendUid == me.uid) {
      throw StateError('لا يمكنك دعوة نفسك');
    }
    final friendName = (fd['displayName'] ?? 'صديق').toString();

    final group = await _db.collection('groups').doc(groupId).get();
    final gd = group.data();
    if (gd == null || !(List.from(gd['adminIds'] ?? []).contains(me.uid))) {
      throw StateError('إرسال دعوات المجموعة متاح للمشرف فقط');
    }
    if (List.from(gd['memberIds'] ?? []).contains(friendUid)) {
      throw StateError('هذا الصديق عضو في المجموعة بالفعل');
    }

    final ref = _requests.doc('${groupId}_$friendUid');
    final old = await ref.get();
    final expiresAt = Timestamp.fromDate(
      DateTime.now().toUtc().add(const Duration(hours: 48)),
    );

    if (old.exists) {
      final oldData = old.data()!;
      final expiry = oldData['expiresAt'];
      final active = oldData['status'] == 'pending' &&
          expiry is Timestamp &&
          expiry.toDate().isAfter(DateTime.now());
      if (active) {
        throw StateError('الدعوة أُرسلت بالفعل ولم تنته صلاحيتها');
      }
      if (oldData['status'] == 'accepted') {
        throw StateError('سبق قبول هذه الدعوة');
      }
      await ref.update({
        'status': 'pending',
        'friendCode': code,
        'fromUid': me.uid,
        'fromName': me.displayName ?? me.email ?? 'مشرف المجموعة',
        'groupName': (gd['name'] ?? 'مجموعة').toString(),
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
      });
    } else {
      await ref.set({
        'groupId': groupId,
        'groupName': (gd['name'] ?? 'مجموعة').toString(),
        'friendCode': code,
        'fromUid': me.uid,
        'fromName': me.displayName ?? me.email ?? 'مشرف المجموعة',
        'toUid': friendUid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
      });
    }
    return 'تم إرسال دعوة إلى $friendName، في انتظار موافقته';
  }

  Future<void> accept(String invitationId) async {
    final me = _user;
    final ref = _requests.doc(invitationId);
    final data = (await ref.get()).data();
    if (data == null || data['toUid'] != me.uid || data['status'] != 'pending') {
      throw StateError('الدعوة غير متاحة');
    }
    final expiresAt = data['expiresAt'];
    if (expiresAt is! Timestamp || expiresAt.toDate().isBefore(DateTime.now())) {
      throw StateError('الدعوة انتهت صلاحيتها. اطلب دعوة جديدة');
    }
    final groupId = data['groupId'] as String;
    final groupRef = _db.collection('groups').doc(groupId);
    final batch = _db.batch();
    batch.update(groupRef, {
      'memberIds': FieldValue.arrayUnion([me.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(ref, {'status': 'accepted'});
    await batch.commit();
  }

  Future<void> reject(String invitationId) async {
    final me = _user;
    final ref = _requests.doc(invitationId);
    final data = (await ref.get()).data();
    if (data == null || data['toUid'] != me.uid || data['status'] != 'pending') {
      throw StateError('الدعوة غير متاحة');
    }
    await ref.update({'status': 'rejected'});
  }
}
