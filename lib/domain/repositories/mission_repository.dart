import '../../data/models/mission.dart';

abstract class MissionRepository {
  Future<List<Mission>> getMissionsForDate(DateTime date);
  Future<void> saveMission(Mission mission);
  Future<void> deleteMission(int id);
}
