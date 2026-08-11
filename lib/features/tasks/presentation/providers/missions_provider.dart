import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/mission.dart';
import '../../../../core/services/notification_service.dart';
import './data_providers.dart';
import '../../../progress/presentation/providers/user_stats_provider.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

class MissionNotifier extends StateNotifier<AsyncValue<List<Mission>>> {
  MissionNotifier(this.ref, {bool loadImmediately = true}) : super(const AsyncValue.loading()) {
    if (loadImmediately) {
      _loadMissions();
    }
  }

  void setLoading() {
    state = const AsyncValue.loading();
  }

  final Ref ref;

  Future<void> _loadMissions() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(missionRepositoryProvider);
      final rawMissions = await repository.getAllMissions();
      
      // If no missions exist, seed tutorial tasks on first launch
      if (rawMissions.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final seeded = prefs.getBool('tutorial_tasks_seeded') ?? false;
        if (!seeded) {
          await _seedTutorialTasks();
          await prefs.setBool('tutorial_tasks_seeded', true);
          final seededMissions = await repository.getAllMissions();
          state = AsyncValue.data(seededMissions);
          return;
        }
      }
      
      // Cleanup stale completed 'Once' tasks from previous days, and reset Daily/Weekly
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final activeMissions = <Mission>[];
      bool changed = false;
      
      for (final m in rawMissions) {
        bool isOnce = m.description == null || (!m.description!.contains('Repeats: Daily') && !m.description!.contains('Repeats: Weekly'));
        
        if (m.isCompleted && isOnce) {
          // Do nothing, we no longer delete completed Once tasks overnight.
          // They are simply filtered out of the Planner view.
        } else if (!isOnce) {
          // Reset Daily or Weekly tasks!
          if (m.description!.contains('Repeats: Daily')) {
            final lastCompletedMatch = RegExp(r'\[LastCompleted:\s*([\d-]+)\]').firstMatch(m.description!);
            if (lastCompletedMatch != null) {
              final lastCompletedDate = DateTime.tryParse(lastCompletedMatch.group(1)!);
              if (lastCompletedDate != null) {
                final lastDay = DateTime(lastCompletedDate.year, lastCompletedDate.month, lastCompletedDate.day);
                if (lastDay.isBefore(today)) {
                   m.isCompleted = false;
                   m.description = m.description!.replaceAll(RegExp(r'\n*\[LastCompleted:\s*[\d-]+\]'), '');
                   m.description = m.description!.replaceAll('• [x] ', '• [ ] ');
                   await repository.saveMission(m);
                   changed = true;
                }
              }
            }
          } else if (m.description!.contains('Repeats: Weekly')) {
            final lastCompletedWeekMatch = RegExp(r'\[LastCompletedWeek:\s*([\d-]+)\]').firstMatch(m.description!);
            if (lastCompletedWeekMatch != null) {
              final lastWeekMonday = DateTime.tryParse(lastCompletedWeekMatch.group(1)!);
              if (lastWeekMonday != null) {
                final thisWeekMonday = getStartOfWeek(now);
                if (lastWeekMonday.isBefore(thisWeekMonday)) {
                   m.isCompleted = false;
                   m.description = m.description!.replaceAll(RegExp(r'\n*\[LastCompletedWeek:\s*[\d-]+\]'), '');
                   m.description = m.description!.replaceAll(RegExp(r'\n*\[CompletedDays:\s*[0-9,\s]+\]'), '');
                   m.description = m.description!.replaceAll('• [x] ', '• [ ] ');
                   await repository.saveMission(m);
                   changed = true;
                }
              }
            }
          }
        }
        activeMissions.add(m);
      }
      
      state = AsyncValue.data(activeMissions);
      
