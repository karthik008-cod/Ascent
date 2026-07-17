import 'package:isar/isar.dart';

part 'user_stats.g.dart';

@collection
class UserStats {
  Id id = 1; // Singleton

  int totalXp = 0;
  
  int currentLevel = 1;
  
  int currentStreak = 0;
  
  int longestStreak = 0;
  
  DateTime? lastActiveDate;
}
