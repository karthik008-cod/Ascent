import 'package:isar/isar.dart';

part 'task_item.g.dart';

@collection
class TaskItem {
  Id id = Isar.autoIncrement;

  late String title;
  
  bool isCompleted = false;
  
  int? projectId;
  
  DateTime? deadline;
  
  DateTime createdAt = DateTime.now();
}
