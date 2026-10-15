import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PilgrimAlarmService {
  PilgrimAlarmService._();

  static final PilgrimAlarmService instance =
      PilgrimAlarmService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'pilgrim_alarms';

  static const String _channelName =
      'منبهات المعتمر والحاج';

  static const String _channelDescription =
      'تنبيهات ومنبهات ساعة المعتمر والحاج';

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    _initialized = true;
  }

  void _onNotificationTap(
    NotificationResponse response,
  ) {
    // Later we can use response.payload to open
    // the pilgrim clock screen directly.
  }

  Future<bool> requestPermissions() async {
    await initialize();

    bool granted = true;

    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final notificationPermission =
          await androidPlugin?.requestNotificationsPermission();

      if (notificationPermission == false) {
        granted = false;
      }

      try {
        await androidPlugin?.requestExactAlarmsPermission();
      } catch (_) {
        // Some Android versions do not need
        // a separate exact-alarm permission prompt.
      }
    }

    if (Platform.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      final iosPermission = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (iosPermission == false) {
        granted = false;
      }
    }

    return granted;
  }

  Future<void> scheduleDailyAlarm({
    required int id,
    required String title,
    required int hour,
    required int minute,
    bool useMakkahTime = true,
  }) async {
    await initialize();

    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(
        hour,
        'hour',
        'Hour must be between 0 and 23.',
      );
    }

    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(
        minute,
        'minute',
        'Minute must be between 0 and 59.',
      );
    }

    final scheduledDate = useMakkahTime
        ? _nextMakkahTime(
            hour: hour,
            minute: minute,
          )
        : _nextLocalTime(
            hour: hour,
            minute: minute,
          );

    await _notifications.zonedSchedule(
      id: id,
      title: '⏰ ساعة المعتمر والحاج',
      body: title,
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'pilgrim_clock_alarm:$id',
    );
  }

  Future<void> scheduleOneTimeAlarm({
    required int id,
    required String title,
    required DateTime dateTime,
  }) async {
    await initialize();

    final scheduledDate = tz.TZDateTime.from(
      dateTime,
      tz.local,
    );

    if (scheduledDate.isBefore(
      tz.TZDateTime.now(tz.local),
    )) {
      throw ArgumentError(
        'Alarm date must be in the future.',
      );
    }

    await _notifications.zonedSchedule(
      id: id,
      title: '⏰ ساعة المعتمر والحاج',
      body: title,
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'pilgrim_clock_alarm:$id',
    );
  }

  Future<void> scheduleTestAlarm({
    int seconds = 5,
  }) async {
    await initialize();

    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(
      Duration(seconds: seconds),
    );

    await _notifications.zonedSchedule(
      id: 999999,
      title: '⏰ اختبار منبه رِفقة',
      body: 'المنبه يعمل بنجاح',
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'pilgrim_clock_test',
    );
  }

  Future<void> cancelAlarm(
    int id,
  ) async {
    await initialize();

    await _notifications.cancel(
      id: id,
    );
  }

  Future<void> cancelAllAlarms() async {
    await initialize();

    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>>
      pendingAlarms() async {
    await initialize();

    return _notifications.pendingNotificationRequests();
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  tz.TZDateTime _nextLocalTime({
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(
      tz.local,
    );

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(
        const Duration(days: 1),
      );
    }

    return scheduled;
  }

  tz.TZDateTime _nextMakkahTime({
    required int hour,
    required int minute,
  }) {
    final makkah = tz.getLocation(
      'Asia/Riyadh',
    );

    final nowInMakkah = tz.TZDateTime.now(
      makkah,
    );

    var makkahAlarm = tz.TZDateTime(
      makkah,
      nowInMakkah.year,
      nowInMakkah.month,
      nowInMakkah.day,
      hour,
      minute,
    );

    if (!makkahAlarm.isAfter(nowInMakkah)) {
      makkahAlarm = makkahAlarm.add(
        const Duration(days: 1),
      );
    }

    // Convert the Makkah instant to the device's local timezone
    // before passing it to the local notification scheduler.
    return tz.TZDateTime.from(
      makkahAlarm,
      tz.local,
    );
  }
}