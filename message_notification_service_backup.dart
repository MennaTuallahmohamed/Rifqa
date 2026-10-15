import 'dart:async';

import 'dart:convert';

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

  static const _channelName = 'رسائل رِفقة';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _messageSubscriptions = {};

  final Set<String> _seededGroups = {};

  final Map<String, DateTime> _listenStartedAt = {};

  final Set<String> _shownMessages = {};

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
              description: 'رسائل الأصدقاء والمجموعات وبلاغات الاستغاثة',
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

      _groupsSubscription = null;

      for (final sub in _messageSubscriptions.values) {
        await sub.cancel();
      }

      _messageSubscriptions.clear();

      _seededGroups.clear();

      _listenStartedAt.clear();

      _shownMessages.clear();

      if (generation == _watchGeneration && uid != null) {
        _subscribeToGroups(uid, generation);
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

        final groupName = group.data()['name']?.toString() ?? 'رفقتي';

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
            if (change.type != DocumentChangeType.added) continue;

            final document = change.doc;

            if (document.metadata.hasPendingWrites) continue;

            final data = document.data();

            if (data == null || data['senderId'] == uid) continue;

            if (data['createdAt'] is! Timestamp) continue;

            if (!(data['createdAt'] as Timestamp).toDate().isAfter(
                  _listenStartedAt[groupId] ?? DateTime.now(),
                )) {
              continue;
            }

            final key = '$groupId/${document.id}';

            if (!_shownMessages.add(key)) continue;

            if (_shownMessages.length > 300) _shownMessages.clear();

            if (!_isForeground || !_notificationsAllowed) continue;

            final sender = data['senderName']?.toString() ?? 'عضو';

            final type = data['type']?.toString() ?? 'text';

            final body = type == 'image'
                ? '$sender: 📷 صورة جديدة'
                : type == 'voice'
                    ? '$sender: 🎤 رسالة صوتية'
                    : type == 'location'
                        ? '$sender: 📍 شارك موقعه'
                        : '$sender: ${data['text'] ?? 'رسالة جديدة'}';

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
      title: 'اختبار إشعارات رفقة 🔔',
      body: 'لو الإشعار ده ظهر، الإشعارات المحلية شغالة.',
      data: {'type': 'notification_test'},
    );
    debugPrint('[Rifqa Notifications] local test submitted to Android');
  }

  /// Stops listeners cleanly if the notification service is ever reset.

  Future<void> dispose() async {
    ++_watchGeneration;

    await _authSubscription?.cancel();

    await _groupsSubscription?.cancel();

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
          channelDescription: 'رسائل الأصدقاء والمجموعات وبلاغات الاستغاثة',
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
