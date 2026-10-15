// ═══════════════════════════════════════════════════════════════
//  إشعارات حقيقية لتذكيرات الروضة (اختياري)
//  لا تضع هذا الملف داخل lib/ إلا بعد تنفيذ الخطوات التالية، وإلا فلن يُبنى المشروع.
//
//  1) pubspec.yaml:
//       flutter_local_notifications: ^19.0.0
//       timezone: ^0.10.0
//  2) Android (android/app/src/main/AndroidManifest.xml) أضف:
//       <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//       <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
//       <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
//     وأضف داخل <application> مستقبِلات الحزمة (راجع توثيق flutter_local_notifications)
//     لتعمل الإشعارات المجدولة بعد إعادة تشغيل الهاتف.
//  3) iOS: اطلب الإذن (يفعله هذا الملف) وفعّل Notifications في Capabilities.
//  4) في main() قبل runApp:
//       RawdahNotifier.I = LocalRawdahNotifier();
//
//  ملاحظة: الكود مكتوب لإصدار 19 من الحزمة؛ تغيّرت توقيعات بعض الدوال بين الإصدارات.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../rawdah_data.dart';
import '../rawdah_reminders.dart';

class LocalRawdahNotifier implements RawdahNotifier {
  final FlutterLocalNotificationsPlugin _p = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  @override
  bool get supported => true;

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await _p.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    final android =
        _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    await _p
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _ready = true;
  }

  @override
  Future<bool> schedule(List<RAttempt> items, {int leadMinutes = 10}) async {
    try {
      await _init();
      await _p.cancelAll();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'rawdah_reminders',
          'تذكيرات حجز الروضة',
          channelDescription: 'تنبيهات مواعيد محاولة حجز الروضة الشريفة',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      var id = 1000;
      final now = DateTime.now().toUtc();
      for (final a in items) {
        final pre = a.instant.subtract(Duration(minutes: leadMinutes));
        final times = <List<Object>>[
          [pre, 'جهّز نسك الآن ⏰', '${a.title}: بعد $leadMinutes دقيقة. افتح نسك واختر الاسم وكن مستعدًا.'],
          [a.instant, 'ادخل الآن إلى نسك 🕌', '${a.title}: حان وقت المحاولة. صلِّ على النبي ﷺ وتوكّل على الله.'],
        ];
        for (final t in times) {
          final when = t[0] as DateTime;
          if (!when.isAfter(now)) continue;
          await _p.zonedSchedule(
            id: id++,
            title: t[1] as String,
            body: t[2] as String,
            scheduledDate: tz.TZDateTime.from(when, tz.UTC),
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> cancelAll() async {
    await _init();
    await _p.cancelAll();
  }
}
