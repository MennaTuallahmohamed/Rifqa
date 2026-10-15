import 'dart:async';

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter/widgets.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Free foreground notifications from Firestore listeners.

/// A trusted FCM sender is still required for background/terminated push.

class MessageNotificationService with WidgetsBindingObserver {
  MessageNotificationService._();

  static final instance = MessageNotificationService._();

  static const _channelId = 'rifqa_messages';

  static const _channelName = 'Ø±Ø³Ø§Ø¦Ù„ Ø±ÙÙÙ‚Ø©';

  // Cloudflare Worker endpoint. Never put Firebase service account secrets here.
  static const _pushRelay =
      'https://long-heart-750frifqa-notifications.mohamedmenna139.workers.dev/notify';
  final Set<String> _dispatchedMessages = {};

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _messageSubscriptions = {};

  final Set<String> _seededGroups = {};

  final Map<String, DateTime> _listenStartedAt = {};

  final Set<String> _shownMessages = {};

  // Direct messages: Firestore rules prohibit listing direct_chats.
  // Discover permitted chat IDs from the owner's friends instead.
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _directSubscriptions = {};
  final Map<String, String> _directFriendNames = {};
  final Set<String> _directChecking = {};
  final Map<String, DateTime> _directListeningSince = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _friendsSubscription;
  Set<String> _currentFriendIds = {};

  StreamSubscription<User?>? _authSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _groupsSubscription;

  StreamSubscription<String>? _tokenSubscription;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  StreamSubscription<RemoteMessage>? _openedSubscription;

  bool _initialized = false;

  bool _appReady = false;

  bool _notificationsAllowed = false;

  bool _isForeground = true;

  String? _registeredUid;

  String? _registeredToken;

  String? _watchingUid;

  int _watchGeneration = 0;

  Future<void> Function(Map<String, String>)? _tapHandler;

  Map<String, String>? _pendingTap;

  void setNotificationTapHandler(
    Future<void> Function(Map<String, String>) handler,
  ) {
    _tapHandler = handler;

    _dispatchPendingTap();
  }

  void markAppReady() {
    _appReady = true;

    _dispatchPendingTap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (_isForeground && _watchingUid != null) {
      // Newly created direct chats may not have existed on first login.
      unawaited(_refreshDirectChats(_watchingUid!, _watchGeneration));
    }
    debugPrint('[Rifqa Notifications] foreground=$_isForeground');
  }

  void _dispatchPendingTap() {
    final pending = _pendingTap;

    final handler = _tapHandler;

    if (!_appReady || pending == null || handler == null) return;

    _pendingTap = null;

    unawaited(handler(pending));
  }

  Future<void> _openData(Map<String, dynamic> data) async {
    if (data.isEmpty) return;

    final payload = data.map((key, value) => MapEntry(key, value.toString()));

    final handler = _tapHandler;

    if (!_appReady || handler == null) {
      _pendingTap = payload;

      return;
    }

    await handler(payload);
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;

    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);

