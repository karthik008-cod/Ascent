import '../../data/models/user_stats.dart';

abstract class StatsRepository {
  Future<UserStats> getUserStats();
  Future<void> saveUserStats(UserStats stats);
}