      // Sync all exact alarms for the next 14 days based on current missions
      NotificationService.syncMissionsToNotifications(activeMissions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _seedTutorialTasks() async {
    final repository = ref.read(missionRepositoryProvider);
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day);

    final tutorials = [
      Mission()
        ..title = '👈 Swipe me left to delete'
        ..description = 'Swipe any task to the left to permanently remove it.\n\nRepeats: Daily\n\n[TUTORIAL_TASK]'
        ..type = MissionType.routine
        ..xpReward = 0
        ..date = startDate
        ..isCompleted = false,
      Mission()
        ..title = '👉 Swipe me right to complete'
        ..description = 'Swipe any task to the right to mark it as done and earn XP!\n\nRepeats: Daily\n\n[TUTORIAL_TASK]'
        ..type = MissionType.routine
        ..xpReward = 0
        ..date = startDate
        ..isCompleted = false,
      Mission()
        ..title = '☑️ Tap the circle icon to toggle status'
        ..description = 'You can also tap the circle on the left side to complete or uncomplete a task.\n\nRepeats: Daily\n\n[TUTORIAL_TASK]'
        ..type = MissionType.side
        ..xpReward = 0
        ..date = startDate
        ..isCompleted = false,
      Mission()
        ..title = '✏️ Tap anywhere on a task to edit it'
        ..description = 'Tap on any mission card to open the editor and change details.\n\nRepeats: Daily\n\n[TUTORIAL_TASK]'
        ..type = MissionType.side
        ..xpReward = 0
        ..date = startDate
        ..isCompleted = false,
      Mission()
        ..title = '⚙️ Tap the logo icon for Settings'
        ..description = 'The app logo on the top-right opens your Settings — manage accounts, themes, and more.\n\nRepeats: Daily\n\n[TUTORIAL_TASK]'
        ..type = MissionType.routine
        ..xpReward = 0
        ..date = startDate
        ..isCompleted = false,
      Mission()
        ..title = 'Tap the + button to create a new mission'
        ..description = 'Use the floating + button to add your own Main Goals, Side Goals, and Daily Routines.\n\nRepeats: Daily\n\n[TUTORIAL_TASK]'
        ..type = MissionType.main
        ..xpReward = 0
        ..date = startDate
        ..isCompleted = false,
      Mission()
        ..title = '📊 Check the Progress tab for your stats'
        ..description = 'Navigate to the Progress tab to see your XP, level, and streak statistics.\n\nRepeats: Daily\n\n[TUTORIAL_TASK]'
        ..type = MissionType.routine
        ..xpReward = 0
        ..date = startDate
        ..isCompleted = false,
      Mission()
        ..title = '🔔 Set reminders for important tasks'
        ..description = 'When creating a mission, set a reminder time to receive a notification at the right moment.\n\nRepeats: Daily\n\n[TUTORIAL_TASK]'
        ..type = MissionType.side
        ..xpReward = 0
        ..date = startDate
        ..isCompleted = false,
    ];

    for (final mission in tutorials) {
      await repository.saveMission(mission);
    }
  }

