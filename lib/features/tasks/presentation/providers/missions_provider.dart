import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/mission.dart';
import '../../../../core/services/notification_service.dart';
import './data_providers.dart';
import '../../../progress/presentation/providers/user_stats_provider.dart';

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

  /// Returns the new level if a level-up occurred, null otherwise.
  Future<int?> toggleMissionStatus(Mission mission) async {
    final repository = ref.read(missionRepositoryProvider);
    mission.isCompleted = !mission.isCompleted;
    await repository.saveMission(mission);
    
    int? newLevel;
    // XP Calculation & Notification Cancellation
    if (mission.isCompleted) {
      newLevel = await ref.read(userStatsNotifierProvider.notifier).addXp(mission.xpReward);
      await NotificationService.cancelNotification(mission.id);
    } else {
      await ref.read(userStatsNotifierProvider.notifier).removeXp(mission.xpReward);
    }
    
    await _loadMissions();
    return newLevel;
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
    await NotificationService.cancelNotification(id);
    await repository.deleteMission(id);
    await _loadMissions();
  }
}

final missionNotifierProvider = StateNotifierProvider<MissionNotifier, AsyncValue<List<Mission>>>((ref) {
  return MissionNotifier(ref);
});

final missionFilterProvider = StateProvider<String>((ref) => 'All');
final missionSortProvider = StateProvider<String>((ref) => 'Default');

final availableHashtagsProvider = Provider<List<String>>((ref) {
  final missionsAsync = ref.watch(missionNotifierProvider);
  final Set<String> tags = {'#Career', '#Fitness', '#Mindset', '#Project', '#Personal'};
  missionsAsync.whenData((missions) {
    for (final m in missions) {
      if (m.description != null) {
        final matches = RegExp(r'#\w+').allMatches(m.description!);
        for (final match in matches) {
          if (match.group(0) != null) {
            tags.add(match.group(0)!);
          }
        }
      }
    }
  });
  return tags.toList()..sort();
});

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
    } else if (sort == 'By Hashtag') {
      filtered.sort((a, b) {
        String extractTag(Mission m) {
          if (m.description == null) return 'zzzzz';
          final match = RegExp(r'#\w+').firstMatch(m.description!);
          return match != null ? match.group(0)!.toLowerCase() : 'zzzzz';
        }
        final tagA = extractTag(a);
        final tagB = extractTag(b);
        final cmp = tagA.compareTo(tagB);
        if (cmp != 0) return cmp;
        return (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0);
      });
    }

    return filtered;
  });
});

bool isMissionActiveForDay(Mission m, DateTime targetDate) {
  final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
  final start = DateTime(m.date.year, m.date.month, m.date.day);

  if (target.isBefore(start)) {
    return false;
  }

  if (m.description == null) {
    return target.isAtSameMomentAs(start);
  }

  final desc = m.description!;
  if (desc.contains('Repeats: Daily')) {
    return true;
  } else if (desc.contains('Repeats: Weekly') || desc.contains('Repeats: Custom Days')) {
    final daysMatch = RegExp(r'Days:\s*([0-9,\s]+)').firstMatch(desc);
    if (daysMatch != null && daysMatch.group(1) != null) {
      final days = daysMatch.group(1)!
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toSet();
      if (days.isNotEmpty) {
        return days.contains(target.weekday);
      }
    }
    if (desc.contains('Repeats: Weekly')) {
      return target.weekday == start.weekday;
    }
    return true;
  } else if (desc.contains('Repeats: Never')) {
    return target.isAtSameMomentAs(start);
  }

  return target.isAtSameMomentAs(start);
}

final todayMissionsProvider = Provider<AsyncValue<List<Mission>>>((ref) {
  final filteredAsync = ref.watch(filteredSortedMissionsProvider);
  return filteredAsync.whenData((missions) {
    final today = DateTime.now();
    return missions.where((m) => isMissionActiveForDay(m, today)).toList();
  });
});
