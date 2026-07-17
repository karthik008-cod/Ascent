import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/mission.dart';
import 'data_providers.dart';
import 'user_stats_provider.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

class MissionNotifier extends StateNotifier<AsyncValue<List<Mission>>> {
  MissionNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadMissions();
  }

  final Ref ref;

  Future<void> _loadMissions() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(missionRepositoryProvider);
      final date = ref.read(selectedDateProvider);
      final missions = await repository.getMissionsForDate(date);
      state = AsyncValue.data(missions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleMissionStatus(Mission mission) async {
    final repository = ref.read(missionRepositoryProvider);
    mission.isCompleted = !mission.isCompleted;
    await repository.saveMission(mission);
    
    // XP Calculation Use Case
    if (mission.isCompleted) {
      await ref.read(userStatsNotifierProvider.notifier).addXp(mission.xpReward);
    } else {
      await ref.read(userStatsNotifierProvider.notifier).removeXp(mission.xpReward);
    }
    
    await _loadMissions();
  }

  Future<void> addMission(Mission mission) async {
    final repository = ref.read(missionRepositoryProvider);
    await repository.saveMission(mission);
    await _loadMissions();
  }

  Future<void> updateMission(Mission mission) async {
    final repository = ref.read(missionRepositoryProvider);
    await repository.saveMission(mission);
    await _loadMissions();
  }

  Future<void> deleteMission(int id) async {
    final repository = ref.read(missionRepositoryProvider);
    await repository.deleteMission(id);
    await _loadMissions();
  }
}

final missionNotifierProvider = StateNotifierProvider<MissionNotifier, AsyncValue<List<Mission>>>((ref) {
  return MissionNotifier(ref);
});

final missionFilterProvider = StateProvider<String>((ref) => 'All');
final missionSortProvider = StateProvider<String>((ref) => 'Default');

final filteredSortedMissionsProvider = Provider<AsyncValue<List<Mission>>>((ref) {
  final missionsAsync = ref.watch(missionNotifierProvider);
  final filter = ref.watch(missionFilterProvider);
  final sort = ref.watch(missionSortProvider);

  return missionsAsync.whenData((missions) {
    var filtered = missions.where((m) {
      if (filter == 'All') return true;
      if (filter == 'Main') return m.type == MissionType.main;
      if (filter == 'Side') return m.type == MissionType.side;
      if (filter == 'Routine') return m.type == MissionType.routine;
      if (filter.startsWith('#')) {
        return m.description?.contains(filter) ?? false;
      }
      return true;
    }).toList();

    if (sort == 'XP High to Low') {
      filtered.sort((a, b) => b.xpReward.compareTo(a.xpReward));
    } else if (sort == 'Title A-Z') {
      filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (sort == 'Incomplete First') {
      filtered.sort((a, b) => (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0));
    }

    return filtered;
  });
});
