import 'dart:io';
import 'package:isar/isar.dart';
import 'lib/features/tasks/data/models/mission.dart';
import 'lib/features/tasks/data/models/project.dart';
import 'lib/features/tasks/data/models/task_item.dart';
import 'lib/features/progress/data/models/user_stats.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  // We can't easily initialize path_provider without Flutter, 
  // but we can initialize Isar in a local folder.
  Isar.initializeIsarCore(download: true);
  final isar = await Isar.open(
    [MissionSchema, ProjectSchema, TaskItemSchema, UserStatsSchema],
    directory: '.',
  );

  final mission = Mission()
    ..title = 'Test'
    ..date = DateTime.now()
    ..type = MissionType.main;
    
  print('Before put: ${mission.id}');
  await isar.writeTxn(() async {
    await isar.missions.put(mission);
  });
  print('After put: ${mission.id}');
  
  await isar.close(deleteFromDisk: true);
}
