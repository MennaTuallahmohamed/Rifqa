// lib/services/haramain/rifqa_history_service.dart
//
// pubspec.yaml: cloud_firestore, firebase_auth
//
// البنية (خاصة بكل مستخدم، فقواعد الحماية أبسط وأأمن):
//   users/{uid}/ai_conversations/{cid}            ← العنوان + آخر تحديث
//   users/{uid}/ai_conversations/{cid}/messages/{mid}
//
// قواعد Firestore (ضيفيها في firestore.rules):
//
//   match /users/{uid}/ai_conversations/{cid} {
//     allow read, write: if request.auth != null && request.auth.uid == uid;
//     match /messages/{mid} {
//       allow read: if request.auth != null && request.auth.uid == uid;
//       allow create: if request.auth != null && request.auth.uid == uid
//                     && request.resource.data.text is string
//                     && request.resource.data.text.size() < 4000;
//       allow delete: if request.auth != null && request.auth.uid == uid;
//     }
//   }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.title,
    required this.preview,
    required this.updatedAt,
  });
  final String id;
  final String title;
  final String preview;
  final DateTime updatedAt;
}

class StoredMessage {
  const StoredMessage({
    required this.text,
    required this.isUser,
    this.fromAi = false,
    this.sos = false,
    required this.time,
  });
  final String text;
  final bool isUser;
  final bool fromAi;
  final bool sos;
  final DateTime time;
}

class RifqaHistoryService {
  RifqaHistoryService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// يرجع null لو المستخدم مش مسجّل دخول (وقتها المحادثة لا تُحفظ).
  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('ai_conversations');
  }

  bool get isAvailable => _col != null;

  Future<String?> create(String firstQuestion) async {
    final col = _col;
    if (col == null) return null;
    final title = firstQuestion.length > 45
        ? '${firstQuestion.substring(0, 45)}…'
        : firstQuestion;
    final doc = col.doc();
    // لا ننتظر السيرفر: Firestore يخزّن محليًا ويرفع لما النت يرجع.
    doc.set({
      'title': title,
      'preview': firstQuestion,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> addMessage(String conversationId, StoredMessage m) async {
    final col = _col;
    if (col == null) return;
    final convo = col.doc(conversationId);
    convo.collection('messages').add({
      'text': m.text,
      'isUser': m.isUser,
      'fromAi': m.fromAi,
      'sos': m.sos,
      'createdAt': Timestamp.fromDate(m.time),
    });
    convo.set({
      'preview': m.text.length > 90 ? '${m.text.substring(0, 90)}…' : m.text,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<ConversationSummary>> watch() {
    final col = _col;
    if (col == null) return Stream.value(const []);
    return col
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              final ts = data['updatedAt'];
              return ConversationSummary(
                id: d.id,
                title: (data['title'] as String?) ?? 'محادثة',
                preview: (data['preview'] as String?) ?? '',
                updatedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
              );
            }).toList());
  }

  Future<List<StoredMessage>> load(String conversationId) async {
    final col = _col;
    if (col == null) return const [];
    final snap = await col
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .limit(200)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return StoredMessage(
        text: (data['text'] as String?) ?? '',
        isUser: (data['isUser'] as bool?) ?? false,
        fromAi: (data['fromAi'] as bool?) ?? false,
        sos: (data['sos'] as bool?) ?? false,
        time: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  Future<void> delete(String conversationId) async {
    final col = _col;
    if (col == null) return;
    final convo = col.doc(conversationId);
    final msgs = await convo.collection('messages').limit(450).get();
    final batch = _db.batch();
    for (final d in msgs.docs) {
      batch.delete(d.reference);
    }
    batch.delete(convo);
    await batch.commit();
  }

  Future<void> clearAll() async {
    final col = _col;
    if (col == null) return;
    final all = await col.limit(50).get();
    for (final d in all.docs) {
      await delete(d.id);
    }
  }
}