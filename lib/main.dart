import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'services/message_notification_service.dart';
import 'services/community/community_reply_bridge.dart';
import 'screens/community/community_screen.dart';
import 'screens/groups/friends_screen.dart';
import 'screens/auth/flow_screen.dart';
import 'screens/groups/direct_chat_screen.dart';
import 'screens/groups/groups_screen.dart' show GroupChatScreen;
import 'state/app_state.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> _openNotification(Map<String, String> data) async {
  final user = FirebaseAuth.instance.currentUser;
  final navigator = appNavigatorKey.currentState;
  if (user == null ||
      user.isAnonymous ||
      !user.emailVerified ||
      navigator == null) {
    return;
  }

  try {
    if (data['type'] == 'direct_message') {
      final chatId = data['chatId'];
      var friendUid = data['friendUid'];
      var friendName = data['friendName'];

      if ((friendUid == null || friendUid.isEmpty) && chatId != null) {
        final chat = await FirebaseFirestore.instance
            .collection('direct_chats')
            .doc(chatId)
            .get();
        final participants = (chat.data()?['participantIds'] as List?)
                ?.whereType<String>()
                .toList() ??
            [];
        final otherParticipants =
            participants.where((uid) => uid != user.uid).toList();
        friendUid = otherParticipants.isEmpty ? null : otherParticipants.first;
      }
      if (friendUid == null || friendUid.isEmpty) return;

      if (friendName == null || friendName.isEmpty) {
        final friend = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('friends')
            .doc(friendUid)
            .get();
        friendName = friend.data()?['name']?.toString() ?? 'صديق';
      }
      if (!navigator.mounted) return;
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => DirectChatScreen(
            friendUid: friendUid!,
            friendName: friendName!,
          ),
        ),
      );
      return;
    }

    if (data['type'] == 'community_reply' || data['type'] == 'community_activity') {
      final postId = data['postId'];
      final notificationId = data['notificationId'];
      if (notificationId != null && notificationId.isNotEmpty) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid)
            .collection('community_notifications').doc(notificationId)
            .update({'read': true});
        } catch (error) {
          debugPrint('[Rifqa] mark notification read: $error');
        }
      }
      if (data['kind'] == 'friend_request') {
        navigator.push(MaterialPageRoute<void>(
          builder: (_) => const FriendsScreen(),
        ));
        return;
      }
      if (postId == null || postId.isEmpty) return;
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => CommunityScreen(initialPostId: postId),
      ));
      return;
    }
    final type = data['type'];
    if (type != 'group_message' &&
        type != 'group_announcement' &&
        type != 'lost_pilgrim') {
      return;
    }
    final groupId = data['groupId'];
    if (groupId == null || groupId.isEmpty) return;

    final groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .get();
    final group = groupSnapshot.data();
    if (group == null) return;
    final members =
        (group['memberIds'] as List?)?.whereType<String>() ?? const <String>[];
    if (!members.contains(user.uid)) return;
    final admins =
        (group['adminIds'] as List?)?.whereType<String>() ?? const <String>[];
    if (!navigator.mounted) return;
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => GroupChatScreen(
          groupId: groupId,
          groupName: group['name']?.toString() ?? 'رفقتي',
          isAdmin: admins.contains(user.uid),
        ),
      ),
    );
  } catch (error) {
    debugPrint('[Rifqa Notifications] open notification failed: $error');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  MessageNotificationService.instance
      .setNotificationTapHandler(_openNotification);

  final state = AppState();
  await state.load();

  runApp(AppScope(state: state, child: const RafeeqApp()));

  // The Navigator must exist before handling taps from a cold launch.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    MessageNotificationService.instance.markAppReady();
  });

  unawaited(
    MessageNotificationService.instance.initialize().then((_) {
      CommunityReplyBridge.instance.start();
    }).catchError((Object error) {
      debugPrint('Message notifications unavailable: $error');
    }),
  );
}

class RafeeqApp extends StatelessWidget {
  const RafeeqApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'رفيق المعتمر',
      locale: const Locale('ar'),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const FlowScreen(),
      navigatorKey: appNavigatorKey,
    );
  }
}
