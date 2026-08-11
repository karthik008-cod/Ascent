import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // User's timezone likely IST
  
  DateTime scheduledDateTime = DateTime.now().add(Duration(days: 1)); // Tomorrow
  
  for (int i = 0; i < 7; i++) {
    var nextDay = scheduledDateTime.add(Duration(days: i));
    if (nextDay.isBefore(DateTime.now())) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    print("i=$i nextDay=$nextDay tz=${tz.TZDateTime.from(nextDay, tz.local)}");
  }
}
