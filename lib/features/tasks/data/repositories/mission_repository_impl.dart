import '../../domain/repositories/mission_repository.dart';
import '../models/mission.dart';
import '../../../../core/datasources/local_isar_datasource.dart';

class MissionRepositoryImpl implements MissionRepository {
  final LocalIsarDataSource dataSource;

  MissionRepositoryImpl(this.dataSource);

  @override
  Future<List<Mission>> getMissionsForDate(DateTime date) {
    return dataSource.getMissionsForDate(date);
  }

  @override
  Future<void> saveMission(Mission mission) {
    return dataSource.saveMission(mission);
  }

  @override
  Future<void> deleteMission(int id) {
    return dataSource.deleteMission(id);
  }
}
