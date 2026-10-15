import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class MessageNotificationService {
  MessageNotificationService._();

  static final instance = MessageNotificationService._();
  static const _channelId = 'rifqa_messages';
  static const _channelName = 'رسائل رِفقة';

  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _appReady = false;
  bool _notificationsAllowed = false;
  String? _registeredUid;
  String? _registeredToken;
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
    final canNotify = permission.authorizationStatus == AuthorizationStatus.authorized ||
        permission.authorizationStatus == AuthorizationStatus.provisional;
    _notificationsAllowed = canNotify;
    if (canNotify) await _saveToken();
    _messaging.onTokenRefresh.listen((_) => _saveToken());
    FirebaseAuth.instance.authStateChanges().listen((_) => _saveToken());
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _openData(message.data));
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) await _openData(initialMessage.data);
    _initialized = true;
  }

  Future<void> _saveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || !user.emailVerified || !_notificationsAllowed) {
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
    } catch (error) {
      debugPrint('Unable to save FCM token: $error');
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

  Future<void> prepareForSignOut() => _removeRegisteredToken();

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if (title == null || body == null) return;
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
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
      payload: jsonEncode(message.data),
    );
  }
}
