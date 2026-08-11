import 'package:isar/isar.dart';

part 'mission.g.dart';

@collection
class Mission {
  Id id = Isar.autoIncrement;

  late DateTime date;
  
  late String title;
  
  String? description;
  
  @enumerated
  late MissionType type;
  
  bool isCompleted = false;
  
  int xpReward = 0;
  
  int? projectId;
  
  String? reminderTime; // e.g., "09:00"
  
  String? reminderRepeatMode; // "Once", "Daily", "Weekly"
  
  List<int>? reminderWeeklyDays;
}

enum MissionType {
  main,
  side,
  routine
}
