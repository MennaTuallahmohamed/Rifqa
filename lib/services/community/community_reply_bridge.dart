import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../message_notification_service.dart';

/// Streams durable reply alerts and shows local OS alerts only while the app
/// is in foreground. Background push requires a trusted FCM sender.
class CommunityReplyBridge {
  CommunityReplyBridge._();
  static final instance = CommunityReplyBridge._();
  StreamSubscription<User?>? _auth;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _replies;
  String? _uid;
  int _generation = 0;
  final Set<String> _shown = {};

  void start() {
    if (_auth != null) return;
    _auth = FirebaseAuth.instance.idTokenChanges().listen((user) {
      final uid = user != null && !user.isAnonymous && user.emailVerified
          ? user.uid : null;
      if (uid == _uid) return;
      _uid = uid;
      final generation = ++_generation;
      unawaited(_replies?.cancel());
      _replies = null;
      _shown.clear();
      if (uid == null) return;
      final subscribedAt = DateTime.now().subtract(const Duration(seconds: 1));
      _replies = FirebaseFirestore.instance.collection('users').doc(uid)
          .collection('community_notifications')
          .orderBy('createdAt', descending: true).limit(30)
          .snapshots().listen((snapshot) {
        if (generation != _generation) return;
        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added ||
              change.doc.metadata.hasPendingWrites) continue;
          final data = change.doc.data();
          if (data == null || data['read'] == true) continue;
          final time = data['createdAt'];
          if (time is! Timestamp || time.toDate().isBefore(subscribedAt)) continue;
          if (!_shown.add(change.doc.id)) continue;
          if (_shown.length > 200) _shown.clear();
          unawaited(MessageNotificationService.instance.showCommunityReply(
            senderName: data['senderName']?.toString() ?? 'عضو رفقة',
            preview: data['body']?.toString() ?? 'رد جديد',
            postId: data['postId']?.toString() ?? '',
            kind: data['kind']?.toString() ?? 'comment',
            notificationId: change.doc.id,
          ));
        }
      }, onError: (Object e) {
        debugPrint('[Rifqa Community] reply notification listener: $e');
      });
    });
  }

  Future<void> dispose() async {
    ++_generation;
    await _replies?.cancel();
    await _auth?.cancel();
    _uid = null;
    _auth = null;
    _replies = null;
    _shown.clear();
  }
}
