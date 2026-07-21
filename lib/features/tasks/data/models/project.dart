import 'package:isar/isar.dart';

part 'project.g.dart';

@collection
class Project {
  Id id = Isar.autoIncrement;

  late String title;
  
  String? description;
  
  String? notes;
  
  double progress = 0.0;
  
  DateTime createdAt = DateTime.now();
}