  /// Returns the LevelUpEvent if a level-up occurred, null otherwise.
  Future<LevelUpEvent?> toggleMissionStatus(Mission mission, {bool fromPlanner = false, int? plannerDayIndex}) async {
    final now = DateTime.now();
    bool isOnce = mission.description == null || (!mission.description!.contains('Repeats: Daily') && !mission.description!.contains('Repeats: Weekly'));
    bool isWeekly = mission.description != null && mission.description!.contains('Repeats: Weekly');
    bool isDaily = mission.description != null && mission.description!.contains('Repeats: Daily');

    bool wasCompleted = false;
    
    if (isWeekly) {
       final dayToToggle = plannerDayIndex ?? now.weekday;
       final completedDaysMatch = RegExp(r'\[CompletedDays:\s*([0-9,\s]+)\]').firstMatch(mission.description!);
       Set<int> completedDays = {};
       if (completedDaysMatch != null && completedDaysMatch.group(1) != null) {
         completedDays = completedDaysMatch.group(1)!.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toSet();
       }
       
       if (completedDays.contains(dayToToggle)) {
          completedDays.remove(dayToToggle);
          wasCompleted = false; // It is now uncompleted
       } else {
          completedDays.add(dayToToggle);
          wasCompleted = true; // It is now completed
       }
       
       // Update the description with the new set
       mission.description = mission.description!.replaceAll(RegExp(r'\n*\[CompletedDays:\s*[0-9,\s]+\]'), '');
       mission.description = mission.description!.replaceAll(RegExp(r'\n*\[LastCompletedWeek:\s*[\d-]+\]'), '');
       
       if (completedDays.isNotEmpty) {
          mission.description = mission.description! + '\n[CompletedDays: ${completedDays.join(', ')}]';
          mission.description = mission.description! + '\n[LastCompletedWeek: ${getStartOfWeek(now).toString().split(' ')[0]}]';
          mission.isCompleted = true; // Set global flag to true for sorts/filters
       } else {
          mission.isCompleted = false;
       }
    } else {
       mission.isCompleted = !mission.isCompleted;
       wasCompleted = mission.isCompleted;
       
       if (isDaily) {
          mission.description = mission.description!.replaceAll(RegExp(r'\n*\[LastCompleted:\s*[\d-]+\]'), '');
          if (wasCompleted) {
             mission.description = mission.description! + '\n[LastCompleted: ${now.toString().split(' ')[0]}]';
          }
       }
    }
    
    // We no longer delete tasks immediately upon completion from Home so they can show in the Completed section.
    // BUT if it is completed from the Planner Tab, the user wants it permanently deleted immediately.
    bool shouldDelete = wasCompleted && fromPlanner;

    // Optimistic update: toggle in current state immediately
    final currentMissions = state.valueOrNull ?? [];
    List<Mission> updatedMissions;
    if (shouldDelete) {
      updatedMissions = currentMissions.where((m) => m.id != mission.id).toList();
    } else {
      updatedMissions = currentMissions.map((m) {
        if (m.id == mission.id) {
          return mission;
        }
        return m;
      }).toList();
    }
    state = AsyncValue.data(updatedMissions);

    // Update the permanent completed counter regardless of deletion
    if (mission.xpReward > 0) {
      if (wasCompleted) {
        await ref.read(userStatsNotifierProvider.notifier).incrementCompletedToday();
      } else {
        await ref.read(userStatsNotifierProvider.notifier).decrementCompletedToday();
      }
    }

    final repository = ref.read(missionRepositoryProvider);
    LevelUpEvent? event;
    
    if (wasCompleted) {
      event = await ref.read(userStatsNotifierProvider.notifier).addXp(mission.xpReward);
      
      // Update streaks if it's NOT a tutorial task
      if (!(mission.description?.contains('[TUTORIAL_TASK]') ?? false)) {
        await ref.read(userStatsNotifierProvider.notifier).checkAndUpdateStreak();
      }

      await NotificationService.cancelNotification(mission.id);
      if (shouldDelete) {
        await repository.deleteMission(mission.id);
      } else {
        await repository.saveMission(mission);
      }
    } else {
      await ref.read(userStatsNotifierProvider.notifier).removeXp(mission.xpReward);
      await repository.saveMission(mission);
      if (mission.reminderTime != null) {
        await NotificationService.scheduleMissionNotification(mission: mission);
      }
    }
    
    return event;
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
    // Optimistic update: remove from current state immediately
    final currentMissions = state.valueOrNull ?? [];
    final updatedMissions = currentMissions.where((m) => m.id != id).toList();
    state = AsyncValue.data(updatedMissions);

    // Then perform the actual delete
    final repository = ref.read(missionRepositoryProvider);
    await NotificationService.cancelNotification(id);
    await repository.deleteMission(id);
  }
}

