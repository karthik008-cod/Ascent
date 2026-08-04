import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification click if needed
      },
    );

    // Request Android 13+ Notification Permissions
    await requestPermissions();

    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    // Via permission_handler
    final status = await Permission.notification.status;
    if (status.isDenied || status.isRestricted) {
      await Permission.notification.request();
    }

    // Also request via flutter_local_notifications Android plugin
    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  static Future<void> showInstantNotification({required String title, required String body}) async {
    await init();
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ascent_missions_channel',
      'Mission Reminders',
      channelDescription: 'Notifications for upcoming Ascent missions and routines',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      platformDetails,
    );
  }

  static Future<void> scheduleMissionNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String repeatMode = 'Once',
    List<int>? weeklyDays,
  }) async {
    await init();

    // If the scheduled time is in the past and it's a one-time notification, skip
    if (scheduledDateTime.isBefore(DateTime.now()) && repeatMode == 'Once') {
      return;
    }

    // For repeating notifications where the time today has passed, push to tomorrow
    var effectiveDateTime = scheduledDateTime;
    if (effectiveDateTime.isBefore(DateTime.now())) {
      effectiveDateTime = effectiveDateTime.add(const Duration(days: 1));
    }

    DateTimeComponents? matchComponents;
    if (repeatMode == 'Weekly') {
      matchComponents = DateTimeComponents.dayOfWeekAndTime;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ascent_missions_channel',
      'Mission Reminders',
      channelDescription: 'Notifications for upcoming Ascent missions and routines',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    try {
      if (repeatMode == 'Weekly' && weeklyDays != null && weeklyDays.isNotEmpty) {
        // Schedule a separate notification for each selected day of the week
        for (final day in weeklyDays) {
          // Calculate the next occurrence of this day of the week
          var nextDay = scheduledDateTime;
          while (nextDay.weekday != day) {
            nextDay = nextDay.add(const Duration(days: 1));
          }
          if (nextDay.isBefore(DateTime.now())) {
            nextDay = nextDay.add(const Duration(days: 7));
          }
          final notificationId = id + (day * 100000); // Unique ID for each day
          
          await _notificationsPlugin.zonedSchedule(
            notificationId,
            title,
            body,
            tz.TZDateTime.from(nextDay, tz.local),
            platformDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      } else if (repeatMode == 'Daily' || repeatMode == 'Hourly (Nag)') {
        // Schedule exact alarms for the next 7 days instead of relying on DateTimeComponents.time,
        // because the plugin ignores future start dates for time-based components.
        for (int i = 0; i < 7; i++) {
          var nextDay = scheduledDateTime.add(Duration(days: i));
          if (nextDay.isBefore(DateTime.now())) {
            nextDay = nextDay.add(const Duration(days: 1));
          }
          final notificationId = id + (i * 100000); // Unique ID for each day offset
          
          await _notificationsPlugin.zonedSchedule(
            notificationId,
            title,
            body,
            tz.TZDateTime.from(nextDay, tz.local),
            platformDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: null,
          );
        }
      } else {
        // Single schedule for Once
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(effectiveDateTime, tz.local),
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await init();
      await _notificationsPlugin.cancel(id);
      // Also cancel any potential weekly variants
      for (int i = 1; i <= 7; i++) {
        await _notificationsPlugin.cancel(id + (i * 100000));
      }
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await init();
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }
}
