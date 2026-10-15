

import 'dart:convert';
import '../../services/message_notification_service.dart';

import 'dart:math';

import 'dart:typed_data';



import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';



class FriendService {

  FriendService._();



  static final FriendService instance = FriendService._();



  final FirebaseFirestore db = FirebaseFirestore.instance;

  final FirebaseAuth auth = FirebaseAuth.instance;



  User get user {

    final u = auth.currentUser;



    if (u == null || u.isAnonymous || !u.emailVerified) {

      throw StateError(

        'يجب تسجيل الدخول بحساب مؤكّد البريد أولاً',

      );

    }



    return u;

  }



  String get _name =>

      user.displayName ?? user.email ?? 'عضو';



  Future<void> _refresh() async {

    final currentUser = auth.currentUser;



    if (currentUser == null) return;



    try {

      await currentUser.reload();

      await auth.currentUser?.getIdToken(true);

    } catch (_) {

      // The next Firebase request will report any connection errors.

    }

  }



  CollectionReference<Map<String, dynamic>> get codes =>

      db.collection('friend_codes');



  CollectionReference<Map<String, dynamic>> get requests =>

      db.collection('friend_requests');



  CollectionReference<Map<String, dynamic>> get directChats =>

      db.collection('direct_chats');



  CollectionReference<Map<String, dynamic>> _friends(String uid) =>

      db.collection('users').doc(uid).collection('friends');



  // ============================================================

  // DIRECT CHAT

  // ============================================================



  Future<String> openDirectChat(String friendUid) async {

    await _refresh();



    final currentUser = user;



    if (friendUid == currentUser.uid) {

      throw StateError('لا يمكنك بدء محادثة مع نفسك');

    }



    // Check that the friend exists in the current user's friends list.

    final friendDoc =

        await _friends(currentUser.uid).doc(friendUid).get();



    if (!friendDoc.exists) {

      throw StateError('هذا المستخدم ليس ضمن أصدقائك');

    }



    // Both users always generate the same chat ID.

    final participantIds = [

      currentUser.uid,

      friendUid,

    ]..sort();



    final chatId = participantIds.join('_');

    final chatRef = directChats.doc(chatId);



    try {

      // Try to create the chat without reading a missing document.

      await chatRef.set({

        'participantIds': participantIds,

        'createdAt': FieldValue.serverTimestamp(),

      });

    } on FirebaseException catch (e) {

      if (e.code != 'permission-denied') {

        rethrow;

      }



      // Firestore rules prevent overwriting an existing chat.

      // Check whether it already belongs to these two users.

      final existing = await chatRef.get();

      final data = existing.data();



      if (data == null) {

        rethrow;

      }



      final existingParticipants =

          List<String>.from(data['participantIds'] ?? []);



      if (existingParticipants.length != 2 ||

          !existingParticipants.contains(currentUser.uid) ||

          !existingParticipants.contains(friendUid)) {

        throw StateError(

          'لا يمكنك فتح هذه المحادثة',

        );

      }

    }



    MessageNotificationService.instance.watchNewDirectChat(chatId, friendUid);
    return chatId;

  }



  Stream<QuerySnapshot<Map<String, dynamic>>> directMessages(

    String chatId,

  ) {

    return directChats

        .doc(chatId)

        .collection('messages')

        .orderBy('createdAt', descending: true)

        .limit(80)

        .snapshots();

  }



  Future<Uint8List> fetchDirectMedia(String chatId, String mediaId) async {

    final snapshot =

        await directChats.doc(chatId).collection('media').doc(mediaId).get();

    final data = snapshot.data()?['data'] as String?;

    if (data == null) throw StateError('الملف غير متاح');

    return base64Decode(data);

  }



  Future<void> sendDirectMessage(

    String chatId,

    String text,

  ) async {

    final currentUser = user;

    final content = text.trim();



    if (content.isEmpty || content.length > 2000) {

      return;

    }



    await directChats.doc(chatId).collection('messages').add({

      'senderId': currentUser.uid,

      'senderName': _name,

      'text': content,

      'createdAt': FieldValue.serverTimestamp(),

    });

  }



