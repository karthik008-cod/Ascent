import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

  final now = DateTime.now();
  print('Now: $now');
  
  // Simulated AddMissionScreen inputs
  final startDate = DateTime(now.year, now.month, now.day + 1); // tomorrow
  final reminderHour = 21;
  final reminderMinute = 25;
  
  final scheduledDateTime = DateTime(
    startDate.year, startDate.month, startDate.day,
    reminderHour, reminderMinute,
  );
  print('Scheduled: $scheduledDateTime');
  
  final repeatMode = 'Once'; // Let's test Once first
  
  var effectiveDateTime = scheduledDateTime;
  if (effectiveDateTime.isBefore(DateTime.now())) {
    effectiveDateTime = effectiveDateTime.add(const Duration(days: 1));
  }
  
  final tzDate = tz.TZDateTime.from(effectiveDateTime, tz.local);
  print('Final TZDate for Once: $tzDate');
  
  // Test Daily logic
  print('\nTesting Daily Logic:');
  for (int i = 0; i < 7; i++) {
    var nextDay = scheduledDateTime.add(Duration(days: i));
    if (nextDay.isBefore(DateTime.now())) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    final tzNextDay = tz.TZDateTime.from(nextDay, tz.local);
    print('Daily day $i: $tzNextDay');
  }
}
