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
}

enum MissionType {
  main,
  side,
  routine
}
