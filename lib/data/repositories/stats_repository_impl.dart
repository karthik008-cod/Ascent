import '../../domain/repositories/stats_repository.dart';
import '../models/user_stats.dart';
import '../datasources/local_isar_datasource.dart';

class StatsRepositoryImpl implements StatsRepository {
  final LocalIsarDataSource dataSource;

  StatsRepositoryImpl(this.dataSource);

  @override
  Future<UserStats> getUserStats() {
    return dataSource.getUserStats();
  }

  @override
  Future<void> saveUserStats(UserStats stats) {
    return dataSource.saveUserStats(stats);
  }
}