  Future<void> sendDirectImage(

    String chatId,

    Uint8List bytes, {

    String caption = '',

  }) async {

    final currentUser = user;

    if (bytes.length > 650 * 1024) {

      throw StateError('الصورة كبيرة، اختاري صورة أصغر');

    }

    if (caption.trim().length > 500) {

      throw StateError('التعليق أطول من المسموح');

    }



    final chat = directChats.doc(chatId);

    final mediaRef = chat.collection('media').doc();

    final messageRef = chat.collection('messages').doc();

    final batch = db.batch();

    batch.set(mediaRef, {

      'senderId': currentUser.uid,

      'kind': 'image',

      'mime': 'image/jpeg',

      'data': base64Encode(bytes),

      'messageId': messageRef.id,

      'createdAt': FieldValue.serverTimestamp(),

    });

    batch.set(messageRef, {

      'senderId': currentUser.uid,

      'senderName': _name,

      'type': 'image',

      'text': caption.trim(),

      'mediaId': mediaRef.id,

      'createdAt': FieldValue.serverTimestamp(),

    });

    await batch.commit();

  }



  Future<void> sendDirectVoice(

    String chatId,

    Uint8List bytes,

    int durationMs,

  ) async {

    final currentUser = user;

    if (bytes.length > 440 * 1000) {

      throw StateError('التسجيل طويل، الحد الأقصى دقيقة واحدة');

    }

    if (durationMs < 800 || durationMs > 65000) {

      throw StateError('مدة التسجيل غير صحيحة');

    }



    final chat = directChats.doc(chatId);

    final mediaRef = chat.collection('media').doc();

    final messageRef = chat.collection('messages').doc();

    final batch = db.batch();

    batch.set(mediaRef, {

      'senderId': currentUser.uid,

      'kind': 'voice',

      'mime': 'audio/mp4',

      'data': base64Encode(bytes),

      'messageId': messageRef.id,

      'createdAt': FieldValue.serverTimestamp(),

    });

    batch.set(messageRef, {

      'senderId': currentUser.uid,

      'senderName': _name,

      'type': 'voice',

      'text': '',

      'mediaId': mediaRef.id,

      'durationMs': durationMs,

      'createdAt': FieldValue.serverTimestamp(),

    });

    await batch.commit();

  }



  // ============================================================

  // FRIEND CODES

  // ============================================================



  String _newCode() {

    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    final random = Random.secure();



    return List.generate(

      8,

      (_) => chars[random.nextInt(chars.length)],

    ).join();

  }



  /// Creates a permanent friend code or returns the existing one.

  Future<String> myCode() async {

    await _refresh();



    final currentUser = user;



    final existing = await codes

        .where('uid', isEqualTo: currentUser.uid)

        .limit(1)

        .get();



    if (existing.docs.isNotEmpty) {

      return existing.docs.first.id;

    }



    for (var i = 0; i < 5; i++) {

      final code = _newCode();

      final ref = codes.doc(code);



      final created = await db.runTransaction<bool>(

        (transaction) async {

          final snapshot = await transaction.get(ref);



          if (snapshot.exists) {

            return false;

          }



          transaction.set(ref, {

            'uid': currentUser.uid,

            'displayName': _name,

            'createdAt': FieldValue.serverTimestamp(),

          });



          return true;

        },

      );



      if (created) {

        return code;

      }

    }



    throw StateError(

      'تعذر إنشاء كود الصداقة، حاولي مجددًا',

    );

  }



  // ============================================================

  // ADD FRIEND BY CODE

  // ============================================================



