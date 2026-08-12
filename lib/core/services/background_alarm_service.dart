import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import '../../features/tasks/data/models/mission.dart';
import '../../features/tasks/data/models/project.dart';
import '../../features/tasks/data/models/task_item.dart';
import '../../features/progress/data/models/user_stats.dart';

class BackgroundAlarmService {
  /// Schedules the next native exact alarm for Android.
  /// 
  /// Key rule: NEVER schedule an alarm before mission.date (the start date).
  /// This works like a real clock app — the start date is the floor.
  static Future<void> scheduleNextAlarm(Mission mission) async {
    if (mission.reminderTime == null || mission.isCompleted) return;

    final timeParts = mission.reminderTime!.split(':');
    if (timeParts.length != 2) return;
    final hour = int.tryParse(timeParts[0]) ?? 9;
    final minute = int.tryParse(timeParts[1]) ?? 0;

    final now = DateTime.now();
    final repeatMode = mission.reminderRepeatMode ?? 'Once';
    final weeklyDays = mission.reminderWeeklyDays ?? [];
    
    // The start date is the absolute floor — no alarm before this date
    final startDate = DateTime(mission.date.year, mission.date.month, mission.date.day);

    DateTime? nextAlarmTime;

    if (repeatMode == 'Once') {
      // For "Once", the alarm fires at the exact date + time the user set
      final candidate = DateTime(
        mission.date.year, mission.date.month, mission.date.day,
        hour, minute,
      );
      if (candidate.isAfter(now)) {
        nextAlarmTime = candidate;
      } else {
        // Already in the past — don't schedule
        return;
      }
    } else if (repeatMode == 'Daily' || repeatMode == 'Hourly (Nag)') {
      // Start searching from the later of today or the mission start date
      DateTime searchFrom;
      if (now.isBefore(startDate)) {
        // Mission hasn't started yet — first alarm is on the start date
        searchFrom = startDate;
      } else {
        // Mission already started — search from today
        searchFrom = DateTime(now.year, now.month, now.day);
      }
      
      var candidate = DateTime(searchFrom.year, searchFrom.month, searchFrom.day, hour, minute);
      // If this candidate is in the past (today's time already passed), move to next day
      if (!candidate.isAfter(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      nextAlarmTime = candidate;
    } else if (repeatMode == 'Weekly' && weeklyDays.isNotEmpty) {
      // Start searching from the later of today or the mission start date
      DateTime searchFrom;
      if (now.isBefore(startDate)) {
        searchFrom = startDate;
      } else {
        searchFrom = DateTime(now.year, now.month, now.day);
      }
      
      // Search up to 8 days to find the next matching weekday
      for (int i = 0; i < 8; i++) {
        final candidateDate = searchFrom.add(Duration(days: i));
        final candidate = DateTime(
          candidateDate.year, candidateDate.month, candidateDate.day,
          hour, minute,
        );
        // Must be in the future AND on a matching weekday
        if (candidate.isAfter(now) && weeklyDays.contains(candidate.weekday)) {
          nextAlarmTime = candidate;
          break;
        }
      }
      if (nextAlarmTime == null) return;
    } else {
      // Unknown repeat mode, fall back to Once behavior
      final candidate = DateTime(
        mission.date.year, mission.date.month, mission.date.day,
        hour, minute,
      );
      if (candidate.isAfter(now)) {
        nextAlarmTime = candidate;
      } else {
        return;
      }
    }

    // Register with AndroidAlarmManager
    // The ID is the mission ID since we only have one active alarm per mission
    await AndroidAlarmManager.oneShotAt(
      nextAlarmTime,
      mission.id,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    debugPrint('[Ascent] Scheduled Android Alarm for Mission ${mission.id} '
        '("${mission.title}") at $nextAlarmTime (repeat=$repeatMode, startDate=$startDate)');
  }

  /// Cancels an existing Android alarm
  static Future<void> cancelAlarm(int missionId) async {
    await AndroidAlarmManager.cancel(missionId);
  }

  /// Cancel alarms for a batch of mission IDs
  static Future<void> cancelAlarms(List<int> missionIds) async {
    for (final id in missionIds) {
      await AndroidAlarmManager.cancel(id);
    }
  }
}

/// The callback executed by the background isolate when the exact time is reached.
/// This runs in a SEPARATE ISOLATE — no access to the main app's state or platform channels.
@pragma('vm:entry-point')
void alarmCallback(int id) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Open Isar safely in background isolate
    final dir = await getApplicationDocumentsDirectory();
    Isar? isar = Isar.getInstance();
    if (isar == null) {
      isar = await Isar.open(
        [MissionSchema, ProjectSchema, TaskItemSchema, UserStatsSchema],
        directory: dir.path,
      );
    }

    final mission = await isar.missions.get(id);
    if (mission == null) {
      debugPrint('[Ascent] alarmCallback: Mission $id not found in DB, skipping.');
      return;
    }
    if (mission.isCompleted) {
      debugPrint('[Ascent] alarmCallback: Mission $id is completed, skipping.');
      return;
    }

    // Initialize notification plugin directly in this isolate
    // Do NOT call NotificationService.init() — it uses platform channels
    // (FlutterTimezone) that crash in background isolates.
    final FlutterLocalNotificationsPlugin notificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);

    await notificationsPlugin.initialize(initSettings);

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
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(
      mission.id,
      'Ascent Reminder: ${mission.title}',
      'It is time to focus on your mission!',
      platformDetails,
    );

    debugPrint('[Ascent] alarmCallback: Notification shown for Mission ${mission.id} '
        '("${mission.title}")');

    // If repeat, schedule the next alarm
    final repeatMode = mission.reminderRepeatMode ?? 'Once';
    if (repeatMode != 'Once') {
      await BackgroundAlarmService.scheduleNextAlarm(mission);
      debugPrint('[Ascent] alarmCallback: Re-scheduled next alarm for Mission ${mission.id}');
    }
  } catch (e, st) {
    debugPrint('[Ascent] alarmCallback ERROR for mission $id: $e');
    debugPrint('[Ascent] Stack trace: $st');
  }
}