      if (decoded is Map) {
        unawaited(_openData(Map<String, dynamic>.from(decoded)));
      }
    } catch (error) {
      debugPrint('Invalid notification payload: $error');
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;

    WidgetsBinding.instance.addObserver(this);

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _local.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final localLaunch = await _local.getNotificationAppLaunchDetails();

    if (localLaunch?.didNotificationLaunchApp == true) {
      final response = localLaunch?.notificationResponse;

      if (response != null) _onNotificationTap(response);
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description:
                  'Ø±Ø³Ø§Ø¦Ù„ Ø§Ù„Ø£ØµØ¯Ù‚Ø§Ø¡ ÙˆØ§Ù„Ù…Ø¬Ù…ÙˆØ¹Ø§Øª ÙˆØ¨Ù„Ø§ØºØ§Øª Ø§Ù„Ø§Ø³ØªØºØ§Ø«Ø©',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
    }

    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    _notificationsAllowed =
        permission.authorizationStatus == AuthorizationStatus.authorized ||
            permission.authorizationStatus == AuthorizationStatus.provisional;

    _tokenSubscription = _messaging.onTokenRefresh.listen((_) {
      unawaited(_saveToken());
    });

    _authSubscription = FirebaseAuth.instance.idTokenChanges().listen((user) {
      unawaited(_onAuthChanged(user));
    });

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      unawaited(_showForegroundNotification(message));
    });

    _openedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(_openData(message.data));
    });

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) await _openData(initialMessage.data);

    if (_notificationsAllowed) await _saveToken();
  }

  Future<void> _onAuthChanged(User? user) async {
    final uid = user != null && !user.isAnonymous && user.emailVerified
        ? user.uid
        : null;

    debugPrint('[Rifqa Notifications] auth verified user=${uid != null}');
    if (uid != _watchingUid) {
      _watchingUid = uid;

      final generation = ++_watchGeneration;

      await _groupsSubscription?.cancel();
      await _friendsSubscription?.cancel();
      _friendsSubscription = null;
      for (final sub in _directSubscriptions.values) {
        await sub.cancel();
      }
      _directSubscriptions.clear();
      _directChecking.clear();
      _directFriendNames.clear();
      _directListeningSince.clear();
      _currentFriendIds = {};

      _groupsSubscription = null;

      for (final sub in _messageSubscriptions.values) {
        await sub.cancel();
      }

      _messageSubscriptions.clear();

      _seededGroups.clear();

      _listenStartedAt.clear();

      _shownMessages.clear();
      _dispatchedMessages.clear();

      if (generation == _watchGeneration && uid != null) {
        _subscribeToGroups(uid, generation);
        _subscribeToFriends(uid, generation);
      }
    }

    await _saveToken();
  }

  void _subscribeToGroups(String uid, int generation) {
    _groupsSubscription = FirebaseFirestore.instance
        .collection('groups')
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .listen((snapshot) {
      if (generation != _watchGeneration) return;
      debugPrint('[Rifqa Notifications] groups=${snapshot.docs.length}');

      final present = snapshot.docs.map((d) => d.id).toSet();

      for (final id in _messageSubscriptions.keys.toList()) {
        if (!present.contains(id)) {
          unawaited(_messageSubscriptions.remove(id)?.cancel());

          _seededGroups.remove(id);

          _listenStartedAt.remove(id);
        }
      }

      for (final group in snapshot.docs) {
        if (_messageSubscriptions.containsKey(group.id)) continue;

        final groupId = group.id;
        debugPrint('[Rifqa Notifications] watching group=$groupId');

        _listenStartedAt[groupId] =
            DateTime.now().subtract(const Duration(seconds: 2));

        final groupName = group.data()['name']?.toString() ?? 'Ø±ÙÙ‚ØªÙŠ';

        _messageSubscriptions[groupId] = FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .snapshots()
            .listen((messages) {
          if (generation != _watchGeneration) return;

          _seededGroups.add(groupId);
          debugPrint(
              '[Rifqa Notifications] group=$groupId changes=${messages.docChanges.length}');
          for (final change in messages.docChanges) {
            final document = change.doc;

            if (document.metadata.hasPendingWrites) continue;

            final data = document.data();

            if (data == null) continue;
            if (data['createdAt'] is! Timestamp) continue;
            if (data['senderId'] == uid) {
              // Firestore serverTimestamp commonly resolves on a modified
              // event, after the local pending-write event.
              if ((data['createdAt'] as Timestamp)
                  .toDate()
                  .isAfter(_listenStartedAt[groupId] ?? DateTime.now())) {
                unawaited(_relayOwnMessage('group', groupId, document.id));
              }
              continue;
            }

            if (!(data['createdAt'] as Timestamp).toDate().isAfter(
                  _listenStartedAt[groupId] ?? DateTime.now(),
                )) {
              continue;
            }

            if (change.type != DocumentChangeType.added) continue;
            final key = '$groupId/${document.id}';

            if (!_shownMessages.add(key)) continue;

            if (_shownMessages.length > 300) _shownMessages.clear();

            if (!_isForeground || !_notificationsAllowed) continue;

            final sender = data['senderName']?.toString() ?? 'Ø¹Ø¶Ùˆ';

            final type = data['type']?.toString() ?? 'text';

            final body = type == 'image'
                ? '$sender: ðŸ“· ØµÙˆØ±Ø© Ø¬Ø¯ÙŠØ¯Ø©'
                : type == 'voice'
                    ? '$sender: ðŸŽ¤ Ø±Ø³Ø§Ù„Ø© ØµÙˆØªÙŠØ©'
                    : type == 'location'
                        ? '$sender: ðŸ“ Ø´Ø§Ø±Ùƒ Ù…ÙˆÙ‚Ø¹Ù‡'
                        : '$sender: ${data['text'] ?? 'Ø±Ø³Ø§Ù„Ø© Ø¬Ø¯ÙŠØ¯Ø©'}';

            debugPrint('[Rifqa Notifications] showing group message=$key');
            unawaited(_showLocal(
              title: groupName,
              body: body,
              data: {'type': 'group_message', 'groupId': groupId},
            ));
          }
        }, onError: (Object error) {
          debugPrint('Group messages listener ($groupId): $error');
        });
      }
    }, onError: (Object error) {
      debugPrint('Group notification listener: $error');
    });
  }

  // ---------------------------------------------------------
  // Foreground-only notifications for existing direct chats.
  // No collection-wide direct_chats query: that is forbidden by our rules.
  // ---------------------------------------------------------
  void _subscribeToFriends(String uid, int generation) {
    _friendsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .listen((snapshot) {
      if (generation != _watchGeneration || uid != _watchingUid) return;
      final present = snapshot.docs.map((doc) => doc.id).toSet();
      _currentFriendIds = present;

      for (final chatId in _directSubscriptions.keys.toList()) {
        final members = chatId.split('_');
        final other = members.where((part) => part != uid).toList();
        if (other.length != 1 || !present.contains(other.single)) {
          unawaited(_directSubscriptions.remove(chatId)?.cancel());
          _directFriendNames.remove(chatId);
          _directListeningSince.remove(chatId);
        }
      }

      for (final friend in snapshot.docs) {
        final friendUid = friend.id;
        if (friendUid == uid) continue;
        final pair = <String>[uid, friendUid]..sort();
        final chatId = pair.join('_');
        _directFriendNames[chatId] =
            friend.data()['name']?.toString() ?? 'ØµØ¯ÙŠÙ‚';
      }
      debugPrint('[Rifqa Notifications] friends=${present.length}');
      unawaited(_refreshDirectChats(uid, generation));
    }, onError: (Object error) {
      debugPrint('[Rifqa Notifications] friends listener error: $error');
    });
  }

  Future<void> _refreshDirectChats(String uid, int generation) async {
    if (generation != _watchGeneration || uid != _watchingUid) return;
    for (final friendUid in _currentFriendIds.toList()) {
      if (friendUid == uid) continue;
      final pair = <String>[uid, friendUid]..sort();
      final chatId = pair.join('_');
      if (_directSubscriptions.containsKey(chatId) ||
          !_directChecking.add(chatId)) {
        continue;
      }
      try {
        // A missing direct chat cannot be read under the current rules.
        // That is normal: many friendships have not opened a chat yet.
        final chat = await FirebaseFirestore.instance
            .collection('direct_chats')
            .doc(chatId)
            .get();
        if (generation != _watchGeneration ||
            uid != _watchingUid ||
            !_currentFriendIds.contains(friendUid) ||
            !chat.exists) {
          continue;
        }
        _watchDirectMessages(chatId, uid, generation);
      } on FirebaseException catch (error) {
        if (error.code != 'permission-denied' && error.code != 'not-found') {
          debugPrint('[Rifqa Notifications] check direct chat failed: $error');
        }
      } catch (error) {
        debugPrint('[Rifqa Notifications] check direct chat failed: $error');
      } finally {
        _directChecking.remove(chatId);
      }
    }
  }

  /// Call after a direct chat is created so its first message can trigger push.
  void watchNewDirectChat(String chatId, String friendUid) {
    final uid = _watchingUid;
    if (uid == null || !_currentFriendIds.contains(friendUid)) return;
    final parts = <String>[uid, friendUid]..sort();
    if (chatId != parts.join('_')) return;
    _watchDirectMessages(chatId, uid, _watchGeneration);
  }

  void _watchDirectMessages(String chatId, String uid, int generation) {
    if (_directSubscriptions.containsKey(chatId)) return;
    // Accept only messages newly sent after starting to watch the chat.
    // Small tolerance protects messages arriving during listener setup.
    _directListeningSince[chatId] =
        DateTime.now().subtract(const Duration(seconds: 2));
    debugPrint('[Rifqa Notifications] watching direct chat=$chatId');
    _directSubscriptions[chatId] = FirebaseFirestore.instance
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      if (generation != _watchGeneration || uid != _watchingUid) return;
      for (final change in snapshot.docChanges) {
        final message = change.doc;
        if (message.metadata.hasPendingWrites) continue;
        final data = message.data();
        if (data == null) continue;
        final timestamp = data['createdAt'];
        if (data['senderId'] == uid) {
          if (timestamp is Timestamp &&
              timestamp
                  .toDate()
                  .isAfter(_directListeningSince[chatId] ?? DateTime.now())) {
            unawaited(_relayOwnMessage('direct', chatId, message.id));
          }
          continue;
        }
        if (change.type != DocumentChangeType.added) continue;
        if (timestamp is! Timestamp ||
            !timestamp.toDate().isAfter(
                  _directListeningSince[chatId] ?? DateTime.now(),
                )) {
          continue;
        }
        final key = 'direct/$chatId/${message.id}';
        if (!_shownMessages.add(key)) continue;
        if (_shownMessages.length > 300) _shownMessages.clear();
        if (!_isForeground || !_notificationsAllowed) continue;

        final senderName = data['senderName']?.toString();
        final title = _directFriendNames[chatId] ??
            (senderName != null && senderName.isNotEmpty
                ? senderName
                : 'Ø±Ø³Ø§Ù„Ø© Ø®Ø§ØµØ©');
        final type = data['type']?.toString() ?? 'text';
        final content = data['text']?.toString() ?? '';
        final body = switch (type) {
          'image' =>
            content.isEmpty ? 'ðŸ“· ØµÙˆØ±Ø© Ø¬Ø¯ÙŠØ¯Ø©' : 'ðŸ“· $content',
          'voice' => 'ðŸŽ¤ Ø±Ø³Ø§Ù„Ø© ØµÙˆØªÙŠØ© Ø¬Ø¯ÙŠØ¯Ø©',
          _ => content.isEmpty ? 'Ø±Ø³Ø§Ù„Ø© Ø¬Ø¯ÙŠØ¯Ø©' : content,
        };
        debugPrint('[Rifqa Notifications] showing direct message=$key');
        unawaited(_showLocal(
          title: title,
          body: body,
          data: {
            'type': 'direct_message',
            'chatId': chatId,
          },
        ).catchError((Object error) {
          debugPrint(
              '[Rifqa Notifications] direct notification failed: $error');
        }));
      }
    }, onError: (Object error) {
      debugPrint('[Rifqa Notifications] direct listener ($chatId): $error');
      unawaited(_directSubscriptions.remove(chatId)?.cancel());
      _directListeningSince.remove(chatId);
    });
  }

  // Only the signed-in sender requests dispatch. The Worker independently
  // verifies the Firebase ID token, message, membership and age, and keeps
  // service account credentials on its server. Spark has no Firestore trigger.
  Future<void> _relayOwnMessage(
      String kind, String chatId, String messageId) async {
    if (kIsWeb || !_isForeground) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || !user.emailVerified) return;
    final key = '$kind/$chatId/$messageId';
    if (!_dispatchedMessages.add(key)) return;
    if (_dispatchedMessages.length > 600) _dispatchedMessages.clear();
    HttpClient? client;
    try {
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) return;
      client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final req = await client
          .postUrl(Uri.parse(_pushRelay))
          .timeout(const Duration(seconds: 9));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'kind': kind,
        'chatId': chatId,
        'messageId': messageId,
      }));
      final response = await req.close().timeout(const Duration(seconds: 12));
      final body = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 12));
      debugPrint('[Rifqa Push] $key status=${response.statusCode} $body');
    } catch (error) {
      debugPrint('[Rifqa Push] dispatch failed $key: $error');
    } finally {
      client?.close(force: true);
    }
  }

  Future<void> _saveToken() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null ||
        user.isAnonymous ||
        !user.emailVerified ||
        !_notificationsAllowed) {
      await _removeRegisteredToken();

      return;
    }

    try {
      final token = await _messaging.getToken();

      if (token == null || token.isEmpty) return;

      if (_registeredUid != null &&
          _registeredToken != null &&
          (_registeredUid != user.uid || _registeredToken != token)) {
        await _removeRegisteredToken();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fcm_tokens')
          .doc(token)
          .set({'token': token, 'updatedAt': FieldValue.serverTimestamp()});

      _registeredUid = user.uid;

      _registeredToken = token;
      debugPrint('[Rifqa Notifications] FCM token saved successfully');
    } catch (error) {
      debugPrint('Unable to save FCM token (check Firestore rules): $error');
    }
  }

  Future<void> _removeRegisteredToken() async {
    final uid = _registeredUid;

    final token = _registeredToken;

    if (uid == null || token == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcm_tokens')
          .doc(token)
          .delete();

      _registeredUid = null;

      _registeredToken = null;
    } catch (error) {
      debugPrint('Unable to remove previous FCM token: $error');
    }
  }

  /// Diagnostic only: verifies OS permission, channel and local notification UI.
  /// Call from a debug button or temporary startup code after initialize().
  Future<void> testLocalNotification() async {
    if (!_initialized) {
      throw StateError('Initialize MessageNotificationService first');
    }
    debugPrint(
        '[Rifqa Notifications] test local: allowed=$_notificationsAllowed');
    if (!_notificationsAllowed) {
      debugPrint('[Rifqa Notifications] local test skipped: permission denied');
      return;
    }
    await _showLocal(
      title: 'Ø§Ø®ØªØ¨Ø§Ø± Ø¥Ø´Ø¹Ø§Ø±Ø§Øª Ø±ÙÙ‚Ø© ðŸ””',
      body:
          'Ù„Ùˆ Ø§Ù„Ø¥Ø´Ø¹Ø§Ø± Ø¯Ù‡ Ø¸Ù‡Ø±ØŒ Ø§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª Ø§Ù„Ù…Ø­Ù„ÙŠØ© Ø´ØºØ§Ù„Ø©.',
      data: {'type': 'notification_test'},
    );
    debugPrint('[Rifqa Notifications] local test submitted to Android');
  }

  /// Stops listeners cleanly if the notification service is ever reset.

  Future<void> dispose() async {
    ++_watchGeneration;

    await _authSubscription?.cancel();

    await _groupsSubscription?.cancel();
    await _friendsSubscription?.cancel();
    for (final sub in _directSubscriptions.values) {
      await sub.cancel();
    }
    _directSubscriptions.clear();
    _directChecking.clear();
    _directFriendNames.clear();
    _directListeningSince.clear();
    _currentFriendIds = {};
    _friendsSubscription = null;

    await _tokenSubscription?.cancel();

    await _foregroundSubscription?.cancel();

    await _openedSubscription?.cancel();

    for (final subscription in _messageSubscriptions.values) {
      await subscription.cancel();
    }

    _messageSubscriptions.clear();

    _seededGroups.clear();

    _listenStartedAt.clear();

    _shownMessages.clear();

    _authSubscription = null;

    _groupsSubscription = null;

    _tokenSubscription = null;

    _foregroundSubscription = null;

    _openedSubscription = null;

    _watchingUid = null;

    _initialized = false;

    WidgetsBinding.instance.removeObserver(this);
  }

  Future<void> prepareForSignOut() => _removeRegisteredToken();

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    // The Firestore listeners display these while the app is foregrounded.
    // Avoid a duplicate notification for the same FCM delivery.
    if (message.data['type'] == 'group_message' ||
        message.data['type'] == 'direct_message') {
      return;
    }

    final title =
        message.notification?.title ?? message.data['title']?.toString();

    final body = message.notification?.body ?? message.data['body']?.toString();

    if (title == null || body == null || !_notificationsAllowed) return;

    await _showLocal(title: title, body: body, data: message.data);
  }

  Future<void> _showLocal({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.remainder(1 << 31);

    await _local.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription:
              'Ø±Ø³Ø§Ø¦Ù„ Ø§Ù„Ø£ØµØ¯Ù‚Ø§Ø¡ ÙˆØ§Ù„Ù…Ø¬Ù…ÙˆØ¹Ø§Øª ÙˆØ¨Ù„Ø§ØºØ§Øª Ø§Ù„Ø§Ø³ØªØºØ§Ø«Ø©',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }
}