  Future<String> addByCode(String rawCode) async {

    await _refresh();



    final currentUser = user;



    final code = rawCode

        .trim()

        .toUpperCase()

        .replaceAll(' ', '');



    if (code.length != 8) {

      throw StateError(

        'كود الصديق يتكوّن من 8 خانات',

      );

    }



    final snapshot = await codes.doc(code).get();

    final data = snapshot.data();



    if (data == null) {

      throw StateError('كود الصديق غير صحيح');

    }



    final toUid = data['uid'] as String;

    final toName =

        (data['displayName'] ?? 'عضو').toString();



    if (toUid == currentUser.uid) {

      throw StateError(

        'ده كودك أنتِ 😄 شاركيه مع شخص آخر',

      );

    }



    final alreadyFriend =

        await _friends(currentUser.uid).doc(toUid).get();



    if (alreadyFriend.exists) {

      throw StateError(

        'أنتم أصدقاء بالفعل',

      );

    }



    // If this user has already sent an incoming friend request,

    // accept that request instead of creating another one.

    final incomingRequest = await requests

        .where('fromUid', isEqualTo: toUid)

        .where('toUid', isEqualTo: currentUser.uid)

        .where('status', isEqualTo: 'pending')

        .limit(1)

        .get();



    if (incomingRequest.docs.isNotEmpty) {

      await accept(

        incomingRequest.docs.first.id,

        toUid,

        toName,

      );



      return 'تمت الصداقة مع $toName 🎉';

    }



    try {

      await requests

          .doc('${currentUser.uid}_$toUid')

          .set({

        'fromUid': currentUser.uid,

        'fromName': _name,

        'toUid': toUid,

        'toName': toName,

        'status': 'pending',

        'createdAt': FieldValue.serverTimestamp(),

      });

    } on FirebaseException catch (e) {

      if (e.code == 'permission-denied') {

        throw StateError(

          'يوجد طلب سابق بينكما، أو تعذر إرسال الطلب',

        );

      }



      rethrow;

    }



    return 'اتبعت طلب الصداقة إلى $toName';

  }



  // ============================================================

  // ACCEPT FRIEND REQUEST

  // ============================================================



  Future<void> accept(

    String requestId,

    String fromUid,

    String fromName,

  ) async {

    final currentUser = user;

    final batch = db.batch();



    batch.update(

      requests.doc(requestId),

      {'status': 'accepted'},

    );



    // Save the friendship in both users' documents atomically.

    batch.set(

      _friends(currentUser.uid).doc(fromUid),

      {

        'name': fromName,

        'createdAt': FieldValue.serverTimestamp(),

        'rid': requestId,

      },

    );



    batch.set(

      _friends(fromUid).doc(currentUser.uid),

      {

        'name': _name,

        'createdAt': FieldValue.serverTimestamp(),

        'rid': requestId,

      },

    );



    await batch.commit();

  }



  // ============================================================

  // DELETE / REJECT FRIEND REQUEST

  // ============================================================



  Future<void> deleteRequest(String requestId) async {

    user;



    await requests.doc(requestId).delete();

  }



  // ============================================================

  // REMOVE FRIEND

  // ============================================================



  Future<void> removeFriend(String friendUid) async {

    final currentUser = user;



    final friendship =

        await _friends(currentUser.uid).doc(friendUid).get();



    final requestId = friendship.data()?['rid'] as String?;



    final batch = db.batch();



    batch.delete(

      _friends(currentUser.uid).doc(friendUid),

    );



    batch.delete(

      _friends(friendUid).doc(currentUser.uid),

    );



    if (requestId != null) {

      batch.delete(requests.doc(requestId));

    }



    await batch.commit();

  }



  // ============================================================

  // REALTIME STREAMS

  // ============================================================



  Stream<QuerySnapshot<Map<String, dynamic>>> friends() {

    return _friends(user.uid)

        .orderBy('createdAt', descending: true)

        .snapshots();

  }



  Stream<QuerySnapshot<Map<String, dynamic>>> incoming() {

    return requests

        .where('toUid', isEqualTo: user.uid)

        .where('status', isEqualTo: 'pending')

        .snapshots();

  }



  Stream<QuerySnapshot<Map<String, dynamic>>> outgoing() {

    return requests

        .where('fromUid', isEqualTo: user.uid)

        .where('status', isEqualTo: 'pending')

        .snapshots();

  }

}
