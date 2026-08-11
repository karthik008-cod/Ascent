import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';
import '../../features/tasks/data/models/mission.dart';
import 'background_alarm_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    // FlutterTimezone uses platform channels — only works in the main isolate.
    // Wrap in try-catch so background isolate callers don't crash.
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (e) {
      // Fallback: default to Asia/Kolkata (user's timezone) if platform channel fails
      debugPrint('[Ascent] FlutterTimezone failed (likely background isolate), using fallback: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        // Already set or location not found — ignore
      }
    }

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
    required Mission mission,
  }) async {
    await init();
    
    // First, clear existing alarms for this mission ID
    await cancelNotification(mission.id);
    
    if (mission.reminderTime == null) return;
    
    if (Platform.isAndroid) {
      await BackgroundAlarmService.scheduleNextAlarm(mission);
      return;
    }
    
    // ----------------------------------------------------
    // FALLBACK FOR iOS (Using Native flutter_local_notifications)
    // ----------------------------------------------------
    
    final timeParts = mission.reminderTime!.split(':');
    if (timeParts.length != 2) return;
    final hour = int.tryParse(timeParts[0]) ?? 9;
    final minute = int.tryParse(timeParts[1]) ?? 0;
    
    // Compute the base scheduled date time
    final scheduledDateTime = DateTime(
      mission.date.year, mission.date.month, mission.date.day,
      hour, minute,
    );
    
    final repeatMode = mission.reminderRepeatMode ?? 'Once';
    final weeklyDays = mission.reminderWeeklyDays ?? [];

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails platformDetails = NotificationDetails(iOS: iosDetails);

    final title = 'Ascent Reminder: ${mission.title}';
    final body = 'It is time to focus on your mission!';

    // Calculate dates to schedule (iOS only allows up to 64 local notifications total, we'll schedule a few)
    List<DateTime> datesToSchedule = [];
    
    if (repeatMode == 'Once') {
      if (scheduledDateTime.isAfter(DateTime.now())) {
        datesToSchedule.add(scheduledDateTime);
      }
    } else if (repeatMode == 'Daily' || repeatMode == 'Hourly (Nag)') {
      // Schedule for the next 14 occurrences
      for (int i = 0; i < 60; i++) {
        var nextDay = scheduledDateTime.add(Duration(days: i));
        if (nextDay.isAfter(DateTime.now())) {
          datesToSchedule.add(nextDay);
          if (datesToSchedule.length >= 14) break; 
        }
      }
    } else if (repeatMode == 'Weekly' && weeklyDays.isNotEmpty) {
      // Schedule for the next 4 weeks (max 14 alarms total)
      for (int i = 0; i < 60; i++) {
        var nextDay = scheduledDateTime.add(Duration(days: i));
        if (weeklyDays.contains(nextDay.weekday) && nextDay.isAfter(DateTime.now())) {
          datesToSchedule.add(nextDay);
          if (datesToSchedule.length >= 14) break;
        }
      }
    }
    
    // Schedule exact alarms
    try {
      for (int i = 0; i < datesToSchedule.length; i++) {
        final date = datesToSchedule[i];
        final notificationId = mission.id + (i * 100000);
        
        await _notificationsPlugin.zonedSchedule(
          notificationId,
          title,
          body,
          tz.TZDateTime.from(date, tz.local),
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        );
      }
    } catch (e) {
      debugPrint('[Ascent] Error scheduling iOS notification: $e');
    }
  }

  /// Re-syncs all mission notifications. Cancels ALL existing alarms/notifications first.
  static Future<void> syncMissionsToNotifications(List<Mission> missions) async {
    // Cancel all flutter_local_notifications
    await cancelAllNotifications();
    
    // Also cancel all AndroidAlarmManager alarms for known missions
    if (Platform.isAndroid) {
      final missionIds = missions.map((m) => m.id).toList();
      await BackgroundAlarmService.cancelAlarms(missionIds);
    }
    
    // Re-schedule all active reminders
    for (final mission in missions) {
      if (mission.reminderTime != null && !mission.isCompleted) {
        await scheduleMissionNotification(mission: mission);
      }
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await init();
      
      if (Platform.isAndroid) {
        await BackgroundAlarmService.cancelAlarm(id);
      }
      
      await _notificationsPlugin.cancel(id);
      // Also cancel any potential weekly variants or future exact alarms
      for (int i = 1; i <= 60; i++) {
        await _notificationsPlugin.cancel(id + (i * 100000));
      }
    } catch (e) {
      debugPrint('[Ascent] Error canceling notification: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await init();
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('[Ascent] Error canceling all notifications: $e');
    }
  }
}
