import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'watch_store.dart';

/// Android local notifications; these are NOT hard real-time or emergency alarms.
/// Ritual reminders deliberately use Saudi Arabia's official civil timezone.
/// No notifications are sent unless the user explicitly enables an alarm.
class RifqaWatchNotifications {
  RifqaWatchNotifications._();
  static final instance = RifqaWatchNotifications._();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  late final tz.Location _saudi;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    _saudi = tz.getLocation('Asia/Riyadh');
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await _plugin.initialize(settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ));
    }
    _initialized = true;
  }

  Future<bool> askPermission() async {
    try {
      await init();
      if (kIsWeb) return false;
      if (Platform.isAndroid) {
        return await _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission() ?? false;
      }
      if (Platform.isIOS) {
        return await _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: true, badge: true, sound: true) ?? false;
      }
    } catch (e) { debugPrint('Watch permission: $e'); }
    return false;
  }

  NotificationDetails _details(bool important) => NotificationDetails(
    android: AndroidNotificationDetails(
      important ? 'rifqa_ritual_important' : 'rifqa_ritual_gentle',
      important ? 'رِفقة — مناسك مهمة' : 'رِفقة — تذكيرات هادئة',
      channelDescription: 'تذكيرات اختار المستخدم تفعيلها',
      importance: important ? Importance.high : Importance.defaultImportance,
      priority: important ? Priority.high : Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
    ),
    iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  int _notificationId(int alarmId, int weekday, bool early) =>
      alarmId * 20 + (weekday - 1) * 2 + (early ? 1 : 0);

  Future<void> cancelAlarm(PilgrimWatchAlarm alarm) async {
    await init();
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    for (var day = 1; day <= 7; day++) {
      for (final early in [false, true]) {
        await _plugin.cancel(id: _notificationId(alarm.id, day, early));
      }
    }
    await _plugin.cancel(id: alarm.id * 20 + 19);
  }

  tz.TZDateTime _nextSaudiWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(_saudi);
    final days = (weekday - now.weekday + 7) % 7;
    var date = tz.TZDateTime(_saudi, now.year, now.month, now.day + days,
      hour, minute);
    if (!date.isAfter(now)) date = date.add(const Duration(days: 7));
    return date;
  }

  /// Schedules weekly recurring main reminders and optional earlier heads-up.
  /// Accuracy is subject to OS notification policies and battery restrictions.
  Future<void> schedule(PilgrimWatchAlarm alarm, {bool quietMode = false}) async {
    await cancelAlarm(alarm);
    if (!alarm.enabled || (quietMode && !alarm.important)) return;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    for (final weekday in alarm.days.toSet()) {
      if (weekday < 1 || weekday > 7) continue;
      final at = _nextSaudiWeekday(weekday, alarm.hour, alarm.minute);
      await _plugin.zonedSchedule(
        id: _notificationId(alarm.id, weekday, false),
        title: 'ساعة رِفقة | ${alarm.title}',
        body: alarm.important ? 'حان وقت المهمة المهمة. راجع تعليمات رحلتك.'
            : 'تذكيرك الخاص جاهز. خذ وقتك وابدأ بهدوء.',
        scheduledDate: at,
        notificationDetails: _details(alarm.important),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      if (alarm.earlyMinutes > 0) {
        await _plugin.zonedSchedule(
          id: _notificationId(alarm.id, weekday, true),
          title: 'استعدّي | ${alarm.title}',
          body: 'متبقي ${alarm.earlyMinutes} دقيقة على تذكيرك بتوقيت مكة.',
          scheduledDate: at.subtract(Duration(minutes: alarm.earlyMinutes)),
          notificationDetails: _details(false),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  /// Manual postpone: user action; do not call automatically from an alert.
  Future<void> postpone(PilgrimWatchAlarm alarm, int minutes) async {
    await init();
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      throw StateError('Notifications are not available on this platform');
    }
    await _plugin.zonedSchedule(
      id: alarm.id * 20 + 19,
      title: 'رِفقة | ${alarm.title}',
      body: 'التذكير المؤجّل الذي طلبتيه',
      scheduledDate: tz.TZDateTime.now(_saudi).add(Duration(minutes: minutes)),
      notificationDetails: _details(alarm.important),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> refresh(RifqaWatchStore store) async {
    await init();
    for (final alarm in store.alarms) {
      await schedule(alarm, quietMode: store.quietMode);
    }
  }
}