final missionNotifierProvider = StateNotifierProvider<MissionNotifier, AsyncValue<List<Mission>>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState.isLoading) {
    return MissionNotifier(ref, loadImmediately: false)..setLoading();
  }
  return MissionNotifier(ref, loadImmediately: true);
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
      if (m.isCompleted && (m.description?.contains('[TUTORIAL_TASK]') ?? false)) {
        return false;
      }
      if (filter == 'All') return true;
      if (filter == 'Main') return m.type == MissionType.main;
      if (filter == 'Side') return m.type == MissionType.side;
      if (filter == 'Routine') return m.type == MissionType.routine;
      if (filter == 'Daily') return m.description?.contains('Repeats: Daily') ?? false;
      if (filter.startsWith('Weekly')) {
        if (m.description == null) return false;
        if (!m.description!.contains('Repeats: Weekly')) {
          return false;
        }
        if (filter.contains(':')) {
          final dayStr = filter.split(':')[1];
          final dayIndex = int.tryParse(dayStr);
          if (dayIndex != null) {
            final daysMatch = RegExp(r'Days:\s*([0-9a-zA-Z,\s]+)').firstMatch(m.description!);
            if (daysMatch != null && daysMatch.group(1) != null) {
              final reverseMap = {'Mon': 1, 'Tue': 2, 'Wed': 3, 'Thu': 4, 'Fri': 5, 'Sat': 6, 'Sun': 7};
              final days = <int>{};
              for (final s in daysMatch.group(1)!.split(',')) {
                final val = s.trim();
                if (reverseMap.containsKey(val)) {
                  days.add(reverseMap[val]!);
                } else {
                  final d = int.tryParse(val);
                  if (d != null) days.add(d);
                }
              }
              return days.contains(dayIndex);
            } else {
               return m.date.weekday == dayIndex;
            }
          }
        }
        return true;
      }
      if (filter == 'Once') {
        return m.description == null || 
               m.description!.contains('Repeats: Once') || 
               (!m.description!.contains('Repeats: Daily') && 
                !m.description!.contains('Repeats: Weekly'));
      }
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

  bool isOnce = m.description == null || (!m.description!.contains('Repeats: Daily') && !m.description!.contains('Repeats: Weekly'));

  if (isOnce) {
    if (target.isAtSameMomentAs(start)) return true;
    if (target.isAfter(start) && !m.isCompleted) return true;
    return false;
  }

  final desc = m.description!;
  if (desc.contains('Repeats: Daily')) {
    return true;
  } else if (desc.contains('Repeats: Weekly')) {
    final daysMatch = RegExp(r'Days:\s*([0-9a-zA-Z,\s]+)').firstMatch(desc);
    if (daysMatch != null && daysMatch.group(1) != null) {
      final reverseMap = {'Mon': 1, 'Tue': 2, 'Wed': 3, 'Thu': 4, 'Fri': 5, 'Sat': 6, 'Sun': 7};
      final days = <int>{};
      for (final s in daysMatch.group(1)!.split(',')) {
        final val = s.trim();
        if (reverseMap.containsKey(val)) {
          days.add(reverseMap[val]!);
        } else {
          final d = int.tryParse(val);
          if (d != null) days.add(d);
        }
      }
      
      if (days.isNotEmpty) {
        return days.contains(target.weekday);
      }
    }
    return target.weekday == start.weekday;
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

DateTime getStartOfWeek(DateTime date) {
  final int daysToSubtract = date.weekday - 1;
  final monday = date.subtract(Duration(days: daysToSubtract));
  return DateTime(monday.year, monday.month, monday.day);
}

bool isMissionCompletedForDay(Mission m, int weekday) {
  if (m.description == null || !m.description!.contains('Repeats: Weekly')) {
    return m.isCompleted;
  }
  
  final match = RegExp(r'\[CompletedDays:\s*([0-9,\s]+)\]').firstMatch(m.description!);
  if (match != null && match.group(1) != null) {
    final days = match.group(1)!.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toSet();
    return days.contains(weekday);
  }
  return false;
}
