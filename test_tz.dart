import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

  final localDateTime = DateTime(2026, 8, 5, 20, 52);
  print('Local DateTime: $localDateTime');

  final tzDateTime = tz.TZDateTime.from(localDateTime, tz.local);
  print('TZDateTime: $tzDateTime');
  
  if (tzDateTime.isBefore(DateTime.now())) {
    print('Is before now');
  } else {
    print('Is after now');
  }
}
